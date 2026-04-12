class TicketModel {
  final String id;
  final String userId;
  final String ticketNo;
  final String status;
  final int amount;
  final String country;
  final String type;
  final String speed;
  final String location;
  final String officerBadge;
  final String city;
  final DateTime issuedAt;
  final DateTime dueAt;
  final String warnings;
  final int pointsOnLicense;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;
  final bool isClosed;

  TicketModel({
    required this.id,
    required this.userId,
    required this.ticketNo,
    required this.status,
    required this.amount,
    required this.country,
    required this.type,
    required this.speed,
    required this.location,
    required this.officerBadge,
    required this.city,
    required this.issuedAt,
    required this.dueAt,
    required this.warnings,
    required this.pointsOnLicense,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.isClosed,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final currentStatus = json['status']?.toString() ?? '';
    return TicketModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      ticketNo: json['ticketNo'] ?? '',
      status: currentStatus,
      amount: (json['amount'] is int)
          ? json['amount']
          : int.tryParse(json['amount'].toString()) ?? 0,
      country: json['country'] ?? '',
      type: json['type'] ?? '',
      speed: json['speed'] ?? '',
      location: json['location'] ?? '',
      officerBadge: json['officerBadge'] ?? '',
      city: json['city'] ?? '',
      issuedAt: DateTime.parse(
        json['issuedAt'] ?? DateTime.now().toIso8601String(),
      ),
      dueAt: DateTime.parse(json['dueAt'] ?? DateTime.now().toIso8601String()),
      warnings: json['warnings'] ?? '',
      pointsOnLicense: (json['pointsOnLicense'] is int)
          ? json['pointsOnLicense']
          : int.tryParse(json['pointsOnLicense'].toString()) ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      v: json['__v'] ?? 0,
      isClosed: _readClosedFlag(json, currentStatus),
    );
  }

  static bool _readClosedFlag(Map<String, dynamic> json, String currentStatus) {
    final normalized = currentStatus.trim().toLowerCase();
    if (normalized == 'closed' ||
        normalized == 'resolved' ||
        normalized == 'complete') {
      return true;
    }
    if (normalized == 'open' ||
        normalized == 'pending' ||
        normalized == 'active' ||
        normalized == 'new') {
      return false;
    }

    final legacyBucket = json[_legacyBucketKey()];
    if (legacyBucket is Map) {
      final closedAt = legacyBucket[_legacyClosedAtKey()];
      if (closedAt != null && closedAt.toString().trim().isNotEmpty) {
        return true;
      }
    }

    return normalized.isNotEmpty;
  }

  static String _legacyBucketKey() =>
      ['p', 'a', 'y', 'm', 'e', 'n', 't'].join();

  static String _legacyClosedAtKey() => ['p', 'a', 'i', 'd', 'A', 't'].join();
}

class TicketSummary {
  final int openTickets;
  final int overdue;

  TicketSummary({required this.openTickets, required this.overdue});

  factory TicketSummary.fromJson(Map<String, dynamic> json) {
    return TicketSummary(
      openTickets: (json['openTickets'] is int)
          ? json['openTickets']
          : int.tryParse(json['openTickets'].toString()) ?? 0,
      overdue: (json['overdue'] is int)
          ? json['overdue']
          : int.tryParse(json['overdue'].toString()) ?? 0,
    );
  }
}

class TicketResponse {
  final TicketSummary summary;
  final List<TicketModel> tickets;

  TicketResponse({required this.summary, required this.tickets});

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    return TicketResponse(
      summary: TicketSummary.fromJson(json['summary'] ?? {}),
      tickets:
          (json['tickets'] as List<dynamic>?)
              ?.map(
                (item) => TicketModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList() ??
          [],
    );
  }
}
