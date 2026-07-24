import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme.dart';
import '../../../core/dio_client.dart';
import '../../../core/socket_client.dart';
import '../models/chat_message_model.dart';

class CitizenAssistantPage extends StatefulWidget {
  const CitizenAssistantPage({super.key});

  @override
  State<CitizenAssistantPage> createState() => _CitizenAssistantPageState();
}

class _CitizenAssistantPageState extends State<CitizenAssistantPage> {
  final TextEditingController _aiCtrl = TextEditingController();
  final ScrollController _aiScrollCtrl = ScrollController();
  final List<Map<String, String>> _aiConversations = [];
  int _selectedPane = 0;
  bool _aiThinking = false;

  List<Map<String, dynamic>> _myIncidents = [];
  bool _loadingIncidents = false;
  String? _selectedIncidentId;

  @override
  void initState() {
    super.initState();
    _fetchMyIncidents();
  }

  @override
  void dispose() {
    _aiCtrl.dispose();
    _aiScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchMyIncidents() async {
    setState(() => _loadingIncidents = true);
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/incidents/my-reports');
      if (!mounted) return;

      final list = List<Map<String, dynamic>>.from(resp.data['incidents'] ?? []);
      setState(() {
        _myIncidents = list;
        _loadingIncidents = false;
        if (list.isNotEmpty) _selectedIncidentId = list.first['id']?.toString();
      });
    } catch (_) {
      if (mounted) setState(() => _loadingIncidents = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_aiScrollCtrl.hasClients) return;
      _aiScrollCtrl.animateTo(
        _aiScrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _sendAiPrompt([String? cannedPrompt]) async {
    final prompt = (cannedPrompt ?? _aiCtrl.text).trim();
    if (prompt.isEmpty || _aiThinking) return;

    _aiCtrl.clear();
    setState(() {
      _aiConversations.add({'role': 'user', 'text': prompt});
      _aiThinking = true;
    });
    _scrollToBottom();

    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.post('/ai/chat', data: {
        'prompt': prompt,
        if (_selectedIncidentId != null && _selectedIncidentId!.isNotEmpty) 'incident_id': _selectedIncidentId,
        'history': _aiConversations.map((c) {
          return {
            'role': c['role'] == 'user' ? 'user' : 'model',
            'text': c['text'] ?? '',
          };
        }).toList(),
      });
      if (!mounted) return;

      setState(() {
        _aiConversations.add({'role': 'ai', 'text': resp.data['reply']?.toString() ?? 'No response'});
        _aiThinking = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _aiConversations.add({'role': 'ai', 'text': 'I could not reach the assistant. Please try again.'});
        _aiThinking = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: IrmsAppBar(
        title: 'Emergency Chat',
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: _loadingIncidents ? null : _fetchMyIncidents,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 840;
          final content = isWide ? _buildWideLayout(theme) : _buildCompactLayout(theme);

          return ColoredBox(
            color: theme.colorScheme.surfaceContainerLowest,
            child: SafeArea(
              top: false,
              child: content,
            ),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: _AssistantSidebar(
            incidents: _myIncidents,
            selectedIncidentId: _selectedIncidentId,
            loadingIncidents: _loadingIncidents,
            onIncidentChanged: (value) => setState(() => _selectedIncidentId = value),
            onPromptSelected: _sendAiPrompt,
          ),
        ),
        VerticalDivider(width: 1, color: theme.colorScheme.outline.withValues(alpha: 0.35)),
        Expanded(
          flex: 3,
          child: _buildAiAssistantPanel(theme, showQuickPrompts: false),
        ),
        VerticalDivider(width: 1, color: theme.colorScheme.outline.withValues(alpha: 0.35)),
        Expanded(
          flex: 2,
          child: _buildLiveIncidentChatPanel(theme, embedded: true),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, icon: Icon(Icons.auto_awesome), label: Text('Assistant')),
              ButtonSegment(value: 1, icon: Icon(Icons.forum), label: Text('Live chat')),
            ],
            selected: {_selectedPane},
            onSelectionChanged: (selected) => setState(() => _selectedPane = selected.first),
            showSelectedIcon: false,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _selectedPane == 0
                ? _buildAiAssistantPanel(theme, key: const ValueKey('ai'))
                : _buildLiveIncidentChatPanel(theme, key: const ValueKey('live')),
          ),
        ),
      ],
    );
  }

  Widget _buildAiAssistantPanel(ThemeData theme, {Key? key, bool showQuickPrompts = true}) {
    return Column(
      key: key,
      children: [
        if (showQuickPrompts)
          _AssistantHeader(
            selectedIncident: _selectedIncidentLabel,
            onPromptSelected: _sendAiPrompt,
          ),
        Expanded(
          child: _aiConversations.isEmpty
              ? _AssistantEmptyState(onPromptSelected: _sendAiPrompt)
              : ListView.builder(
                  controller: _aiScrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  itemCount: _aiConversations.length + (_aiThinking ? 1 : 0),
                  itemBuilder: (ctx, idx) {
                    if (idx == _aiConversations.length && _aiThinking) {
                      return const _TypingBubble();
                    }

                    final c = _aiConversations[idx];
                    return _AiBubble(
                      text: c['text'] ?? '',
                      isUser: c['role'] == 'user',
                    );
                  },
                ),
        ),
        _ChatComposer(
          controller: _aiCtrl,
          hintText: 'Ask for emergency guidance...',
          sendIcon: Icons.auto_awesome,
          busy: _aiThinking,
          onSend: () => _sendAiPrompt(),
        ),
      ],
    );
  }

  Widget _buildLiveIncidentChatPanel(ThemeData theme, {Key? key, bool embedded = false}) {
    if (_loadingIncidents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myIncidents.isEmpty) {
      return _EmptyNotice(
        key: key,
        icon: Icons.mark_chat_unread_outlined,
        title: 'No active incident chat',
        message: 'Submit an emergency report first to chat with dispatchers and response units.',
      );
    }

    return Column(
      key: key,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(embedded ? 16 : 12, 12, embedded ? 16 : 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.25))),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedIncidentId,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.report_outlined),
              labelText: 'Incident thread',
              isDense: true,
            ),
            items: _myIncidents.map((inc) {
              final title = inc['title']?.toString() ?? 'Incident';
              final code = inc['tracking_code']?.toString() ?? inc['id'].toString().substring(0, 8);
              return DropdownMenuItem<String>(
                value: inc['id']?.toString(),
                child: Text('$code: $title', overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedIncidentId = value),
          ),
        ),
        Expanded(
          child: _selectedIncidentId == null
              ? const SizedBox.shrink()
              : _InlineLiveChatView(incidentId: _selectedIncidentId!),
        ),
      ],
    );
  }

  String get _selectedIncidentLabel {
    if (_selectedIncidentId == null) return 'No report linked';
    final incident = _myIncidents.cast<Map<String, dynamic>?>().firstWhere(
          (inc) => inc?['id']?.toString() == _selectedIncidentId,
          orElse: () => null,
        );
    if (incident == null) return 'Report linked';
    return incident['tracking_code']?.toString() ?? incident['title']?.toString() ?? 'Report linked';
  }
}

