import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/billing_month.dart';
import '../cubit/payment_form.dart';
import 'month_grid.dart';

class BillingMonthGrid extends StatelessWidget {
  final PaymentForm form;
  final ValueChanged<BillingMonth> onToggle;
  final ValueChanged<int> onShowYear;

  const BillingMonthGrid({
    super.key,
    required this.form,
    required this.onToggle,
    required this.onShowYear,
  });

  MonthCellLook _lookOf(BillingMonth month) {
    if (form.isPaid(month)) {
      return const MonthCellLook.unavailable(
        caption: AppStrings.registerPaymentMonthPaid,
      );
    }
    if (form.isSelected(month)) {
      return const MonthCellLook.selected(AppStrings.registerPaymentMonthChosen);
    }

    return const MonthCellLook.available();
  }

  @override
  Widget build(BuildContext context) {
    final year = form.visibleYear;

    return MonthGrid(
      view: MonthGridYear(year: year, canGoBack: year > form.earliestYear),
      lookOf: _lookOf,
      onTap: onToggle,
      onShowYear: onShowYear,
    );
  }
}
