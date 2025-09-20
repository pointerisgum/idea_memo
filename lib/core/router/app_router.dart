import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../presentation/views/main_view.dart';
import '../../presentation/views/add_idea_view.dart';
import '../../presentation/views/alarm_view.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
