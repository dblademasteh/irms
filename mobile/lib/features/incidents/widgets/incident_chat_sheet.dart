import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../core/app_toast.dart';
import '../../../core/dio_client.dart';
import '../../../core/socket_client.dart';
import '../models/chat_message_model.dart';
import 'ai_incident_analysis_card.dart';

void showIncidentChatSheet(
  BuildContext context, {
  required String incidentId,
  String? currentUserId,
  String? role,
  Map<String, dynamic>? incident,
}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => IncidentChatSheet(
      incidentId: incidentId,
      currentUserId: currentUserId,
      role: role ?? 'citizen',
      incident: incident,
    ),
  );
}

class IncidentChatSheet extends StatefulWidget {
  final String incidentId;
  final String? currentUserId;
  final String role;
  final Map<String, dynamic>? incident;

  const IncidentChatSheet({
    super.key,
    required this.incidentId,
    this.currentUserId,
    required this.role,
    this.incident,
  });

  @override
  State<IncidentChatSheet> createState() => _IncidentChatSheetState();
}

class _IncidentChatSheetState extends State<IncidentChatSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatCtrl = TextEditingController();
  final TextEditingController _aiCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();

  final List<ChatMessageModel> _messages = [];
  final Set<String> _messageIds = {};
  final List<_AiMessage> _aiConversations = [];
  bool _loadingMessages = false;
  bool _sendingMessage = false;
  bool _aiThinking = false;
  bool _emergencyCallPending = false;
  Timer? _scrollDebounce;

  static const int _aiHistoryLimit = 20;

  late final Map<String, dynamic> _inc;

  String get _incidentType => (_inc['type'] ?? 'fire').toString();
  String get _incidentSeverity => (_inc['severity'] ?? 'medium').toString();
  String get _incidentStatus => (_inc['status'] ?? 'submitted').toString();

  @override
  void initState() {
    super.initState();
    _inc = widget.incident ?? {};
    _tabController = TabController(length: 3, vsync: this);
    _fetchMessages();
    _initSocketListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatCtrl.dispose();
    _aiCtrl.dispose();
    _chatScrollCtrl.dispose();
    _scrollDebounce?.cancel();
    _removeSocketListeners();
    super.dispose();
  }

  void _initSocketListeners() {
    try {
      final socket = context.read<SocketClient>();
      socket.trackIncident(widget.incidentId);
      socket.onNewChatMessage(_onNewMessage);
    } catch (_) {}
  }

  void _removeSocketListeners() {
    try {
      final socket = context.read<SocketClient>();
      socket.offNewChatMessage(_onNewMessage);
    } catch (_) {}
  }

  void _onNewMessage(dynamic data) {
    if (!mounted || data == null || data is! Map<String, dynamic>) return;
    final msg = ChatMessageModel.fromJson(data);
    if (msg.id.isNotEmpty && _messageIds.contains(msg.id)) return;
    setState(() {
      if (msg.id.isNotEmpty) _messageIds.add(msg.id);
      _messages.add(msg);
    });
    _debouncedScroll();
  }

  Future<void> _fetchMessages() async {
    setState(() => _loadingMessages = true);
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/incidents/${widget.incidentId}/messages');
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(resp.data['messages'] ?? []);
      final fetched = list.map((m) => ChatMessageModel.fromJson(m)).toList();
      setState(() {
        _messages.clear();
        _messageIds.clear();
        for (final msg in fetched) {
          _messages.add(msg);
          if (msg.id.isNotEmpty) _messageIds.add(msg.id);
        }
        _loadingMessages = false;
      });
      _debouncedScroll();
    } catch (_) {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  void _debouncedScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 150), _scrollToBottom);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendLiveMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _sendingMessage) return;
    setState(() => _sendingMessage = true);
    try {
      final dio = context.read<DioClient>();
      await dio.dio.post('/incidents/${widget.incidentId}/messages', data: {
        'message': text,
      });
      _chatCtrl.clear();
    } catch (_) {
      if (mounted) AppToast.error(context, 'Failed to send message');
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  Future<void> _sendAiPrompt() async {
    final prompt = _aiCtrl.text.trim();
    if (prompt.isEmpty || _aiThinking) return;
    _aiCtrl.clear();
    setState(() {
      _aiConversations.add(_AiMessage(text: prompt, isUser: true));
      _aiThinking = true;
    });

    final history = _aiConversations
        .where((c) => c.text.isNotEmpty)
        .take(_aiHistoryLimit)
        .map((c) => {'role': c.isUser ? 'user' : 'model', 'text': c.text})
        .toList();

    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.post('/ai/chat', data: {
        'prompt': prompt,
        'incident_id': widget.incidentId,
        'history': history,
      });
      if (mounted) {
        setState(() {
          _aiConversations.add(_AiMessage(text: resp.data['reply'] ?? 'No response', isUser: false));
          _aiThinking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiConversations.add(const _AiMessage(text: 'Something went wrong. Please try again.', isUser: false));
          _aiThinking = false;
        });
      }
    }
  }

  Future<void> _callEmergency(String number) async {
    if (_emergencyCallPending) return;
    _emergencyCallPending = true;
    try {
      final uri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) AppToast.warning(context, 'Cannot make calls on this device');
      }
    } finally {
      _emergencyCallPending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 48, height: 5,
              decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2.5)),
            ),
          ),
          if (_inc.isNotEmpty) _buildIncidentBanner(theme),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Live Chat'),
              Tab(icon: Icon(Icons.shield_outlined), text: 'Safety Info'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'AI Assistant'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveChatTab(theme),
                _buildSafetyTab(theme),
                _buildAiChatTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Incident Banner ──────────────────────────────────────────────

  Widget _buildIncidentBanner(ThemeData theme) {
    final typeColor = _typeColor(_incidentType);
    final sevColor = _severityColor(_incidentSeverity);
    final typeIcon = _typeIcon(_incidentType);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor.withValues(alpha: 0.12), typeColor.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_inc['title'] ?? 'Incident').toString().toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: typeColor, letterSpacing: 0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_inc['address'] != null)
                      Text(
                        _inc['address'].toString(),
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _buildBadge(_incidentType.replaceAll('_', ' ').toUpperCase(), typeColor),
              const SizedBox(width: 6),
              _buildBadge(_incidentSeverity.toUpperCase(), sevColor),
            ],
          ),
          if (_inc['description'] != null && _inc['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _inc['description'].toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                _timeSince(_inc['created_at']),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(_incidentStatus).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _incidentStatus.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(_incidentStatus)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
    );
  }

  // ─── Safety Tab ───────────────────────────────────────────────────

  Widget _buildSafetyTab(ThemeData theme) {
    final tips = _safetyTipsForType(_incidentType);
    final firstAid = _firstAidForType(_incidentType);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(theme, Icons.warning_amber_rounded, 'Emergency Actions', Colors.red),
        const SizedBox(height: 10),
        _buildEmergencyActionCard(
          theme,
          icon: Icons.local_hospital,
          label: 'Call Emergency Hotline',
          subtitle: '911 — National Emergency',
          color: Colors.red,
          onTap: () => _callEmergency('911'),
        ),
        const SizedBox(height: 8),
        _buildEmergencyActionCard(
          theme,
          icon: Icons.local_fire_department,
          label: 'Bureau of Fire Protection',
          subtitle: 'Fire & Rescue — (02) 8426-0219',
          color: Colors.orange,
          onTap: () => _callEmergency('0284260219'),
        ),
        const SizedBox(height: 8),
        _buildEmergencyActionCard(
          theme,
          icon: Icons.local_police,
          label: 'Philippine National Police',
          subtitle: 'Police Emergency — 117',
          color: IrmsColors.primary,
          onTap: () => _callEmergency('117'),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(theme, Icons.tips_and_updates, 'Safety Tips', Colors.amber),
        const SizedBox(height: 10),
        ...tips.map((tip) => _buildListItem(theme, tip, Icons.check_circle, Colors.amber.shade600)),
        const SizedBox(height: 20),

        _buildSectionHeader(theme, Icons.medical_services, 'First-Aid Guide', Colors.green),
        const SizedBox(height: 10),
        ...firstAid.map((step) => _buildListItem(theme, step, Icons.medical_services_outlined, Colors.green.shade600)),
        const SizedBox(height: 20),

        _buildSectionHeader(theme, Icons.info_outline, 'What to Expect', Colors.blue),
        const SizedBox(height: 10),
        _buildInfoCard(theme, 'After Reporting', [
          'Your report is reviewed by a dispatcher within minutes.',
          'A responder unit will be assigned based on severity.',
          'You can track the response status in real-time via this chat.',
          'Keep this chat open to communicate with responders directly.',
          'Do not leave the scene unless instructed by responders.',
        ]),
        const SizedBox(height: 16),
        _buildInfoCard(theme, 'While Waiting', [
          'Stay calm and keep your phone charged.',
          'Do not attempt to handle dangerous situations alone.',
          'If the situation worsens, call 911 immediately.',
          'Note any changes in the situation to share with responders.',
          'Keep bystanders at a safe distance from the incident.',
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildEmergencyActionCard(ThemeData theme, {required IconData icon, required String label, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Icon(Icons.phone, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(ThemeData theme, String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, height: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 4, color: Colors.blue.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item, style: TextStyle(fontSize: 12, height: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ─── Safety tips data ─────────────────────────────────────────────

  List<String> _safetyTipsForType(String type) {
    return switch (type) {
      'fire' => [
          'Evacuate the area immediately — do not stop to collect belongings.',
          'Stay low to avoid smoke inhalation; crawl under smoke if needed.',
          'Feel doors before opening — if hot, do not open; find another route.',
          'Do not use elevators — always use stairs during fire evacuation.',
          'Once out, stay out — never re-enter a burning building.',
          'Call 911 immediately if you haven\'t already.',
        ],
      'medical' => [
          'Do not move the patient unless they are in immediate danger.',
          'Keep the patient calm and still — reassure them help is coming.',
          'If the patient is unconscious, check breathing and pulse.',
          'Do not give food or water to someone who may need surgery.',
          'Note the time symptoms started — inform responders.',
          'Loosen tight clothing and keep the patient warm.',
        ],
      'crime' => [
          'Do not confront the suspect — prioritize your safety.',
          'Move to a secure location and lock doors if possible.',
          'Note the suspect\'s appearance, clothing, and direction of travel.',
          'Do not touch anything the suspect may have touched.',
          'Call 117 (PNP) or 911 immediately.',
          'Preserve any evidence — do not clean or move items.',
        ],
      'accident' => [
          'Do not move injured persons unless there is fire or danger.',
          'Turn on hazard lights and set up warning triangles if safe.',
          'Check for fuel leaks — move away from damaged vehicles.',
          'Apply pressure to bleeding wounds with a clean cloth.',
          'Note the number of vehicles and persons involved.',
          'Do not attempt to remove trapped persons — wait for rescue.',
        ],
      'natural_disaster' => [
          'Move to higher ground immediately if flooding.',
          'Stay away from rivers, streams, and drainage channels.',
          'Turn off main power breaker if water is rising indoors.',
          'Do not walk through moving water — 6 inches can knock you down.',
          'Listen to official radio or news for updates.',
          'Prepare an emergency kit with water, food, and medications.',
        ],
      _ => [
          'Keep clear of the scene for emergency responders.',
          'Maintain communication — keep your phone charged.',
          'Follow instructions from arriving responders.',
          'Note any changes in the situation.',
          'Do not spread unverified information.',
          'Stay calm and help others stay calm.',
        ],
    };
  }

  List<String> _firstAidForType(String type) {
    return switch (type) {
      'fire' => [
          'For burns: Cool the burn under running water for 10–20 minutes.',
          'Do not apply ice, butter, or toothpaste to burns.',
          'Cover burns loosely with a sterile, non-stick dressing.',
          'For smoke inhalation: Move to fresh air, monitor breathing.',
          'If not breathing, begin CPR if trained.',
          'Treat for shock: Lay person flat, elevate legs 12 inches.',
        ],
      'medical' => [
          'For severe bleeding: Apply firm, direct pressure with clean cloth.',
          'Maintain pressure for 10–15 minutes — do not remove the dressing.',
          'Elevate the injured area above the heart if possible.',
          'For chest pain: Help person sit upright, loosen tight clothing.',
          'For seizure: Clear area around person, do not restrain them.',
          'Note pulse rate and breathing rate for responders.',
        ],
      'crime' => [
          'For injuries: Apply pressure to wounds with clean cloth.',
          'Keep victim warm and calm — monitor consciousness.',
          'Do not remove objects embedded in wounds.',
          'For head injuries: Keep person still, do not move neck.',
          'Check ABCs: Airway, Breathing, Circulation.',
          'Record time of injury for medical responders.',
        ],
      'accident' => [
          'For suspected spinal injury: Do not move the person.',
          'Control bleeding with direct pressure.',
          'For broken bones: Immobilize the limb, do not realign.',
          'For shock: Lay flat, elevate legs, cover with blanket.',
          'Check for concussion: Ask name, date, location.',
          'Monitor breathing — be prepared to perform CPR.',
        ],
      'natural_disaster' => [
          'For drowning: Begin CPR immediately if not breathing.',
          'For hypothermia: Remove wet clothes, warm gradually.',
          'For debris injuries: Control bleeding, do not remove embedded objects.',
          'For crush injuries: Do not remove heavy objects — wait for rescue.',
          'Clean wounds with clean water to prevent infection.',
          'Watch for signs of shock: pale skin, rapid breathing, confusion.',
        ],
      _ => [
          'Assess the scene for safety before approaching.',
          'Call 911 before administering first aid.',
          'Wear gloves if available to prevent infection.',
          'Apply pressure to control bleeding.',
          'Keep the person warm and calm.',
          'Do not give food or drink to seriously injured persons.',
        ],
    };
  }

  // ─── Chat Bubbles (shared) ────────────────────────────────────────

  Widget _buildChatBubble(ThemeData theme, {required String text, required bool isOwn, required String label, Color? labelColor, DateTime? timestamp}) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn
              ? theme.colorScheme.primary
              : labelColor ?? theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOwn || labelColor != null ? Colors.white70 : theme.colorScheme.primary,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      fontSize: 9,
                      color: isOwn || labelColor != null ? Colors.white54 : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isOwn || labelColor != null ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar({
    required ThemeData theme,
    required TextEditingController controller,
    required String hint,
    required bool sending,
    required VoidCallback onSend,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autocorrect: false, enableSuggestions: false,
                autofillHints: const <String>[],
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(icon),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Live Chat Tab ────────────────────────────────────────────────

  Widget _buildLiveChatTab(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: _loadingMessages
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No messages yet.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 4),
                          Text('Start a conversation with responders.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _chatScrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, idx) {
                        final m = _messages[idx];
                        final isMe = m.senderId != null && m.senderId == widget.currentUserId;
                        final isDispatcher = m.senderRole == 'dispatcher';
                        return _buildChatBubble(
                          theme,
                          text: m.message,
                          isOwn: isMe,
                          label: m.senderName,
                          labelColor: isDispatcher ? IrmsColors.warning : null,
                          timestamp: DateTime.tryParse(m.createdAt),
                        );
                      },
                    ),
        ),
        _buildInputBar(
          theme: theme,
          controller: _chatCtrl,
          hint: 'Type message to responders...',
          sending: _sendingMessage,
          onSend: _sendLiveMessage,
          icon: Icons.send,
        ),
      ],
    );
  }

  // ─── AI Chat Tab ──────────────────────────────────────────────────

  Widget _buildAiChatTab(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_inc.isNotEmpty) ...[
                AiIncidentAnalysisCard(incidentId: widget.incidentId),
                const SizedBox(height: 20),
              ],
              if (_aiConversations.isEmpty) ...[
                _buildAiEmptyState(theme),
              ] else ...[
                ...List.generate(_aiConversations.length, (idx) {
                  final c = _aiConversations[idx];
                  return _buildChatBubble(
                    theme,
                    text: c.text,
                    isOwn: c.isUser,
                    label: c.isUser ? 'You' : 'AI Assistant',
                    labelColor: c.isUser ? null : theme.colorScheme.tertiary,
                  );
                }),
                if (_aiThinking) _buildAiThinkingBubble(theme),
              ],
            ],
          ),
        ),
        _buildInputBar(
          theme: theme,
          controller: _aiCtrl,
          hint: 'Ask AI assistant for help...',
          sending: _aiThinking,
          onSend: _sendAiPrompt,
          icon: Icons.auto_awesome,
        ),
      ],
    );
  }

  Widget _buildAiEmptyState(ThemeData theme) {
    final prompts = _aiPromptsForType(_incidentType);
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              Icon(Icons.auto_awesome, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('AI Emergency Assistant', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Ask for first-aid guide or status updates.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: prompts.map((p) => ActionChip(
            avatar: Icon(p.$1, size: 16),
            label: Text(p.$2),
            onPressed: () { _aiCtrl.text = p.$3; _sendAiPrompt(); },
          )).toList(),
        ),
      ],
    );
  }

  List<(IconData, String, String)> _aiPromptsForType(String type) {
    return switch (type) {
      'fire' => [
          (Icons.help_outline, 'Report status?', 'What is the status of my report?'),
          (Icons.local_fire_department_outlined, 'Fire evacuation guide', 'What should I do during a fire evacuation?'),
          (Icons.medical_services_outlined, 'Burn first-aid', 'What are the first-aid steps for burns?'),
        ],
      'medical' => [
          (Icons.help_outline, 'Report status?', 'What is the status of my report?'),
          (Icons.medical_services_outlined, 'Severe bleeding first-aid', 'What are the first-aid steps for severe bleeding?'),
          (Icons.health_and_safety, 'CPR instructions', 'What are the step by step CPR instructions?'),
        ],
      'crime' => [
          (Icons.help_outline, 'Report status?', 'What is the status of my report?'),
          (Icons.local_police, 'Safety precautions', 'What safety precautions should I take during a crime incident?'),
          (Icons.medical_services_outlined, 'Injury first-aid', 'How do I treat injuries from a crime incident?'),
        ],
      'accident' => [
          (Icons.help_outline, 'Report status?', 'What is the status of my report?'),
          (Icons.medical_services_outlined, 'Spinal injury first-aid', 'What should I do for a suspected spinal injury?'),
          (Icons.car_crash, 'Accident safety guide', 'What should I do at an accident scene?'),
        ],
      'natural_disaster' => [
          (Icons.help_outline, 'Report status?', 'What is the status of my report?'),
          (Icons.storm, 'Disaster safety guide', 'What should I do during a natural disaster?'),
          (Icons.medical_services_outlined, 'Drowning first-aid', 'What are the first-aid steps for drowning?'),
        ],
      _ => [
          (Icons.help_outline, 'Report status?', 'What is the status of my report?'),
          (Icons.medical_services_outlined, 'Severe bleeding first-aid', 'What are the first-aid steps for severe bleeding?'),
          (Icons.local_fire_department_outlined, 'Fire evacuation guide', 'What should I do during a fire evacuation?'),
        ],
    };
  }

  Widget _buildAiThinkingBubble(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.tertiary),
            ),
            const SizedBox(width: 10),
            Text('AI is thinking...', style: TextStyle(fontSize: 13, color: theme.colorScheme.tertiary)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Color _typeColor(String type) {
    return switch (type) {
      'fire' => IrmsStatusColors.fire.light,
      'accident' => IrmsStatusColors.pending.light,
      'crime' => IrmsColors.primary,
      'medical' => IrmsStatusColors.medical.light,
      'natural_disaster' => IrmsColors.info,
      _ => IrmsColors.mutedText,
    };
  }

  Color _severityColor(String sev) {
    return switch (sev) {
      'critical' => Colors.red,
      'high' => Colors.orange,
      'medium' => Colors.amber,
      _ => Colors.green,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'submitted' => IrmsStatusColors.submitted.light,
      'under_review' => IrmsStatusColors.underReview.light,
      'verified' => IrmsStatusColors.verified.light,
      'rejected' => IrmsStatusColors.rejected.light,
      'resolved' => IrmsStatusColors.resolved.light,
      _ => Colors.grey,
    };
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'fire' => Icons.local_fire_department,
      'accident' => Icons.car_crash,
      'crime' => Icons.local_police,
      'medical' => Icons.medical_services,
      'natural_disaster' => Icons.storm,
      'infrastructure' => Icons.construction,
      _ => Icons.warning_amber,
    };
  }

  String _timeSince(dynamic createdAt) {
    if (createdAt == null) return 'Unknown time';
    final dt = DateTime.tryParse(createdAt.toString());
    if (dt == null) return 'Unknown time';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AiMessage {
  final String text;
  final bool isUser;
  const _AiMessage({required this.text, required this.isUser});
}
