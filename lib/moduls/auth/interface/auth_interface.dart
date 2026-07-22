import 'package:dartz/dartz.dart';

import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../model/forget_password_request_model.dart';
import '../model/login_request_model.dart';
import '../model/logout_request_model.dart';
import '../model/register_request_model.dart' show RegisterRequest;
import '../model/reset_password_request_model.dart';
import '../model/change_password_request_model.dart';
import '../model/verify_email_request_model.dart';
import '../model/verify_email_register_request_model.dart';

abstract base class AuthInterface extends BaseRepository {
  Future<Either<DataCRUDFailure,Success<String>>> login( {required LoginRequestModel param});

  Future<Either<DataCRUDFailure,Success<String>>> signInWithApple();

  Future<Either<DataCRUDFailure,Success<String>>> register( {required RegisterRequest param});

  Future<Either<DataCRUDFailure,Success<String>>> forgetPassword( {required ForgetPasswordRequestModel param});
  
  Future<Either<DataCRUDFailure,Success<String>>> verifyEmail( {required VerifyEmailRequestModel param});

  Future<Either<DataCRUDFailure,Success<String>>> verifyRegisterEmail({required VerifyEmailRegisterRequestModel param});
  
  Future<Either<DataCRUDFailure,Success<String>>> resetPassword( {required ResetPasswordRequestModel param});
  Future<Either<DataCRUDFailure,Success<String>>> logout({required LogoutRequestModel param});
  Future<Either<DataCRUDFailure,Success<String>>> changePassword({required ChangePasswordRequestModel param});
  // Stream<AuthStatus> authStream();
}
