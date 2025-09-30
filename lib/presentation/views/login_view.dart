import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:ideamemo/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ideamemo/core/utils/snackbar_utils.dart';
import 'package:ideamemo/presentation/viewmodels/font_size_viewmodel.dart';
import 'package:ideamemo/core/constants/app_colors.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> with TickerProviderStateMixin {
  late AnimationController _lottieController;
  bool _showSubtitle = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);

    // 제목 타이핑 완료 후 부제목 표시 (아이디어 메모: 6글자 * 150ms + 여유시간)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSubtitle = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    ref.watch(fontSizeNotifierProvider);
    final authNotifier = ref.read(authViewModelProvider.notifier);

    _listenToAuthChanges(ref, context);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLogo(),
                _buildTitle(),
                _buildSubtitle(),
                const Spacer(),
                _buildLoginButtons(authNotifier),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (authState.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  void _listenToAuthChanges(WidgetRef ref, BuildContext context) {
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.isLoggedIn && !next.isLoading) {
        context.go('/');
      }
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        SnackbarUtils.showError(context, next.errorMessage!);
      }
    });
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.03),
            AppColors.primaryLight.withOpacity(0.9),
            AppColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return GestureDetector(
      onTap: () {
        _lottieController.reset();
        _lottieController.forward();
      },
      child: Container(
        height: 400,
        color: Colors.transparent,
        child: Lottie.asset(
          'assets/Idea_bulb.json',
          controller: _lottieController,
          fit: BoxFit.contain,
          repeat: false,
          animate: false, // controller로 제어하므로 false
          frameRate: FrameRate.max,
          onLoaded: (composition) {
            _lottieController.duration = composition.duration * 1.5;
            _lottieController.forward(); // 초기 1회 재생
          },
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.8),
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: AnimatedTextKit(
          animatedTexts: [
            TyperAnimatedText(
              '아이디어 메모',
              textStyle: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                  Shadow(
                    color: AppColors.primary.withOpacity(0.5),
                    offset: const Offset(0, 0),
                    blurRadius: 8,
                  ),
                ],
              ),
              speed: const Duration(milliseconds: 120),
            ),
          ],
          totalRepeatCount: 1,
          pause: const Duration(milliseconds: 50),
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
          isRepeatingAnimation: false,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    if (!_showSubtitle) {
      return const SizedBox(height: 28); // 부제목 공간 확보
    }

    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.8),
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              '생각을 기록하고 관리하세요',
              textStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                  Shadow(
                    color: AppColors.primary.withOpacity(0.5),
                    offset: const Offset(0, 0),
                    blurRadius: 8,
                  ),
                ],
              ),
              speed: const Duration(milliseconds: 80),
              cursor: '_',
            ),
          ],
          totalRepeatCount: 1,
          pause: const Duration(milliseconds: 100),
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
          isRepeatingAnimation: false,
        ),
      ),
    );
  }

  Widget _buildLoginButtons(dynamic authNotifier) {
    return Column(
      children: [
        _buildSignInButton(
          SignInButton(
            Buttons.Google,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onPressed: () => authNotifier.signInWithGoogle(),
          ),
        ),
        const SizedBox(height: 15),
        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
          _buildSignInButton(
            SignInButton(
              Buttons.Apple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onPressed: () => authNotifier.signInWithApple(),
            ),
          ),
          const SizedBox(height: 15),
        ],
        _buildSignInButton(
          SignInButtonBuilder(
            text: 'Sign in with Kakao',
            textColor: const Color(0xFF000000).withOpacity(0.85),
            image: Image.asset('assets/icons/ic_kakao.png', width: 18, height: 18),
            backgroundColor: const Color(0xFFFEE500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onPressed: () => authNotifier.signInWithKakao(),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton(Widget button) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: button,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
          strokeWidth: 3,
        ),
      ),
    );
  }
}
