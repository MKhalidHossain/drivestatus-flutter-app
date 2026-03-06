import 'package:dartz/dartz.dart';
import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../model/delete_account_request_model.dart';
import '../model/notification_settings_request_model.dart';
import '../model/profile_response_model.dart';
import '../model/update_profile_request_model.dart';

abstract base class ProfileInterface extends BaseRepository {
  Future<Either<DataCRUDFailure, Success<ProfileResponseModel>>> getProfile();

  Future<Either<DataCRUDFailure, Success<String>>> deleteAccount({
    required DeleteAccountRequestModel param,
  });

  Future<Either<DataCRUDFailure, Success<ProfileResponseModel>>>
  updateNotificationSettings({required NotificationSettingsRequestModel param});

  Future<Either<DataCRUDFailure, Success<ProfileResponseModel>>> updateProfile({
    required UpdateProfileRequestModel param,
  });
}
