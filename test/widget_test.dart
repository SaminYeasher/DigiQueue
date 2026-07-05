import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_queue/models/queue_model.dart';
import 'package:digital_queue/models/token_model.dart';
import 'package:digital_queue/providers/token_provider.dart';
import 'package:digital_queue/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login screen builds', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('DigiQueue'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });

  group('QueueModel', () {
    test('waitingCount is calculated correctly', () {
      const queue = QueueModel(
        id: 'test_queue',
        professorName: 'Dr. Smith',
        roomNumber: 'Room 301',
        isLive: true,
        currentServing: 3,
        lastIssuedToken: 10,
      );
      expect(queue.waitingCount, 7);
    });

    test('copyWith creates correct copy', () {
      const queue = QueueModel(
        id: 'test_queue',
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

    test('completed status is detected', () {
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
    });
  });

  group('computePeopleAhead', () {
    test('returns correct count when ahead', () {
      expect(computePeopleAhead(tokenNumber: 10, currentServing: 5), 4);
    });

    test('returns 0 when your turn', () {
      expect(computePeopleAhead(tokenNumber: 5, currentServing: 5), 0);
    });

    test('returns 0 when passed', () {
      expect(computePeopleAhead(tokenNumber: 3, currentServing: 5), 0);
    });

    test('returns null when tokenNumber is null', () {
      expect(computePeopleAhead(tokenNumber: null, currentServing: 5), null);
    });
  });

  group('isStudentTurn', () {
    test('returns true when token matches serving', () {
      expect(isStudentTurn(tokenNumber: 5, currentServing: 5), true);
    });

    test('returns false when not turn', () {
      expect(isStudentTurn(tokenNumber: 10, currentServing: 5), false);
    });
  });
}
