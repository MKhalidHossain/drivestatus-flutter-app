class LicenseCreateRequestModel {
  final String fullName;
  final String userPhoto;
  final String licenseNumber;
  final String state;
  final String dateOfBirth;
  final String expiryDate;
  final String licenseClass;
  final String licensePhoto;

  const LicenseCreateRequestModel({
    required this.fullName,
    required this.userPhoto,
    required this.licenseNumber,
    required this.state,
    required this.dateOfBirth,
    required this.expiryDate,
    required this.licenseClass,
    required this.licensePhoto,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'userPhoto': userPhoto,
        'licenseNumber': licenseNumber,
        'state': state,
        'dateOfBirth': dateOfBirth,
        'expiryDate': expiryDate,
        'licenseClass': licenseClass,
        'licensePhoto': licensePhoto,
      };

  factory LicenseCreateRequestModel.fromJson(Map<String, dynamic> json) {
    return LicenseCreateRequestModel(
      fullName: json['fullName']?.toString() ?? '',
      userPhoto: json['userPhoto']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      expiryDate: json['expiryDate']?.toString() ?? '',
      licenseClass: json['licenseClass']?.toString() ?? '',
      licensePhoto: json['licensePhoto']?.toString() ?? '',
    );
  }

  LicenseCreateRequestModel copyWith({
    String? fullName,
    String? userPhoto,
    String? licenseNumber,
    String? state,
    String? dateOfBirth,
    String? expiryDate,
    String? licenseClass,
    String? licensePhoto,
  }) {
    return LicenseCreateRequestModel(
      fullName: fullName ?? this.fullName,
      userPhoto: userPhoto ?? this.userPhoto,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      state: state ?? this.state,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      expiryDate: expiryDate ?? this.expiryDate,
      licenseClass: licenseClass ?? this.licenseClass,
      licensePhoto: licensePhoto ?? this.licensePhoto,
    );
  }
}
