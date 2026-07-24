import 'package:socket_io_client/socket_io_client.dart' as io;
import 'storage.dart';
import 'notifications/notification_helper.dart';

class SocketClient {
  final SecureStorage _storage;
  io.Socket? _socket;
  String _baseUrl;
  final Map<String, Set<Function(dynamic)>> _listeners = {};

  SocketClient(this._storage, {String baseUrl = 'http://localhost:4000'})
      : _baseUrl = baseUrl;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return;
      if (_socket?.connected == true) return;

      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      print('[socket] initializing connection to $_baseUrl');
      AppNotificationService.requestPermission();

      _socket = io.io(_baseUrl, <String, dynamic>{
        'auth': {'token': token},
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.onConnect((_) {
        print('[socket] connected successfully to $_baseUrl');
      });
      _socket!.onDisconnect((_) => print('[socket] disconnected'));
      _socket!.onError((err) => print('[socket] error: $err'));

      _socket!.on('system:broadcast', (data) {
        if (data != null && data is Map) {
          final msg = data['message']?.toString() ?? 'New emergency alert';
          AppNotificationService.show('📢 System Broadcast', msg);
        }
      });

      _socket!.on('queue:new_incident', (data) {
        if (data != null && data is Map) {
          final title = data['title']?.toString() ?? 'Emergency Incident';
          final type = data['type']?.toString() ?? 'Report';
          AppNotificationService.show('🚨 New Incident Reported ($type)', title);
        }
      });

      // Bind all accumulated event listeners to the new socket instance
      _listeners.forEach((event, handlers) {
        for (final handler in handlers) {
          _socket!.on(event, handler);
        }
      });

      _socket!.connect();
    } catch (e) {
      print('[socket] connect error: $e');
    }
  }

  void updateBaseUrl(String url) {
    if (_baseUrl != url) {
      _baseUrl = url;
      if (_socket != null) {
        disconnect();
        connect();
      }
    }
  }

  void _on(String event, Function(dynamic) handler) {
    _listeners.putIfAbsent(event, () => {}).add(handler);
    _socket?.on(event, handler);
  }

  void _off(String event, Function(dynamic) handler) {
    final handlers = _listeners[event];
    if (handlers != null) {
      handlers.remove(handler);
      if (handlers.isEmpty) {
        _listeners.remove(event);
      }
    }
    _socket?.off(event, handler);
  }

  void joinQueue() => _socket?.emit('join_queue');
  void trackIncident(String id) => _socket?.emit('track_incident', id);
  void untrackIncident(String id) => _socket?.emit('untrack_incident', id);

  void onQueueNewIncident(Function(dynamic) handler) =>
      _on('queue:new_incident', handler);
  void offQueueNewIncident(Function(dynamic) handler) =>
      _off('queue:new_incident', handler);

  void onQueueUpdate(Function(dynamic) handler) =>
      _on('queue:update', handler);
  void offQueueUpdate(Function(dynamic) handler) =>
      _off('queue:update', handler);

  void onIncidentStatus(Function(dynamic) handler) =>
      _on('incident:status', handler);

  void onConnect(Function() handler) {
    _on('connect', (_) => handler());
  }

  void onDisconnect(Function() handler) {
    _on('disconnect', (_) => handler());
  }

  void onSystemBroadcast(Function(dynamic) handler) =>
      _on('system:broadcast', handler);
  void offSystemBroadcast(Function(dynamic) handler) =>
      _off('system:broadcast', handler);

  void onUnitDispatched(Function(dynamic) handler) =>
      _on('incident:unit_dispatched', handler);
  void offUnitDispatched(Function(dynamic) handler) =>
      _off('incident:unit_dispatched', handler);

  void onNewChatMessage(Function(dynamic) handler) =>
      _on('incident:new_chat_message', handler);
  void offNewChatMessage(Function(dynamic) handler) =>
      _off('incident:new_chat_message', handler);

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
