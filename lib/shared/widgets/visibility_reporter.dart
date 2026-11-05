import 'package:flutter/widgets.dart';

class VisibilityReporter extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  final Widget child;

  const VisibilityReporter({
    super.key,
    required this.onChanged,
    required this.child,
  });

  @override
  State<VisibilityReporter> createState() => _VisibilityReporterState();
}

class _VisibilityReporterState extends State<VisibilityReporter> {
  bool _reported = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isVisible = TickerMode.valuesOf(context).enabled;
    if (isVisible == _reported) return;

    _reported = isVisible;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reported == isVisible) widget.onChanged(isVisible);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
