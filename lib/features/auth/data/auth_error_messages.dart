String authErrorMessage(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'That email and password do not match. Check them and try again.';
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'email-already-in-use':
      return 'An account already exists for this email. Sign in instead.';
    case 'weak-password':
      return 'That password is too weak. Use at least 8 characters with a '
          'letter and a number.';
    case 'user-disabled':
      return 'This account has been disabled. Contact your pharmacy owner.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a few minutes and try again.';
    case 'network-request-failed':
      return 'No internet connection. Check your connection and try again.';
    case 'account-exists-with-different-credential':
      return 'This email is already registered with a password. Sign in '
          'with your email and password instead.';
    case 'requires-recent-login':
      return 'For your security, sign in again and retry.';
    case 'permission-denied':
      return 'You do not have permission to do that.';
    case 'unavailable':
      return 'The server could not be reached. Try again in a moment.';
    default:
      return 'Something went wrong. Please try again.';
  }
}