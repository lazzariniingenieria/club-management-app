import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../domain/entities/court.dart';
import '../cubit/court_form_cubit.dart';

class CourtStatusAction extends StatelessWidget {
  final Court court;
  final bool enabled;
  final ValueGetter<bool> hasUnsavedChanges;

  const CourtStatusAction({
    super.key,
    required this.court,
    required this.enabled,
    required this.hasUnsavedChanges,
  });

  Future<void> _toggleActive(BuildContext context) async {
    final cubit = context.read<CourtFormCubit>();
    final deactivating = court.isActive;
    final upcoming =
        deactivating ? await cubit.upcomingReservations(court.id) : 0;
    if (!context.mounted) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      ConfirmationDialog(
        title: deactivating
            ? AppStrings.courtDeactivateTitle(court.name)
            : AppStrings.courtReactivateTitle(court.name),
        message: _message(deactivating, upcoming),
        confirmLabel: deactivating
            ? AppStrings.courtDeactivate
            : AppStrings.courtReactivateShort,
        isDestructive: deactivating,
      ),
    );
    if (confirmed) await cubit.setActive(court.id, isActive: !deactivating);
  }

  String _message(bool deactivating, int? upcomingReservations) {
    return [
      if (deactivating)
        AppStrings.courtDeactivateMessage
      else
        AppStrings.courtReactivateMessage,
      if (deactivating && upcomingReservations != 0)
        AppStrings.courtDeactivateCancels(upcomingReservations),
      if (hasUnsavedChanges()) AppStrings.adminUnsavedChangesLost,
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? () => _toggleActive(context) : null,
      icon: Icon(
        court.isActive ? Icons.block_rounded : Icons.restart_alt_rounded,
      ),
      label: Text(
        court.isActive
            ? AppStrings.courtDeactivate
            : AppStrings.courtReactivate,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor:
            court.isActive ? AppColors.dangerText : AppColors.successText,
      ),
    );
  }
}
