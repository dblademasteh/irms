import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/dio_client.dart';
import '../../../core/map_launcher.dart';
import '../../../app/theme.dart';

class IncidentsMapPage extends StatefulWidget {
  const IncidentsMapPage({super.key});

  @override
  State<IncidentsMapPage> createState() => _IncidentsMapPageState();
}

class _IncidentsMapPageState extends State<IncidentsMapPage> {
  List<Map<String, dynamic>> _incidents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/incidents/search');
      final list = List<Map<String, dynamic>>.from(resp.data['incidents'] ?? []);
      setState(() {
        _incidents = list.where((i) => i['latitude'] != null && i['longitude'] != null).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _severityColor(String? severity, bool isDark) {
    return switch (severity) {
      'critical' => IrmsStatusColors.resolve('critical', isDark),
      'high' => IrmsStatusColors.resolve('pending', isDark),
      'medium' => IrmsStatusColors.resolve('pending', isDark),
      'low' => IrmsStatusColors.resolve('verified', isDark),
      _ => IrmsColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final initialCenter = _incidents.isNotEmpty
        ? LatLng((_incidents.first['latitude'] as num).toDouble(), (_incidents.first['longitude'] as num).toDouble())
        : const LatLng(14.5995, 120.9842); // Default Manila coordinates

    return Scaffold(
      appBar: AppBar(
        title: Text('Incidents Map (${_incidents.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadIncidents),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.irms_mobile',
          ),
          MarkerLayer(
            markers: _incidents.map((inc) {
              final lat = (inc['latitude'] as num).toDouble();
              final lng = (inc['longitude'] as num).toDouble();
              final color = _severityColor(inc['severity'], Theme.of(context).brightness == Brightness.dark);
              return Marker(
                point: LatLng(lat, lng),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => _showSummarySheet(inc),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showSummarySheet(Map<String, dynamic> inc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(inc['title'] ?? 'Incident', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(inc['address'] ?? 'No address provided', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => openMapDirections(
                  (inc['latitude'] as num).toDouble(),
                  (inc['longitude'] as num).toDouble(),
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
              ),
            ],
          ),
        );
      },
    );
  }
}
