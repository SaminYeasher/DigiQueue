import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  final String id;
  final String professorName;
  final String roomNumber;
  final bool isLive;
  final int currentServing;
  final int lastIssuedToken;
  final String? professorId;
  final DateTime? holdUntil;
  final int? holdDurationMinutes;
  final String? currentStudentStatus; // "serving", "on_hold", "accepted", "rejected"

  const QueueModel({
    required this.id,
    required this.professorName,
    required this.roomNumber,
    required this.isLive,
    required this.currentServing,
    required this.lastIssuedToken,
    this.professorId,
    this.holdUntil,
    this.holdDurationMinutes,
    this.currentStudentStatus,
  });

  factory QueueModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return QueueModel(
      id: doc.id,
      professorName: data['professorName'] as String? ?? 'Unknown',
      roomNumber: data['roomNumber'] as String? ?? '',
      isLive: data['isLive'] as bool? ?? false,
      currentServing: data['currentServing'] as int? ?? 0,
      lastIssuedToken: data['lastIssuedToken'] as int? ?? 0,
      professorId: data['professorId'] as String?,
      holdUntil: (data['holdUntil'] as Timestamp?)?.toDate(),
      holdDurationMinutes: data['holdDurationMinutes'] as int?,
      currentStudentStatus: data['currentStudentStatus'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'professorName': professorName,
      'roomNumber': roomNumber,
      'isLive': isLive,
      'currentServing': currentServing,
      'lastIssuedToken': lastIssuedToken,
      'professorId': professorId,
      if (holdUntil != null) 'holdUntil': Timestamp.fromDate(holdUntil!),
      if (holdDurationMinutes != null)
        'holdDurationMinutes': holdDurationMinutes,
      if (currentStudentStatus != null)
        'currentStudentStatus': currentStudentStatus,
    };
  }

  QueueModel copyWith({
    String? id,
    String? professorName,
    String? roomNumber,
    bool? isLive,
    int? currentServing,
    int? lastIssuedToken,
    String? professorId,
    DateTime? holdUntil,
    int? holdDurationMinutes,
    String? currentStudentStatus,
  }) {
    return QueueModel(
      id: id ?? this.id,
      professorName: professorName ?? this.professorName,
      roomNumber: roomNumber ?? this.roomNumber,
      isLive: isLive ?? this.isLive,
      currentServing: currentServing ?? this.currentServing,
      lastIssuedToken: lastIssuedToken ?? this.lastIssuedToken,
      professorId: professorId ?? this.professorId,
      holdUntil: holdUntil ?? this.holdUntil,
      holdDurationMinutes: holdDurationMinutes ?? this.holdDurationMinutes,
      currentStudentStatus: currentStudentStatus ?? this.currentStudentStatus,
    );
  }

  /// Number of students currently waiting in this queue
  int get waitingCount => lastIssuedToken - currentServing;

  /// Whether the current student is on hold
  bool get isOnHold =>
      currentStudentStatus == 'on_hold' &&
      holdUntil != null &&
      holdUntil!.isAfter(DateTime.now());

  @override
  String toString() =>
      'QueueModel(id: $id, prof: $professorName, live: $isLive, serving: $currentServing/$lastIssuedToken)';
}
