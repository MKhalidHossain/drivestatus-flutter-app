class PlanModel {
  final String id;
  final String name;
  final double price;
  final String currency;
  final bool recurring;
  final String interval;
  final bool isCurrent;
  final List<String> features;

  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.recurring,
    required this.interval,
    required this.isCurrent,
    required this.features,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'];
    final rawInterval =
        json['interval'] ??
        json['billingCycle'] ??
        json['billing_cycle'] ??
        json['durationUnit'] ??
        json['duration_unit'] ??
        json['period'] ??
        json['cycle'];
    final normalizedInterval = _normalizeInterval(
      value: rawInterval?.toString(),
      planName: json['name']?.toString() ?? '',
      intervalCount: _readNum(
        json['intervalCount'] ?? json['interval_count'] ?? json['duration'],
      )?.toInt(),
    );

    return PlanModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'USD',
      recurring: json['recurring'] == true,
      interval: normalizedInterval,
      isCurrent: _readCurrentPlanFlag(json),
      features: featuresJson is List
          ? featuresJson.map((item) => item.toString()).toList()
          : const <String>[],
    );
  }

  PlanModel copyWith({
    String? id,
    String? name,
    double? price,
    String? currency,
    bool? recurring,
    String? interval,
    bool? isCurrent,
    List<String>? features,
  }) {
    return PlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      recurring: recurring ?? this.recurring,
      interval: interval ?? this.interval,
      isCurrent: isCurrent ?? this.isCurrent,
      features: features ?? this.features,
    );
  }

  static String _normalizeInterval({
    required String? value,
    required String planName,
    required int? intervalCount,
  }) {
    final candidates = <String>[
      value?.toLowerCase().trim() ?? '',
      planName.toLowerCase(),
    ];
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      if (candidate.contains('year') ||
          candidate.contains('annual') ||
          candidate.contains('annually') ||
          candidate.contains('annum') ||
          candidate.contains('/yr')) {
        return 'year';
      }
      if (candidate.contains('month') ||
          candidate.contains('monthly') ||
          candidate.contains('/mo')) {
        return 'month';
      }
    }
    if ((intervalCount ?? 0) >= 12) {
      return 'year';
    }
    return 'month';
  }

  static bool _readCurrentPlanFlag(Map<String, dynamic> json) {
    const keys = <String>[
      'isCurrent',
      'current',
      'active',
      'isActive',
      'isSubscribed',
      'subscribed',
      'currentPlan',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        if (value) return true;
        continue;
      }
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (normalized == 'true' ||
            normalized == '1' ||
            normalized == 'active' ||
            normalized == 'current') {
          return true;
        }
      }
      if (value is num && value == 1) {
        return true;
      }
    }
    return false;
  }

  static num? _readNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
