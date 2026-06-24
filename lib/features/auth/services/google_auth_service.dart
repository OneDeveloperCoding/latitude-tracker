import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latitude_tracker/core/services/error_reporter.dart';

sealed class GoogleAuthResult {
  const GoogleAuthResult();
}

class GoogleAuthSuccess extends GoogleAuthResult {
  const GoogleAuthSuccess();
}

class GoogleAuthCancelled extends GoogleAuthResult {
  const GoogleAuthCancelled();
}

class GoogleAuthCredentialAlreadyInUse extends GoogleAuthResult {
  const GoogleAuthCredentialAlreadyInUse();
}

class GoogleAuthNoExistingData extends GoogleAuthResult {
  const GoogleAuthNoExistingData();
}

class GoogleAuthNetworkError extends GoogleAuthResult {
  const GoogleAuthNetworkError();
}

class GoogleAuthUnknown extends GoogleAuthResult {
  const GoogleAuthUnknown(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

class GoogleAuthService {
  Future<GoogleAuthResult> signInWithGoogle() async {
    try {
      final credential = await _buildCredential();
      if (credential == null) return const GoogleAuthCancelled();

      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = result.user!.uid;

      final hasData = await _userHasData(uid);
      if (!hasData) {
        await FirebaseAuth.instance.signOut();
        return const GoogleAuthNoExistingData();
      }

      return const GoogleAuthSuccess();
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e);
    } on Object catch (e, st) {
      logError(e, st);
      return GoogleAuthUnknown(e, st);
    }
  }

  Future<GoogleAuthResult> linkGoogleAccount() async {
    try {
      final credential = await _buildCredential();
      if (credential == null) return const GoogleAuthCancelled();

      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
      return const GoogleAuthSuccess();
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e);
    } on Object catch (e, st) {
      logError(e, st);
      return GoogleAuthUnknown(e, st);
    }
  }

  Future<OAuthCredential?> _buildCredential() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  Future<bool> _userHasData(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sales')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  GoogleAuthResult _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'credential-already-in-use' => const GoogleAuthCredentialAlreadyInUse(),
      'network-request-failed' => const GoogleAuthNetworkError(),
      _ => GoogleAuthUnknown(e, StackTrace.current),
    };
  }
}
