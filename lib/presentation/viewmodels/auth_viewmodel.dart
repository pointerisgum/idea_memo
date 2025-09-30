import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/auth_service.dart';

part 'auth_viewmodel.g.dart';
part 'auth_viewmodel.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoggedIn,
    User? user,
    String? errorMessage,
  }) = _AuthState;
}

@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  AuthState build() {
    // 초기 상태 설정 - 현재 사용자 확인
    final currentUser = AuthService.currentUser;
    final initialState = AuthState(
      isLoading: false,
      isLoggedIn: currentUser != null,
      user: currentUser,
    );

    // Firebase Auth 상태 변화 감지
    AuthService.authStateChanges.listen((user) {
      state = state.copyWith(
        isLoggedIn: user != null,
        user: user,
        isLoading: false,
      );
    });

    return initialState;
  }

  // Google 로그인
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userCredential = await AuthService.signInWithGoogle();
      if (userCredential != null) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          user: userCredential.user,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          // errorMessage: 'Google 로그인이 취소되었습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google 로그인 중 오류가 발생했습니다: $e',
      );
    }
  }

  // Apple 로그인
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userCredential = await AuthService.signInWithApple();
      if (userCredential != null) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          user: userCredential.user,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          // errorMessage: 'Apple 로그인이 취소되었습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Apple 로그인 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 카카오 로그인
  Future<void> signInWithKakao() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userCredential = await AuthService.signInWithKakao();
      if (userCredential != null) {
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          user: userCredential.user,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          // errorMessage: '카카오 로그인이 취소되었습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '카카오 로그인 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    debugPrint('🔄 [AuthViewModel] 로그아웃 시작');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await AuthService.signOut();

      // 로그아웃 후 상태 확인
      final currentUser = AuthService.currentUser;
      debugPrint('🔄 [AuthViewModel] 로그아웃 후 현재 사용자: $currentUser');

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        user: null,
      );

      debugPrint('✅ [AuthViewModel] 로그아웃 완료 - isLoggedIn: ${state.isLoggedIn}');
    } catch (e) {
      debugPrint('❌ [AuthViewModel] 로그아웃 실패: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '로그아웃 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await AuthService.deleteAccount();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '계정 삭제 중 오류가 발생했습니다: $e',
      );
    }
  }

  // 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
