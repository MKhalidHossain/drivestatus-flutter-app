class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String role;
  final bool subscribed;
  final String subscriptionPlanId;
  final String planName;
  final String subscriptionInterval;
  final String subscriptionStartsAt;
  final String subscriptionEndsAt;
  final Map<String, dynamic> responseBody;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> authData;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
    required this.subscribed,
    required this.subscriptionPlanId,
    required this.planName,
    required this.subscriptionInterval,
    required this.subscriptionStartsAt,
    required this.subscriptionEndsAt,
    required this.responseBody,
    required this.payload,
    required this.userData,
    required this.authData,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value) => value?.toString().trim() ?? '';
    bool readBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }
      return false;
    }

    String pickFirstString(List<dynamic> values) {
      for (final value in values) {
        final stringValue = readString(value);
        if (stringValue.isNotEmpty) {
          return stringValue;
        }
      }
      return '';
    }

    dynamic pickFirstNonNull(List<dynamic> values) {
      for (final value in values) {
        if (value == null) continue;
        if (value is String && value.trim().isEmpty) continue;
        return value;
      }
      return null;
    }

    String extractPlanName(Map<String, dynamic> source) {
      final direct = readString(source['planName']);
      if (direct.isNotEmpty) return direct;
      final currentPlan = source['currentPlan'];
      if (currentPlan is Map) {
        final fromCurrent = readString(currentPlan['name']);
        if (fromCurrent.isNotEmpty) return fromCurrent;
      }
      final activePlan = source['activePlan'];
      if (activePlan is Map) {
        final fromActive = readString(activePlan['name']);
        if (fromActive.isNotEmpty) return fromActive;
      }
      final plan = source['plan'];
      if (plan is Map) {
        final fromPlan = readString(plan['name']);
        if (fromPlan.isNotEmpty) return fromPlan;
      }
      return '';
    }

    String extractSubscriptionInterval(Map<String, dynamic> source) {
      final direct = readString(source['subscriptionInterval']);
      if (direct.isNotEmpty) return direct;
      final currentPlan = source['currentPlan'];
      if (currentPlan is Map) {
        final fromCurrent = readString(currentPlan['interval']);
        if (fromCurrent.isNotEmpty) return fromCurrent;
      }
      final activePlan = source['activePlan'];
      if (activePlan is Map) {
        final fromActive = readString(activePlan['interval']);
        if (fromActive.isNotEmpty) return fromActive;
      }
      final plan = source['plan'];
      if (plan is Map) {
        final fromPlan = readString(plan['interval']);
        if (fromPlan.isNotEmpty) return fromPlan;
      }
      return '';
    }

    String extractSubscriptionStartsAt(Map<String, dynamic> source) {
      final direct = pickFirstString([
        source['subscriptionStartsAt'],
        source['subscriptionStartAt'],
        source['subscriptionStartDate'],
        source['startsAt'],
        source['startAt'],
        source['startDate'],
      ]);
      if (direct.isNotEmpty) return direct;
      final subscription = source['subscription'];
      if (subscription is Map) {
        final nested = extractSubscriptionStartsAt(
          Map<String, dynamic>.from(subscription),
        );
        if (nested.isNotEmpty) return nested;
      }
      final currentSubscription = source['currentSubscription'];
      if (currentSubscription is Map) {
        final nested = extractSubscriptionStartsAt(
          Map<String, dynamic>.from(currentSubscription),
        );
        if (nested.isNotEmpty) return nested;
      }
      return '';
    }

    String extractSubscriptionEndsAt(Map<String, dynamic> source) {
      final direct = pickFirstString([
        source['subscriptionEndsAt'],
        source['subscriptionEndAt'],
        source['subscriptionEndDate'],
        source['endsAt'],
        source['endAt'],
        source['endDate'],
        source['expireAt'],
        source['expiresAt'],
        source['expiredAt'],
      ]);
      if (direct.isNotEmpty) return direct;
      final subscription = source['subscription'];
      if (subscription is Map) {
        final nested = extractSubscriptionEndsAt(
          Map<String, dynamic>.from(subscription),
        );
        if (nested.isNotEmpty) return nested;
      }
      final currentSubscription = source['currentSubscription'];
      if (currentSubscription is Map) {
        final nested = extractSubscriptionEndsAt(
          Map<String, dynamic>.from(currentSubscription),
        );
        if (nested.isNotEmpty) return nested;
      }
      return '';
    }

    final responseBody = Map<String, dynamic>.from(json);
    final data = responseBody['data'] is Map
        ? Map<String, dynamic>.from(responseBody['data'])
        : responseBody;
    final userData = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : data;

    final accessToken = pickFirstString([
      data['accessToken'],
      data['token'],
      responseBody['accessToken'],
      responseBody['token'],
    ]);
    var refreshToken = pickFirstString([
      data['refreshToken'],
      responseBody['refreshToken'],
    ]);
    final userId = pickFirstString([
      userData['id'],
      userData['_id'],
      data['userId'],
      data['_id'],
      responseBody['userId'],
      responseBody['_id'],
    ]);
    final role = pickFirstString([
      userData['role'],
      data['role'],
      responseBody['role'],
    ]);
    final subscribedValue = pickFirstNonNull([
      userData['subscribed'],
      userData['isSubscribed'],
      data['subscribed'],
      data['isSubscribed'],
      responseBody['subscribed'],
      responseBody['isSubscribed'],
    ]);
    final subscribed = subscribedValue != null
        ? readBool(subscribedValue)
        : false;
    final subscriptionPlanId = pickFirstString([
      userData['subscriptionPlanId'],
      userData['planId'],
      data['subscriptionPlanId'],
      data['planId'],
      responseBody['subscriptionPlanId'],
      responseBody['planId'],
    ]);
    final planName = pickFirstString([
      extractPlanName(userData),
      extractPlanName(data),
      extractPlanName(responseBody),
    ]);
    final subscriptionInterval = pickFirstString([
      extractSubscriptionInterval(userData),
      extractSubscriptionInterval(data),
      extractSubscriptionInterval(responseBody),
    ]);
    final subscriptionStartsAt = pickFirstString([
      extractSubscriptionStartsAt(userData),
      extractSubscriptionStartsAt(data),
      extractSubscriptionStartsAt(responseBody),
    ]);
    final subscriptionEndsAt = pickFirstString([
      extractSubscriptionEndsAt(userData),
      extractSubscriptionEndsAt(data),
      extractSubscriptionEndsAt(responseBody),
    ]);
    final authData = Map<String, dynamic>.from(userData);
    authData['subscribed'] = subscribed;
    if (subscriptionPlanId.isNotEmpty) {
      authData['subscriptionPlanId'] = subscriptionPlanId;
      authData['planId'] = subscriptionPlanId;
    }
    if (planName.isNotEmpty) authData['planName'] = planName;
    if (subscriptionInterval.isNotEmpty) {
      authData['subscriptionInterval'] = subscriptionInterval;
    }
    if (subscriptionStartsAt.isNotEmpty) {
      authData['subscriptionStartsAt'] = subscriptionStartsAt;
    }
    if (subscriptionEndsAt.isNotEmpty) {
      authData['subscriptionEndsAt'] = subscriptionEndsAt;
    }

    return LoginResponseModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      role: role,
      subscribed: subscribed,
      subscriptionPlanId: subscriptionPlanId,
      planName: planName,
      subscriptionInterval: subscriptionInterval,
      subscriptionStartsAt: subscriptionStartsAt,
      subscriptionEndsAt: subscriptionEndsAt,
      responseBody: responseBody,
      payload: data,
      userData: userData,
      authData: authData,
    );
  }
}
