import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import 'email_otp_screen.dart';

class RegisterOtpScreen extends StatelessWidget {
  const RegisterOtpScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.role,
  });

  final String email;
  final String password;
  final String name;
  final String phone;
  final String role;

  @override
  Widget build(BuildContext context) {
    return EmailOtpScreen(
      email: email,
      role: role,
      purpose: 'register',
      displayName: name,
      onVerified: () async {
        final profile = await AuthService.signUp(
          email: email,
          password: password,
          name: name,
          phone: phone,
          role: role,
        );
        await SessionService.save(profile.role);
        if (context.mounted) {
          context.go(SessionService.homeForRole(profile.role));
        }
        return UserModelResult(profile: profile);
      },
    );
  }
}
