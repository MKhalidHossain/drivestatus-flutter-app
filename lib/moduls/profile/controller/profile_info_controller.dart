import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/notifiers/snackbar_notifier.dart';
import '../interface/profile_interface.dart';
import '../model/profile_response_model.dart';
import '../model/profile_data.dart';

class ProfileInfoController {
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);

  static void _applyProfile(ProfileResponseModel profile) {
    ProfileData.instance.updateFromProfile(profile);
  }

  static Future<void> loadProfile({SnackbarNotifier? snackbarNotifier}) async {
    try {
      isLoading.value = true;
      final profileInterface = Get.find<ProfileInterface>();
      final result = await profileInterface.getProfile();

      result.fold(
        (failure) {
          snackbarNotifier?.notifyError(
            message: failure.uiMessage.isNotEmpty
                ? failure.uiMessage
                : 'Failed to load profile',
          );
        },
        (success) {
          final profile = success.data;
          if (profile != null) {
            _applyProfile(profile);
          } else {
            snackbarNotifier?.notifyError(message: 'Profile data unavailable');
          }
        },
      );
    } catch (e) {
      snackbarNotifier?.notifyError(
        message: 'An error occurred while loading profile',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
