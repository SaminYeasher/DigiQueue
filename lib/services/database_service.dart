import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_model.dart';
import '../models/token_model.dart';
import '../models/appointment_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collection References ───────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _queuesRef =>
      _db.collection('queues');

  CollectionReference<Map<String, dynamic>> get _tokensRef =>
      _db.collection('tokens');

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _db.collection('appointments');

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _db.collection('messages');

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  // ─── User Operations ────────────────────────────────────────────

  /// Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Stream user profile
  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Stream all faculty users (for student appointment request)
  Stream<List<UserModel>> streamFacultyUsers() {
    return _usersRef
        .where('role', isEqualTo: 'faculty')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  // ─── Queue Streams ───────────────────────────────────────────────

  /// Stream all queues, ordered by professorName
  Stream<List<QueueModel>> streamAllQueues() {
    return _queuesRef
        .orderBy('professorName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QueueModel.fromFirestore(doc))
            .toList());
  }

  /// Stream a single queue by ID
  Stream<QueueModel?> streamQueue(String queueId) {
    return _queuesRef.doc(queueId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return QueueModel.fromFirestore(doc);
    });
  }

  // ─── Queue Mutations ────────────────────────────────────────────

  /// Create a new queue (professor self-service)
  Future<String> createQueue({
    required String professorName,
    required String roomNumber,
    required String professorId,
  }) async {
    final docRef = await _queuesRef.add({
      'professorName': professorName,
      'roomNumber': roomNumber,
      'isLive': false,
      'currentServing': 0,
      'lastIssuedToken': 0,
      'professorId': professorId,
      'currentStudentStatus': null,
      'holdUntil': null,
      'holdDurationMinutes': null,
    });
    return docRef.id;
  }

  /// Toggle queue live/closed status
  Future<void> toggleQueueLive(String queueId, bool isLive) {
    return _queuesRef.doc(queueId).update({'isLive': isLive});
  }

  /// Reset queue counters (for a new session)
  Future<void> resetQueue(String queueId) {
    return _queuesRef.doc(queueId).update({
      'currentServing': 0,
      'lastIssuedToken': 0,
      'isLive': false,
      'currentStudentStatus': null,
      'holdUntil': null,
      'holdDurationMinutes': null,
    });
  }

  /// Delete a queue and all its tokens
  Future<void> deleteQueue(String queueId) async {
    // Delete all tokens for this queue
    final tokens = await _tokensRef
        .where('queueId', isEqualTo: queueId)
        .get();
    final batch = _db.batch();
    for (final doc in tokens.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_queuesRef.doc(queueId));
    await batch.commit();
  }

  // ─── Faculty Queue Controls ─────────────────────────────────────

  /// Accept the current student — marks token as accepted
  Future<void> acceptStudent(String queueId) async {
    await _db.runTransaction((transaction) async {
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) return;

      final queue = QueueModel.fromFirestore(queueDoc);

      // Mark the current token as accepted
      final currentTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('tokenNumber', isEqualTo: queue.currentServing)
          .where('status', whereIn: ['waiting', 'serving', 'on_hold'])
          .limit(1)
          .get();

      for (final doc in currentTokens.docs) {
        transaction.update(doc.reference, {'status': 'accepted'});
      }

      // Update queue status
      transaction.update(_queuesRef.doc(queueId), {
        'currentStudentStatus': 'accepted',
        'holdUntil': null,
        'holdDurationMinutes': null,
      });
    });
  }

  /// Put current student on hold for specified minutes
  Future<void> holdStudent(String queueId, int minutes) async {
    final holdUntil = DateTime.now().add(Duration(minutes: minutes));
    await _db.runTransaction((transaction) async {
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) return;

      final queue = QueueModel.fromFirestore(queueDoc);

      // Mark the current token as on_hold
      final currentTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('tokenNumber', isEqualTo: queue.currentServing)
          .where('status', whereIn: ['waiting', 'serving'])
          .limit(1)
          .get();

      for (final doc in currentTokens.docs) {
        transaction.update(doc.reference, {'status': 'on_hold'});
      }

      // Update queue hold state
      transaction.update(_queuesRef.doc(queueId), {
        'currentStudentStatus': 'on_hold',
        'holdUntil': Timestamp.fromDate(holdUntil),
        'holdDurationMinutes': minutes,
      });
    });
  }

  /// Clear hold status
  Future<void> clearHold(String queueId) async {
    await _queuesRef.doc(queueId).update({
      'currentStudentStatus': 'serving',
      'holdUntil': null,
      'holdDurationMinutes': null,
    });

    // Also update token status back to serving
    final queueDoc = await _queuesRef.doc(queueId).get();
    if (!queueDoc.exists) return;
    final queue = QueueModel.fromFirestore(queueDoc);

    final currentTokens = await _tokensRef
        .where('queueId', isEqualTo: queueId)
        .where('tokenNumber', isEqualTo: queue.currentServing)
        .where('status', isEqualTo: 'on_hold')
        .limit(1)
        .get();

    for (final doc in currentTokens.docs) {
      await doc.reference.update({'status': 'serving'});
    }
  }

  /// Reject the current student — marks token as rejected and advances
  Future<void> rejectStudent(
    String queueId, {
    String? message,
    String? professorId,
    String? professorName,
    String? professorEmail,
  }) async {
    TokenModel? rejectedToken;
    await _db.runTransaction((transaction) async {
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) return;

      final queue = QueueModel.fromFirestore(queueDoc);
      final newServing = queue.currentServing + 1;

      // Mark the current token as rejected
      final currentTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('tokenNumber', isEqualTo: queue.currentServing)
          .where('status', whereIn: ['waiting', 'serving', 'on_hold'])
          .limit(1)
          .get();

      for (final doc in currentTokens.docs) {
        transaction.update(doc.reference, {'status': 'rejected'});
        rejectedToken = TokenModel.fromFirestore(doc);
      }

      // Advance to next student
      transaction.update(_queuesRef.doc(queueId), {
        'currentServing': newServing,
        'currentStudentStatus': 'serving',
        'holdUntil': null,
        'holdDurationMinutes': null,
      });
    });

    if (message != null &&
        message.trim().isNotEmpty &&
        professorId != null &&
        rejectedToken != null) {
      await sendMessage(
        fromId: professorId,
        fromName: professorName ?? 'Faculty',
        fromEmail: professorEmail ?? '',
        toId: rejectedToken!.studentId,
        toName: rejectedToken!.studentName,
        toEmail: rejectedToken!.studentEmail,
        subject: 'Queue Update: Please Reschedule',
        body: 'You were skipped in the live queue.\n\nMessage from ${professorName ?? 'Faculty'}:\n$message',
        type: 'schedule_notification',
      );
    }
  }

  // ─── Token Operations ───────────────────────────────────────────

  /// Join a queue — uses a transaction to atomically increment lastIssuedToken
  /// and create the token document. Prevents race conditions.
  Future<TokenModel> joinQueue({
    required String queueId,
    required String studentId,
    required String studentName,
    required String studentEmail,
  }) async {
    return _db.runTransaction<TokenModel>((transaction) async {
      // Read the queue document
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) {
        throw Exception('Queue not found');
      }

      final queue = QueueModel.fromFirestore(queueDoc);

      if (!queue.isLive) {
        throw Exception('Queue is not currently open');
      }

      // Check if student is already in this queue
      final existingTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      if (existingTokens.docs.isNotEmpty) {
        throw Exception('You are already in this queue');
      }

      // Increment the token counter
      final newTokenNumber = queue.lastIssuedToken + 1;

      // Update the queue
      transaction.update(_queuesRef.doc(queueId), {
        'lastIssuedToken': newTokenNumber,
      });

      // Create the token document
      final tokenRef = _tokensRef.doc();
      final now = DateTime.now();
      final tokenData = {
        'queueId': queueId,
        'studentId': studentId,
        'studentName': studentName,
        'studentEmail': studentEmail,
        'tokenNumber': newTokenNumber,
        'status': 'waiting',
        'joinedAt': Timestamp.fromDate(now),
      };
      transaction.set(tokenRef, tokenData);

      return TokenModel(
        id: tokenRef.id,
        queueId: queueId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        tokenNumber: newTokenNumber,
        status: 'waiting',
        joinedAt: now,
      );
    });
  }

  /// Leave queue — marks the token as "skipped"
  Future<void> leaveQueue(String tokenId) {
    return _tokensRef.doc(tokenId).update({'status': 'skipped'});
  }

  /// Advance to the next student — increments currentServing and marks the
  /// previous token as "completed"
  Future<void> nextStudent(String queueId) async {
    await _db.runTransaction((transaction) async {
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) return;

      final queue = QueueModel.fromFirestore(queueDoc);
      final newServing = queue.currentServing + 1;

      // Mark the current token as completed
      final currentTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('tokenNumber', isEqualTo: queue.currentServing)
          .where('status', whereIn: ['waiting', 'serving', 'accepted', 'on_hold'])
          .limit(1)
          .get();

      for (final doc in currentTokens.docs) {
        transaction.update(doc.reference, {'status': 'completed'});
      }

      // Update queue's currentServing
      transaction.update(_queuesRef.doc(queueId), {
        'currentServing': newServing,
        'currentStudentStatus': 'serving',
        'holdUntil': null,
        'holdDurationMinutes': null,
      });
    });
  }

  /// Skip the current student — marks as "skipped" and advances
  Future<void> skipStudent(String queueId) async {
    await _db.runTransaction((transaction) async {
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) return;

      final queue = QueueModel.fromFirestore(queueDoc);
      final newServing = queue.currentServing + 1;

      // Mark the current token as skipped
      final currentTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('tokenNumber', isEqualTo: queue.currentServing)
          .where('status', whereIn: ['waiting', 'serving', 'on_hold'])
          .limit(1)
          .get();

      for (final doc in currentTokens.docs) {
        transaction.update(doc.reference, {'status': 'skipped'});
      }

      // Update queue's currentServing
      transaction.update(_queuesRef.doc(queueId), {
        'currentServing': newServing,
        'currentStudentStatus': 'serving',
        'holdUntil': null,
        'holdDurationMinutes': null,
      });
    });
  }

  // ─── Token Streams ──────────────────────────────────────────────

  /// Stream the active "waiting" token for a specific student in a queue
  Stream<TokenModel?> streamStudentToken(String queueId, String studentId) {
    return _tokensRef
        .where('queueId', isEqualTo: queueId)
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return TokenModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Stream all active tokens for a student across all queues
  Stream<List<TokenModel>> streamAllStudentTokens(String studentId) {
    return _tokensRef
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TokenModel.fromFirestore(doc))
            .toList());
  }

  /// Stream the next N waiting students in a queue, ordered by token number
  Stream<List<TokenModel>> streamUpNext(String queueId, {int limit = 5}) {
    return _tokensRef
        .where('queueId', isEqualTo: queueId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('tokenNumber')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TokenModel.fromFirestore(doc))
            .toList());
  }

  /// Stream the currently serving token for a queue
  Stream<TokenModel?> streamCurrentlyServing(String queueId, int tokenNumber) {
    return _tokensRef
        .where('queueId', isEqualTo: queueId)
        .where('tokenNumber', isEqualTo: tokenNumber)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return TokenModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Stream queues owned by a specific professor
  Stream<List<QueueModel>> streamProfessorQueues(String professorId) {
    return _queuesRef
        .where('professorId', isEqualTo: professorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QueueModel.fromFirestore(doc))
            .toList());
  }

  // ─── Appointment Operations ─────────────────────────────────────

  /// Create a new appointment request
  Future<String> createAppointment({
    required String studentId,
    required String studentName,
    required String studentEmail,
    required String facultyId,
    required String facultyName,
    required String facultyEmail,
    required DateTime requestedDate,
    required String requestedTime,
    required String subject,
    required String description,
  }) async {
    final now = DateTime.now();
    final docRef = await _appointmentsRef.add({
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
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    // Send in-app message to faculty
    await sendMessage(
      fromId: studentId,
      fromName: studentName,
      fromEmail: studentEmail,
      toId: facultyId,
      toName: facultyName,
      toEmail: facultyEmail,
      subject: 'Appointment Request: $subject',
      body: '$studentName has requested an appointment.\n\n'
          'Date: ${requestedDate.toString().split(' ')[0]}\n'
          'Time: $requestedTime\n'
          'Subject: $subject\n'
          '${description.isNotEmpty ? 'Details: $description' : ''}',
      type: 'appointment_request',
      relatedAppointmentId: docRef.id,
    );

    return docRef.id;
  }

  /// Accept an appointment
  Future<void> acceptAppointment(String appointmentId) async {
    final doc = await _appointmentsRef.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);

    await _appointmentsRef.doc(appointmentId).update({
      'status': 'accepted',
      'updatedAt': Timestamp.now(),
    });

    // Notify student
    await sendMessage(
      fromId: appointment.facultyId,
      fromName: appointment.facultyName,
      fromEmail: appointment.facultyEmail,
      toId: appointment.studentId,
      toName: appointment.studentName,
      toEmail: appointment.studentEmail,
      subject: 'Appointment Accepted: ${appointment.subject}',
      body: '${appointment.facultyName} has accepted your appointment request.\n\n'
          'Date: ${appointment.requestedDate.toString().split(' ')[0]}\n'
          'Time: ${appointment.requestedTime}\n'
          'Subject: ${appointment.subject}',
      type: 'appointment_response',
      relatedAppointmentId: appointmentId,
    );
  }

  /// Reject an appointment
  Future<void> rejectAppointment(String appointmentId, {String? message}) async {
    final doc = await _appointmentsRef.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);

    await _appointmentsRef.doc(appointmentId).update({
      'status': 'rejected',
      'updatedAt': Timestamp.now(),
    });

    String bodyText = '${appointment.facultyName} has rejected your appointment request.\n\n'
        'Original Date: ${appointment.requestedDate.toString().split(' ')[0]}\n'
        'Original Time: ${appointment.requestedTime}\n'
        'Subject: ${appointment.subject}\n\n';
        
    if (message != null && message.trim().isNotEmpty) {
      bodyText += 'Message: $message\n\n';
    }
    bodyText += 'Please try requesting a different time slot.';

    // Notify student
    await sendMessage(
      fromId: appointment.facultyId,
      fromName: appointment.facultyName,
      fromEmail: appointment.facultyEmail,
      toId: appointment.studentId,
      toName: appointment.studentName,
      toEmail: appointment.studentEmail,
      subject: 'Appointment Rejected: ${appointment.subject}',
      body: bodyText,
      type: 'appointment_response',
      relatedAppointmentId: appointmentId,
    );
  }

  /// Reschedule an appointment with new date/time
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
  }) async {
    final doc = await _appointmentsRef.doc(appointmentId).get();
    if (!doc.exists) return;
    final appointment = AppointmentModel.fromFirestore(doc);

    await _appointmentsRef.doc(appointmentId).update({
      'status': 'rescheduled',
      'rescheduledDate': Timestamp.fromDate(newDate),
      'rescheduledTime': newTime,
      'updatedAt': Timestamp.now(),
    });

    // Notify student
    await sendMessage(
      fromId: appointment.facultyId,
      fromName: appointment.facultyName,
      fromEmail: appointment.facultyEmail,
      toId: appointment.studentId,
      toName: appointment.studentName,
      toEmail: appointment.studentEmail,
      subject: 'Appointment Rescheduled: ${appointment.subject}',
      body: '${appointment.facultyName} has rescheduled your appointment.\n\n'
          'New Date: ${newDate.toString().split(' ')[0]}\n'
          'New Time: $newTime\n'
          'Subject: ${appointment.subject}',
      type: 'schedule_notification',
      relatedAppointmentId: appointmentId,
    );
  }

  /// Stream faculty appointments
  Stream<List<AppointmentModel>> streamFacultyAppointments(String facultyId) {
    return _appointmentsRef
        .where('facultyId', isEqualTo: facultyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  /// Stream student appointments
  Stream<List<AppointmentModel>> streamStudentAppointments(String studentId) {
    return _appointmentsRef
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  // ─── Message / Inbox Operations ─────────────────────────────────

  /// Send an in-app message
  Future<String> sendMessage({
    required String fromId,
    required String fromName,
    required String fromEmail,
    required String toId,
    required String toName,
    required String toEmail,
    required String subject,
    required String body,
    required String type,
    String? relatedAppointmentId,
  }) async {
    final docRef = await _messagesRef.add({
      'fromId': fromId,
      'fromName': fromName,
      'fromEmail': fromEmail,
      'toId': toId,
      'toName': toName,
      'toEmail': toEmail,
      'subject': subject,
      'body': body,
      'type': type,
      if (relatedAppointmentId != null) // ignore: use_null_aware_elements
        'relatedAppointmentId': relatedAppointmentId,
      'isRead': false,
      'createdAt': Timestamp.now(),
    });
    return docRef.id;
  }

  /// Stream inbox messages for a user
  Stream<List<MessageModel>> streamInbox(String userId) {
    return _messagesRef
        .where('toId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Stream unread message count
  Stream<int> streamUnreadCount(String userId) {
    return _messagesRef
        .where('toId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a message as read
  Future<void> markMessageRead(String messageId) {
    return _messagesRef.doc(messageId).update({'isRead': true});
  }

  /// Send schedule notification (when appointment is canceled)
  Future<void> sendScheduleNotification({
    required String fromId,
    required String fromName,
    required String fromEmail,
    required String toId,
    required String toName,
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    await sendMessage(
      fromId: fromId,
      fromName: fromName,
      fromEmail: fromEmail,
      toId: toId,
      toName: toName,
      toEmail: toEmail,
      subject: subject,
      body: body,
      type: 'schedule_notification',
    );
  }
}
