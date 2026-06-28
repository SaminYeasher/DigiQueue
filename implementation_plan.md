# DigiQueue — Full Feature Implementation Plan

Comprehensive upgrade to add faculty controls, appointment system, email messaging, .edu-only auth, and real-time queue tracking.

## User Review Required

> [!IMPORTANT]
> **Email/Messaging System**: Since Firebase doesn't provide built-in email sending from the client, the "email" features will be implemented as an **in-app messaging/inbox system** stored in Firestore. Students and faculty will see messages in an inbox within the app. If you need actual emails to be sent (e.g. via SendGrid/SMTP), that requires a backend Cloud Function — let me know if you want that added too.

> [!WARNING]
> **`.edu` email enforcement**: The login screen will be updated to reject any email that doesn't end in `.edu`. Existing users with non-.edu emails will be unable to log in. Guest/anonymous login will be removed.

## Open Questions

> [!IMPORTANT]
> 1. **Hold Timer Behavior**: When a faculty member puts a student on "Hold" for 2/5/10/15 min, should the hold automatically expire and move to the next student, or should it just be a visual timer that the faculty manually dismisses?
> 2. **Appointment vs Queue**: Are appointments separate from the live queue? (i.e., a student can book a future appointment slot AND also join a live walk-in queue?) — I'll implement them as **separate features**: live queue for walk-ins, appointments for scheduled meetings.

---

## Proposed Changes

### 1. Data Models

#### [NEW] [appointment_model.dart](file:///e:/DigiQueue/lib/models/appointment_model.dart)
New Firestore model for appointment requests:
- `id`, `studentId`, `studentName`, `studentEmail`
- `facultyId`, `facultyName`, `facultyEmail`
- `requestedDate` (DateTime), `requestedTime` (String)
- `subject` (String — 2-line max description)
- `status`: `pending` → `accepted` | `rejected` | `rescheduled`
- `rescheduledDate`, `rescheduledTime` (set by faculty on reschedule)
- `createdAt`, `updatedAt`

#### [NEW] [message_model.dart](file:///e:/DigiQueue/lib/models/message_model.dart)
In-app messaging/inbox model:
- `id`, `fromId`, `fromName`, `fromEmail`
- `toId`, `toName`, `toEmail`
- `subject`, `body`
- `type`: `appointment_request` | `appointment_response` | `schedule_notification` | `general`
- `relatedAppointmentId` (nullable)
- `isRead` (bool), `createdAt`

#### [NEW] [user_model.dart](file:///e:/DigiQueue/lib/models/user_model.dart)
Registered user profile stored in Firestore `users` collection:
- `uid`, `email`, `displayName`, `role` (`student` | `faculty`)
- `createdAt`

