import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/fee_receipts_document.dart';
import '../entities/payment_report_period.dart';
import '../repositories/payment_report_repository.dart';

class DownloadFeeReceiptsUseCase {
  final PaymentReportRepository repository;

  DownloadFeeReceiptsUseCase(this.repository);

  Future<Either<Failure, FeeReceiptsDocument?>> call(
    PaymentReportPeriod period,
  ) {
    if (!period.isValid) {
      return Future.value(const Left(ValidationFailure('Invalid period')));
    }

    return repository.downloadFeeReceipts(period);
  }
}
