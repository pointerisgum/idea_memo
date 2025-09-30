import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ideamemo/firebase_options.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'core/router/app_router.dart';
import 'core/utils/font_size_manager.dart';
import 'presentation/views/alarm_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 카카오 SDK 초기화
  KakaoSdk.init(
    nativeAppKey: 'fb065d8daf5c087c4e6c0fbdc70f3e0b',
  );

  // Timezone 초기화
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  // 글씨 크기 설정 초기화
  await FontSizeManager.loadFontSize();

  runApp(const ProviderScope(child: MyApp()));
}

// // 오버레이 진입점 - 별도 isolate에서 실행됨
// @pragma("vm:entry-point")
// void overlayMain() {
//   runApp(const MaterialApp(
//     home: OverlayView(),
//     debugShowCheckedModeBanner: false,
//   ));
// }

// 알람 진입점 - AlarmActivity에서 사용
@pragma("vm:entry-point")
void alarmMain() {
  runApp(const MaterialApp(
    home: AlarmView(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: '아이디어 메모',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
