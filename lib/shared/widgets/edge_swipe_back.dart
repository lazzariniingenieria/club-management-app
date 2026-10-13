import 'package:flutter/material.dart';

class EdgeSwipeBack extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const EdgeSwipeBack({super.key, required this.enabled, required this.child});

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  static const double _edgeWidth = 20;
  static const double _triggerDistance = 60;

  double _draggedDistance = 0;

  bool get _isActive =>
      widget.enabled && Theme.of(context).platform == TargetPlatform.iOS;

  void _onDragEnd(DragEndDetails details) {
    if (_draggedDistance < _triggerDistance) return;

    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_isActive)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _edgeWidth + MediaQuery.paddingOf(context).left,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => _draggedDistance = 0,
              onHorizontalDragUpdate: (details) =>
                  _draggedDistance += details.primaryDelta ?? 0,
              onHorizontalDragEnd: _onDragEnd,
            ),
          ),
      ],
    );
  }
}
