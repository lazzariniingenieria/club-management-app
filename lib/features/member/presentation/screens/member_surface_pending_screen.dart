import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/coming_soon_view.dart';
import '../../../../shared/widgets/logout_button.dart';

class MemberSurfacePendingScreen extends StatelessWidget {
  const MemberSurfacePendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ComingSoonView(
          icon: Icons.sports_tennis_rounded,
          title: AppStrings.memberSurfacePendingTitle,
          message: AppStrings.memberSurfacePendingMessage,
          action: LogoutButton(),
        ),
      ),
    );
  }
}
