import 'package:cloud_firestore/cloud_firestore.dart';

class TokenModel {
  final String id;
  final String queueId;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final int tokenNumber;
  final String status; // "waiting", "serving", "accepted", "rejected", "on_hold", "completed", "skipped"
  final DateTime joinedAt;

  const TokenModel({
    required this.id,
    required this.queueId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.tokenNumber,
    required this.status,
    required this.joinedAt,
  });

  factory TokenModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TokenModel(
      id: doc.id,
      queueId: data['queueId'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? 'Anonymous',
      studentEmail: data['studentEmail'] as String? ?? '',
      tokenNumber: data['tokenNumber'] as int? ?? 0,
      status: data['status'] as String? ?? 'waiting',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'queueId': queueId,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'tokenNumber': tokenNumber,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  TokenModel copyWith({
    String? id,
    String? queueId,
    String? studentId,
    String? studentName,
    String? studentEmail,
    int? tokenNumber,
    String? status,
    DateTime? joinedAt,
  }) {
    return TokenModel(
      id: id ?? this.id,
      queueId: queueId ?? this.queueId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isServing => status == 'serving';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isOnHold => status == 'on_hold';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';

  @override
  String toString() =>
      'TokenModel(id: $id, queue: $queueId, token#: $tokenNumber, status: $status)';
}
