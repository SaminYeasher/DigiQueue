import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Current Firebase user (null if not signed in)
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Validate .edu email
  bool _isEduEmail(String email) {
    return email.trim().toLowerCase().endsWith('.edu.bd');
  }

  /// Sign in with email and password (.edu only)
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isEduEmail(email)) {
      throw 'Only .edu.bd email addresses are allowed. Please use your university email.';
    }
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Register a new account with email, password, and display name (.edu only)
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    if (!_isEduEmail(email)) {
      throw 'Only .edu.bd email addresses are allowed. Please use your university email.';
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Set the display name
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      // Create user profile in Firestore
      if (credential.user != null) {
        await _db.collection('users').doc(credential.user!.uid).set({
          'email': email.trim(),
          'displayName': displayName.trim(),
          'role': role,
          'createdAt': Timestamp.now(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  /// Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  /// Stream user profile
  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  /// Save/update user role in Firestore
  Future<void> saveUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).set(
      {'role': role},
      SetOptions(merge: true),
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Map Firebase auth exceptions to user-friendly messages
  String _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
