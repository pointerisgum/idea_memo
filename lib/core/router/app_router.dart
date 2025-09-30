import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:ideamemo/presentation/views/login_view.dart';
import 'package:ideamemo/presentation/views/main_view.dart';
import 'package:ideamemo/presentation/views/add_idea_view.dart';
import 'package:ideamemo/presentation/views/alarm_view.dart';
import 'package:ideamemo/presentation/views/settings_view.dart';
import 'package:ideamemo/presentation/views/font_size_settings_view.dart';
import 'package:ideamemo/presentation/views/idea_detail_view.dart';
import 'package:ideamemo/presentation/views/idea_edit_view.dart';
import 'package:ideamemo/presentation/viewmodels/auth_viewmodel.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // Firebase Auth 상태 변화를 감지하여 라우터 리프레시
  ref.listen(authViewModelProvider, (previous, next) {
    // 인증 상태가 변경되면 라우터를 무효화하여 redirect 로직 재실행
    ref.invalidateSelf();
  });

  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final currentUser = authState.user;

      debugPrint('🔄 [ROUTER] 현재 경로: ${state.uri.toString()}, 로그인 상태: $isLoggedIn, 사용자: $currentUser');

      // 로그인되지 않은 상태에서 메인 화면 접근 시 로그인 화면으로 리다이렉트
      if (!isLoggedIn && state.uri.toString() != '/login') {
        debugPrint('🔄 [ROUTER] 로그인 화면으로 리다이렉트');
        return '/login';
      }

      // 로그인된 상태에서 로그인 화면 접근 시 메인 화면으로 리다이렉트
      if (isLoggedIn && state.uri.toString() == '/login') {
        debugPrint('🔄 [ROUTER] 메인 화면으로 리다이렉트');
        return '/';
      }

      debugPrint('🔄 [ROUTER] 리다이렉트 없음');
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainView(),
      ),
      GoRoute(
        path: '/add-idea',
        name: 'add-idea',
        builder: (context, state) => const AddIdeaView(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: '/font-size-settings',
        name: 'font-size-settings',
        builder: (context, state) => const FontSizeSettingsView(),
      ),
      GoRoute(
        path: '/idea-detail/:ideaId',
        name: 'idea-detail',
        builder: (context, state) {
          final ideaId = state.pathParameters['ideaId']!;
          return IdeaDetailView(ideaId: ideaId);
        },
      ),
      GoRoute(
        path: '/idea-edit/:ideaId',
        name: 'idea-edit',
        builder: (context, state) {
          final ideaId = state.pathParameters['ideaId']!;
          return IdeaEditView(ideaId: ideaId);
        },
      ),
      GoRoute(
        path: '/alarm',
        name: 'alarm',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'TODO 알람';
          final message = state.uri.queryParameters['message'] ?? '알람이 울렸습니다!';
          return AlarmView(
            title: title,
            message: message,
            onDismiss: () {
              // 알람 해제 시 메인화면으로 돌아가기
              context.go('/');
            },
            onSnooze: () {
              // 스누즈 시 메인화면으로 돌아가기 (5분 후 다시 알람 설정)
              context.go('/');
            },
          );
        },
      ),
    ],
  );
}
