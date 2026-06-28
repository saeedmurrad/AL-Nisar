import 'package:cloud_firestore/cloud_firestore.dart';

/// User-facing message when a member submits or resubmits a Sabaq access request.
String sabaqAccessRequestErrorMessage(Object error) {
  if (error is StateError) {
    switch (error.message) {
      case 'not_signed_in':
        return 'Please sign in to request access.';
      case 'request_already_active':
        return 'A request is already pending or approved for this Sabaq.';
    }
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Request not allowed. Sign out and sign in again, or contact admin.';
      case 'unauthenticated':
        return 'Session expired. Please sign in again.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Could not send request. Please try again.';
    }
  }
  return 'Could not send request. Please try again.';
}
