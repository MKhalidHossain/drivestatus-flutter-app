part of '../app_pigeon.dart';

class SocketConnectParam {
  final String _token;
  final String _joinId;
  final String url;

  SocketConnectParam({
    required String token,
    required String joinId,
    required this.url,
  }) : _token = token,
       _joinId = joinId;
}

sealed class NetworkStatus {
  const NetworkStatus();
}

final class NetworkConnected extends NetworkStatus {
  const NetworkConnected();
}

final class NetworkDisconnected extends NetworkStatus {
  const NetworkDisconnected();
}

class SocketService {
  final Map<String, StreamController<dynamic>> _events = {};
  io.Socket? _socket;
  final Debugger _debugger = AuthDebugger();

  SocketService();
  int _attempts = 0;

  SocketConnectParam? _param;

  bool get isConnected => _socket?.connected ?? false;

  void init(SocketConnectParam socketConnectParam) {
    _attempts++;
    debugPrint("Socket init attempt: $_attempts");
    _param = socketConnectParam;
    _disposeSocket();
    _init();
  }

  Future<void> _init() async {
    if (_socket != null) {
      debugPrint("Socket already initialized. Not initializing again.");
      return;
    }
    if (_param == null) {
      return;
    }
    final token = _param!._token;
    _socket = io.io(
      _param!.url,
      io.OptionBuilder().setTransports(['websocket']).setExtraHeaders({
        'Authorization': 'Bearer $token',
      }).build(),
    );
    _socket?.connect();
    _socket?.onConnect((data) {
      debugPrint("Socket connected with data: $data${"\n\n"}");
    });
  }

  void emit(String eventName, dynamic data) {
    _init().then((_) {
      debugPrint("Emitting event: $eventName, data: $data");
      debugPrint("Socket instance: ${_socket?.connected}");
      _socket?.emit(eventName, data);
    });
  }

  Stream<dynamic> listen(String eventName) {
    debugPrint("Listening to $eventName");
    if (_events.containsKey(eventName)) {
      debugPrint("Already listening to $eventName");
      return _events[eventName]!.stream;
    }

    final controller = StreamController<dynamic>.broadcast();
    _events[eventName] = controller;

    _init().then((_) {
      _socket?.on(eventName, (data) {
        debugPrint("Socket data: $data");
        controller.add(data);
      });
    });

    return controller.stream;
  }

  void stopListeningForEvent(String eventName) {
    _socket?.off(eventName);
    _events[eventName]?.close();
    _events.remove(eventName);
  }

  void _disposeSocket() {
    _debugger.dekhao("Closing controllers and diposing socket...");
    for (var controller in _events.values) {
      controller.close();
    }
    _events.clear();
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
  }
}
