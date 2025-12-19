import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// GOOGLE SIGN IN — ALWAYS SHOW ACCOUNT CHOOSER
  Future<User?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );

    // 🔥 FORCE ACCOUNT CHOOSER
    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser =
        await googleSignIn.signIn();

    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    return userCredential.user;
  }

  /// AUTO LOGIN SUPPORT
  User? get currentUser => _auth.currentUser;

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
