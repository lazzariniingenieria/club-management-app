import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/fee_receipts_document.dart';
import '../entities/payment_report_period.dart';

abstract class PaymentReportRepository {
  Future<Either<Failure, FeeReceiptsDocument?>> downloadFeeReceipts(
    PaymentReportPeriod period,
  );
}
