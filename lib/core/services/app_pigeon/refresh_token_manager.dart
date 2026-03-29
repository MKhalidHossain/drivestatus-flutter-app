
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';

import '../../utils/helpers/format_response_data.dart';
import '../debug/debug_service.dart';

base class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic>? data;
  RefreshTokenResponse({
    this.data,
    required this.accessToken,
    required this.refreshToken,
  });

}

abstract interface class RefreshTokenManagerInterface {
  final String url;

  RefreshTokenManagerInterface(this.url);
  /// Makes a http call to the relative api to get refresh token. Returns [RefreshTokenResponse]
  /// This gets called by [AuthService] on expire of access-token.
  Future<RefreshTokenResponse> refreshToken({required String refreshToken});

  Future<bool> isExpiredTokenError({required DioException err});
}

class RefreshTokenManager implements RefreshTokenManagerInterface{
  final Dio _dio = Dio();
  final String refreshTokenUrl;
  RefreshTokenManager( this.refreshTokenUrl,);

  @override
  String get url => refreshTokenUrl;

  @override
  Future<RefreshTokenResponse> refreshToken({required String refreshToken}) async{
    AuthDebugger().dekhao("Refreshing token with url: $url, refreshToken: $refreshToken");
    final response = await _dio.post(url, data: {
      "refreshToken": refreshToken,
    });
    debugPrint("Refresh token response: ${response.data}");
    final data = extractBodyData(response);
    return RefreshTokenResponse(
      accessToken: data["accessToken"], 
      refreshToken: data["refreshToken"],
      data: (data["userId"] != null) ? 
        {
          "userId": data["userId"],
        } : null
    );
  }
  
  @override
  Future<bool> isExpiredTokenError({required DioException err}) async{
    AuthDebugger().dekhao("isExpiredTokenError: ${err.response?.statusCode} error: ${err.message} ${"\n"} isRefresh: ${err.response?.statusCode == 401 && !_isRefreshRequest(err.requestOptions)}");
    bool isExpired = err.response?.statusCode == 401 && err.response?.data["message"] == "Invalid or expired token" && !_isRefreshRequest(err.requestOptions);
    debugPrint("isExpired: $isExpired");
    return isExpired;
  }

   bool _isRefreshRequest(RequestOptions request) {
    return request.path.contains(url);
  }
}


