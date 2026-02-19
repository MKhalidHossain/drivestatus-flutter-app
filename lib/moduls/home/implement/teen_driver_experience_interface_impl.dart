import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/app_pigeon/app_pigeon.dart';
import '../interface/teen_driver_experience_interface.dart';
import '../model/teen_driver_comment_request_model.dart';
import '../model/teen_driver_comment_response_model.dart';
import '../model/teen_driver_experience_request_model.dart';
import '../model/teen_driver_experience_response_model.dart';

final class TeenDriverExperienceInterfaceImpl
    extends TeenDriverExperienceInterface {
  final AppPigeon appPigeon;

  TeenDriverExperienceInterfaceImpl({required this.appPigeon});

  @override
  Future<Either<DataCRUDFailure, Success<TeenDriverExperienceResponseModel>>>
      createTeenDriverExperience({
    required TeenDriverExperienceRequestModel param,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final formData = FormData.fromMap({
          'title': param.title,
          'description': param.description,
          if (param.mediaPath.isNotEmpty)
            'media': await MultipartFile.fromFile(
              param.mediaPath,
              filename: param.mediaPath.split('/').last,
            ),
        });
        final response = await appPigeon.post(
          ApiEndpoints.createTeenDriverExperience,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final message =
            responseBody['message']?.toString() ?? 'Teen post created';

        return Success(
          message: message,
          data: TeenDriverExperienceResponseModel.fromJson(payload),
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<List<TeenDriverExperienceResponseModel>>>>
      getTeenDriverPosts() async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getTeenDriverPosts);
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];
        final message =
            responseBody['message']?.toString() ?? 'Teen posts fetched';

        List<TeenDriverExperienceResponseModel> posts = [];
        if (responseData is List) {
          posts = responseData
              .map((item) => TeenDriverExperienceResponseModel.fromJson(
                  Map<String, dynamic>.from(item)))
              .toList();
        }

        return Success(
          message: message,
          data: posts,
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<TeenDriverCommentResponseModel>>>
      addTeenDriverPostComment({
    required String postId,
    required TeenDriverCommentRequestModel param,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.addTeenDriverPostComment(postId),
          data: param.toJson(),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final message = responseBody['message']?.toString() ?? 'Comment added';

        return Success(
          message: message,
          data: TeenDriverCommentResponseModel.fromJson(payload),
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<TeenDriverCommentResponseModel>>>
      addTeenDriverGlobalComment({
    required TeenDriverCommentRequestModel param,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.addTeenDriverGlobalComment,
          data: param.toJson(),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final message =
            responseBody['message']?.toString() ?? 'Comment added';

        return Success(
          message: message,
          data: TeenDriverCommentResponseModel.fromJson(payload),
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<List<TeenDriverCommentResponseModel>>>>
      getTeenDriverPostComments({required String postId}) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.getTeenDriverPostComments(postId),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];
        final message = responseBody['message']?.toString() ?? 'Comments fetched';

        List<TeenDriverCommentResponseModel> comments = [];
        if (responseData is List) {
          comments = responseData
              .map((item) => TeenDriverCommentResponseModel.fromJson(
                  Map<String, dynamic>.from(item)))
              .toList();
        }

        return Success(
          message: message,
          data: comments,
        );
      },
    );
  }

  @override
  Future<Either<DataCRUDFailure, Success<int>>> likeTeenDriverPost({
    required String postId,
  }) async {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.likeTeenDriverPost(postId),
        );
        final responseBody = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : <String, dynamic>{};
        final responseData = responseBody['data'];
        final payload = responseData is Map
            ? Map<String, dynamic>.from(responseData)
            : <String, dynamic>{};
        final likesCount = payload['likesCount'] is num
            ? (payload['likesCount'] as num).toInt()
            : int.tryParse(payload['likesCount']?.toString() ?? '') ?? 0;
        final message = responseBody['message']?.toString() ?? 'Post liked';

        return Success(
          message: message,
          data: likesCount,
        );
      },
    );
  }
}
