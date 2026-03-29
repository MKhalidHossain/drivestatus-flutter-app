import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/helpers/handle_fold.dart';
import '../../../core/helpers/validation.dart';
import '../../../core/notifiers/button_status_notifier.dart';
import '../../../core/notifiers/snackbar_notifier.dart';
import '../interface/auth_interface.dart';
import '../model/register_request_model.dart';

class RegisterScreenController extends ChangeNotifier {
  final ProcessStatusNotifier processStatusNotifier = ProcessStatusNotifier();
  final SnackbarNotifier snackbarNotifier;

  RegisterScreenController(this.snackbarNotifier);

  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  // Simple flags you can use in UI without depending on ProcessStatusNotifier internals
  bool _busy = false;
  bool get isBusy => _busy;

  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;

  set email(String v) {
    if (v != _email) {
      _email = v.trim();
      _canRegister();
      notifyListeners();
    }
  }

  set password(String v) {
    if (v != _password) {
      _password = v;
      _canRegister();
      notifyListeners();
    }
  }

  set confirmPassword(String v) {
    if (v != _confirmPassword) {
      _confirmPassword = v;
      _canRegister();
      notifyListeners();
    }
  }

  // Local “can submit” check so the UI doesn’t need to access internal fields of ProcessStatusNotifier
  bool get canSubmit =>
      _email.isNotEmpty &&
          isEmail(_email) &&
          _password.isNotEmpty &&
          _password.length >= 6 &&
          _confirmPassword.isNotEmpty &&
          _confirmPassword == _password;

  void _canRegister() {
    if (canSubmit) {
      processStatusNotifier.setEnabled();
    } else {
      processStatusNotifier.setDisabled();
    }
  }

  Future<void> register({
    VoidCallback? onSuccessNavigate, // Optional: navigate upon success
  }) async {
    // Guard
    if (!canSubmit) {
      // snackbarNotifier.error(message: 'Please fill all fields correctly.');
      return;
    }
    _busy = true;
    notifyListeners();
    processStatusNotifier.setLoading();

    final payload = RegisterRequest(
      email: _email,
      password: _password,
      confirmPassword: _confirmPassword,
    );

    // Optional small delay to match your login behavior
    await Future.delayed(const Duration(milliseconds: 600));

    final either = await Get.find<AuthInterface>().register(param: payload);
    bool didSucceed = false;
    either.fold((_) {}, (_) => didSucceed = true);
    handleFold(
      either: either,
      processStatusNotifier: processStatusNotifier,
      successSnackbarNotifier: snackbarNotifier,
      errorSnackbarNotifier: snackbarNotifier,
    );
    if (didSucceed && onSuccessNavigate != null) {
      onSuccessNavigate();
    }

    _busy = false;
    notifyListeners();
  }
}
