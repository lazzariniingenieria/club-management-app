import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/fee_receipts_document.dart';
import '../../domain/entities/payment_report_period.dart';
import '../../domain/repositories/payment_report_repository.dart';
import '../datasources/payment_report_remote_data_source.dart';

class PaymentReportRepositoryImpl implements PaymentReportRepository {
  final PaymentReportRemoteDataSource remoteDataSource;
  final AppLogger logger;

  PaymentReportRepositoryImpl({
    required this.remoteDataSource,
    required this.logger,
  });

  @override
  Future<Either<Failure, FeeReceiptsDocument?>> downloadFeeReceipts(
    PaymentReportPeriod period,
  ) async {
    try {
      return Right(await remoteDataSource.fetchFeeReceipts(period));
    } catch (error) {
      logger.error(
        'downloadFeeReceipts failed',
        context: 'PaymentReportRepository',
        cause: error,
      );

      return Left(failureFromException(error));
    }
  }
}
