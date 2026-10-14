import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

class PaymentSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PaymentSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      child: Text(label),
    );
  }
}
