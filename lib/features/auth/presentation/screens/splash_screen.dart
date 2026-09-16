import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration progressDelay = Duration(milliseconds: 300);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _progressTimer;
  bool _showProgress = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthSessionRequested());
    _progressTimer = Timer(
      SplashScreen.progressDelay,
      () => setState(() => _showProgress = true),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_tennis_rounded,
              size: AppSpacing.xxxl,
              color: AppColors.textOnDark,
            ),
            if (_showProgress) const _SlowResolutionIndicator(),
          ],
        ),
      ),
    );
  }
}

class _SlowResolutionIndicator extends StatelessWidget {
  const _SlowResolutionIndicator();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: AppSpacing.xxl),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
        ),
        SizedBox(height: AppSpacing.xl),
        _LoadingLabel(),
      ],
    );
  }
}

class _LoadingLabel extends StatelessWidget {
  const _LoadingLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.splashLoading,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.infoSurface),
    );
  }
}
