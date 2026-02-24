import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// 토큰 관리 서비스
class TokenService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Storage Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';
  static const String _userInfoKey = 'user_info';

  /// Access Token 저장
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    // Access Token 만료 시간 저장 (1시간 후)
    final expiryTime = DateTime.now().add(const Duration(hours: 1)).toIso8601String();
    await _storage.write(key: _tokenExpiryKey, value: expiryTime);
  }

  /// Refresh Token 저장
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
    // Refresh Token 만료 시간 저장 (14일 후)
    final expiryTime = DateTime.now().add(const Duration(days: 14)).toIso8601String();
    await _storage.write(key: _refreshTokenExpiryKey, value: expiryTime);
  }

  /// 사용자 정보 저장
  static Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    await _storage.write(key: _userInfoKey, value: jsonEncode(userInfo));
  }

  /// 모든 토큰 정보 한번에 저장
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userInfo,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserInfo(userInfo),
    ]);
  }

  /// Access Token 가져오기
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Refresh Token 가져오기
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// 사용자 정보 가져오기
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final userInfoStr = await _storage.read(key: _userInfoKey);
    if (userInfoStr == null) return null;
    return jsonDecode(userInfoStr) as Map<String, dynamic>;
  }

  /// Access Token 만료 여부 확인
  /// [bufferMinutes] 만료 전 몇 분부터 갱신할지 (기본 5분)
  static Future<bool> isAccessTokenExpired({int bufferMinutes = 5}) async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return true;

    final expiryTime = DateTime.parse(expiryStr);
    final now = DateTime.now();
    final bufferTime = now.add(Duration(minutes: bufferMinutes));

    // 현재 시간 + 버퍼가 만료 시간을 넘으면 갱신 필요
    return bufferTime.isAfter(expiryTime);
  }

  /// Refresh Token 만료 여부 확인
  /// [bufferDays] 만료 전 몇 일부터 갱신할지 (기본 3일)
  static Future<bool> isRefreshTokenExpiringSoon({int bufferDays = 3}) async {
    final expiryStr = await _storage.read(key: _refreshTokenExpiryKey);
    if (expiryStr == null) return true;

    final expiryTime = DateTime.parse(expiryStr);
    final now = DateTime.now();
    final bufferTime = now.add(Duration(days: bufferDays));

    // 현재 시간 + 버퍼(3일)가 만료 시간을 넘으면 갱신 필요
    return bufferTime.isAfter(expiryTime);
  }

  /// 로그인 여부 확인
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// 모든 토큰 삭제 (로그아웃)
  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _tokenExpiryKey),
      _storage.delete(key: _userInfoKey),
    ]);
  }

  /// 토큰 정보 출력 (디버깅용)
  static Future<void> printTokenInfo() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    final expiryStr = await _storage.read(key: _tokenExpiryKey);

    print('=== Token Info ===');
    print('Access Token: ${accessToken?.substring(0, 20)}...');
    print('Refresh Token: ${refreshToken?.substring(0, 20)}...');
    print('Expiry: $expiryStr');
    print('Is Expired: ${await isAccessTokenExpired()}');
    print('==================');
  }
}
