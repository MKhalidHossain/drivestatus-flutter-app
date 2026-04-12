class ProfileResponseModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String avatarUrl;
  final String shopLogoUrl;
  final String language;
  final bool ticketAlerts;
  final bool licenseExpiryAlerts;
  final bool inactiveAlerts;
  final bool teenDriverAlerts;
  final bool communityAlerts;
  final String role;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dateOfBirth;

  const ProfileResponseModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.avatarUrl,
    required this.shopLogoUrl,
    required this.language,
    required this.ticketAlerts,
    required this.licenseExpiryAlerts,
    required this.inactiveAlerts,
    required this.teenDriverAlerts,
    required this.communityAlerts,
    required this.role,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.dateOfBirth,
  });

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value) => value?.toString() ?? '';

    bool readBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == '1' || normalized == 'yes';
      }
      return false;
    }

    DateTime? readDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    String extractUrl(dynamic data) {
      if (data == null) return '';
      if (data is String) return data.trim();
      if (data is Map) {
        final url = data['url'];
        if (url is String) return url.trim();
      }
      return '';
    }

    final primaryId = readString(json['_id']);
    final fallbackId = readString(json['id']);

    return ProfileResponseModel(
      id: primaryId.isNotEmpty ? primaryId : fallbackId,
      email: readString(json['email']),
      name: readString(json['name']),
      phone: readString(json['phone']),
      avatarUrl: extractUrl(json['avatar']),
      shopLogoUrl: extractUrl(json['shopLogo']),
      language: readString(json['language']),
      ticketAlerts: readBool(json['ticketAlerts']),
      licenseExpiryAlerts: readBool(json['licenseExpiryAlerts']),
      inactiveAlerts: readBool(
        json['inactiveAlerts'] ?? json['lnactiveAlerts'],
      ),
      teenDriverAlerts: readBool(json['teenDriverAlerts']),
      communityAlerts: readBool(json['communityAlerts']),
      role: readString(json['role']),
      isEmailVerified: readBool(json['isEmailVerified']),
      createdAt: readDate(json['createdAt']),
      updatedAt: readDate(json['updatedAt']),
      dateOfBirth: readDate(json['dob']),
    );
  }
}
