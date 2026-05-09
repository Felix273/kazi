import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'storage_service.dart';

const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // Must be set via --dart-define or in build configuration
  // Example: flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
);

class ApiClient {
  late final Dio _dio;
  final StorageService _storage;

  ApiClient(this._storage) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));
    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      error: true,
      compact: true,
    ));
  }

  Dio get dio => _dio;

  // Auth
  Future<Response> requestOTP(String phoneNumber) =>
      _dio.post('/auth/request-otp/', data: {'phone_number': phoneNumber});

  Future<Response> verifyOTP(String phoneNumber, String code) =>
      _dio.post('/auth/verify-otp/', data: {'phone_number': phoneNumber, 'code': code});

  Future<Response> completeRegistration(Map<String, dynamic> data) =>
      _dio.post('/auth/complete-registration/', data: data);

  Future<Response> refreshToken(String refresh) =>
      _dio.post('/auth/refresh/', data: {'refresh': refresh});

  // Users
  Future<Response> getMyProfile() => _dio.get('/users/me/');
  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.patch('/users/me/', data: data);
  Future<Response> updateLocation(double lat, double lng, String locationName) =>
      _dio.post('/users/location/', data: {
        'latitude': lat, 'longitude': lng, 'location_name': locationName,
      });
  Future<Response> updateFCMToken(String token) =>
      _dio.post('/users/fcm-token/', data: {'fcm_token': token});
  Future<Response> setOnlineStatus(bool isOnline) =>
      _dio.post('/users/online-status/', data: {'is_online': isOnline});
  Future<Response> getSkills({String? category}) =>
      _dio.get('/users/skills/', queryParameters: category != null ? {'category': category} : null);
  Future<Response> getPublicProfile(String userId) => _dio.get('/users/profile/$userId/');

  // Jobs
  Future<Response> getJobs({Map<String, dynamic>? filters}) =>
      _dio.get('/jobs/', queryParameters: filters);
  Future<Response> getJob(String jobId) => _dio.get('/jobs/$jobId/');
  Future<Response> createJob(Map<String, dynamic> data) => _dio.post('/jobs/create/', data: data);
  Future<Response> applyForJob(String jobId, {String? coverNote, double? proposedRate}) =>
      _dio.post('/jobs/$jobId/apply/', data: {
        if (coverNote != null) 'cover_note': coverNote,
        if (proposedRate != null) 'proposed_rate': proposedRate,
      });
  Future<Response> acceptApplication(String jobId, String applicationId) =>
      _dio.post('/jobs/$jobId/applications/$applicationId/accept/');
  Future<Response> startJob(String jobId) => _dio.post('/jobs/$jobId/start/');
  Future<Response> completeJob(String jobId) => _dio.post('/jobs/$jobId/complete/');
  Future<Response> cancelJob(String jobId, {String? reason}) =>
      _dio.post('/jobs/$jobId/cancel/', data: {'reason': reason ?? ''});
  Future<Response> getJobApplications(String jobId) => _dio.get('/jobs/$jobId/applications/');
  Future<Response> submitReview(String jobId, int rating, String comment) =>
      _dio.post('/jobs/$jobId/review/', data: {'rating': rating, 'comment': comment});

  // Payments
  Future<Response> initiatePayment(String jobId, String payerPhone) =>
      _dio.post('/payments/initiate/', data: {'job_id': jobId, 'payer_phone': payerPhone});
  Future<Response> getPaymentStatus(String jobId) => _dio.get('/payments/$jobId/status/');

  // Chat
  Future<Response> getChatRoom(String jobId) => _dio.get('/chat/$jobId/');
  Future<Response> getChatMessages(String roomId, {int page = 1}) =>
      _dio.get('/chat/$roomId/messages/', queryParameters: {'page': page});

  // Notifications
  Future<Response> getNotifications() => _dio.get('/notifications/');
  Future<Response> markNotificationRead(String id) => _dio.post('/notifications/$id/read/');
}

class _AuthInterceptor extends Interceptor {
  final StorageService _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired — try refresh
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _dio.post('/auth/refresh/', data: {'refresh': refreshToken});
          final newAccess = response.data['access'];
          final newRefresh = response.data['refresh'];
          await _storage.saveTokens(access: newAccess, refresh: newRefresh);

          // Retry original request with new token
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retried = await _dio.fetch(err.requestOptions);
          return handler.resolve(retried);
        } catch (_) {
          await _storage.clearAll();
          // AuthBloc will detect missing token and redirect to login
        }
      }
    }
    handler.next(err);
  }
}
