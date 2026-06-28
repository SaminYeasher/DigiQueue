import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String fromId;
  final String fromName;
  final String fromEmail;
  final String toId;
  final String toName;
  final String toEmail;
  final String subject;
  final String body;
  final String type; // "appointment_request", "appointment_response", "schedule_notification", "general"
  final String? relatedAppointmentId;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.fromEmail,
    required this.toId,
    required this.toName,
    required this.toEmail,
    required this.subject,
    required this.body,
    required this.type,
    this.relatedAppointmentId,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MessageModel(
      id: doc.id,
      fromId: data['fromId'] as String? ?? '',
      fromName: data['fromName'] as String? ?? '',
      fromEmail: data['fromEmail'] as String? ?? '',
      toId: data['toId'] as String? ?? '',
      toName: data['toName'] as String? ?? '',
      toEmail: data['toEmail'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      relatedAppointmentId: data['relatedAppointmentId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromId': fromId,
      'fromName': fromName,
      'fromEmail': fromEmail,
      'toId': toId,
      'toName': toName,
      'toEmail': toEmail,
      'subject': subject,
      'body': body,
      'type': type,
      if (relatedAppointmentId != null)
        'relatedAppointmentId': relatedAppointmentId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isAppointmentRequest => type == 'appointment_request';
  bool get isAppointmentResponse => type == 'appointment_response';
  bool get isScheduleNotification => type == 'schedule_notification';

  MessageModel copyWith({
    String? id,
    String? fromId,
    String? fromName,
    String? fromEmail,
    String? toId,
    String? toName,
    String? toEmail,
    String? subject,
    String? body,
    String? type,
    String? relatedAppointmentId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      fromName: fromName ?? this.fromName,
      fromEmail: fromEmail ?? this.fromEmail,
      toId: toId ?? this.toId,
      toName: toName ?? this.toName,
      toEmail: toEmail ?? this.toEmail,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedAppointmentId:
          relatedAppointmentId ?? this.relatedAppointmentId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'MessageModel(id: $id, from: $fromName, to: $toName, subject: $subject, read: $isRead)';
}
