import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String facultyId;
  final String facultyName;
  final String facultyEmail;
  final DateTime requestedDate;
  final String requestedTime;
  final String subject;
  final String description;
  final String status; // "pending", "accepted", "rejected", "rescheduled"
  final DateTime? rescheduledDate;
  final String? rescheduledTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.facultyId,
    required this.facultyName,
    required this.facultyEmail,
    required this.requestedDate,
    required this.requestedTime,
    required this.subject,
    required this.description,
    required this.status,
    this.rescheduledDate,
    this.rescheduledTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppointmentModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      studentEmail: data['studentEmail'] as String? ?? '',
      facultyId: data['facultyId'] as String? ?? '',
      facultyName: data['facultyName'] as String? ?? '',
      facultyEmail: data['facultyEmail'] as String? ?? '',
      requestedDate:
          (data['requestedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requestedTime: data['requestedTime'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      rescheduledDate:
          (data['rescheduledDate'] as Timestamp?)?.toDate(),
      rescheduledTime: data['rescheduledTime'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'facultyEmail': facultyEmail,
      'requestedDate': Timestamp.fromDate(requestedDate),
      'requestedTime': requestedTime,
      'subject': subject,
      'description': description,
      'status': status,
      if (rescheduledDate != null)
        'rescheduledDate': Timestamp.fromDate(rescheduledDate!),
      if (rescheduledTime != null) 'rescheduledTime': rescheduledTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isRescheduled => status == 'rescheduled';

  AppointmentModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? facultyId,
    String? facultyName,
    String? facultyEmail,
    DateTime? requestedDate,
    String? requestedTime,
    String? subject,
    String? description,
    String? status,
    DateTime? rescheduledDate,
    String? rescheduledTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      facultyId: facultyId ?? this.facultyId,
      facultyName: facultyName ?? this.facultyName,
      facultyEmail: facultyEmail ?? this.facultyEmail,
      requestedDate: requestedDate ?? this.requestedDate,
      requestedTime: requestedTime ?? this.requestedTime,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      rescheduledDate: rescheduledDate ?? this.rescheduledDate,
      rescheduledTime: rescheduledTime ?? this.rescheduledTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'AppointmentModel(id: $id, student: $studentName, faculty: $facultyName, status: $status)';
}
