import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 👇 1. Your Web Client ID is perfectly placed!
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '937726428403-5hvhf5a5r3n6ta227g1nqf6lr09rpjdf.apps.googleusercontent.com',
  );

  // Function to handle Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 👇 Force the account chooser to appear every time by signing out first
      await _googleSignIn.signOut();

      // 2. Trigger the Google Authentication flow (V6 uses .signIn)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If the user cancels the sign-in, return null
      if (googleUser == null) return null;

      // 3. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Create a new credential using BOTH tokens (Required in V6)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase with that credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // 👇 Save their Google profile to Firestore so we know their name!
      if (userCredential.user != null) {
        await DatabaseService().createUserProfile(
          userCredential.user!.displayName ?? "User",
          userCredential.user!.email ?? "",
        );
      }
      
      return userCredential;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  // 👇 Add this Sign Out function!
  Future<void> signOut() async {
    try {
      // Disconnect from Google to force account chooser on next login
      await _googleSignIn.disconnect();
      // Sign out of Firebase
      await _auth.signOut();
    } catch (e) {
      print("Error during sign out: $e");
    }
  }
}
