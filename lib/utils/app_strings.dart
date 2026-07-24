/// Centralized English UI strings used throughout the Kazi application.
class AppStrings {
  AppStrings._();

  static const String appName = 'Kazi';

  // Common actions
  static const String cancel = 'Cancel';
  static const String close = 'Close';
  static const String edit = 'Edit';
  static const String ok = 'OK';

  // Authentication
  static const String loginMessage = 'Enter your email address and password';
  static const String createAccountMessage =
      'Create a new account with your email address';

  // General errors
  static const String errorUnknown = 'Something went wrong. Please try again.';

  // Profile
  static const String profileVerified = 'Verified';

  // Settings
  static const String settingsTitle = 'Settings';
  static const String settingsAccount = 'Account';
  static const String settingsEditProfile = 'Edit Profile';
  static const String settingsChangePhone = 'Change Phone Number';
  static const String settingsVerifyId = 'Verify Identity';
  static const String settingsPreferences = 'Preferences';
  static const String settingsDarkMode = 'Dark Mode';
  static const String settingsNotifications = 'Notifications';
  static const String settingsSearchRadius = 'Search Radius';
  static const String settingsSupport = 'Support';
  static const String settingsFAQ = 'How Kazi Works';
  static const String settingsContactSupport = 'Contact Support';
  static const String settingsRateApp = 'Rate the App';
  static const String settingsTerms = 'Terms and Privacy';
  static const String settingsDangerZone = 'Danger Zone';
  static const String settingsDeleteAccount = 'Delete Account';
  static const String settingsDeleteAccountDesc =
      'This will permanently delete your account, profile, and associated '
      'data. This action cannot be undone.';
  static const String settingsLogout = 'Log Out';
  static const String settingsLogoutConfirm =
      'Are you sure you want to log out?';

  // Notification settings
  static const String notifSettingsTitle = 'Notification Settings';

  // Search radius
  static const String searchRadiusTitle = 'Job Search Radius';
  static const String entireNairobi = 'Entire Nairobi';

  // Phone number
  static const String changePhoneTitle = 'Change Phone Number';
  static const String changePhoneSuccess = 'Phone number updated successfully.';

  // Terms
  static const String termsContent =
      'By using Kazi, you agree to our Terms of Service and Privacy Policy. '
      'Payments, account activity, and use of the platform are governed by '
      'our policies and applicable laws.';

  // Frequently asked questions
  static const String faqHowWorksQ = 'How does Kazi work?';
  static const String faqHowWorksA =
      'Employers post jobs and job seekers apply. Once hired, both parties '
      'can communicate securely through in-app messaging.';

  static const String faqPaymentQ = 'How do I get paid?';
  static const String faqPaymentA =
      'Payments are processed through M-Pesa. After a job is completed, '
      'funds are released to your Kazi Wallet.';

  static const String faqCostQ = 'How much does Kazi cost?';
  static const String faqCostA =
      'Applying for jobs is free. Employers pay a 15% platform fee for each '
      'completed job.';

  static const String faqSafetyQ = 'Is Kazi safe to use?';
  static const String faqSafetyA =
      'Kazi includes account verification, secure payments, reporting tools, '
      'and dispute support to help protect users.';
}
