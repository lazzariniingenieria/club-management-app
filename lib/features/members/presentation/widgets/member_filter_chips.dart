import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/member_collection_filter.dart';

class MemberFilterChips extends StatefulWidget {
  final MemberCollectionFilter selected;
  final Map<MemberCollectionFilter, int> counts;
  final ValueChanged<MemberCollectionFilter> onSelected;

  const MemberFilterChips({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  @override
  State<MemberFilterChips> createState() => _MemberFilterChipsState();
}

class _MemberFilterChipsState extends State<MemberFilterChips> {
  static const double _fadeWidth = 28;

  final ScrollController _controller = ScrollController();
  bool _fadesStart = false;
  bool _fadesEnd = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncFades);
    _scheduleFadeSync();
  }

  @override
  void didUpdateWidget(MemberFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleFadeSync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleFadeSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFades();
    });
  }

  void _syncFades() {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    final fadesStart = position.pixels > position.minScrollExtent;
    final fadesEnd = position.pixels < position.maxScrollExtent;
    if (fadesStart == _fadesStart && fadesEnd == _fadesEnd) return;

    setState(() {
      _fadesStart = fadesStart;
      _fadesEnd = fadesEnd;
    });
  }

  Shader _fadeShader(Rect bounds) {
    final fade = (_fadeWidth / bounds.width).clamp(0.0, 0.5);

    return LinearGradient(
      colors: [
        _fadesStart ? Colors.transparent : Colors.black,
        Colors.black,
        Colors.black,
        _fadesEnd ? Colors.transparent : Colors.black,
      ],
      stops: [0, fade, 1 - fade, 1],
    ).createShader(bounds);
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: _fadeShader,
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            for (final filter in MemberCollectionFilter.values)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _FilterChip(
                  filter: filter,
                  count: widget.counts[filter] ?? 0,
                  isSelected: filter == widget.selected,
                  onSelected: widget.onSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final MemberCollectionFilter filter;
  final int count;
  final bool isSelected;
  final ValueChanged<MemberCollectionFilter> onSelected;

  const _FilterChip({
    required this.filter,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(AppStrings.withCount(_labelFor(filter), count)),
      selected: isSelected,
      showCheckmark: false,
      side: BorderSide(
        color: isSelected ? AppColors.brandNavy : AppColors.border,
      ),
      onSelected: (_) => onSelected(filter),
    );
  }
}

String _labelFor(MemberCollectionFilter filter) {
  return switch (filter) {
    MemberCollectionFilter.all => AppStrings.adminPaymentsFilterAll,
    MemberCollectionFilter.overdue => AppStrings.adminPaymentsFilterOverdue,
    MemberCollectionFilter.toCollect => AppStrings.adminPaymentsFilterToCollect,
  };
}