class _AssistantSidebar extends StatelessWidget {
  const _AssistantSidebar({
    required this.incidents,
    required this.selectedIncidentId,
    required this.loadingIncidents,
    required this.onIncidentChanged,
    required this.onPromptSelected,
  });

  final List<Map<String, dynamic>> incidents;
  final String? selectedIncidentId;
  final bool loadingIncidents;
  final ValueChanged<String?> onIncidentChanged;
  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Icon(Icons.health_and_safety_outlined, color: theme.colorScheme.primary, size: 34),
          const SizedBox(height: 14),
          Text('Response assistant', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Ask for immediate guidance while live incident chat stays visible beside it.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 22),
          Text('Linked report', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          if (loadingIncidents)
            const LinearProgressIndicator(minHeight: 3)
          else if (incidents.isEmpty)
            Text('No submitted reports yet.', style: theme.textTheme.bodySmall)
          else
            DropdownButtonFormField<String>(
              value: selectedIncidentId,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: incidents.map((inc) {
                final title = inc['title']?.toString() ?? 'Incident';
                final code = inc['tracking_code']?.toString() ?? inc['id'].toString().substring(0, 8);
                return DropdownMenuItem<String>(
                  value: inc['id']?.toString(),
                  child: Text('$code: $title', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onIncidentChanged,
            ),
          const SizedBox(height: 24),
          Text('Quick prompts', style: theme.textTheme.labelLarge),
          const SizedBox(height: 10),
          _PromptTile(
            icon: Icons.monitor_heart_outlined,
            label: 'CPR steps',
            prompt: 'What are the step by step CPR instructions?',
            onSelected: onPromptSelected,
          ),
          _PromptTile(
            icon: Icons.bloodtype_outlined,
            label: 'Severe bleeding',
            prompt: 'How to stop severe bleeding first-aid?',
            onSelected: onPromptSelected,
          ),
          _PromptTile(
            icon: Icons.local_fire_department_outlined,
            label: 'Fire evacuation',
            prompt: 'What should I do during a fire emergency?',
            onSelected: onPromptSelected,
          ),
          _PromptTile(
            icon: Icons.fact_check_outlined,
            label: 'Report status',
            prompt: 'What is the status of my report?',
            onSelected: onPromptSelected,
          ),
        ],
      ),
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({
    required this.selectedIncident,
    required this.onPromptSelected,
  });

  final String selectedIncident;
  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.25))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI emergency assistant',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusChip(label: selectedIncident),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PromptChip(label: 'CPR', prompt: 'What are the step by step CPR instructions?', onSelected: onPromptSelected),
                _PromptChip(label: 'Bleeding', prompt: 'How to stop severe bleeding first-aid?', onSelected: onPromptSelected),
                _PromptChip(label: 'Fire', prompt: 'What should I do during a fire emergency?', onSelected: onPromptSelected),
                _PromptChip(label: 'Status', prompt: 'What is the status of my report?', onSelected: onPromptSelected),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState({required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.auto_awesome, size: 36, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 18),
              Text('What do you need right now?', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Get first-aid steps, evacuation guidance, or context-aware help for your active report.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.68)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _PromptChip(label: 'Adult CPR', prompt: 'What are the step by step CPR instructions?', onSelected: onPromptSelected),
                  _PromptChip(label: 'Stop bleeding', prompt: 'How to stop severe bleeding first-aid?', onSelected: onPromptSelected),
                  _PromptChip(label: 'Fire safety', prompt: 'What should I do during a fire emergency?', onSelected: onPromptSelected),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = width >= 840 ? 560.0 : width * 0.82;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 18),
            ),
            border: isUser ? null : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.28)),
          ),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Text('Assistant is checking guidance...', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.label,
    required this.prompt,
    required this.onSelected,
  });

  final String label;
  final String prompt;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        avatar: const Icon(Icons.bolt_outlined, size: 16),
        onPressed: () => onSelected(prompt),
      ),
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({
    required this.icon,
    required this.label,
    required this.prompt,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final String prompt;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelected(prompt),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: theme.textTheme.labelLarge)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.hintText,
    required this.sendIcon,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData sendIcon;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.25))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.55)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: busy ? null : onSend,
              icon: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(sendIcon),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: theme.colorScheme.onSurface.withValues(alpha: 0.34)),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.66)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineLiveChatView extends StatefulWidget {
  const _InlineLiveChatView({required this.incidentId});

  final String incidentId;

  @override
  State<_InlineLiveChatView> createState() => _InlineLiveChatViewState();
}

