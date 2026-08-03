import 'package:flutter_test/flutter_test.dart';
import 'package:DigiQueue/models/queue_model.dart';
import 'package:DigiQueue/models/token_model.dart';

void main() {
  group('QueueModel', () {
    test('waitingCount is calculated correctly when actively serving', () {
      final queue = QueueModel(
        id: 'test_queue',
        professorId: 'p1',
        professorName: 'Dr. Smith',
        roomNumber: 'Room 301',
        isLive: true,
        currentServing: 3,
        lastIssuedToken: 10,
        currentStudentStatus: 'serving',
      );
      // Student 3 is serving; students 4..10 (7 students) are waiting
      expect(queue.waitingCount, 7);
      expect(queue.isActivelyServing, true);
      expect(queue.isQueueEmpty, false);
    });

    test('waitingCount is calculated correctly when queue refilled after empty', () {
      final queue = QueueModel(
        id: 'test_queue',
        professorId: 'p1',
        professorName: 'Dr. Smith',
        roomNumber: 'Room 301',
        isLive: true,
        currentServing: 3,
        lastIssuedToken: 3,
        currentStudentStatus: null,
      );
      // Slot 3 hasn't been called yet (status is null), so 1 student is waiting
      expect(queue.waitingCount, 1);
      expect(queue.isActivelyServing, false);
      expect(queue.isQueueEmpty, false);
    });

    test('isQueueEmpty is true when queue ran out of students', () {
      final queue = QueueModel(
        id: 'test_queue',
        professorId: 'p1',
        professorName: 'Dr. Smith',
        roomNumber: 'Room 301',
        isLive: true,
        currentServing: 4,
        lastIssuedToken: 3,
        currentStudentStatus: null,
      );
      expect(queue.waitingCount, 0);
      expect(queue.isActivelyServing, false);
      expect(queue.isQueueEmpty, true);
    });

    test('copyWith creates correct copy', () {
      final queue = QueueModel(
        id: 'test_queue',
        professorId: 'p1',
        professorName: 'Dr. Smith',
        roomNumber: 'Room 301',
        isLive: false,
        currentServing: 0,
        lastIssuedToken: 0,
      );
      final updated = queue.copyWith(isLive: true, currentServing: 5);
      expect(updated.isLive, true);
      expect(updated.currentServing, 5);
      expect(updated.professorName, 'Dr. Smith');
    });
  });

  group('TokenModel', () {
    test('status helpers work correctly', () {
      final realToken = TokenModel(
        id: 'test_token',
        queueId: 'q1',
        studentId: 's1',
        studentName: 'Student',
        studentEmail: 'student@test.edu',
        tokenNumber: 5,
        status: 'waiting',
        joinedAt: DateTime.now(),
      );
      expect(realToken.isWaiting, true);
      expect(realToken.isCompleted, false);
      expect(realToken.isSkipped, false);
    });

    test('completed and serving statuses are detected', () {
      final token = TokenModel(
        id: 't2',
        queueId: 'q1',
        studentId: 's1',
        studentName: 'Student',
        studentEmail: 'student@test.edu',
        tokenNumber: 3,
        status: 'completed',
        joinedAt: DateTime.now(),
      );
      expect(token.isCompleted, true);
      expect(token.isWaiting, false);

      final servingToken = token.copyWith(status: 'serving');
      expect(servingToken.isServing, true);
    });
  });
}
