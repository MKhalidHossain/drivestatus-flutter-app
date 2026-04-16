import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bighustle/core/api_handler/failure.dart';
import 'package:flutter_bighustle/core/api_handler/success.dart';
import 'package:flutter_bighustle/core/constants/api_endpoints.dart';
import 'package:flutter_bighustle/core/services/app_pigeon/app_pigeon.dart';
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
      if (refreshToken.isEmpty) {
        return Left(
          DataCRUDFailure(
            failure: Failure.dioFailure,
            fullError: 'Refresh token missing in login response',
            uiMessage: 'Authentication failed. Please log in again.',
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
}