class _InlineLiveChatViewState extends State<_InlineLiveChatView> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<ChatMessageModel> _messages = [];
  bool _loading = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _initSocket();
  }

  @override
  void didUpdateWidget(covariant _InlineLiveChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentId != widget.incidentId) {
      _fetch();
      _initSocket();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _initSocket() {
    try {
      final socket = context.read<SocketClient>();
      socket.trackIncident(widget.incidentId);
      socket.onNewChatMessage((data) {
        if (!mounted || data == null || data is! Map<String, dynamic>) return;
        final msg = ChatMessageModel.fromJson(data);
        setState(() => _messages.add(msg));
        _scrollToBottom();
      });
    } catch (_) {}
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/incidents/${widget.incidentId}/messages');
      if (!mounted) return;

      final list = List<Map<String, dynamic>>.from(resp.data['messages'] ?? []);
      setState(() {
        _messages = list.map((m) => ChatMessageModel.fromJson(m)).toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    _ctrl.clear();
    setState(() => _sending = true);
    try {
      final dio = context.read<DioClient>();
      await dio.dio.post('/incidents/${widget.incidentId}/messages', data: {'message': text});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const _EmptyNotice(
                  icon: Icons.forum_outlined,
                  title: 'Thread is ready',
                  message: 'Send a message when you need to reach dispatchers about this incident.',
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, idx) {
                    final m = _messages[idx];
                    return _LiveChatBubble(message: m);
                  },
                ),
        ),
        _ChatComposer(
          controller: _ctrl,
          hintText: 'Message responders...',
          sendIcon: Icons.send,
          busy: _sending,
          onSend: _send,
        ),
      ],
    );
  }
}

class _LiveChatBubble extends StatelessWidget {
  const _LiveChatBubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCitizen = message.senderRole == 'citizen';
    final isDispatcher = message.senderRole == 'dispatcher';
    final color = isCitizen
        ? theme.colorScheme.primary
        : isDispatcher
            ? Colors.deepOrange.shade600
            : theme.colorScheme.surface;
    final textColor = isCitizen || isDispatcher ? Colors.white : theme.colorScheme.onSurface;
    final width = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = width >= 840 ? 420.0 : width * 0.78;

    return Align(
      alignment: isCitizen ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isCitizen ? 18 : 6),
              bottomRight: Radius.circular(isCitizen ? 6 : 18),
            ),
            border: isCitizen || isDispatcher ? null : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.senderName.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: textColor.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 4),
              Text(message.message, style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
