import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import 'queue_provider.dart';

/// Streams all appointments for a faculty member
final facultyAppointmentsProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, facultyId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamFacultyAppointments(facultyId);
});

/// Streams all appointments for a student
final studentAppointmentsProvider =
    StreamProvider.family<List<AppointmentModel>, String>((ref, studentId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamStudentAppointments(studentId);
});
