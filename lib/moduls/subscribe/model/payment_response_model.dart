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
    return PlanPaymentCreateResponse(
      paymentId: json['paymentId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      clientSecret: json['clientSecret']?.toString(),
      providerPaymentId: json['providerPaymentId']?.toString(),
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

  const PlanPaymentModel({
    required this.id,
    required this.planId,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.status,
    required this.providerPaymentId,
  });

  factory PlanPaymentModel.fromJson(Map<String, dynamic> json) {
    return PlanPaymentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      planId: json['planId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? '',
      providerPaymentId: json['providerPaymentId']?.toString() ?? '',
    );
  }
}
