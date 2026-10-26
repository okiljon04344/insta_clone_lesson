import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'supabase_storage_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '550750223602-59bcvifg7dcgngsdc8kt605ctffq8ktl.apps.googleusercontent.com',
  );

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Sign in with email/password ─────────────────────────────────────────────
  Future<UserModel> signInWithEmail({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      String email = emailOrUsername;

      // Support signing in with a username
      if (!emailOrUsername.contains('@')) {
        final query = await _db
            .collection('users')
            .where('username', isEqualTo: emailOrUsername.toLowerCase().trim())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw AuthException('Bunday foydalanuvchi topilmadi');
        }
        email = query.docs.first.data()['email'] as String;
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return await _getUserModel(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseErrorToUzb(e.code));
    }
  }

  // ─── Register with email ────────────────────────────────────────
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String? bio,
    XFile? profileImage,
  }) async {
    try {
      // Check that the username is not taken
      final usernameQuery = await _db
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw AuthException('Bu foydalanuvchi nomi allaqachon band');
      }

      // Create the account in Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Upload the profile image
      String photoUrl = '';
      if (profileImage != null) {
        photoUrl = await _uploadProfileImage(cred.user!.uid, profileImage);
      }

      // Update the Firebase Auth profile
      await cred.user!.updateDisplayName(displayName);
      if (photoUrl.isNotEmpty) {
        await cred.user!.updatePhotoURL(photoUrl);
      }

      // Create the user document in Firestore
      final user = UserModel(
        uid: cred.user!.uid,
        email: email.trim(),
        username: username.toLowerCase().trim(),
        displayName: displayName.trim(),
        photoUrl: photoUrl,
        bio: bio ?? '',
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(user.uid).set(user.toMap());

      // Send the email verification message
      await cred.user!.sendEmailVerification();

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseErrorToUzb(e.code));
    } on AuthException {
      rethrow;
    }
  }

  // ─── Sign in with phone number ───────────────────────────────────────────
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(UserCredential cred) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        final cred = await _auth.signInWithCredential(credential);
        onAutoVerified(cred);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_firebaseErrorToUzb(e.code));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserModel> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    String? displayName,
    String? username,
    XFile? profileImage,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user!.uid;

      // Check whether the user already exists
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }

      // New user: create the profile
      String photoUrl = '';
      if (profileImage != null) {
        photoUrl = await _uploadProfileImage(uid, profileImage);
      }

      final finalUsername =
          username?.toLowerCase().trim() ?? 'user_${uid.substring(0, 8)}';

      final user = UserModel(
        uid: uid,
        email: cred.user!.email ?? '',
        username: finalUsername,
        displayName: displayName ?? finalUsername,
        photoUrl: photoUrl,
        phoneNumber: cred.user!.phoneNumber ?? '',
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(uid).set(user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseErrorToUzb(e.code));
    }
  }

  // ─── Sign in with Google ──────────────────────────────────────────────────
  Future<UserModel> ensurePhoneUserProfile(
    UserCredential cred, {
    String? displayName,
    String? username,
    XFile? profileImage,
  }) async {
    final uid = cred.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }

    String photoUrl = '';
    if (profileImage != null) {
      photoUrl = await _uploadProfileImage(uid, profileImage);
    }

    final finalUsername =
        username?.toLowerCase().trim() ?? 'user_${uid.substring(0, 8)}';

    final user = UserModel(
      uid: uid,
      email: cred.user!.email ?? '',
      username: finalUsername,
      displayName: displayName ?? finalUsername,
      photoUrl: photoUrl,
      phoneNumber: cred.user!.phoneNumber ?? '',
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      late UserCredential cred;

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        cred = await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw AuthException('Google kirish bekor qilindi');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }

      final firebaseUser = cred.user;
      if (firebaseUser == null) {
        throw AuthException(
          'Google kirish muvaffaqiyatsiz, qayta urinib ko\'ring',
        );
      }
      final uid = firebaseUser.uid;

      // Existing user?
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }

      // New user: create the profile in Firestore
      final googleEmail = firebaseUser.email ?? '';
      final baseUsername = googleEmail
          .split('@')
          .first
          .replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '_')
          .toLowerCase();

      // Ensure the username is unique
      String finalUsername = baseUsername;
      int suffix = 1;
      while (true) {
        final q = await _db
            .collection('users')
            .where('username', isEqualTo: finalUsername)
            .limit(1)
            .get();
        if (q.docs.isEmpty) break;
        finalUsername = '${baseUsername}_$suffix';
        suffix++;
      }

      final newUser = UserModel(
        uid: uid,
        email: googleEmail,
        username: finalUsername,
        displayName: firebaseUser.displayName ?? finalUsername,
        photoUrl: firebaseUser.photoURL ?? '',
        bio: '',
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(uid).set(newUser.toMap());
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseErrorToUzb(e.code));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Google kirish xatoligi: $e');
    }
  }

  // ─── Password reset ──────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_firebaseErrorToUzb(e.code));
    }
  }

  // ─── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Get the current user ──────────────────────────────────────────
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _getUserModel(user.uid);
  }

  Future<UserModel> _getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw AuthException('Foydalanuvchi topilmadi');
    return UserModel.fromMap(doc.data()!);
  }

  Future<String> _uploadProfileImage(String uid, XFile image) async {
    return SupabaseStorageService().uploadAvatar(uid: uid, image: image);
  }

  String _firebaseErrorToUzb(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bunday email bilan hisob topilmadi';
      case 'wrong-password':
        return 'Parol noto\'g\'ri';
      case 'email-already-in-use':
        return 'Bu email allaqachon ro\'yxatdan o\'tgan';
      case 'invalid-email':
        return 'Email manzil noto\'g\'ri';
      case 'weak-password':
        return 'Parol juda qisqa (kamida 6 ta belgi)';
      case 'too-many-requests':
        return 'Juda ko\'p urinish. Keyinroq qayta urinib ko\'ring';
      case 'network-request-failed':
        return 'Internet aloqasi yo\'q';
      case 'invalid-verification-code':
        return 'SMS kod noto\'g\'ri';
      case 'invalid-phone-number':
        return 'Telefon raqam noto\'g\'ri';
      case 'session-expired':
        return 'SMS kodning muddati tugadi. Qayta yuborish';
      case 'invalid-credential':
        return 'Email yoki parol noto\'g\'ri';
      default:
        return 'Xatolik yuz berdi: $code';
    }
  }
}
