import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import 'email_otp_screen.dart';

class LoginOtpScreen extends StatelessWidget {
  const LoginOtpScreen({
    super.key,
    required this.email,
    required this.password,
    required this.role,
  });

  final String email;
  final String password;
  final String role;

  @override
  Widget build(BuildContext context) {
    return EmailOtpScreen(
      email: email,
      role: role,
      purpose: 'login',
      onVerified: () async {
        final profile = await AuthService.signInWithOtp(
          email: email,
          password: password,
          intendedRole: role,
        );
        if (profile.role != role) {
          try {
            await AuthService.updateUserRole(role);
          } catch (_) {}
        }
        await SessionService.save(profile.role);
        if (context.mounted) {
          context.go(SessionService.homeForRole(profile.role));
        }
        return UserModelResult(profile: profile);
      },
    );
  }
}
