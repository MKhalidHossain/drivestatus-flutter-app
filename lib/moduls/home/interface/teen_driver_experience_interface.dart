import 'package:dartz/dartz.dart';

import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../model/teen_driver_comment_request_model.dart';
import '../model/teen_driver_comment_response_model.dart';
import '../model/teen_driver_experience_request_model.dart';
import '../model/teen_driver_experience_response_model.dart';

abstract base class TeenDriverExperienceInterface extends BaseRepository {
  Future<Either<DataCRUDFailure, Success<TeenDriverExperienceResponseModel>>>
      createTeenDriverExperience({
    required TeenDriverExperienceRequestModel param,
  });

  Future<Either<DataCRUDFailure,
      Success<List<TeenDriverExperienceResponseModel>>>> getTeenDriverPosts();

  Future<Either<DataCRUDFailure, Success<TeenDriverCommentResponseModel>>>
      addTeenDriverPostComment({
    required String postId,
    required TeenDriverCommentRequestModel param,
  });

  Future<Either<DataCRUDFailure, Success<TeenDriverCommentResponseModel>>>
      addTeenDriverGlobalComment({
    required TeenDriverCommentRequestModel param,
  });

  Future<Either<DataCRUDFailure, Success<List<TeenDriverCommentResponseModel>>>>
      getTeenDriverPostComments({
    required String postId,
  });

  Future<Either<DataCRUDFailure, Success<int>>> likeTeenDriverPost({
    required String postId,
  });
}
