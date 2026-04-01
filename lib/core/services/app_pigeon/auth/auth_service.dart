part of '../app_pigeon.dart';

class _CancelRefreshToken extends CancelToken {}

class _AuthStatusDecider {
  static AuthStatus get(Auth? auth) {
    if (auth == null) {
      return UnAuthenticated();
    }
    return Authenticated(auth: auth);
  }
}

class AuthService extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage _secureStorage;
  final RefreshTokenManagerInterface refreshTokenManager;
  final Debugger _authDebugger = AuthDebugger();
  late final _AuthStorage _authStorage;
  AuthService(this._secureStorage, this.dio, this.refreshTokenManager) {
    _authStorage = _AuthStorage(secureStorage: _secureStorage);
  }

  void init() {
    _authDebugger.dekhao("Initializing auth service...");
    _authStorage.init();
  }

  Stream<AuthStatus> get authStream =>
      _authStorage._authStreamController.stream;

  Future<AuthStatus> currentAuth() async =>
      await _authStorage.currentAuthStatus();
  Future<void> dispose() async {
    _authStorage.dispose();
  }

  bool _refreshingToken = false;

  /// Attach access token to every request
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final auth = await _authStorage.getCurrentAuth();
    final accessToken = auth?._accessToken;
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    _authDebugger.dekhao({
      "type": "API_REQUEST",
      "method": options.method,
      "url": options.uri.toString(),
      "query": options.queryParameters,
      "body": options.data,
    });

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    _authDebugger.dekhao({
      "type": "API_RESPONSE",
      "method": response.requestOptions.method,
      "url": response.requestOptions.uri.toString(),
      "statusCode": response.statusCode,
      "body": response.data,
    });
    handler.next(response);
  }

  /// Catch errors like 401 and retry with new access token if access token expires.
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _authDebugger.dekhao({
      "type": "API_ERROR",
      "method": err.requestOptions.method,
      "url": err.requestOptions.uri.toString(),
      "statusCode": err.response?.statusCode,
      "errorType": err.type.name,
      "message": err.message,
      "body": err.response?.data,
    });
    // IF TIMEOUT, then possibly internet is down. Hence reject the request.
    final status = (await _authStorage.currentAuthStatus());
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      _authDebugger.dekhao("Timeout error");
      return handler.reject(err);
    }
    if (_refreshingToken) {
      _authDebugger.dekhao("Already refreshing token");
      return handler.reject(err);
    }

    if (err.requestOptions.cancelToken != null) {
      return handler.reject(err);
    }

    if (err.response?.statusCode == 401 && (status is Authenticated)) {
      // get new access token
      RefreshTokenResponse refreshTokenResponse;
      try {
        _refreshingToken = true;
        refreshTokenResponse = await refreshTokenManager.refreshToken(
          refreshToken: status.auth._refreshToken ?? "",
        );
        _refreshingToken = false;
        await _authStorage.updateCurrentAuth(
          UpdateAuthParams(
            accessToken: refreshTokenResponse.accessToken,
            refreshToken: refreshTokenResponse.refreshToken,
            data: refreshTokenResponse.data,
          ),
        );
        // Wait a second to receive changes from secure storage.
        await Future.delayed(Duration(seconds: 1)).then((_) async {
          final RequestOptions requestOptions = err.requestOptions;

          try {
            final cloneReq = await dio.request(
              requestOptions.path,
              options: Options(
                method: requestOptions.method,
                contentType: requestOptions.contentType,
              ),
              cancelToken: _CancelRefreshToken(),
              data: requestOptions.data,
              queryParameters: requestOptions.queryParameters,
            );
            return handler.resolve(cloneReq);
          } catch (e) {
            return handler.reject(e as DioException);
          }
        });
      } catch (e) {
        _authStorage.clearCurrentAuthRecord();
        _refreshingToken = false;
        return handler.reject(e as DioException);
      }
    } else {
      _authDebugger.dekhao(
        "error debug from dio interceptor: ${err.response?.data}",
      );
      debugPrint(err.message);
      return handler.next(err);
    }
  }

  /// Saves the new auth as currentAuth.
  /// Throws Exception, if user is still logged in.
  /// Must logout first.
  Future<void> saveNewAuth({
    required SaveNewAuthParams saveNewAuthParams,
  }) async => _authStorage.saveNewAuth(saveNewAuthParams);

  Future<void> updateCurrentAuth({
    required UpdateAuthParams updateAuthParams,
  }) async => _authStorage.updateCurrentAuth(updateAuthParams);

  Future<void> clearCurrentAuthRecord() async =>
      await _authStorage.clearCurrentAuthRecord();
}
