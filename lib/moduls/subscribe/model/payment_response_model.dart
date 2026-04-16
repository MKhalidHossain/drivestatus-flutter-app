class PlanPaymentCreateResponse {
  final String paymentId;
  final double amount;
  final String currency;
  final String? clientSecret;
  final String? providerPaymentId;

  const PlanPaymentCreateResponse({
    required this.paymentId,
    required this.amount,
    required this.currency,
    this.clientSecret,
    this.providerPaymentId,
  });

  factory PlanPaymentCreateResponse.fromJson(Map<String, dynamic> json) {
    final transactionId = json['transactionId']?.toString();
    final paymentIntentId = json['paymentIntentId']?.toString();
    return PlanPaymentCreateResponse(
      paymentId:
          json['paymentId']?.toString() ?? json['payment_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      clientSecret: json['clientSecret'] ?? json['client_secret'] ?? '',
      providerPaymentId:
          json['providerPaymentId']?.toString() ??
          transactionId ??
          paymentIntentId ??
          json['payment_intent']?.toString(),
    );
  }
}

class PlanPaymentModel {
  final String id;
  final String planId;
  final String provider;
  final double amount;
  final String currency;
  final String status;
  final String providerPaymentId;
  final String planName;
  final String subscriptionInterval;
  final String subscriptionStartsAt;
  final String subscriptionEndsAt;
  final bool subscribed;

  const PlanPaymentModel({
    required this.id,
    required this.planId,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.status,
    required this.providerPaymentId,
    this.planName = '',
    this.subscriptionInterval = '',
    this.subscriptionStartsAt = '',
    this.subscriptionEndsAt = '',
    this.subscribed = false,
  });

  factory PlanPaymentModel.fromJson(Map<String, dynamic> json) {
    bool readBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }
      return false;
    }

    String readString(dynamic value) => value?.toString().trim() ?? '';
    final subscription = json['subscription'];

    return PlanPaymentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? '',
      providerPaymentId:
          json['providerPaymentId']?.toString() ??
          json['transactionId']?.toString() ??
          json['paymentIntentId']?.toString() ??
          json['payment_intent']?.toString() ??
          '',
      planName: readString(
        json['planName'] ??
            (subscription is Map ? subscription['planName'] : null),
      ),
      subscriptionInterval: readString(
        json['subscriptionInterval'] ??
            (subscription is Map ? subscription['subscriptionInterval'] : null),
      ),
      subscriptionStartsAt: readString(
        json['subscriptionStartsAt'] ??
            (subscription is Map ? subscription['subscriptionStartsAt'] : null),
      ),
      subscriptionEndsAt: readString(
        json['subscriptionEndsAt'] ??
            (subscription is Map ? subscription['subscriptionEndsAt'] : null),
      ),
      subscribed: readBool(
        json['subscribed'] ??
            (subscription is Map ? subscription['subscribed'] : null),
      ),
    );
  }
}
