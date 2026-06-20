import 'package:cloud_firestore/cloud_firestore.dart';

class TokenModel {
  final String id;
  final String queueId;
  final String studentId;
  final String studentName;
  final int tokenNumber;
  final String status; // "waiting", "completed", "skipped"
  final DateTime joinedAt;

  const TokenModel({
    required this.id,
    required this.queueId,
    required this.studentId,
    required this.studentName,
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
    int? tokenNumber,
    String? status,
    DateTime? joinedAt,
  }) {
    return TokenModel(
      id: id ?? this.id,
      queueId: queueId ?? this.queueId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';

  @override
  String toString() =>
      'TokenModel(id: $id, queue: $queueId, token#: $tokenNumber, status: $status)';
}
