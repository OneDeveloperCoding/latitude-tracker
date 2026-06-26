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
  // Singleton avoids losing cached sign-in state between calls and gives
  // us a stable handle to call signOut() when we need to evict the session.
  static final _googleSignIn = GoogleSignIn();

  // Exposed so DriveBackupService can share this instance — a second
  // GoogleSignIn() would have conflicting sign-in state.
  static GoogleSignIn get googleSignIn => _googleSignIn;

  Future<GoogleAuthResult> signInWithGoogle() async {
    try {
      final credential = await _buildCredential();
      if (credential == null) return const GoogleAuthCancelled();

      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final uid = result.user?.uid;
      if (uid == null) {
        await _signOutBoth();
        return GoogleAuthUnknown(
          StateError('signInWithCredential returned null user'),
          StackTrace.current,
        );
      }

      try {
        final hasData = await _userHasData(uid);
        if (!hasData) {
          await _signOutBoth();
          return const GoogleAuthNoExistingData();
        }
      } on Object catch (e, st) {
        // Always evict the session on data-check failure so the orphan
        // account never persists as the active Firebase session.
        await _signOutBoth();
        logError(e, st);
        return GoogleAuthUnknown(e, st);
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

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _googleSignIn.signOut();
        return GoogleAuthUnknown(
          StateError('linkGoogleAccount called with no signed-in user'),
          StackTrace.current,
        );
      }

      await user.linkWithCredential(credential);
      return const GoogleAuthSuccess();
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e);
    } on Object catch (e, st) {
      logError(e, st);
      return GoogleAuthUnknown(e, st);
    }
  }

  Future<OAuthCredential?> _buildCredential() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    return GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  Future<bool> _userHasData(String uid) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    final results = await Future.wait([
      ref.collection('sales').limit(1).get(),
      ref.collection('buyers').limit(1).get(),
    ]);
    return results.any((s) => s.docs.isNotEmpty);
  }

  Future<void> _signOutBoth() async {
    await Future.wait([
      FirebaseAuth.instance.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  GoogleAuthResult _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'credential-already-in-use' ||
      'account-exists-with-different-credential' =>
        const GoogleAuthCredentialAlreadyInUse(),
      'network-request-failed' => const GoogleAuthNetworkError(),
      _ => GoogleAuthUnknown(e, e.stackTrace ?? StackTrace.current),
    };
  }
}
