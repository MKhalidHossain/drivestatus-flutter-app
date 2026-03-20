class PlanModel {
  final String id;
  final String name;
  final double price;
  final String currency;
  final bool recurring;
  final String interval;
  final List<String> features;

  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.recurring,
    required this.interval,
    required this.features,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'];
    return PlanModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      recurring: json['recurring'] == true,
      interval: json['interval']?.toString() ?? 'month',
      features: featuresJson is List
          ? featuresJson.map((item) => item.toString()).toList()
          : const <String>[],
    );
  }
}
