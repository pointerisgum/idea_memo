import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' hide User;
import 'package:kakao_flutter_sdk_user/src/model/user.dart' as KakaoUser;
import 'package:flutter/foundation.dart';
import 'package:ideamemo/core/services/firestore_service.dart';

/// 최신 Firebase Auth 베스트 프랙티스를 적용한 계정 삭제 서비스
///
/// 참고: Firebase 공식 문서 및 커뮤니티 베스트 프랙티스
/// - 먼저 재인증 없이 삭제 시도 (최근 로그인한 경우)
/// - requires-recent-login 에러 시에만 재인증 수행
/// - 제공자별 최적화된 재인증 방식 사용
class AccountDeletionService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 계정 삭제 메인 메서드
  static Future<void> deleteAccount() async {
    try {
      debugPrint('🔄 [DELETE] 계정 삭제 시작');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 1단계: 재인증 없이 삭제 시도 (최근 로그인한 경우)
      if (await _tryDeleteWithoutReauth(user)) {
        return; // 성공적으로 삭제됨
      }

      // 2단계: 재인증 필요한 경우
      await _deleteWithReauth(user);
    } catch (e) {
      debugPrint('❌ [DELETE] 계정 삭제 실패: $e');
      rethrow;
    }
  }

  /// 재인증 없이 삭제 시도
  static Future<bool> _tryDeleteWithoutReauth(User user) async {
    try {
      debugPrint('🔄 [DELETE] 재인증 없이 삭제 시도');

      // 사용자 데이터 먼저 삭제
      await _deleteUserData();

      // Firebase 계정 삭제
      await user.delete();
      debugPrint('✅ [DELETE] 계정 삭제 완료 (재인증 불필요)');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint('🔄 [DELETE] 재인증이 필요함');
        return false; // 재인증 필요
      } else {
        debugPrint('❌ [DELETE] Firebase 에러: ${e.code} - ${e.message}');
        throw Exception('계정 삭제 중 오류가 발생했습니다: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ [DELETE] 예상치 못한 에러: $e');
      throw Exception('계정 삭제 중 예상치 못한 오류가 발생했습니다.');
    }
  }

  /// 재인증 후 삭제
  static Future<void> _deleteWithReauth(User user) async {
    debugPrint('🔄 [DELETE] 재인증 후 삭제 시작');

    // 로그인 제공자 확인
    final providerData = user.providerData;
    if (providerData.isEmpty) {
      throw Exception('로그인 제공자 정보를 찾을 수 없습니다.');
    }

    final providerId = providerData.first.providerId;
    debugPrint('🔍 [DELETE] 로그인 제공자: $providerId');

    // 제공자별 재인증
    switch (providerId) {
      case 'google.com':
        await _reauthenticateWithGoogle(user);
        break;
      case 'password':
        await _handleEmailPasswordAccount(user);
        break;
      case 'apple.com':
        throw Exception('Apple 계정 삭제는 현재 지원되지 않습니다.\n고객센터로 문의해주세요.');
      default:
        throw Exception('지원되지 않는 로그인 제공자입니다: $providerId\n고객센터로 문의해주세요.');
    }

    // 사용자 데이터 삭제
    await _deleteUserData();

    // Firebase 계정 삭제
    await user.delete();
    debugPrint('✅ [DELETE] 계정 삭제 완료');
  }

  /// Google 재인증
  static Future<void> _reauthenticateWithGoogle(User user) async {
    try {
      debugPrint('🔄 [DELETE] Google 재인증 시작');

      // 기존 세션 정리 (중요: 캐시된 토큰 문제 방지)
      await _googleSignIn.signOut();

      // 새로운 Google 로그인
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google 재인증이 취소되었습니다.');
      }

      // 인증 토큰 획득
      final googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google 인증 토큰을 가져올 수 없습니다.');
      }

      // Firebase 크리덴셜 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 재인증
      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ [DELETE] Google 재인증 완료');
    } catch (e) {
      debugPrint('❌ [DELETE] Google 재인증 실패: $e');

      // 구체적인 에러 메시지 제공
      if (e.toString().contains('network')) {
        throw Exception('네트워크 연결을 확인하고 다시 시도해주세요.');
      } else if (e.toString().contains('cancelled') || e.toString().contains('취소')) {
        throw Exception('Google 재인증이 취소되었습니다.\n계정 탈퇴를 위해서는 재인증이 필요합니다.');
      } else {
        throw Exception('Google 재인증에 실패했습니다.\n앱을 재시작하고 다시 시도해주세요.');
      }
    }
  }

  /// Email/Password 계정 처리 (카카오 로그인으로 생성된 계정)
  static Future<void> _handleEmailPasswordAccount(User user) async {
    try {
      debugPrint('🔄 [DELETE] 카카오 계정 확인 시작');

      // 카카오 사용자 정보 확인
      final kakaoUser = await UserApi.instance.me();
      final email = kakaoUser.kakaoAccount?.email;

      if (email == null) {
        throw Exception('카카오 계정에서 이메일을 가져올 수 없습니다.');
      }

      // 이메일 일치 확인
      if (email != user.email) {
        throw Exception('카카오 계정의 이메일이 일치하지 않습니다.');
      }

      debugPrint('✅ [DELETE] 카카오 계정 확인 완료 (재인증 스킵)');
    } catch (e) {
      debugPrint('❌ [DELETE] 카카오 계정 확인 실패: $e');
      throw Exception('카카오 계정 확인에 실패했습니다.\n카카오 계정으로 다시 로그인 후 시도해주세요.');
    }
  }

  /// 사용자 데이터 삭제 (Firestore)
  static Future<void> _deleteUserData() async {
    try {
      debugPrint('🔄 [DELETE] 사용자 데이터 삭제 시작');
      await FirestoreService.deleteAllUserIdeas();
      debugPrint('✅ [DELETE] 사용자 데이터 삭제 완료');
    } catch (e) {
      debugPrint('⚠️ [DELETE] 사용자 데이터 삭제 실패 (계속 진행): $e');
      // 데이터 삭제 실패해도 계정 삭제는 진행
    }
  }
}
