import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_exception.dart';

/// Converts any thrown object into a friendly, user-facing message.
/// Never show raw Firebase error codes in the UI.
String friendlyError(Object error) {
  debugPrint('friendlyError -> ${error.runtimeType}: $error');
  if (error is AppException) return error.message;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'account-exists-with-different-credential':
        return 'This email is registered with a different sign-in method.';
      case 'requires-recent-login':
        return 'Please log in again to continue.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return "You don't have permission to perform this action.";
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Connection problem. Check your internet and try again.';
      case 'not-found':
        return "We couldn't find what you were looking for.";
      case 'already-exists':
        return 'This record already exists.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // Google Sign-In / platform plugin failures.
  if (error is PlatformException) {
    final msg = '${error.message}';
    if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
      return 'Google sign-in is not configured for this build (SHA-1 missing).';
    }
    if (msg.contains('ApiException: 7') || error.code == 'network_error') {
      return 'No internet connection. Check your network and try again.';
    }
    if (msg.contains('ApiException: 12500')) {
      return 'Google sign-in is not set up correctly. Check the Firebase support email.';
    }
    return 'Google sign-in failed. Please try again.';
  }

  if (error is SocketException) {
    return 'No internet connection. Check your network and try again.';
  }
  return 'Something went wrong. Please try again.';
}