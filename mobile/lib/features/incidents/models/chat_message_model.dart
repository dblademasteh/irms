class ChatMessageModel {
  final String id;
  final String incidentId;
  final String? senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final bool isAi;
  final String createdAt;

  ChatMessageModel({
    required this.id,
    required this.incidentId,
    this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.isAi,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      incidentId: json['incident_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString(),
      senderName: json['sender_name']?.toString() ?? 'User',
      senderRole: json['sender_role']?.toString() ?? 'citizen',
      message: json['message']?.toString() ?? '',
      isAi: json['is_ai'] == true,
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incident_id': incidentId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'message': message,
      'is_ai': isAi,
      'created_at': createdAt,
    };
  }
}
