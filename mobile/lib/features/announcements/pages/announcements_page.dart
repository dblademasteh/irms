import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/app_toast.dart';
import '../../../core/socket_client.dart';
import '../../../core/dio_client.dart';
import '../../../app/router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../widgets/announcement_detail_modal.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final List<Map<String, dynamic>> _announcements = [];
  final List<Map<String, dynamic>> _nationalAdvisories = [];
  bool _loading = true;
  String? _error;

  late SocketClient _socket;
  String _selectedCategory = 'all';

  Future<void> _loadNationalAdvisories() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/national-advisories');
      final list = List<Map<String, dynamic>>.from(resp.data['advisories'] ?? []);
      setState(() {
        _nationalAdvisories.clear();
        _nationalAdvisories.addAll(list.map((a) => {
          'id': a['id'] ?? '',
          'title': a['title'] ?? 'National Advisory',
          'message': a['description'] ?? '',
          'author': 'GDACS',
          'category': 'national',
          'timestamp': a['pubDate'] ?? '',
          'isPinned': false,
          'targetRole': 'all',
          'link': a['link'] ?? '',
        }));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load national advisories: $e';
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadBroadcasts();
  }

  @override
  void initState() {
    super.initState();
    _socket = context.read<SocketClient>();
    _socket.onSystemBroadcast(_handleLiveBroadcast);
    _loadBroadcasts();
  }

  @override
  void dispose() {
    _socket.offSystemBroadcast(_handleLiveBroadcast);
    super.dispose();
  }

  Future<void> _loadBroadcasts() async {
    if (_selectedCategory == 'national') {
      await _loadNationalAdvisories();
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final dio = context.read<DioClient>();
      dynamic resp;
      try {
        resp = await dio.dio.get('/admin/broadcasts');
      } catch (_) {
        resp = await dio.dio.get('/broadcasts');
      }
      final list = List<Map<String, dynamic>>.from(resp.data['broadcasts'] ?? []);
      setState(() {
        _announcements.clear();
        _announcements.addAll(list.map((b) => {
          'id': b['id'] ?? '',
          'title': b['title'] ?? 'Broadcast Alert',
          'message': b['message'] ?? '',
          'author': b['author_name'] ?? 'System',
          'category': b['category'] ?? 'emergency',
          'timestamp': b['created_at'] ?? '',
          'isPinned': true,
          'targetRole': b['target_role'] ?? 'all',
        }));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        // Keep existing alerts if any, or clear loading state
      });
    }
  }

  void _handleLiveBroadcast(dynamic data) {
    if (!mounted) return;
    final targetRole = data['targetRole'] ?? 'all';
    if (targetRole == 'dispatchers' && !isDispatcher(roleNotifier.value)) return;
    if (targetRole == 'reporters' && isDispatcher(roleNotifier.value)) return;

    setState(() {
      _announcements.insert(0, {
        'id': data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'LIVE BROADCAST ALERT',
        'message': data['message'] ?? '',
        'author': data['authorName'] ?? 'Command Center',
        'category': data['category'] ?? 'emergency',
        'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        'isPinned': true,
        'targetRole': targetRole,
      });
    });
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final msgCtrl = TextEditingController();
    bool isSubmitting = false;
    bool isGenerating = false;
    String targetRole = 'all';
    String category = 'emergency';
    String? selectedTemplate;

    const templates = [
      {'key': 'general_emergency', 'label': 'General Emergency'},
      {'key': 'weather_advisory', 'label': 'Weather Advisory'},
      {'key': 'fire_alert', 'label': 'Fire Alert'},
      {'key': 'crime_safety', 'label': 'Crime / Safety'},
      {'key': 'medical_alert', 'label': 'Medical Alert'},
      {'key': 'traffic_update', 'label': 'Traffic Update'},
      {'key': 'earthquake_advisory', 'label': 'Earthquake Advisory'},
      {'key': 'flood_warning', 'label': 'Flood Warning'},
      {'key': 'tsunami_warning', 'label': 'Tsunami Warning'},
      {'key': 'incident_summary', 'label': 'Incident Summary'},
      {'key': 'safety_tip', 'label': 'Safety Tip'},
      {'key': 'system_maintenance', 'label': 'System Maintenance'},
    ];

    Future<void> generate() async {
      if (selectedTemplate == null) return;
      isGenerating = true;
      try {
        final dio = context.read<DioClient>();
        final resp = await dio.dio.post('/admin/broadcast/generate', data: {
          'template': selectedTemplate,
        });
        msgCtrl.text = resp.data['message'] as String;
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, 'Failed to generate: $e');
        }
      } finally {
        isGenerating = false;
      }
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final navigator = Navigator.of(dialogCtx);
        final route = ModalRoute.of(dialogCtx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.campaign, color: IrmsColors.error),
              SizedBox(width: 10),
              Text('Broadcast Announcement', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'This emergency alert will be broadcast in real-time to the selected audience.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: targetRole,
                  decoration: InputDecoration(
                    labelText: 'Send to',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'dispatchers', child: Text('Dispatchers Only')),
                    DropdownMenuItem(value: 'reporters', child: Text('Reporters Only')),
                  ],
                  onChanged: (v) => setDialogState(() => targetRole = v ?? 'all'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                    DropdownMenuItem(value: 'system', child: Text('System')),
                    DropdownMenuItem(value: 'safety', child: Text('Safety')),
                    DropdownMenuItem(value: 'traffic', child: Text('Traffic')),
                    DropdownMenuItem(value: 'earthquake', child: Text('Earthquake')),
                    DropdownMenuItem(value: 'flood', child: Text('Flood')),
                    DropdownMenuItem(value: 'tsunami', child: Text('Tsunami')),
                    DropdownMenuItem(value: 'weather', child: Text('Weather')),
                  ],
                  onChanged: (v) => setDialogState(() => category = v ?? 'emergency'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text('Quick Generate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTemplate,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Template',
                    hintText: 'Pick a template...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: templates.map((t) => DropdownMenuItem(
                    value: t['key'] as String,
                    child: Text(t['label'] as String, style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedTemplate = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (selectedTemplate == null || isGenerating)
                        ? null
                        : () async {
                            setDialogState(() => isGenerating = true);
                            await generate();
                            setDialogState(() => isGenerating = false);
                          },
                    icon: isGenerating
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 16),
                    label: Text(isGenerating ? 'Generating...' : 'Generate', style: const TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: msgCtrl,
                  autocorrect: false, enableSuggestions: false,
                  autofillHints: const <String>[],
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Announcement Message',
                    hintText: 'Enter advisory or emergency alert details...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      if (route != null) {
                        navigator.removeRoute(route);
                      } else {
                        navigator.pop();
                      }
                    },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18),
              label: const Text('Broadcast Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: IrmsColors.error,
                foregroundColor: Colors.white,
                ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final msg = msgCtrl.text.trim();
                      if (msg.isEmpty) {
                        AppToast.warning(context, 'Please enter an announcement message.');
                        return;
                      }
                      final dio = context.read<DioClient>();
                      setDialogState(() => isSubmitting = true);
                      try {
                        await dio.dio.post('/admin/broadcast', data: {
                          'message': msg,
                          'category': category,
                          'target_role': targetRole,
                        });
                        if (route != null) {
                          navigator.removeRoute(route);
                        } else {
                          navigator.pop();
                        }
                        _loadBroadcasts();
                        if (context.mounted) {
                          AppToast.success(context, 'Announcement successfully broadcasted!');
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          AppToast.error(context, 'Failed to broadcast alert: $e');
                        }
                      }
                    },
            ),
          ],
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    final filteredList = _selectedCategory == 'all'
        ? _announcements
        : _selectedCategory == 'national'
            ? _nationalAdvisories
            : _announcements.where((a) => a['category'] == _selectedCategory).toList();

    return Scaffold(
      appBar: IrmsAppBar(
        title: 'Announcements & Alerts',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBroadcasts,
          ),
        ],
      ),
      floatingActionButton: isDispatcher(roleNotifier.value)
          ? FloatingActionButton.small(
              heroTag: 'broadcast_fab',
              onPressed: () => _showCreateAnnouncementDialog(context),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              child: const Icon(Icons.campaign),
            )
          : null,
      body: isDesktop
          ? _buildDesktopLayout(theme, filteredList)
          : _buildMobileLayout(theme, filteredList),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP LAYOUT
  // ---------------------------------------------------------------------------
  Widget _buildDesktopLayout(ThemeData theme, List<Map<String, dynamic>> filteredList) {
    final total = _announcements.length;
    final emergencyCount = _announcements.where((a) => a['category'] == 'emergency').length;
    final systemCount = _announcements.where((a) => a['category'] == 'system').length;
    final safetyCount = _announcements.where((a) => a['category'] == 'safety').length;
    final trafficCount = _announcements.where((a) => a['category'] == 'traffic').length;
    final weatherCount = _announcements.where((a) => a['category'] == 'weather').length;
    final earthquakeCount = _announcements.where((a) => a['category'] == 'earthquake').length;
    final floodCount = _announcements.where((a) => a['category'] == 'flood').length;
    final tsunamiCount = _announcements.where((a) => a['category'] == 'tsunami').length;
    final nationalCount = _nationalAdvisories.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Filter strip (directly below AppBar) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDesktopFilterChip(theme, label: 'All Alerts', icon: Icons.campaign_outlined, categoryKey: 'all', count: total, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'Emergency', icon: Icons.warning_amber_rounded, categoryKey: 'emergency', count: emergencyCount, color: IrmsColors.error),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'System', icon: Icons.settings_outlined, categoryKey: 'system', count: systemCount, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'Safety Tips', icon: Icons.health_and_safety_outlined, categoryKey: 'safety', count: safetyCount, color: IrmsColors.success),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'Traffic', icon: Icons.traffic_outlined, categoryKey: 'traffic', count: trafficCount, color: Colors.orange),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'Weather', icon: Icons.cloud_outlined, categoryKey: 'weather', count: weatherCount, color: Colors.blue),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'Earthquake', icon: Icons.vibration, categoryKey: 'earthquake', count: earthquakeCount, color: Colors.brown),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'Flood', icon: Icons.water_outlined, categoryKey: 'flood', count: floodCount, color: Colors.cyan),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'Tsunami', icon: Icons.waves, categoryKey: 'tsunami', count: tsunamiCount, color: Colors.indigo),
                const SizedBox(width: 8),
                _buildDesktopFilterChip(theme, label: 'National Alerts', icon: Icons.public, categoryKey: 'national', count: nationalCount, color: Colors.blueGrey),
              ],
            ),
          ),
        ),

        // ── Main content ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState(theme)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Stat cards ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
                          child: Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              _buildStatCard(theme, label: 'Total', count: total, icon: Icons.campaign, color: theme.colorScheme.primary),
                              _buildStatCard(theme, label: 'Emergency', count: emergencyCount, icon: Icons.warning_amber_rounded, color: IrmsColors.error),
                              _buildStatCard(theme, label: 'System', count: systemCount, icon: Icons.settings_outlined, color: theme.colorScheme.secondary),
                              _buildStatCard(theme, label: 'Safety', count: safetyCount, icon: Icons.health_and_safety_outlined, color: IrmsColors.success),
                              _buildStatCard(theme, label: 'Traffic', count: trafficCount, icon: Icons.traffic_outlined, color: Colors.orange),
                              _buildStatCard(theme, label: 'Weather', count: weatherCount, icon: Icons.cloud_outlined, color: Colors.blue),
                              _buildStatCard(theme, label: 'Earthquake', count: earthquakeCount, icon: Icons.vibration, color: Colors.brown),
                              _buildStatCard(theme, label: 'Flood', count: floodCount, icon: Icons.water_outlined, color: Colors.cyan),
                              _buildStatCard(theme, label: 'Tsunami', count: tsunamiCount, icon: Icons.waves, color: Colors.indigo),
                              _buildStatCard(theme, label: 'National', count: nationalCount, icon: Icons.public, color: Colors.blueGrey),
                            ],
                          ),
                        ),

                        // ── Card grid ──
                        Expanded(
                          child: filteredList.isEmpty
                              ? _buildEmptyState(theme)
                              : RefreshIndicator(
                                  onRefresh: _loadBroadcasts,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                                    child: GridView.builder(
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        mainAxisExtent: 190,
                                      ),
                                      itemCount: filteredList.length,
                                      itemBuilder: (ctx, i) => _AnnouncementCard(announcement: filteredList[i]),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, {required String label, required int count, required IconData icon, required Color color}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  count.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopFilterChip(ThemeData theme, {required String label, required IconData icon, required String categoryKey, required int count, required Color color}) {
    final isSelected = _selectedCategory == categoryKey;
    return Material(
      color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = categoryKey),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.4) : theme.colorScheme.outline.withValues(alpha: 0.15),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.18) : theme.colorScheme.outline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? color : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT
  // ---------------------------------------------------------------------------
  Widget _buildMobileLayout(ThemeData theme, List<Map<String, dynamic>> filteredList) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SegmentTab(theme: theme, label: 'All', icon: Icons.campaign_outlined, isSelected: _selectedCategory == 'all', onTap: () => _onCategorySelected('all')),
                _SegmentTab(theme: theme, label: 'Emergency', icon: Icons.warning_amber_rounded, isSelected: _selectedCategory == 'emergency', onTap: () => _onCategorySelected('emergency')),
                _SegmentTab(theme: theme, label: 'System', icon: Icons.settings_outlined, isSelected: _selectedCategory == 'system', onTap: () => _onCategorySelected('system')),
                _SegmentTab(theme: theme, label: 'Safety', icon: Icons.health_and_safety_outlined, isSelected: _selectedCategory == 'safety', onTap: () => _onCategorySelected('safety')),
                _SegmentTab(theme: theme, label: 'Traffic', icon: Icons.traffic_outlined, isSelected: _selectedCategory == 'traffic', onTap: () => _onCategorySelected('traffic')),
                _SegmentTab(theme: theme, label: 'Weather', icon: Icons.cloud_outlined, isSelected: _selectedCategory == 'weather', onTap: () => _onCategorySelected('weather')),
                _SegmentTab(theme: theme, label: 'Earthquake', icon: Icons.vibration, isSelected: _selectedCategory == 'earthquake', onTap: () => _onCategorySelected('earthquake')),
                _SegmentTab(theme: theme, label: 'Flood', icon: Icons.water_outlined, isSelected: _selectedCategory == 'flood', onTap: () => _onCategorySelected('flood')),
                _SegmentTab(theme: theme, label: 'Tsunami', icon: Icons.waves, isSelected: _selectedCategory == 'tsunami', onTap: () => _onCategorySelected('tsunami')),
                _SegmentTab(theme: theme, label: 'National', icon: Icons.public, isSelected: _selectedCategory == 'national', onTap: () => _onCategorySelected('national')),
              ],
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState(theme)
                  : filteredList.isEmpty
                      ? _buildEmptyState(theme)
                      : RefreshIndicator(
                          onRefresh: _loadBroadcasts,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredList.length,
                            itemBuilder: (ctx, i) {
                              final item = filteredList[i];
                              return _AnnouncementCard(announcement: item);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text('Failed to load broadcasts', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loadBroadcasts,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'No announcements found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const _AnnouncementCard({required this.announcement});

  String _formatTimestamp(String? ts) {
    if (ts == null || ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, y').format(dt);
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPinned = announcement['isPinned'] == true;
    final catColor = broadcastCategoryColor(announcement['category'] ?? '', theme.colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPinned ? catColor.withValues(alpha: 0.5) : theme.colorScheme.outline,
          width: isPinned ? 1.5 : 1,
        ),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => showAnnouncementDetailModal(context, announcement),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: catColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      (announcement['category'] ?? 'INFO').toString().toUpperCase(),
                      style: TextStyle(
                        color: catColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (isPinned) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.push_pin, size: 14, color: catColor),
                  ],
                  const Spacer(),
                  Text(
                    _formatTimestamp(announcement['timestamp']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                announcement['title'] ?? '',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                announcement['message'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.account_circle_outlined, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text(
                    announcement['author'] ?? 'Command Center',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Read more →',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: catColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _SegmentTab extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.theme,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 5),
            Text(
              label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
