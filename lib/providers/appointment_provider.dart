import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';
import 'queue_provider.dart';

/// Streams all registered faculty users from Firestore
final facultyUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamFacultyUsers();
});

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
