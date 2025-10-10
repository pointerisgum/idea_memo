import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

  // Crashlytics 초기화 (릴리즈 모드에서만 활성화)
  if (!kDebugMode) {
    // Flutter 프레임워크 에러를 Crashlytics에 전달
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Dart 에러를 Crashlytics에 전달 (비동기 에러)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

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
