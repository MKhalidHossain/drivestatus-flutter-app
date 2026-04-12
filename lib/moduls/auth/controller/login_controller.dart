import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api_handler/failure.dart';
import '../../../core/notifiers/button_status_notifier.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../interface/auth_interface.dart';
import '../model/login_request_model.dart';

class LoginsScreenController extends ChangeNotifier {
  final ProcessStatusNotifier processStatusNotifier = ProcessStatusNotifier();
  final SnackbarNotifier snackbarNotifier;
  String _email = '';
  String get email => _email;

  bool get canSubmit => _email.isNotEmpty && _password.isNotEmpty;

  void canLogin() {
    if (canSubmit) {
      processStatusNotifier.setEnabled();
    } else {
      processStatusNotifier.setDisabled();
    }
  }
  
  set email(String value) {
    if (value != _email) {
      _email = value.trim();
      canLogin();
      notifyListeners();
    }
  }

  String _password = '';
  LoginsScreenController(this.snackbarNotifier);
  String get password => _password;
  
  set password(String value) {
    if (value != _password) {
      _password = value;
      canLogin();
      notifyListeners();
    }
  }

  Future<bool> login({
    required VoidCallback needVerification,
  }) async {
    processStatusNotifier.setLoading();
    
    try {
      final result = await Get.find<AuthInterface>().login(
        param: LoginRequestModel(email: email, password: password),
      );
      
      return await result.fold(
        (failure) {
          if (failure.failure == Failure.forbidden) {
            needVerification();
          } else {
            final errorMessage = failure.uiMessage.isNotEmpty 
                ? failure.uiMessage
                : 'Invalid email or password. Please try again.';
            snackbarNotifier.notifyError(message: errorMessage);
          }
          processStatusNotifier.setError();
          return false;
        },
        (success) async {
          processStatusNotifier.setSuccess();
          return true;
        },
      );
    } on FormatException {
      processStatusNotifier.setError();
      snackbarNotifier.notifyError(
        message: 'Invalid response from server. Please try again.',
      );
      return false;
    } catch (e) {
      snackbarNotifier.notifyError(
        message: 'An unexpected error occurred. Please try again.',
      );
       return false;
    }
  }

}
