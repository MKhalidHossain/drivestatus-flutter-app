class TicketModel {
  final Payment payment;
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

  TicketModel({
    required this.payment,
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
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      payment: Payment.fromJson(json['payment'] ?? {}),
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      ticketNo: json['ticketNo'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] is int) ? json['amount'] : int.tryParse(json['amount'].toString()) ?? 0,
      country: json['country'] ?? '',
      type: json['type'] ?? '',
      speed: json['speed'] ?? '',
      location: json['location'] ?? '',
      officerBadge: json['officerBadge'] ?? '',
      city: json['city'] ?? '',
      issuedAt: DateTime.parse(json['issuedAt'] ?? DateTime.now().toIso8601String()),
      dueAt: DateTime.parse(json['dueAt'] ?? DateTime.now().toIso8601String()),
      warnings: json['warnings'] ?? '',
      pointsOnLicense: (json['pointsOnLicense'] is int) ? json['pointsOnLicense'] : int.tryParse(json['pointsOnLicense'].toString()) ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      v: json['__v'] ?? 0,
    );
  }

  bool get isPaid => status == 'paid' || payment.paidAt != null;
}

class Payment {
  final String provider;
  final String paymentId;
  final DateTime? paidAt;

  Payment({
    required this.provider,
    required this.paymentId,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      provider: json['provider'] ?? '',
      paymentId: json['paymentId'] ?? '',
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
}

class TicketSummary {
  final int openTickets;
  final int totalDue;
  final int overdue;

  TicketSummary({
    required this.openTickets,
    required this.totalDue,
    required this.overdue,
  });

  factory TicketSummary.fromJson(Map<String, dynamic> json) {
    return TicketSummary(
      openTickets: (json['openTickets'] is int) ? json['openTickets'] : int.tryParse(json['openTickets'].toString()) ?? 0,
      totalDue: (json['totalDue'] is int) ? json['totalDue'] : int.tryParse(json['totalDue'].toString()) ?? 0,
      overdue: (json['overdue'] is int) ? json['overdue'] : int.tryParse(json['overdue'].toString()) ?? 0,
    );
  }
}

class TicketResponse {
  final TicketSummary summary;
  final List<TicketModel> tickets;

  TicketResponse({
    required this.summary,
    required this.tickets,
  });

  factory TicketResponse.fromJson(Map<String, dynamic> json) {
    return TicketResponse(
      summary: TicketSummary.fromJson(json['summary'] ?? {}),
      tickets: (json['tickets'] as List<dynamic>?)
              ?.map((item) => TicketModel.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
    );
  }
}
