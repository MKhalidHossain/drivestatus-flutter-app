import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bighustle/core/api_handler/failure.dart';
import 'package:flutter_bighustle/core/api_handler/success.dart';
import 'package:flutter_bighustle/core/constants/api_endpoints.dart';
import 'package:flutter_bighustle/core/services/app_pigeon/app_pigeon.dart';
import '../model/delete_account_request_model.dart';
import '../interface/profile_interface.dart';
import '../model/notification_settings_request_model.dart';
import '../model/profile_response_model.dart';
import '../model/update_profile_request_model.dart';
// import '../model/forget_password_request_model.dart';
// import '../model/login_request_model.dart';
// import '../model/logout_request_model.dart';
// import '../model/register_request_model.dart';
// import '../model/reset_password_request_model.dart';
// import '../model/change_password_request_model.dart';
// import '../model/verify_email_request_model.dart';
// import '../model/verify_email_register_request_model.dart';

final class ProfileInterfaceImpl extends ProfileInterface {
  final AppPigeon appPigeon;

  ProfileInterfaceImpl({required this.appPigeon});

  @override
  Future<Either<DataCRUDFailure, Success<ProfileResponseModel>>> getProfile() {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getCurrentProfile);
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody["data"];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final profile = ProfileResponseModel.fromJson(payload);

        return Success(
          message: responseBody['message']?.toString() ?? 'Profile fetched',
          data: profile,
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<String>>> deleteAccount({
    required DeleteAccountRequestModel param,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.delete(
          ApiEndpoints.deleteAccount,
          data: param.toJson(),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};

        return Success(
          message:
              responseBody['message']?.toString() ??
              'Account deleted successfully',
          data: responseBody['data']?['email']?.toString() ?? '',
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<ProfileResponseModel>>>
  updateNotificationSettings({
    required NotificationSettingsRequestModel param,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.put(
          ApiEndpoints.updateNotificationSettings,
          data: param.toJson(),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody["data"];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final profile = ProfileResponseModel.fromJson(payload);

        return Success(
          message:
              responseBody['message']?.toString() ??
              'Settings updated successfully',
          data: profile,
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<ProfileResponseModel>>> updateProfile({
    required UpdateProfileRequestModel param,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final formDataMap = Map<String, dynamic>.from(param.toJson());
        final avatarPath = param.avatarPath;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          final normalizedPath = avatarPath.startsWith('file://')
              ? avatarPath.replaceFirst('file://', '')
              : avatarPath;
          if (!normalizedPath.startsWith('http') &&
              normalizedPath.contains('/')) {
            formDataMap['avatar'] = await MultipartFile.fromFile(
              normalizedPath,
              filename: normalizedPath.split('/').last,
            );
          }
        }
        final formData = FormData.fromMap(formDataMap);
        final response = await appPigeon.put(
          ApiEndpoints.editProfile,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody["data"];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final profile = ProfileResponseModel.fromJson(payload);

        return Success(
          message: responseBody['message']?.toString() ?? 'Profile updated',
          data: profile,
        );
      },
    );
  }

  // ///{signup}
  // @override
  // Future<Either<DataCRUDFailure, Success<String>>> register({
  //   required RegisterRequest param,
  // }) async {
  //   return asyncTryCatch(
  //     tryFunc: () async {
  //       final response = await appPigeon.post(
  //         ApiEndpoints.signup,
  //         data: param.toJson(),
  //       );
  //       final responseBody = response.data is Map
  //           ? Map<String, dynamic>.from(response.data)
  //           : <String, dynamic>{};
  //       final responseData = responseBody["data"];
  //       final payload = responseData is Map
  //           ? Map<String, dynamic>.from(responseData)
  //           : responseBody;
  //       final userData = payload['user'] is Map
  //           ? Map<String, dynamic>.from(payload['user'])
  //           : payload;

  //       String readString(dynamic value) => value?.toString() ?? '';
  //       String pickFirstString(List<dynamic> values) {
  //         for (final value in values) {
  //           final stringValue = readString(value);
  //           if (stringValue.isNotEmpty) {
  //             return stringValue;
  //           }
  //         }
  //         return '';
  //       }

  //       final accessToken = pickFirstString([
  //         payload['accessToken'],
  //         payload['token'],
  //         responseBody['accessToken'],
  //         responseBody['token'],
  //       ]);
  //       var refreshToken = pickFirstString([
  //         payload['refreshToken'],
  //         responseBody['refreshToken'],
  //       ]);
  //       if (refreshToken.isEmpty) {
  //         refreshToken = accessToken;
  //       }
  //       final userId = pickFirstString([
  //         userData['id'],
  //         userData['_id'],
  //         payload['userId'],
  //         payload['_id'],
  //         responseBody['userId'],
  //         responseBody['_id'],
  //       ]);

  //       if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
  //         await appPigeon.saveNewAuth(
  //           saveAuthParams: SaveNewAuthParams(
  //             accessToken: accessToken,
  //             refreshToken: refreshToken,
  //             data: userData,
  //             uid: userId.isNotEmpty ? userId : null,
  //           ),
  //         );
  //       }

  //       return Success(
  //         message: 'Register Successfuly',
  //         data: 'Successful Register.',
  //       );
  //     },
  //   );
  // }
}
