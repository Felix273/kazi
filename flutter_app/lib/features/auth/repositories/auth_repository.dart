import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../profile/models/user_model.dart';

class OTPVerifyResult {
  final UserModel user;
  final bool isNewUser;
  OTPVerifyResult({required this.user, required this.isNewUser});
}

class AuthRepository {
  final ApiClient _api;
  final StorageService _storage = StorageService();

  AuthRepository(this._api);

  Future<void> requestOTP(String phoneNumber) async {
    final response = await _api.requestOTP(phoneNumber);
    if (response.statusCode != 200) {
      throw Exception(response.data['detail'] ?? 'Failed to send OTP');
    }
  }

  Future<OTPVerifyResult> verifyOTP(String phoneNumber, String code) async {
    final response = await _api.verifyOTP(phoneNumber, code);
    if (response.statusCode != 200) {
      throw Exception(response.data['detail'] ?? 'OTP verification failed');
    }

    final data = response.data;
    final tokens = data['tokens'];
    final user = UserModel.fromJson(data['user']);
    final isNewUser = data['is_new_user'] as bool;

    await _storage.saveTokens(
      access: tokens['access'],
      refresh: tokens['refresh'],
    );
    await _storage.saveUserId(user.id);
    await _storage.saveUserType(user.userType);

    return OTPVerifyResult(user: user, isNewUser: isNewUser);
  }

  Future<UserModel> completeRegistration(Map<String, dynamic> data) async {
    final response = await _api.completeRegistration(data);
    if (response.statusCode != 200) {
      throw Exception('Registration failed');
    }
    final user = UserModel.fromJson(response.data['user']);
    await _storage.saveUserType(user.userType);
    await _storage.setOnboardingComplete(true);
    return user;
  }

  Future<UserModel?> getStoredUser() async {
    final token = await _storage.getAccessToken();
    if (token == null) return null;
    try {
      final response = await _api.getMyProfile();
      return UserModel.fromJson(response.data);
    } catch (_) {
      await _storage.clearAll();
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
