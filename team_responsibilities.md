# DigiQueue Project – Team Responsibilities and Process Breakdown

Based on the project's architecture and the assigned roles, here is the detailed breakdown of the development process, explaining exactly what each team member contributed, their overall project contribution percentage, primary area of responsibility, and the specific files (Dart, JSON, YAML) they were responsible for.

### 1. Md. Samin Yeasher (ID: 231000712) — 20.5% [BE+FE]
**Role:** Project Lead, Core Logic & Architecture

**What they did:** As the Project Lead, Samin built the bridge between the frontend application and the backend database. On the frontend (FE), he set up the foundational app routing and initialization. On the backend (BE), he developed the core database services handling the complex business logic for creating appointments, managing queue flows, and handling CRUD operations. He also managed overall QA and system integration.

**Respective Files:**
* `lib/main.dart` (App entry point and foundational routing setup)
* `lib/services/database_service.dart` (Core backend logic handling database transactions, appointments, and queue operations)
* `lib/providers/appointment_provider.dart` (State management bridging backend appointment streams to the frontend)

### 2. Rifazul Karim Rahat (ID: 231002612) — 16.5% [FE]
**Role:** Frontend Auth UI & Global UI/UX

**What they did:** Rahat was responsible for the visual design, theming, and user experience of the app. He developed the global styling and the foundational authentication screens, ensuring a professional and intuitive gateway for users. He also handled role selection logic on the frontend to direct users to the appropriate workflows.

**Respective Files:**
* `lib/screens/auth/login_screen.dart` (UI for email/password input and visual validation feedback)
* `lib/screens/auth/role_select_screen.dart` (UI for users to pick their role: Student or Faculty)
* `lib/theme/app_theme.dart` (Global styling and color scheme definitions)
* `lib/widgets/inbox_badge.dart` (Reusable UI widget for displaying unread notifications)

### 3. Minhaz Uddin (ID: 231007712) — 16.5% [BE]
**Role:** Backend State Management & Authentication Logic

**What they did:** Minhaz was the primary backend developer responsible for state management and user authentication. He connected the app to Firebase Authentication and enforced security rules like .edu email validation. Furthermore, he developed the backend providers responsible for listening to real-time database updates for queues, tokens, and messages, ensuring the frontend always had up-to-date data.

**Respective Files:**
* `lib/services/auth_service.dart` (Backend logic handling authentication and .edu validation)
* `lib/providers/auth_provider.dart` (State management for persistent user sessions and roles)
* `lib/providers/queue_provider.dart` (State management handling real-time queue data streams)
* `lib/providers/token_provider.dart` (State management handling real-time student token status)
* `lib/providers/message_provider.dart` (State management for real-time inbox messaging)

### 4. Al Sharia Arfin (ID: 231003012) — 16.5% [DB]
**Role:** Database Architecture & Data Modeling

**What they did:** Sharia architected the Firestore database structure and designed the strict data models that represent every entity in the app (Users, Queues, Tokens, Appointments, Messages). He ensured that the database was structured efficiently for NoSQL queries and configured the complex database indexes necessary for the app to quickly fetch relational data.

**Respective Files:**
* `lib/models/user_model.dart` (Database model for users)
* `lib/models/queue_model.dart` (Database model for faculty queues)
* `lib/models/token_model.dart` (Database model for student queue tickets)
* `lib/models/appointment_model.dart` (Database model for scheduled appointments)
* `lib/models/message_model.dart` (Database model for system and user messages)
* `firestore.indexes.json` (Database indexing configurations for optimized complex queries)

### 5. Nisha Das Gupta (ID: 231012312) — 15.0% [FE]
**Role:** Student Workflow Frontend

**What they did:** Nisha built the entire front-end experience for the "Student" role. She developed the screens where students can view available faculty queues, join a queue, and see their live ticket status in real-time. She also implemented the interactive forms for students to request future appointments with faculty members and the inbox screen to check for responses.

**Respective Files:**
* `lib/screens/student/queue_list_screen.dart` (Screen displaying active faculty queues)
* `lib/screens/student/active_ticket_screen.dart` (Real-time display of the student's queue position and serving status)
* `lib/screens/student/student_appointment_screen.dart` (Form interface to request new appointments)
* `lib/screens/student/student_inbox_screen.dart` (Viewing messages and notifications from faculty)
* `lib/widgets/queue_card.dart` (UI widget for displaying individual queues in the list)
* `lib/widgets/ticket_display.dart` (UI component for rendering the student's active ticket details)

### 6. Jannatul Mawa (ID: 231016212) — 15.0% [FE]
**Role:** Faculty Workflow Frontend

**What they did:** Jannatul focused on the complex "Faculty" role experience. She developed the Queue Control dashboard where professors can manage the flow of students by accepting, holding, or rejecting walk-ins. She built custom UI elements like the hold timer and action buttons. She also developed the interfaces where faculty can manage incoming appointment requests and review historical queue data.

**Respective Files:**
* `lib/screens/professor/queue_control_screen.dart` (Main dashboard for advancing the queue)
* `lib/screens/professor/faculty_appointments_screen.dart` (Interface for managing student requests)
* `lib/screens/professor/faculty_inbox_screen.dart` (Viewing system notifications and student messages)
* `lib/screens/professor/queue_history_screen.dart` (Screen displaying historical queue data)
* `lib/widgets/faculty_action_buttons.dart` (Custom Accept/Hold/Reject UI controls)
* `lib/widgets/hold_timer_widget.dart` (Visual countdown timer widget for holding students)
* `lib/widgets/up_next_list.dart` (UI list component showing upcoming students in the queue)
