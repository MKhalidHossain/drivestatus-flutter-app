import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../debug/debug_service.dart';
import 'refresh_token_manager.dart';
part 'auth/auth_service.dart';
part 'auth/auth.dart';
part 'auth/auth_status.dart';
part 'auth/auth_storage.dart';
part 'socket/socket_service.dart';
part 'auth/auth_params.dart';

class SocketConnetParamX {
  ///[Optional]
  ///
  /// Leave this field null, if you want to use your current auth's access token instead.
  final String? token;
  final String socketUrl;
  final String joinId;
  SocketConnetParamX({
    required this.token,
    required this.socketUrl,
    required this.joinId,
  });
}

class AppPigeon {
  final Dio _dio = Dio();
  final SocketService _socketService = SocketService();
  late final AuthService _authService;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final RefreshTokenManagerInterface refreshTokenManager;
  final String baseUrl;
  AppPigeon(
    this.refreshTokenManager, {
    required this.baseUrl,
  }) {
    // Set base url
    _dio.options.baseUrl = baseUrl;
    // Initializes and adds auth interceptor
    _authService = AuthService(_secureStorage, _dio, refreshTokenManager);
    _dio.interceptors.add(_authService);
    _init();
  }

  void _init() {
    _authService.init();
  }

  void dispose() {
    _authService.dispose();
    _socketService._disposeSocket();
  }

  Future<void> socketInit(SocketConnetParamX param) async {
    final token =
        param.token ??
        (await _authService._authStorage.getCurrentAuth())?._accessToken;
    if (token == null) {
      return;
    }
    if(_socketService._socket != null) {
      _socketService._disposeSocket();
    }
    final socketConnectParam = SocketConnectParam(
      url: param.socketUrl,
      token: token,
      joinId: param.joinId,
    );
    _socketService.init(socketConnectParam);
  }

  Stream<AuthStatus> get authStream => _authService.authStream;

  Future<AuthStatus> currentAuth() async=> _authService.currentAuth();

  Future<void> saveNewAuth({required SaveNewAuthParams saveAuthParams}) async {
    await _authService.saveNewAuth(saveNewAuthParams: saveAuthParams);
  }

  Future<void> updateCurrentAuth({
    required UpdateAuthParams updateAuthParams,
  }) async {
    await _authService.updateCurrentAuth(updateAuthParams: updateAuthParams);
  }

  Future<void> logOut() async{
    await _authService.clearCurrentAuthRecord();
  }

  // Public GET/POST/PUT/DELETE wrappers  
  Future<Response> get(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) {
    return _dio.get(path, queryParameters: query, data: data);
  }

  Future<Response> post(String path, {dynamic data, Options? options}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data, Options? options}) {
    return _dio.put(path, data: data, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) {
    return _dio.patch(path, data: data, options: options);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.delete(path, data: data, queryParameters: queryParameters);
  }

  /// Listen to socket event
  Stream<dynamic> listen(String channelName) {
    return _socketService.listen(channelName); // forward events, not just yield the stream object
  }
  /// Emit an event through socket
  void emit(String eventName, [dynamic data]) {
    _socketService.emit(eventName, data);
  }
}
