import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  final String id;
  final String professorName;
  final String roomNumber;
  final bool isLive;
  final int currentServing;
  final int lastIssuedToken;
  final String? professorId;

  const QueueModel({
    required this.id,
    required this.professorName,
    required this.roomNumber,
    required this.isLive,
    required this.currentServing,
    required this.lastIssuedToken,
    this.professorId,
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
  }) {
    return QueueModel(
      id: id ?? this.id,
      professorName: professorName ?? this.professorName,
      roomNumber: roomNumber ?? this.roomNumber,
      isLive: isLive ?? this.isLive,
      currentServing: currentServing ?? this.currentServing,
      lastIssuedToken: lastIssuedToken ?? this.lastIssuedToken,
      professorId: professorId ?? this.professorId,
    );
  }

  /// Number of students currently waiting in this queue
  int get waitingCount => lastIssuedToken - currentServing;

  @override
  String toString() =>
      'QueueModel(id: $id, prof: $professorName, live: $isLive, serving: $currentServing/$lastIssuedToken)';
}
