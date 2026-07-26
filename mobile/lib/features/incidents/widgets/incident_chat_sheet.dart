import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme.dart';
import '../../../core/app_toast.dart';
import '../../../core/dio_client.dart';
import '../../../core/socket_client.dart';
import '../models/chat_message_model.dart';

void showIncidentChatSheet(BuildContext context, {required String incidentId, String? currentUserId, String? role}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => IncidentChatSheet(
      incidentId: incidentId,
      currentUserId: currentUserId,
      role: role ?? 'citizen',
    ),
  );
}

class IncidentChatSheet extends StatefulWidget {
  final String incidentId;
  final String? currentUserId;
  final String role;

  const IncidentChatSheet({
    super.key,
    required this.incidentId,
    this.currentUserId,
    required this.role,
  });

  @override
  State<IncidentChatSheet> createState() => _IncidentChatSheetState();
}

class _IncidentChatSheetState extends State<IncidentChatSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatCtrl = TextEditingController();
  final TextEditingController _aiCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();

  List<ChatMessageModel> _messages = [];
  List<Map<String, String>> _aiConversations = [];
  bool _loadingMessages = false;
  bool _sendingMessage = false;
  bool _aiThinking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMessages();
    _initSocketListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatCtrl.dispose();
    _aiCtrl.dispose();
    _chatScrollCtrl.dispose();
    super.dispose();
  }

  void _initSocketListeners() {
    try {
      final socket = context.read<SocketClient>();
      socket.trackIncident(widget.incidentId);
      socket.onNewChatMessage((data) {
        if (mounted && data != null && data is Map<String, dynamic>) {
          final msg = ChatMessageModel.fromJson(data);
          setState(() {
            _messages.add(msg);
          });
          _scrollToBottom();
        }
      });
    } catch (_) {}
  }

  Future<void> _fetchMessages() async {
    setState(() => _loadingMessages = true);
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.get('/incidents/${widget.incidentId}/messages');
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(resp.data['messages'] ?? []);
        setState(() {
          _messages = list.map((m) => ChatMessageModel.fromJson(m)).toList();
          _loadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMessages = false);
    }
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
    _chatCtrl.clear();
    setState(() => _sendingMessage = true);
    try {
      final dio = context.read<DioClient>();
      await dio.dio.post('/incidents/${widget.incidentId}/messages', data: {
        'message': text,
      });
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to send message: $e');
      }
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  Future<void> _sendAiPrompt() async {
    final prompt = _aiCtrl.text.trim();
    if (prompt.isEmpty || _aiThinking) return;
    _aiCtrl.clear();
    setState(() {
      _aiConversations.add({'role': 'user', 'text': prompt});
      _aiThinking = true;
    });
    try {
      final dio = context.read<DioClient>();
      final resp = await dio.dio.post('/ai/chat', data: {
        'prompt': prompt,
        'incident_id': widget.incidentId,
        'history': _aiConversations.map((c) => {'role': c['role'] == 'user' ? 'user' : 'model', 'text': c['text'] ?? ''}).toList(),
      });
      if (mounted) {
        setState(() {
          _aiConversations.add({'role': 'ai', 'text': resp.data['reply'] ?? 'No response'});
          _aiThinking = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiConversations.add({'role': 'ai', 'text': 'I encountered an error. Please try asking again.'});
          _aiThinking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Live Incident Chat'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'AI Emergency Assistant'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLiveChatTab(theme),
                _buildAiChatTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.colorScheme.primary
: m.senderRole == 'dispatcher'
                                       ? IrmsColors.warning
                                       : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.senderName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isMe || m.senderRole == 'dispatcher' ? Colors.white70 : theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMe || m.senderRole == 'dispatcher' ? Colors.white : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        Container(
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
                    controller: _chatCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type message to responders...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendLiveMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendingMessage ? null : _sendLiveMessage,
                  icon: _sendingMessage
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiChatTab(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: _aiConversations.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.auto_awesome, size: 48, color: theme.colorScheme.primary),
                          const SizedBox(height: 12),
                          Text('AI Emergency Assistant', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Ask for first-aid guide or status updates.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Suggested Questions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.help_outline, size: 16),
                          label: const Text('What is the report status?'),
                          onPressed: () {
                            _aiCtrl.text = 'What is the status of my report?';
                            _sendAiPrompt();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.medical_services_outlined, size: 16),
                          label: const Text('First-aid for severe bleeding'),
                          onPressed: () {
                            _aiCtrl.text = 'What are the first-aid steps for severe bleeding?';
                            _sendAiPrompt();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.local_fire_department_outlined, size: 16),
                          label: const Text('Fire evacuation safety guide'),
                          onPressed: () {
                            _aiCtrl.text = 'What should I do during a fire evacuation?';
                            _sendAiPrompt();
                          },
                        ),
                      ],
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _aiConversations.length,
                  itemBuilder: (ctx, idx) {
                    final c = _aiConversations[idx];
                    final isUser = c['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          c['text'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isUser ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
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
                    controller: _aiCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask AI assistant for help...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendAiPrompt(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _aiThinking ? null : _sendAiPrompt,
                  icon: _aiThinking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
