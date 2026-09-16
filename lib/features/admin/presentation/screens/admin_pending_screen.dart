import 'package:flutter/material.dart';

import '../../../../shared/widgets/coming_soon_view.dart';
import '../widgets/admin_scaffold.dart';

class AdminPendingScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AdminPendingScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: title,
      body: ComingSoonView(icon: icon, title: title, message: message),
    );
  }
}
