import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/biometric_setup_screen.dart';
import 'features/auth/presentation/lock_screen.dart';
import 'features/auth/presentation/pin_setup_screen.dart';
import 'features/auth/presentation/profile_setup_screen.dart';

class CortexApp extends ConsumerWidget {
  const CortexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authStatus = ref.watch(authNotifierProvider);

    return MaterialApp.router(
      title: 'CORTEX',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return switch (authStatus) {
          AuthStatus.unknown        => const _SplashView(),
          AuthStatus.profileNotSet  => const ProfileSetupScreen(),
          AuthStatus.pinNotSet      => const PinSetupScreen(),
          AuthStatus.biometricSetup => const BiometricSetupScreen(),
          AuthStatus.locked         => const LockScreen(),
          AuthStatus.unlocked       => child ?? const SizedBox.shrink(),
        };
      },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CortexLogo(),
            SizedBox(height: 28),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared CORTEX logo widget used on splash, lock and setup screens.
class CortexLogo extends StatelessWidget {
  final double size;
  const CortexLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.hub_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
