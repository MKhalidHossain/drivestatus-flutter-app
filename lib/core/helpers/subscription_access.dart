import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_routes.dart';
import '../../moduls/profile/model/profile_data.dart';
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

  static String normalizeInterval(String interval) {
    final value = interval.trim().toLowerCase();
    if (value.startsWith('year')) return 'year';
    if (value.startsWith('month')) return 'month';
    return value;
  }

  static String _currentSubscriptionInterval() {
    final fromInterval = normalizeInterval(
      ProfileData.instance.subscriptionInterval,
    );
    if (fromInterval == 'month' || fromInterval == 'year') {
      return fromInterval;
    }

    final planName = ProfileData.instance.planName.trim().toLowerCase();
    if (planName.contains('year')) return 'year';
    if (planName.contains('month')) return 'month';
    return '';
  }

  static DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  static DateTime? _currentSubscriptionStartsAt() {
    return _parseDate(ProfileData.instance.subscriptionStartsAt);
  }

  static DateTime _addMonthsUtc(DateTime source, int months) {
    final monthIndex = source.month - 1 + months;
    final year = source.year + (monthIndex ~/ 12);
    final month = (monthIndex % 12) + 1;
    final maxDay = DateTime.utc(year, month + 1, 0).day;
    final day = source.day <= maxDay ? source.day : maxDay;
    return DateTime.utc(
      year,
      month,
      day,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }

  static DateTime? estimateSubscriptionEndsAt({
    required DateTime startsAtUtc,
    required String interval,
  }) {
    final normalized = normalizeInterval(interval);
    if (normalized == 'year') {
      return _addMonthsUtc(startsAtUtc.toUtc(), 12);
    }
    if (normalized == 'month') {
      return _addMonthsUtc(startsAtUtc.toUtc(), 1);
    }
    return null;
  }

  static DateTime? currentSubscriptionEndsAt() {
    final direct = _parseDate(ProfileData.instance.subscriptionEndsAt);
    if (direct != null) return direct;

    final startsAt = _currentSubscriptionStartsAt();
    if (startsAt == null) return null;

    final interval = _currentSubscriptionInterval();
    return estimateSubscriptionEndsAt(
      startsAtUtc: startsAt.toUtc(),
      interval: interval,
    );
  }

  static bool isCurrentSubscriptionActive({DateTime? now}) {
    if (!ProfileData.instance.subscribed) return false;

    final referenceNow = now ?? DateTime.now();
    final endsAt = currentSubscriptionEndsAt();
    if (endsAt == null) {
      // Conservative fallback: if backend marks subscribed but did not send end date,
      // block re-subscribe to avoid duplicate payment attempts.
      return true;
    }
    return !referenceNow.isAfter(endsAt);
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  static String activeSubscriptionPlanLabel() {
    final interval = _currentSubscriptionInterval();
    if (interval == 'year') return 'yearly';
    if (interval == 'month') return 'monthly';
    if (ProfileData.instance.planName.trim().isNotEmpty) {
      return ProfileData.instance.planName.trim();
    }
    return 'current';
  }

  static String? activeSubscriptionBlockMessage({DateTime? now}) {
    if (!isCurrentSubscriptionActive(now: now)) return null;
    final label = activeSubscriptionPlanLabel();
    final endsAt = currentSubscriptionEndsAt();
    if (endsAt != null) {
      return 'You already subscribed to the $label plan until ${_formatDate(endsAt)}.';
    }
    return 'You already subscribed to the $label plan.';
  }

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

  static String _extractSubscriptionStartsAt(Map<String, dynamic> data) {
    final direct = _readString(
      data['subscriptionStartsAt'] ??
          data['subscriptionStartAt'] ??
          data['subscriptionStartDate'],
    );
    if (direct.isNotEmpty) return direct;

    final subscription = data['subscription'];
    if (subscription is Map) {
      final nested = _extractSubscriptionStartsAt(
        Map<String, dynamic>.from(subscription),
      );
      if (nested.isNotEmpty) return nested;
    }

    final nestedUser = data['user'];
    if (nestedUser is Map) {
      return _extractSubscriptionStartsAt(
        Map<String, dynamic>.from(nestedUser),
      );
    }

    return '';
  }

  static String _extractSubscriptionEndsAt(Map<String, dynamic> data) {
    final direct = _readString(
      data['subscriptionEndsAt'] ??
          data['subscriptionEndAt'] ??
          data['subscriptionEndDate'] ??
          data['expireAt'] ??
          data['expiresAt'],
    );
    if (direct.isNotEmpty) return direct;

    final subscription = data['subscription'];
    if (subscription is Map) {
      final nested = _extractSubscriptionEndsAt(
        Map<String, dynamic>.from(subscription),
      );
      if (nested.isNotEmpty) return nested;
    }

    final nestedUser = data['user'];
    if (nestedUser is Map) {
      return _extractSubscriptionEndsAt(Map<String, dynamic>.from(nestedUser));
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
      final subscriptionStartsAt = _extractSubscriptionStartsAt(source);
      final subscriptionEndsAt = _extractSubscriptionEndsAt(source);

      ProfileData.instance.updateSubscription(
        subscribed: subscribed,
        planName: planName,
        subscriptionInterval: subscriptionInterval,
        subscriptionStartsAt: subscriptionStartsAt,
        subscriptionEndsAt: subscriptionEndsAt,
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
                Navigator.pushNamed(context, AppRoutes.subscriptions);
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
