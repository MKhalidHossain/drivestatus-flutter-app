class DeleteAccountRequestModel {
  final String email;

  const DeleteAccountRequestModel({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}
