import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../interface/license_interface.dart';
import '../model/license_alert_model.dart';
import '../model/license_create_request_model.dart';
import '../model/license_response_model.dart';

final class LicenseInterfaceImpl extends LicenseInterface {
  final AppPigeon appPigeon;

  LicenseInterfaceImpl({required this.appPigeon});

  @override
  Future<Either<DataCRUDFailure, Success<String>>> createLicense({
    required LicenseCreateRequestModel param,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final formData = FormData.fromMap({
          'fullName': param.fullName,
          'licenseNumber': param.licenseNumber,
          'state': param.state,
          'dateOfBirth': param.dateOfBirth,
          'expiryDate': param.expiryDate,
          'licenseClass': param.licenseClass,
          'userPhoto': await MultipartFile.fromFile(
            param.userPhoto,
            filename: param.userPhoto.split('/').last,
          ),
          'licensePhoto': await MultipartFile.fromFile(
            param.licensePhoto,
            filename: param.licensePhoto.split('/').last,
          ),
        });
        final response = await appPigeon.post(
          ApiEndpoints.createLicense,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final message =
            responseBody['message']?.toString() ?? 'License created successfully';

        return Success(
          message: message,
          data: message,
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<List<LicenseResponseModel>>>> getLicense() async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getLicense);
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody["data"];
        
        if (responseData == null) {
          return Success(
            message: 'No license data found',
            data: <LicenseResponseModel>[],
          );
        }

        List<LicenseResponseModel> licenses = [];
        if (responseData is List) {
          licenses = responseData
              .map((item) => LicenseResponseModel.fromJson(
                  Map<String, dynamic>.from(item)))
              .toList();
        } else if (responseData is Map) {
          // If single license object instead of array
          licenses = [LicenseResponseModel.fromJson(
              Map<String, dynamic>.from(responseData))];
        }

        return Success(
          message: responseBody['message']?.toString() ?? 'Licenses fetched successfully',
          data: licenses,
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<String>>> updateLicense({
    required String userId,
    required LicenseCreateRequestModel param,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final formDataMap = <String, dynamic>{
          'name': param.fullName,
          'licenseNumber': param.licenseNumber,
          'state': param.state,
          'dateOfBirth': param.dateOfBirth,
          'expirationDate': param.expiryDate,
          'licenseClass': param.licenseClass,
        };

        // Add files only if they are valid file paths (not empty strings)
        if (param.userPhoto.isNotEmpty && 
            !param.userPhoto.startsWith('http') &&
            param.userPhoto.contains('/')) {
          formDataMap['userPhoto'] = await MultipartFile.fromFile(
            param.userPhoto,
            filename: param.userPhoto.split('/').last,
          );
        }

        if (param.licensePhoto.isNotEmpty && 
            !param.licensePhoto.startsWith('http') &&
            param.licensePhoto.contains('/')) {
          formDataMap['licensePhoto'] = await MultipartFile.fromFile(
            param.licensePhoto,
            filename: param.licensePhoto.split('/').last,
          );
        }

        final formData = FormData.fromMap(formDataMap);
        
        final response = await appPigeon.put(
          ApiEndpoints.updateLicense(userId),
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final message =
            responseBody['message']?.toString() ?? 'License updated successfully';

        return Success(
          message: message,
          data: message,
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<List<LicenseAlertModel>>>> getAlerts() async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getAlerts);
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody["data"];
        
        if (responseData == null) {
          return Success(
            message: responseBody['message']?.toString() ?? 'No alerts found',
            data: <LicenseAlertModel>[],
          );
        }

        List<LicenseAlertModel> alerts = [];
        if (responseData is List) {
          alerts = responseData
              .map((item) => LicenseAlertModel.fromJson(
                  Map<String, dynamic>.from(item)))
              .toList();
        }

        return Success(
          message: responseBody['message']?.toString() ?? 'Alerts fetched successfully',
          data: alerts,
        );
      },
    );
  }
}
