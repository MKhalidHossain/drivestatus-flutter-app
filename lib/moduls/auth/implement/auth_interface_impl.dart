import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bighustle/core/api_handler/failure.dart';
import 'package:flutter_bighustle/core/api_handler/success.dart';
import 'package:flutter_bighustle/core/constants/api_endpoints.dart';
import 'package:flutter_bighustle/core/services/app_pigeon/app_pigeon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../profile/model/profile_data.dart';
import '../interface/auth_interface.dart';
import '../model/forget_password_request_model.dart';
import '../model/login_request_model.dart';
import '../model/login_response_model.dart';
import '../model/logout_request_model.dart';
import '../model/register_request_model.dart';
import '../model/reset_password_request_model.dart';
import '../model/change_password_request_model.dart';
import '../model/verify_email_request_model.dart';
import '../model/verify_email_register_request_model.dart';

final class AuthInterfaceImpl extends AuthInterface {
  final AppPigeon appPigeon;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _appleEmailStoragePrefix = 'apple_sign_in_email_';

  AuthInterfaceImpl({required this.appPigeon});

  ///{signup}
  @override
  Future<Either<DataCRUDFailure, Success<String>>> register({
    required RegisterRequest param,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.signup,
          data: param.toJson(),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody["data"];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : responseBody;
        final userData = payload['user'] is Map
            ? Map<String, dynamic>.from(payload['user'])
            : payload;

        String readString(dynamic value) => value?.toString() ?? '';
        String pickFirstString(List<dynamic> values) {
          for (final value in values) {
            final stringValue = readString(value);
            if (stringValue.isNotEmpty) {
              return stringValue;
            }
          }
          return '';
        }

        final accessToken = pickFirstString([
          payload['accessToken'],
          payload['token'],
          responseBody['accessToken'],
          responseBody['token'],
        ]);
        var refreshToken = pickFirstString([
          payload['refreshToken'],
          responseBody['refreshToken'],
        ]);
        if (refreshToken.isEmpty) {
          refreshToken = accessToken;
        }
        final userId = pickFirstString([
          userData['id'],
          userData['_id'],
          payload['userId'],
          payload['_id'],
          responseBody['userId'],
          responseBody['_id'],
        ]);

        if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
          await appPigeon.saveNewAuth(
            saveAuthParams: SaveNewAuthParams(
              accessToken: accessToken,
              refreshToken: refreshToken,
              data: userData,
              uid: userId.isNotEmpty ? userId : null,
            ),
          );
        }

        return Success(
          message: 'Register Successfuly',
          data: 'Successful Register.',
        );
      },
    );
  }

  ///{logout}
  @override
  Future<Either<DataCRUDFailure, Success<String>>> logout({
    required LogoutRequestModel param,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        try {
          await appPigeon.post(ApiEndpoints.logout, data: param.toJson());
        } finally {
          await appPigeon.logOut();
        }
        return Success(message: 'Logout Succesfuly', data: "Logged out");
      },
    );
  }

  // @override
  // Stream<AuthStatus> authStream() {
  //   return appPigeon.authStream;
  // }

  @override
  Future<Either<DataCRUDFailure, Success<String>>> signInWithApple() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return Left(
        DataCRUDFailure(
          failure: Failure.authFailure,
          uiMessage: 'Sign in with Apple is available only on Apple devices.',
          fullError: 'Sign in with Apple is not supported on this platform.',
        ),
      );
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final appleUserId = credential.userIdentifier?.trim() ?? '';
      if (appleUserId.isEmpty) {
        return Left(
          DataCRUDFailure(
            failure: Failure.authFailure,
            uiMessage: 'Apple sign-in did not return a user identifier.',
            fullError: 'Missing Apple user identifier from Apple credential.',
          ),
        );
      }

      final email = await _resolveAppleEmail(
        appleUserId: appleUserId,
        credentialEmail: credential.email,
      );
      if (email.isEmpty) {
        return Left(
          DataCRUDFailure(
            failure: Failure.authFailure,
            uiMessage:
                'Apple did not share an email for this sign-in. Try once more on the same device, or use your existing login.',
            fullError: 'Missing Apple sign-in email for user $appleUserId.',
          ),
        );
      }

      final password = _applePasswordForUser(appleUserId);

      final loginResult = await login(
        param: LoginRequestModel(email: email, password: password),
      );
      DataCRUDFailure? loginFailure;
      final loggedIn = await loginResult.fold((failure) async {
        loginFailure = failure;
        return false;
      }, (_) async => true);
      if (loggedIn) {
        await _persistAppleIdentityOnCurrentAuth(
          credential: credential,
          email: email,
        );
        return Right(Success(data: 'apple'));
      }
      if (loginFailure != null &&
          !_shouldAttemptAppleAutoRegistration(loginFailure!)) {
        return Left(loginFailure!);
      }

      final registerResult = await register(
        param: RegisterRequest(
          email: email,
          password: password,
          confirmPassword: password,
        ),
      );

      return await registerResult.fold((failure) async {
        if (_looksLikeExistingAccountError(failure)) {
          return Left(
            DataCRUDFailure(
              failure: Failure.authFailure,
              uiMessage:
                  'An account already exists for $email. Use your current email login, or add a dedicated Apple login endpoint on the backend.',
              fullError: failure.fullError,
            ),
          );
        }
        return Left(failure);
      }, (_) async {
        final secondLogin = await login(
          param: LoginRequestModel(email: email, password: password),
        );
        return await secondLogin.fold((failure) async {
          return Left(failure);
        }, (_) async {
          await _persistAppleIdentityOnCurrentAuth(
            credential: credential,
            email: email,
          );
          return Right(Success(data: 'apple'));
        });
      });
    } on SignInWithAppleAuthorizationException catch (error) {
      final normalized = error.code.name.toLowerCase();
      final isCanceled = normalized.contains('cancel');
      return Left(
        DataCRUDFailure(
          failure: isCanceled ? Failure.authFailure : Failure.unknownFailure,
          uiMessage: isCanceled
              ? 'Apple sign-in was canceled.'
              : 'Unable to complete Sign in with Apple.',
          fullError: error.toString(),
        ),
      );
    } catch (error) {
      return Left(
        DataCRUDFailure(
          failure: Failure.unknownFailure,
          uiMessage: 'Unable to complete Sign in with Apple.',
          fullError: error.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<DataCRUDFailure, Success<String>>> login({
    required LoginRequestModel param,
  }) async {
    try {
      final response = await appPigeon.post(
        ApiEndpoints.login,
        data: param.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        final errorMessage = response.data is Map
            ? response.data['message']?.toString() ?? 'Login failed'
            : 'Login failed';
        return Left(
          DataCRUDFailure(
            failure: Failure.dioFailure,
            fullError: errorMessage,
            uiMessage: errorMessage,
          ),
        );
      }

      final responseBody = response.data is Map
          ? Map<String, dynamic>.from(response.data)
          : <String, dynamic>{};
      final loginResponse = LoginResponseModel.fromJson(responseBody);
      final accessToken = loginResponse.accessToken;
      final refreshToken = loginResponse.refreshToken;
      final role = loginResponse.role;

      if (accessToken.isEmpty) {
        return Left(
          DataCRUDFailure(
            failure: Failure.dioFailure,
            fullError: 'Invalid token data',
            uiMessage: 'Authentication failed. Please try again.',
          ),
        );
      }

      // Save tokens directly using AppPigeon service
      await appPigeon.saveNewAuth(
        saveAuthParams: SaveNewAuthParams(
          accessToken: accessToken,
          refreshToken: refreshToken,
          data: loginResponse.authData,
          uid: loginResponse.userId.isNotEmpty ? loginResponse.userId : null,
        ),
      );
      ProfileData.instance.updateSubscription(
        subscribed: loginResponse.subscribed,
        planName: loginResponse.planName,
        subscriptionInterval: loginResponse.subscriptionInterval,
        subscriptionStartsAt: loginResponse.subscriptionStartsAt,
        subscriptionEndsAt: loginResponse.subscriptionEndsAt,
      );

      return Right(Success(data: role));
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      final message = responseData is Map && responseData['message'] != null
          ? responseData['message'].toString()
          : e.message ?? 'Login failed';
      return Left(
        DataCRUDFailure(
          failure: statusCode == 403 ? Failure.forbidden : Failure.dioFailure,
          fullError: message,
          uiMessage: message,
        ),
      );
    } catch (e) {
      return Left(
        DataCRUDFailure(
          failure: Failure.dioFailure,
          fullError: e.toString(),
          uiMessage: 'An error occurred. Please try again.',
        ),
      );
    }
  }

  ///{Forget Password}
  @override
  Future<Either<DataCRUDFailure, Success<String>>> forgetPassword({
    required ForgetPasswordRequestModel param,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        await appPigeon.post(ApiEndpoints.forgetPassword, data: param.toJson());
        return Success(message: 'OTP send to your mail', data: '');
      },
    );
  }

  ///{Verify Email}
  @override
  Future<Either<DataCRUDFailure, Success<String>>> verifyEmail({
    required VerifyEmailRequestModel param,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.verifyCode,
          data: param.toJson(),
        );
        final data = response.data['data'];
        String userId = '';
        if (data is Map) {
          if (data['userId'] != null) {
            userId = data['userId'].toString();
          } else if (data['user'] is Map && data['user']['id'] != null) {
            userId = data['user']['id'].toString();
          } else if (data['user'] is Map && data['user']['_id'] != null) {
            userId = data['user']['_id'].toString();
          }
        }
        return Success(message: 'Email verified successfully', data: userId);
      },
    );
  }

  ///{Verify Register Email}
  @override
  Future<Either<DataCRUDFailure, Success<String>>> verifyRegisterEmail({
    required VerifyEmailRegisterRequestModel param,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        await appPigeon.post(ApiEndpoints.verifyEmail, data: param.toJson());
        return Success(message: 'Email verified successfully', data: '');
      },
    );
  }

  ///{Reset Password}
  @override
  Future<Either<DataCRUDFailure, Success<String>>> resetPassword({
    required ResetPasswordRequestModel param,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        await appPigeon.put(ApiEndpoints.resetPassword, data: param.toJson());
        return Success(message: 'Password reset successfully', data: '');
      },
    );
  }

  ///{Change Password}
  @override
  Future<Either<DataCRUDFailure, Success<String>>> changePassword({
    required ChangePasswordRequestModel param,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        await appPigeon.post(ApiEndpoints.changePassword, data: param.toJson());
        return Success(message: 'Password changed successfully', data: '');
      },
    );
  }

  String _applePasswordForUser(String appleUserId) {
    final encoded = base64Url.encode(utf8.encode(appleUserId));
    final sanitized = encoded.replaceAll('=', '');
    return 'AppleAuth!$sanitized';
  }

  Future<String> _resolveAppleEmail({
    required String appleUserId,
    required String? credentialEmail,
  }) async {
    final email = credentialEmail?.trim() ?? '';
    final storageKey = '$_appleEmailStoragePrefix$appleUserId';
    if (email.isNotEmpty) {
      await _secureStorage.write(key: storageKey, value: email);
      return email;
    }

    return (await _secureStorage.read(key: storageKey))?.trim() ?? '';
  }

  bool _looksLikeExistingAccountError(DataCRUDFailure failure) {
    final normalized = failure.fullError.trim().toLowerCase();
    return normalized.contains('already') ||
        normalized.contains('exist') ||
        normalized.contains('taken') ||
        normalized.contains('duplicate');
  }

  bool _shouldAttemptAppleAutoRegistration(DataCRUDFailure failure) {
    if (failure.failure == Failure.forbidden ||
        failure.failure == Failure.socketFailure ||
        failure.failure == Failure.timeout) {
      return false;
    }

    final normalized = failure.fullError.trim().toLowerCase();
    return normalized.contains('invalid') ||
        normalized.contains('not found') ||
        normalized.contains('not exist') ||
        normalized.contains('incorrect') ||
        normalized.contains('failed');
  }

  Future<void> _persistAppleIdentityOnCurrentAuth({
    required AuthorizationCredentialAppleID credential,
    required String email,
  }) async {
    final status = await appPigeon.currentAuth();
    if (status is! Authenticated) {
      return;
    }

    final authData = Map<String, dynamic>.from(status.auth.data);
    authData['authProvider'] = 'apple';
    authData['appleUserIdentifier'] = credential.userIdentifier;
    authData['appleEmail'] = email;
    if ((credential.givenName ?? '').trim().isNotEmpty) {
      authData['firstName'] = credential.givenName!.trim();
    }
    if ((credential.familyName ?? '').trim().isNotEmpty) {
      authData['lastName'] = credential.familyName!.trim();
    }
    if ((credential.identityToken ?? '').trim().isNotEmpty) {
      authData['appleIdentityToken'] = credential.identityToken!.trim();
    }
    if ((credential.authorizationCode ?? '').trim().isNotEmpty) {
      authData['appleAuthorizationCode'] =
          credential.authorizationCode!.trim();
    }

    await appPigeon.updateCurrentAuth(
      updateAuthParams: UpdateAuthParams(
        accessToken: status.auth.accessToken ?? '',
        refreshToken: status.auth.refreshToken ?? '',
        data: authData,
      ),
    );
  }
}
