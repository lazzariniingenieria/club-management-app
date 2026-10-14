import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/digit_layout_formatter.dart';

class PaymentAmountField extends StatefulWidget {
  final int? initialCents;
  final int maxDigits;
  final ValueChanged<String> onChanged;

  const PaymentAmountField({
    super.key,
    required this.initialCents,
    required this.maxDigits,
    required this.onChanged,
  });

  @override
  State<PaymentAmountField> createState() => _PaymentAmountFieldState();
}

class _PaymentAmountFieldState extends State<PaymentAmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: _textFor(widget.initialCents),
  );

  static String _textFor(int? cents) {
    if (cents == null) return '';

    return DigitLayouts.groupedByThousands('${cents ~/ 100}');
  }

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
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        DigitLayoutFormatter(
          layout: DigitLayouts.groupedByThousands,
          maxDigits: widget.maxDigits,
        ),
      ],
      style: AppTextStyles.titleMedium,
      decoration: InputDecoration(
        labelText: AppStrings.registerPaymentAmountLabel,
        prefixText: r'$ ',
        prefixStyle: AppTextStyles.titleMedium,
        hintText: '0',
      ),
    );
  }
}
