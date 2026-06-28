import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this app. Contact support.';
      case 'missing-email':
        return 'Please enter your email address.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
  if (error is Exception && error.toString().contains('cancelled')) {
    return 'Sign-in was cancelled.';
  }
  return 'Something went wrong. Please try again.';
}

String passwordResetErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many reset attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'Password reset is not enabled. Contact support.';
      case 'missing-email':
        return 'Please enter your email address.';
      default:
        return error.message ?? 'Could not send reset email. Please try again.';
    }
  }
  return authErrorMessage(error);
}
