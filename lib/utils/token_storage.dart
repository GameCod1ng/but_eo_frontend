
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static Future<void> saveTokens(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    print("✅ accessToken 저장 완료: $accessToken");

    if (_isJwtFormat(accessToken)) {
      try{
        //JWT 디코딩해서 userId 추출
        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        String userId = decodedToken['sub'];

        //userId로 저장
        await prefs.setString('userId', userId);
        print("userId 저장 : $userId");
      } catch(e) {
        print("jwt 디코딩 실패 $e");
      }
    }else {
      print("accessToken JWT 형식 아님 userId 저장 생략");
    }

  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
  }

  static bool _isJwtFormat(String token) {
    return token.split('.').length == 3;
  }

}