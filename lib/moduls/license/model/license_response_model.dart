class LicenseResponseModel {
  final String id;
  final String userId;
  final String fullName;
  final String userPhoto;
  final String licenseNumber;
  final String state;
  final DateTime? dateOfBirth;
  final DateTime? expiryDate;
  final String licenseClass;
  final String licensePhoto;
  final String licenseStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  LicenseResponseModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.userPhoto,
    required this.licenseNumber,
    required this.state,
    this.dateOfBirth,
    this.expiryDate,
    required this.licenseClass,
    required this.licensePhoto,
    required this.licenseStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LicenseResponseModel.fromJson(Map<String, dynamic> json) {
    // Helper function to extract URL from photo object or string
    String extractPhotoUrl(dynamic photoData) {
      if (photoData == null) return '';
      
      // If it's already a string, return it
      if (photoData is String) {
        return photoData.trim();
      }
      
      // If it's a Map/object, extract the 'url' property
      if (photoData is Map) {
        final url = photoData['url'];
        if (url is String) {
          return url.trim();
        }
      }
      
      return '';
    }


    return LicenseResponseModel(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      userPhoto: extractPhotoUrl(json['userPhoto']),
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      expiryDate: json['expirationDate'] != null
          ? DateTime.tryParse(json['expirationDate'].toString())
          : null,
      licenseClass: json['licenseClass']?.toString() ?? '',
      licensePhoto: extractPhotoUrl(json['licensePhoto']),
      licenseStatus: json['licenseStatus']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
    );
  }




}
