import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_contract_guard.dart';
import '../../../../core/network/api_list_reader.dart';
import '../../../../core/network/api_object_reader.dart';
import '../../../../core/network/api_writer.dart';
import '../../domain/entities/payment_draft.dart';
import '../models/member_ledger_model.dart';
import '../models/payment_model.dart';
import '../models/payment_precheck_model.dart';

abstract class PaymentRemoteDataSource {
  Future<MemberLedgerModel> fetchLedger(int memberId);

  Future<PaymentPrecheckModel> fetchPrecheck(int memberId);

  Future<void> recordPayment(PaymentDraft draft);

  Future<void> voidPayment(int paymentId, {String? reason});
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl(ApiClient apiClient, this._logger)
      : _listReader = ApiListReader(
          apiClient: apiClient,
          logger: _logger,
          logContext: _logContext,
        ),
        _objectReader = ApiObjectReader(
          apiClient: apiClient,
          logger: _logger,
          logContext: _logContext,
        ),
        _writer = ApiWriter(
          apiClient: apiClient,
          logger: _logger,
          logContext: _logContext,
        );

  final AppLogger _logger;
  final ApiListReader _listReader;
  final ApiObjectReader _objectReader;
  final ApiWriter _writer;

  static const String _logContext = 'PaymentRemoteDataSource';
  static const String _monthlyFeeKey = 'monthlyFeeAmount';

  @override
  Future<MemberLedgerModel> fetchLedger(int memberId) async {
    final monthlyFee = _readMonthlyFeeCents();
    final responses = await _listReader.readLists(
      paths: [
        ApiConstants.members,
        ApiConstants.paymentDelinquency,
        ApiConstants.memberPaymentHistory(memberId),
      ],
      build: (responses) => responses,
    );

    return _parsed(
      () async => MemberLedgerModel.fromResponses(
        memberId: memberId,
        members: responses[0],
        delinquency: responses[1],
        payments: responses[2],
        monthlyFeeCents: await monthlyFee,
      ),
    );
  }

  @override
  Future<PaymentPrecheckModel> fetchPrecheck(int memberId) async {
    final responses = await Future.wait<Object>([
      _objectReader.readObject(
        path: ApiConstants.member(memberId),
        build: (member) => member,
      ),
      _listReader.readLists(
        paths: [ApiConstants.memberPaymentHistory(memberId)],
        build: (responses) => responses.single,
      ),
    ]);

    return _parsed(
      () async => PaymentPrecheckModel.fromResponses(
        member: responses[0] as Map<String, dynamic>,
        payments: responses[1] as List<dynamic>,
      ),
    );
  }

  @override
  Future<void> recordPayment(PaymentDraft draft) {
    return _writer.post(
      ApiConstants.payments,
      PaymentModel.bodyFromDraft(draft),
    );
  }

  @override
  Future<void> voidPayment(int paymentId, {String? reason}) {
    return _writer.patch(
      ApiConstants.paymentVoiding(paymentId),
      body: reason == null ? null : {PaymentModel.reasonKey: reason},
    );
  }

  Future<int?> _readMonthlyFeeCents() async {
    try {
      return await _objectReader.readObject(
        path: ApiConstants.currentClub,
        build: (club) {
          final amount = club[_monthlyFeeKey] as num?;

          return amount == null ? null : PaymentModel.centsFrom(amount);
        },
      );
    } catch (error) {
      _logger.warning(
        'Monthly fee unavailable, the amount starts empty: $error',
        context: _logContext,
      );

      return null;
    }
  }

  Future<T> _parsed<T>(Future<T> Function() build) =>
      guardContract(build, logger: _logger, logContext: _logContext);
}
