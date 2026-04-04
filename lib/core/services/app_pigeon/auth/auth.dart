part of '../app_pigeon.dart';

base class Auth {
  final String? _accessToken;
  final String? _refreshToken;
  final Map<String, dynamic> data;

  Auth._internal({
    required String? accessToken,
    required String? refreshToken,
    required this.data,
  }) : _accessToken = accessToken,
       _refreshToken = refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get isVerified => _accessToken != null && _refreshToken != null;

  Auth copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
  }) {
    return Auth._internal(
      accessToken: accessToken ?? _accessToken,
      refreshToken: refreshToken ?? _refreshToken,
      data: data,
    );
  }

  factory Auth.fromMap(Map<String, dynamic> json) {
    return Auth._internal(
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      data: json['data'] == null ? {} : json['data'] as dynamic,
    );
  }

  static Auth? _tryFromJsonString(String source) {
    try {
      AuthDebugger().dekhao({
        "type": "AUTH_STORAGE",
        "action": "Trying to decode source",
        "source": source,
      });
      return Auth.fromMap(jsonDecode(source));
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': _accessToken,
      'refresh_token': _refreshToken,
      'data': data,
    };
  }

  @override
  String toString() {
    return 'Auth{accessToken: $_accessToken, refreshToken: $_refreshToken, data: $data,}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Auth &&
        other._accessToken == _accessToken &&
        other._refreshToken == _refreshToken &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(_accessToken, _refreshToken, data);
}
