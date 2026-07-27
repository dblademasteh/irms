import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'storage.dart';
import 'notifications/notification_helper.dart';

class SocketClient {
  final SecureStorage _storage;
  io.Socket? _socket;
  String _baseUrl;
  final Map<String, Set<Function(dynamic)>> _listeners = {};
  bool _isConnecting = false;

  SocketClient(this._storage, {String baseUrl = 'http://localhost:4000'})
      : _baseUrl = baseUrl;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    try {
      if (_isConnecting || _socket?.connected == true) return;
      _isConnecting = true;

      final token = await _storage.getAccessToken();
      if (token == null) { _isConnecting = false; return; }

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

      _socket!.on('system:broadcast', (data) async {
        if (data != null && data is Map) {
          try {
            final prefs = await SharedPreferences.getInstance();
            if (prefs.getBool('notif_push') == false) return;
          } catch (_) {}
          final msg = data['message']?.toString() ?? 'New emergency alert';
          AppNotificationService.show('📢 System Broadcast', msg);
        }
      });

      _socket!.on('queue:new_incident', (data) async {
        if (data != null && data is Map) {
          try {
            final prefs = await SharedPreferences.getInstance();
            if (prefs.getBool('notif_push') == false) return;
          } catch (_) {}
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
      _isConnecting = false;
    } catch (e) {
      _isConnecting = false;
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

  void onConnect(Function(dynamic) handler) {
    _on('connect', handler);
  }

  void offConnect(Function(dynamic) handler) {
    _off('connect', handler);
  }

  void onDisconnect(Function(dynamic) handler) {
    _on('disconnect', handler);
  }

  void offDisconnect(Function(dynamic) handler) {
    _off('disconnect', handler);
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

  void onNotificationCreated(Function(dynamic) handler) =>
      _on('notification:created', handler);
  void offNotificationCreated(Function(dynamic) handler) =>
      _off('notification:created', handler);

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
