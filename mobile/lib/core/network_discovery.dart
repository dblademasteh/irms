import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkDiscovery {
  static Future<String> detect() async {
    if (kIsWeb) return 'https://railway-britain-fifth-minnesota.trycloudflare.com';

    final backend = await _scanForBackend();
    if (backend != null) return backend;

    final commonIPs = [
      '192.168.0.151',
      '192.168.1.1',
      '192.168.2.1',
      '192.168.2.199',
      '192.168.1.100',
    ];

    for (final ip in commonIPs) {
      if (await _isBackendReachable(ip)) {
        return 'http://$ip:4000';
      }
    }

    return 'http://localhost:4000';
  }

  static Future<String?> _scanForBackend() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) {
            final subnet = ip.substring(0, ip.lastIndexOf('.'));
            final found = await _scanSubnet(subnet);
            if (found != null) return found;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _scanSubnet(String subnet, {int start = 1, int end = 254}) async {
    final futures = <Future<String?>>[];
    for (int i = start; i <= end; i++) {
      final ip = '$subnet.$i';
      futures.add(_checkAndReturn(ip));
    }

    final results = await Future.wait(futures);
    for (final result in results) {
      if (result != null) return result;
    }
    return null;
  }

  static Future<String?> _checkAndReturn(String ip) async {
    if (await _isBackendReachable(ip)) {
      return 'http://$ip:4000';
    }
    return null;
  }

  static Future<bool> _isBackendReachable(String ip) async {
    try {
      final socket = await Socket.connect(ip, 4000,
        timeout: const Duration(milliseconds: 300));
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}
