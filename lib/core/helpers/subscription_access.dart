import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../moduls/profile/model/profile_data.dart';
import '../../moduls/subscribe/presentation/screen/subscribe_screen.dart';
import '../services/app_pigeon/app_pigeon.dart';

class SubscriptionAccess {
  SubscriptionAccess._();

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static String _readString(dynamic value) => value?.toString().trim() ?? '';

  static bool _extractSubscribed(Map<String, dynamic> data) {
    final direct = data['subscribed'] ?? data['isSubscribed'];
    if (direct != null) {
      return _readBool(direct);
    }
    final nestedUser = data['user'];
    if (nestedUser is Map) {
      return _extractSubscribed(Map<String, dynamic>.from(nestedUser));
    }
    return false;
  }

  static String _extractPlanName(Map<String, dynamic> data) {
    final direct = _readString(data['planName']);
    if (direct.isNotEmpty) return direct;

    final currentPlan = data['currentPlan'];
    if (currentPlan is Map) {
      final currentName = _readString(currentPlan['name']);
      if (currentName.isNotEmpty) return currentName;
    }

    final nestedUser = data['user'];
    if (nestedUser is Map) {
      return _extractPlanName(Map<String, dynamic>.from(nestedUser));
    }

    return '';
  }

  static String _extractSubscriptionInterval(Map<String, dynamic> data) {
    final direct = _readString(data['subscriptionInterval']);
    if (direct.isNotEmpty) return direct;

    final currentPlan = data['currentPlan'];
    if (currentPlan is Map) {
      final currentInterval = _readString(currentPlan['interval']);
      if (currentInterval.isNotEmpty) return currentInterval;
    }

    final nestedUser = data['user'];
    if (nestedUser is Map) {
      return _extractSubscriptionInterval(
        Map<String, dynamic>.from(nestedUser),
      );
    }

    return '';
  }

  static Future<bool> syncFromCurrentAuth() async {
    try {
      final appPigeon = Get.find<AppPigeon>();
      final status = await appPigeon.currentAuth();
      if (status is! Authenticated) {
        return ProfileData.instance.subscribed;
      }

      final source = status.auth.data;
      final subscribed = _extractSubscribed(source);
      final planName = _extractPlanName(source);
      final subscriptionInterval = _extractSubscriptionInterval(source);

      ProfileData.instance.updateSubscription(
        subscribed: subscribed,
        planName: planName,
        subscriptionInterval: subscriptionInterval,
      );
      return subscribed;
    } catch (_) {
      return ProfileData.instance.subscribed;
    }
  }

  static Future<bool> isSubscribed() async {
    if (ProfileData.instance.hasLoaded) {
      return ProfileData.instance.subscribed;
    }
    return syncFromCurrentAuth();
  }

  static Future<bool> ensureSubscribedAction({
    required BuildContext context,
    required String featureName,
  }) async {
    final subscribed = await isSubscribed();
    if (subscribed) return true;
    if (!context.mounted) return false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Subscription Required'),
          content: Text('$featureName is available for subscribed users only.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscribeScreen()),
                );
              },
              child: const Text('View Plans'),
            ),
          ],
        );
      },
    );
    return false;
  }
}
