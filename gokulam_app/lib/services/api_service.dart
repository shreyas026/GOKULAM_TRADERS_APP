import 'package:dio/dio.dart';
import 'storage_service.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshToken = await StorageService.getRefreshToken();
          if (refreshToken != null) {
            try {
              final response = await Dio().post(
                '${AppConfig.apiBaseUrl}/auth/token/refresh/',
                data: {'refresh': refreshToken},
              );
              final newAccess = response.data['access'];
              await StorageService.saveTokens(
                access: newAccess,
                refresh: response.data['refresh'] ?? refreshToken,
              );
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await _dio.fetch(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> uploadFile(String path, String filePath,
      {String fieldName = 'image'}) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.post(path, data: formData);
  }
}