import 'package:dio/dio.dart';
import 'token_service.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8080/api';
  final Dio _dio = Dio();

  AuthService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);

    // Interceptor 추가: 자동 토큰 갱신
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Access Token 만료 확인 및 갱신
        // (Refresh Token도 함께 재발급되므로 영구 자동 로그인 유지)
        if (await TokenService.isAccessTokenExpired()) {
          print('Access Token 만료 임박, 자동 갱신 시도...');
          final refreshed = await _refreshAccessToken();
          if (!refreshed) {
            print('토큰 갱신 실패, 재로그인 필요');
            // 갱신 실패 시 요청 취소
            return handler.reject(
              DioException(
                requestOptions: options,
                error: '토큰 갱신 실패. 다시 로그인해주세요.',
              ),
            );
          }
        }

        // 갱신된 토큰으로 헤더 설정
        final accessToken = await TokenService.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }

        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // 401 에러 시 토큰 갱신 후 재시도
        if (error.response?.statusCode == 401) {
          print('401 에러 발생, 토큰 갱신 시도...');
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            // 갱신 성공 시 원래 요청 재시도
            final accessToken = await TokenService.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $accessToken';

            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Access Token 갱신 (내부 메서드)
  /// POST /api/auth/token/refresh
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null) {
        print('Refresh Token이 없습니다.');
        return false;
      }

      final response = await _dio.post(
        '/auth/token/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await TokenService.saveAccessToken(data['accessToken']);
        await TokenService.saveRefreshToken(data['refreshToken']);
        print('토큰 갱신 성공');
        return true;
      }
      return false;
    } catch (e) {
      print('토큰 갱신 오류: $e');
      return false;
    }
  }

  /// 토큰 검증 (필요 시 사용)
  /// GET /api/auth/token/verify?accessToken={token}
  Future<Map<String, dynamic>?> verifyToken(String accessToken) async {
    try {
      final response = await _dio.get(
        '/auth/token/verify',
        queryParameters: {'accessToken': accessToken},
      );

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('토큰 검증 오류: $e');
      return null;
    }
  }

  /// 카카오 사용자 존재 여부 확인
  ///
  /// [accessToken] 카카오 액세스 토큰
  ///
  /// Returns: {"existingUser": true/false}
  Future<Map<String, dynamic>> checkKakaoUser(String accessToken) async {
    try {
      // 카카오 로그인 체크는 Interceptor를 건너뛰어야 함 (아직 토큰이 없으므로)
      final dio = Dio();
      dio.options.baseUrl = baseUrl;
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 3);

      final response = await dio.post(
        '/auth/kakao/check',
        data: {
          'accessToken': accessToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('사용자 확인 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('서버 오류: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('네트워크 오류: ${e.message}');
      }
    }
  }
}
