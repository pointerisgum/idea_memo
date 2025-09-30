import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' hide User;
import 'package:kakao_flutter_sdk_user/src/model/user.dart' as KakaoUser;
import 'package:flutter/foundation.dart';
import 'package:ideamemo/core/services/account_deletion_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 현재 사용자 가져오기
  static User? get currentUser => _auth.currentUser;

  // 로그인 상태 스트림
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google 로그인
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔄 Google 로그인 시작');

      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ Google 로그인 취소됨');
        return null;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase 인증 정보 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Google 로그인 성공: ${userCredential.user?.email}');

      return userCredential;
    } catch (e) {
      debugPrint('❌ Google 로그인 실패: $e');
      return null;
    }
  }

  // Apple 로그인
  static Future<UserCredential?> signInWithApple() async {
    try {
      debugPrint('🔄 Apple 로그인 시작');

      // Apple 로그인 플로우 시작
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Firebase 인증 정보 생성
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebase에 로그인
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      debugPrint('✅ Apple 로그인 성공: ${userCredential.user?.email}');

      return userCredential;
    } catch (e) {
      debugPrint('❌ Apple 로그인 실패: $e');
      return null;
    }
  }

  // 카카오 로그인
  static Future<UserCredential?> signInWithKakao() async {
    bool isLoggedIn = false;
    OAuthToken? kakaoToken;
    KakaoUser.User? kakaoUser;

    try {
      debugPrint('🔄 카카오 로그인 시작');

      // 카카오톡 설치 여부 확인 후 로그인 처리
      if (await isKakaoTalkInstalled() == false) {
        try {
          kakaoToken = await UserApi.instance.loginWithKakaoTalk();
          kakaoUser = await UserApi.instance.me(); // 카카오 사용자 정보 가져오기
          isLoggedIn = true;
          debugPrint('✅ 카카오톡으로 로그인 성공 ${kakaoToken.accessToken}');
        } catch (error) {
          debugPrint('⚠️ 카카오톡으로 로그인 실패 $error');
        }
      } else {
        try {
          kakaoToken = await UserApi.instance.loginWithKakaoAccount();
          kakaoUser = await UserApi.instance.me(); // 카카오 사용자 정보 가져오기
          isLoggedIn = true;
          debugPrint('✅ 카카오계정으로 로그인 성공');
        } catch (error) {
          debugPrint('❌ 카카오계정으로 로그인 실패 $error');
        }
      }

      if (isLoggedIn && kakaoToken != null && kakaoUser != null) {
        // 카카오 이메일 가져오기
        String? email = kakaoUser.kakaoAccount?.email;
        if (email == null) {
          debugPrint('❌ 이메일을 가져오지 못했습니다.');
          return null; // 이메일이 필수인 경우 처리
        }

        String password = '${kakaoUser.id}!ideamemo!';

        try {
          // Firebase 이메일 가입 시도
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          debugPrint('✅ 카카오 로그인 성공 (새 계정): $email');
          return userCredential;
        } catch (e) {
          if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
            // 기존 회원 로그인
            try {
              final credential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              debugPrint('✅ 카카오 로그인 성공 (기존 계정): $email');
              return credential;
            } catch (e) {
              debugPrint('❌ 이미 동일한 계정이 존재합니다: $e');
              return null;
            }
          } else {
            debugPrint('❌ Firebase 로그인/가입 실패: $e');
            return null;
          }
        }
      }

      debugPrint('❌ 카카오 로그인 실패: 로그인되지 않음');
      return null;
    } catch (e) {
      debugPrint('❌ 카카오 로그인 전체 실패: $e');
      return null;
    }
  }

  // 로그아웃
  static Future<void> signOut() async {
    try {
      debugPrint('🔄 로그아웃 시작');

      // Google 로그아웃
      await _googleSignIn.signOut();

      // 카카오 로그아웃 (에러 무시)
      try {
        await UserApi.instance.logout();
      } catch (e) {
        debugPrint('⚠️ 카카오 로그아웃 실패 (무시): $e');
      }

      // Firebase 로그아웃
      await _auth.signOut();

      debugPrint('✅ 로그아웃 완료');
    } catch (e) {
      debugPrint('❌ 로그아웃 실패: $e');
      rethrow;
    }
  }

  // 계정 삭제 (최신 베스트 프랙티스 적용)
  static Future<void> deleteAccount() async {
    // 새로운 계정 삭제 서비스 사용
    await AccountDeletionService.deleteAccount();
  }

  // 사용자 정보 가져오기
  static Map<String, dynamic>? getUserInfo() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'provider': user.providerData.isNotEmpty ? user.providerData.first.providerId : 'unknown',
    };
  }
}
