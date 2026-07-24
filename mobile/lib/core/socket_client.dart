import 'package:socket_io_client/socket_io_client.dart' as io;
import 'storage.dart';

class SocketClient {
  final SecureStorage _storage;
  io.Socket? _socket;
  String _baseUrl;

  SocketClient(this._storage, {String baseUrl = 'http://localhost:4000'})
      : _baseUrl = baseUrl;

  Future<void> connect() async {
    final token = await _storage.getAccessToken();
    if (token == null || _socket?.connected == true) return;

    _socket = io.io(_baseUrl, <String, dynamic>{
      'auth': {'token': token},
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.onConnect((_) => print('[socket] connected'));
    _socket!.onDisconnect((_) => print('[socket] disconnected'));
    _socket!.onError((err) => print('[socket] error: $err'));

    _socket!.connect();
  }

  void updateBaseUrl(String url) {
    _baseUrl = url;
  }

  void joinQueue() => _socket?.emit('join_queue');
  void trackIncident(String id) => _socket?.emit('track_incident', id);
  void untrackIncident(String id) => _socket?.emit('untrack_incident', id);

  void onQueueNewIncident(Function(dynamic) handler) =>
      _socket?.on('queue:new_incident', handler);
  void offQueueNewIncident(Function(dynamic) handler) =>
      _socket?.off('queue:new_incident', handler);

  void onQueueUpdate(Function(dynamic) handler) =>
      _socket?.on('queue:update', handler);
  void offQueueUpdate(Function(dynamic) handler) =>
      _socket?.off('queue:update', handler);

  void onIncidentStatus(Function(dynamic) handler) =>
      _socket?.on('incident:status', handler);

  void onConnect(Function() handler) => _socket?.onConnect((_) => handler());
  void onDisconnect(Function() handler) => _socket?.onDisconnect((_) => handler());

  void onSystemBroadcast(Function(dynamic) handler) =>
      _socket?.on('system:broadcast', handler);
  void offSystemBroadcast(Function(dynamic) handler) =>
      _socket?.off('system:broadcast', handler);

  void onUnitDispatched(Function(dynamic) handler) =>
      _socket?.on('incident:unit_dispatched', handler);
  void offUnitDispatched(Function(dynamic) handler) =>
      _socket?.off('incident:unit_dispatched', handler);

  void onNewChatMessage(Function(dynamic) handler) =>
      _socket?.on('incident:new_chat_message', handler);
  void offNewChatMessage(Function(dynamic) handler) =>
      _socket?.off('incident:new_chat_message', handler);

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
