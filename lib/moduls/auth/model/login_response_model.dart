class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String role;
  final Map<String, dynamic> responseBody;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> authData;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
    required this.responseBody,
    required this.payload,
    required this.userData,
    required this.authData,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value) => value?.toString().trim() ?? '';

    String pickFirstString(List<dynamic> values) {
      for (final value in values) {
        final stringValue = readString(value);
        if (stringValue.isNotEmpty) {
          return stringValue;
        }
      }
      return '';
    }

    final responseBody = Map<String, dynamic>.from(json);
    final data = responseBody['data'] is Map
        ? Map<String, dynamic>.from(responseBody['data'])
        : responseBody;
    final userData = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : data;

    final accessToken = pickFirstString([
      data['accessToken'],
      data['token'],
      responseBody['accessToken'],
      responseBody['token'],
    ]);
    var refreshToken = pickFirstString([
      data['refreshToken'],
      responseBody['refreshToken'],
    ]);
    if (refreshToken.isEmpty) {
      refreshToken = accessToken;
    }

    final userId = pickFirstString([
      userData['id'],
      userData['_id'],
      data['userId'],
      data['_id'],
      responseBody['userId'],
      responseBody['_id'],
    ]);
    final role = pickFirstString([
      userData['role'],
      data['role'],
      responseBody['role'],
    ]);

    return LoginResponseModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      role: role,
      responseBody: responseBody,
      payload: data,
      userData: userData,
      authData: Map<String, dynamic>.from(userData),
    );
  }
}
