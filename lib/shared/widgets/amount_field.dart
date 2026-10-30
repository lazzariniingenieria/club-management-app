import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../formatters/peso_amount.dart';

class AmountField extends StatefulWidget {
  final int? initialCents;
  final ValueChanged<String> onChanged;
  final String label;
  final bool enabled;

  const AmountField({
    super.key,
    required this.initialCents,
    required this.onChanged,
    required this.label,
    this.enabled = true,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
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
      enabled: widget.enabled,
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
