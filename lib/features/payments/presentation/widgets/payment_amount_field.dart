import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../formatting/peso_amount.dart';

class PaymentAmountField extends StatefulWidget {
  final int? initialCents;
  final ValueChanged<String> onChanged;
  final String label;

  const PaymentAmountField({
    super.key,
    required this.initialCents,
    required this.onChanged,
    this.label = AppStrings.registerPaymentAmountLabel,
  });

  @override
  State<PaymentAmountField> createState() => _PaymentAmountFieldState();
}

class _PaymentAmountFieldState extends State<PaymentAmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: PesoAmount.textFor(widget.initialCents),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: const [PesoAmountFormatter()],
      style: AppTextStyles.titleMedium,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: r'$ ',
        prefixStyle: AppTextStyles.titleMedium,
        hintText: '0',
      ),
    );
  }
}
