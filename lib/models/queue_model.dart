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
  final DateTime createdAt;

  QueueModel({
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
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime(2000); // epoch fallback for old docs

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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
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
      'createdAt': Timestamp.fromDate(createdAt),
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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Number of students waiting in line to be served.
  /// When no one is actively at the desk (currentStudentStatus == null), all
  /// tokens from currentServing to lastIssuedToken are waiting.
  /// When someone is actively being served, only students behind them are waiting.
  int get waitingCount {
    if (currentServing == 0) {
      return lastIssuedToken.clamp(0, 99999);
    }
    if (currentStudentStatus == null) {
      return (lastIssuedToken - currentServing + 1).clamp(0, 99999);
    }
    return (lastIssuedToken - currentServing).clamp(0, 99999);
  }

  /// True ONLY when there is a valid student actively being served at the desk.
  /// Requires currentStudentStatus to be 'serving', 'on_hold', or 'accepted'.
  bool get isActivelyServing =>
      currentServing > 0 &&
      currentServing <= lastIssuedToken &&
      currentStudentStatus != null &&
      currentStudentStatus != 'rejected';

  /// True when the queue has run out of students to serve.
  bool get isQueueEmpty =>
      lastIssuedToken == 0 ||
      (currentStudentStatus == null && currentServing > lastIssuedToken);

  /// Whether the current student is on hold
  bool get isOnHold =>
      currentStudentStatus == 'on_hold' &&
      holdUntil != null &&
      holdUntil!.isAfter(DateTime.now());

  @override
  String toString() =>
      'QueueModel(id: $id, prof: $professorName, live: $isLive, serving: $currentServing/$lastIssuedToken)';
}
