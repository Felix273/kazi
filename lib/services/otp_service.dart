import 'package:cloud_functions/cloud_functions.dart';

class OtpService {
  static Future<void> sendEmailOtp({
    required String email,
    String purpose = 'login',
    String? name,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('sendEmailOtp')
          .call({
            'email': email,
            'purpose': purpose,
            if (name != null && name.isNotEmpty) 'name': name,
          });
    } on FirebaseFunctionsException catch (error) {
      throw _mapError(error);
    }
  }

  static Future<bool> verifyEmailOtp({
    required String email,
    required String code,
    String purpose = 'login',
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('verifyEmailOtp')
          .call({'email': email, 'code': code, 'purpose': purpose});
      final data = result.data;
      return data is Map && data['verified'] == true;
    } on FirebaseFunctionsException catch (error) {
      throw _mapError(error);
    }
  }

  static OtpException _mapError(FirebaseFunctionsException error) {
    final code = error.code;
    final message = switch (code) {
      'invalid-argument' =>
        error.message ?? 'The information you provided is invalid.',
      'not-found' => error.message ?? 'No active code. Request a new one.',
      'deadline-exceeded' => error.message ?? 'The code has expired.',
      'resource-exhausted' =>
        error.message ?? 'Too many attempts. Request a new code.',
      'failed-precondition' =>
        error.message ?? 'Email service is not configured. Contact support.',
      'internal' => error.message ?? 'Could not send the email. Try again.',
      _ => error.message ?? 'Something went wrong. Please try again.',
    };
    return OtpException(code, message);
  }
}

class OtpException implements Exception {
  OtpException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'OtpException($code): $message';
}
