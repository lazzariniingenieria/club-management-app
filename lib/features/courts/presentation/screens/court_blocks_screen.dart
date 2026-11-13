import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/status_message_view.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_block.dart';
import '../cubit/court_blocks_cubit.dart';
import '../cubit/court_blocks_state.dart';
import '../formatting/court_block_formats.dart';

class CourtBlocksScreen extends StatelessWidget {
  final Court court;

  const CourtBlocksScreen({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CourtBlocksCubit>(
      create: (_) => sl<CourtBlocksCubit>()..load(court.id),
      child: AdminScaffold(
        title: AppStrings.courtBlocksTitle,
        floatingActionButton: _NewBlockButton(court: court),
        body: _CourtBlocksBody(court: court),
      ),
    );
  }
}

class _NewBlockButton extends StatelessWidget {
  final Court court;

  const _NewBlockButton({required this.court});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourtBlocksCubit, CourtBlocksState>(
      builder: (context, state) {
        if (state is! CourtBlocksReady) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          onPressed: () => context.push(
            AppRoutes.adminCourtBlockCreation(court.id),
            extra: court,
          ),
          icon: const Icon(Icons.block_rounded),
          label: const Text(AppStrings.courtBlocksNew),
        );
      },
    );
  }
}

class _CourtBlocksBody extends StatelessWidget {
  final Court court;

  const _CourtBlocksBody({required this.court});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Text(court.name, style: AppTextStyles.titleMedium),
        ),
        const Expanded(child: _CourtBlocksContent()),
      ],
    );
  }
}

class _CourtBlocksContent extends StatelessWidget {
  const _CourtBlocksContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourtBlocksCubit, CourtBlocksState>(
      builder: (context, state) => switch (state) {
        CourtBlocksLoading() => const _CourtBlocksSkeleton(),
        CourtBlocksFailure(:final isOffline) => StatusMessageView(
            icon: isOffline ? Icons.wifi_off_rounded : Icons.dns_outlined,
            title: AppStrings.courtBlocksErrorTitle,
            message: isOffline
                ? AppStrings.networkErrorMessage
                : AppStrings.ledgerServerErrorMessage,
            actionLabel: AppStrings.retryAction,
            onAction: context.read<CourtBlocksCubit>().reload,
          ),
        CourtBlocksReady(:final blocks) => blocks.isEmpty
            ? const _EmptyBlocks()
            : _BlockList(blocks: blocks),
      },
    );
  }
}

class _BlockList extends StatelessWidget {
  final List<CourtBlock> blocks;

  const _BlockList({required this.blocks});

  static const double _floatingActionClearance = 96;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<CourtBlocksCubit>().reload,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          _floatingActionClearance,
        ),
        itemCount: blocks.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, index) => _BlockTile(
          key: ValueKey(blocks[index].id),
          block: blocks[index],
        ),
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final CourtBlock block;

  const _BlockTile({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(child: _BlockDetails(block: block)),
            _RemoveBlockAction(block: block),
          ],
        ),
      ),
    );
  }
}

class _BlockDetails extends StatelessWidget {
  final CourtBlock block;

  const _BlockDetails({required this.block});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in CourtBlockFormats.range(block))
            Text(line, style: AppTextStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CourtBlockFormats.reason(block),
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _RemoveBlockAction extends StatefulWidget {
  final CourtBlock block;

  const _RemoveBlockAction({required this.block});

  @override
  State<_RemoveBlockAction> createState() => _RemoveBlockActionState();
}

class _RemoveBlockActionState extends State<_RemoveBlockAction> {
  bool _isRemoving = false;

  Future<bool> _confirmRemoval() {
    return ConfirmationDialog.show(
      context,
      const ConfirmationDialog(
        title: AppStrings.courtBlockRemoveTitle,
        message: AppStrings.courtBlockRemoveMessage,
        confirmLabel: AppStrings.courtBlockRemove,
      ),
    );
  }

  Future<void> _remove() async {
    final cubit = context.read<CourtBlocksCubit>();
    if (!await _confirmRemoval() || !mounted) return;

    setState(() => _isRemoving = true);
    final failure = await cubit.remove(widget.block);
    if (!mounted) return;

    if (failure != null) setState(() => _isRemoving = false);
    showAppSnackBar(
      context,
      failure?.userMessage ?? AppStrings.courtBlockRemoved,
      isError: failure != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final range = CourtBlockFormats.range(widget.block).join(', ');

    return TextButton(
      onPressed: _isRemoving ? null : _remove,
      child: _isRemoving
          ? const _RemovingIndicator()
          : Text(
              AppStrings.courtBlockRemove,
              semanticsLabel: AppStrings.courtBlockRemoveSemantics(range),
            ),
    );
  }
}

class _RemovingIndicator extends StatelessWidget {
  const _RemovingIndicator();

  static const double _size = 18;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: _size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        semanticsLabel: AppStrings.courtBlockRemoving,
      ),
    );
  }
}

class _EmptyBlocks extends StatelessWidget {
  const _EmptyBlocks();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.courtBlocksEmptyTitle,
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.courtBlocksEmptyHint,
            style: AppTextStyles.bodyLargeMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CourtBlocksSkeleton extends StatelessWidget {
  const _CourtBlocksSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++) ...[
            const SkeletonBox(height: 72),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