#### [MODIFY] [queue_model.dart](file:///e:/DigiQueue/lib/models/queue_model.dart)
Add fields:
- `holdUntil` (Timestamp? — when the current student's hold expires)
- `holdDurationMinutes` (int? — 2, 5, 10, or 15)
- `currentStudentStatus`: `serving` | `on_hold` | `accepted` | `rejected`

#### [MODIFY] [token_model.dart](file:///e:/DigiQueue/lib/models/token_model.dart)
Add fields:
- `studentEmail` (String)
- Extend `status` to include: `waiting`, `serving`, `accepted`, `rejected`, `on_hold`, `completed`, `skipped`

---

### 2. Services

#### [MODIFY] [auth_service.dart](file:///e:/DigiQueue/lib/services/auth_service.dart)
- Remove `signInAnonymously()` method
- Add `.edu` email validation in `signInWithEmail()` and `registerWithEmail()` — throw error if email doesn't end with `.edu`
- On registration, create a `users/{uid}` Firestore document with role info

#### [MODIFY] [database_service.dart](file:///e:/DigiQueue/lib/services/database_service.dart)
Add new methods:
- **Queue Controls**: `acceptStudent()`, `holdStudent(queueId, minutes)`, `rejectStudent()` — update token status and queue state
- **Hold timer**: `clearHold()` — called when hold expires
- **User registration**: `createUserProfile()`, `getUserProfile()`, `streamUserProfile()`
- **Appointment CRUD**: `createAppointment()`, `acceptAppointment()`, `rejectAppointment()`, `rescheduleAppointment()`, `streamFacultyAppointments()`, `streamStudentAppointments()`
- **Messages/Inbox**: `sendMessage()`, `streamInbox()`, `markMessageRead()`, `streamUnreadCount()`

---

### 3. Providers

#### [MODIFY] [auth_provider.dart](file:///e:/DigiQueue/lib/providers/auth_provider.dart)
- Remove the simple `userRoleProvider` StateProvider
- Add `userProfileProvider` that reads role from Firestore `users` collection
- Role is now persistent (stored in DB, not session-only)

#### [NEW] [appointment_provider.dart](file:///e:/DigiQueue/lib/providers/appointment_provider.dart)
- `facultyAppointmentsProvider(facultyId)` — streams pending/all appointments
- `studentAppointmentsProvider(studentId)` — streams student's appointments

#### [NEW] [message_provider.dart](file:///e:/DigiQueue/lib/providers/message_provider.dart)
- `inboxProvider(userId)` — streams all messages for a user
- `unreadCountProvider(userId)` — streams unread count for badge

#### [MODIFY] [token_provider.dart](file:///e:/DigiQueue/lib/providers/token_provider.dart)
- Add `currentlyServingTokenProvider(queueId)` — streams the token currently being served (for real-time "currently serving" display)

---

### 4. Screens

#### [MODIFY] [login_screen.dart](file:///e:/DigiQueue/lib/screens/auth/login_screen.dart)
- **Remove** "Continue as Guest" button entirely
- **Add** `.edu` email validation — show error if email doesn't end in `.edu`
- Update hint text: "Enter your .edu email"

#### [MODIFY] [role_select_screen.dart](file:///e:/DigiQueue/lib/screens/auth/role_select_screen.dart)
- Save selected role to Firestore `users/{uid}` document
- If user already has a role in Firestore, skip this screen

#### [MODIFY] [queue_control_screen.dart](file:///e:/DigiQueue/lib/screens/professor/queue_control_screen.dart)
Major additions:
- **Accept / Hold / Reject buttons** replacing old Next/Skip
  - **Accept**: Mark current student as accepted, auto-advance after confirmation
  - **Hold**: Show dropdown to pick 2/5/10/15 min, start timer, show countdown
  - **Reject**: Mark current student as rejected, auto-advance to next
- **Next button**: Advances to the next student (keeps existing behavior but now also sends notification)
- **Email for next schedule**: When rejecting/canceling, option to send an in-app message to the student with a new suggested time
- **Real-time "Currently Serving" display** with student name and token number
- **Tab or button** to navigate to Appointments and Inbox screens

#### [NEW] [faculty_appointments_screen.dart](file:///e:/DigiQueue/lib/screens/professor/faculty_appointments_screen.dart)
- Lists all incoming appointment requests
- Accept → sends confirmation message to student
- Reject → sends rejection message
- Reschedule → faculty picks new date/time, sends message with updated info

#### [NEW] [faculty_inbox_screen.dart](file:///e:/DigiQueue/lib/screens/professor/faculty_inbox_screen.dart)
- Shows all messages received (appointment notifications, student messages)
- Mark as read, view details

#### [MODIFY] [queue_list_screen.dart](file:///e:/DigiQueue/lib/screens/student/queue_list_screen.dart)
- Add navigation buttons for Appointments and Inbox
- Add unread message badge

#### [MODIFY] [active_ticket_screen.dart](file:///e:/DigiQueue/lib/screens/student/active_ticket_screen.dart)
- **Real-time queue position**: Show "Your queue number: #X" and "Currently serving: #Y"
- Both update in real-time via Firestore streams
- Show status changes (on_hold, accepted, rejected) with visual feedback

#### [NEW] [student_appointment_screen.dart](file:///e:/DigiQueue/lib/screens/student/student_appointment_screen.dart)
- **Request appointment form**:
  - Select faculty from list
  - Pick date and time
  - Subject line (1 line)
  - Brief description (2 lines max)
- Shows list of student's past/pending appointments with status

#### [NEW] [student_inbox_screen.dart](file:///e:/DigiQueue/lib/screens/student/student_inbox_screen.dart)
- Shows appointment responses, schedule notifications, etc.
- Mark as read

---

### 5. Widgets

#### [NEW] [hold_timer_widget.dart](file:///e:/DigiQueue/lib/widgets/hold_timer_widget.dart)
- Circular countdown timer with glow animation
- Shows remaining hold time
- Auto-fires callback when timer expires

#### [NEW] [faculty_action_buttons.dart](file:///e:/DigiQueue/lib/widgets/faculty_action_buttons.dart)
- Accept (green) / Hold (amber dropdown) / Reject (red) button row
- Hold shows a popup to select 2, 5, 10, or 15 minutes

#### [NEW] [inbox_badge.dart](file:///e:/DigiQueue/lib/widgets/inbox_badge.dart)
- Small badge overlay showing unread message count

---

### 6. Database Schema (Firestore Collections)

```
users/{uid}
  ├── email: string
  ├── displayName: string
  ├── role: "student" | "faculty"
  └── createdAt: timestamp

queues/{queueId}          (existing, extended)
  ├── ... existing fields ...
  ├── holdUntil: timestamp?
  ├── holdDurationMinutes: int?
  └── currentStudentStatus: string?

tokens/{tokenId}          (existing, extended)
  ├── ... existing fields ...
  ├── studentEmail: string
  └── status: "waiting"|"serving"|"accepted"|"rejected"|"on_hold"|"completed"|"skipped"

appointments/{appointmentId}
  ├── studentId, studentName, studentEmail
  ├── facultyId, facultyName, facultyEmail
  ├── requestedDate, requestedTime
  ├── subject, description
  ├── status: "pending"|"accepted"|"rejected"|"rescheduled"
  ├── rescheduledDate?, rescheduledTime?
  ├── createdAt, updatedAt

messages/{messageId}
  ├── fromId, fromName, fromEmail
  ├── toId, toName, toEmail
  ├── subject, body
  ├── type: "appointment_request"|"appointment_response"|"schedule_notification"
  ├── relatedAppointmentId?
  ├── isRead: bool
  └── createdAt
```

---

### 7. Firestore Indexes

#### [MODIFY] [firestore.indexes.json](file:///e:/DigiQueue/firestore.indexes.json)
Add composite indexes for:
- `appointments`: (facultyId + status + createdAt)
- `appointments`: (studentId + status + createdAt)
- `messages`: (toId + isRead + createdAt)
- `messages`: (toId + createdAt)

---

### 8. Dependencies

#### [MODIFY] [pubspec.yaml](file:///e:/DigiQueue/pubspec.yaml)
Add:
- `intl: ^0.20.0` — for date/time formatting
- `url_launcher: ^6.3.1` — for mailto: links (optional fallback)

---

## Verification Plan

### Automated Tests
```bash
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat build web
```

### Manual Verification
1. **Login**: Try registering with non-.edu email → should show error
2. **Faculty flow**: Create queue → Go live → Accept/Hold/Reject students
3. **Student flow**: Join queue → See real-time position updates → Request appointment
4. **Appointments**: Student requests → Faculty accepts/rejects/reschedules → Messages appear in inbox
5. **Real-time**: Open two browser tabs (faculty + student), verify queue updates propagate instantly
