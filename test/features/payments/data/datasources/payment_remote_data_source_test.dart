import 'package:club_management_app/core/constants/api_constants.dart';
import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/core/network/api_client.dart';
import 'package:club_management_app/core/session/session_expiry_notifier.dart';
import 'package:club_management_app/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_secure_storage.dart';
import '../../../../helpers/scripted_http_adapter.dart';

class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(String message,
      {String? context, Object? cause, StackTrace? stackTrace}) {}
}

const List<dynamic> _members = [
  {
    'id': 1,
    'firstName': 'Juan',
    'lastName': 'Álvarez',
    'dni': '35120894',
    'status': 'ACTIVE',
    'familyGroupId': 7,
    'joinedAt': '2024-03-15',
  },
  {
    'id': 2,
    'firstName': 'María',
    'lastName': 'Álvarez',
    'dni': '36120894',
    'status': 'ACTIVE',
    'familyGroupId': 7,
    'joinedAt': '2024-03-15',
  },
  {
    'id': 3,
    'firstName': 'Luis',
    'lastName': 'Gómez',
    'dni': '31444555',
    'status': 'ACTIVE',
  },
];

const List<dynamic> _delinquency = [
  {'memberId': 1, 'daysOverdue': 43, 'lastPeriodCovered': '2026-08-01'},
  {'memberId': 2, 'daysOverdue': 0, 'lastPeriodCovered': '2026-10-01'},
];

const List<dynamic> _history = [
  {
    'id': 10,
    'memberId': 1,
    'paidByMemberId': 2,
    'amount': 15000.00,
    'paidAt': '2026-08-05T13:00:00Z',
    'periodCovered': '2026-08-01',
    'paymentMethod': 'CASH',
    'voidedAt': null,
    'voidReason': null,
  },
];

void main() {
  late ScriptedHttpAdapter adapter;

  PaymentRemoteDataSourceImpl buildDataSource(Responder responder) {
    final dio = Dio();
    final apiClient = ApiClient(
      dio: dio,
      refreshClient: Dio(),
      secureStorage: InMemorySecureStorage(),
      sessionExpiryNotifier: SessionExpiryNotifier(),
      logger: const SilentLogger(),
      baseUrl: 'https://api.test/api',
    );
    adapter = ScriptedHttpAdapter(responder);
    dio.httpClientAdapter = adapter;

    return PaymentRemoteDataSourceImpl(apiClient, const SilentLogger());
  }

  ResponseBody respondWithLedger(
    RequestOptions options, {
    Map<String, dynamic> club = const {'monthlyFeeAmount': 15000.00},
    int clubStatus = 200,
  }) {
    final path = options.path;
    if (path == ApiConstants.members) return jsonListResponse(200, _members);
    if (path == ApiConstants.paymentDelinquency) {
      return jsonListResponse(200, _delinquency);
    }
    if (path.startsWith('${ApiConstants.payments}/members/')) {
      return jsonListResponse(200, _history);
    }
    if (path == ApiConstants.currentClub) return jsonResponse(clubStatus, club);

    return emptyResponse(404);
  }

  group('reading the ledger of a member', () {
    test('asks for the roster, the mora, the history and the fee', () async {
      final dataSource = buildDataSource((options, _) {
        return respondWithLedger(options);
      });

      await dataSource.fetchLedger(1);

      expect(adapter.callsTo(ApiConstants.members), 1);
      expect(adapter.callsTo(ApiConstants.paymentDelinquency), 1);
      expect(adapter.callsTo(ApiConstants.memberPaymentHistory(1)), 1);
      expect(adapter.callsTo(ApiConstants.currentClub), 1);
    });

    test('includes the voided payments in the history request', () {
      expect(
        ApiConstants.memberPaymentHistory(1),
        contains('includeVoided=true'),
      );
    });

    test('joins the member, the family group and the fee', () async {
      final dataSource = buildDataSource((options, _) {
        return respondWithLedger(options);
      });

      final ledger = await dataSource.fetchLedger(1);

      expect(ledger.member.fullName, 'Juan Álvarez');
      expect(ledger.member.daysOverdue, 43);
      expect(ledger.familyMembers.map((member) => member.id), [2]);
      expect(ledger.monthlyFeeCents, 1500000);
      expect(ledger.lastPaidMonth, const BillingMonth(2026, 8));
      expect(ledger.nameOf(2), 'María Álvarez');
    });

    test('a member outside the club is reported as not found', () {
      final dataSource = buildDataSource((options, _) {
        return respondWithLedger(options);
      });

      expect(dataSource.fetchLedger(99), throwsA(isA<NotFoundException>()));
    });

    test('a club without a fee still loads, with the amount empty', () async {
      final dataSource = buildDataSource((options, _) {
        return respondWithLedger(options, club: const {});
      });

      final ledger = await dataSource.fetchLedger(1);

      expect(ledger.monthlyFeeCents, isNull);
    });

    test('a failing fee lookup does not block the ledger', () async {
      final dataSource = buildDataSource((options, _) {
        return respondWithLedger(options, clubStatus: 500);
      });

      final ledger = await dataSource.fetchLedger(1);

      expect(ledger.monthlyFeeCents, isNull);
      expect(ledger.payments, hasLength(1));
    });

    test('maps a connection failure to a network error', () {
      final dataSource = buildDataSource((options, _) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'host unreachable',
        );
      });

      expect(dataSource.fetchLedger(1), throwsA(isA<NetworkException>()));
    });
  });

  group('writes', () {
    const draft = PaymentDraft(
      memberId: 1,
      months: [BillingMonth(2026, 9), BillingMonth(2026, 10)],
      amountCents: 1500000,
      method: PaymentMethod.cash,
      paidByMemberId: 2,
    );

    test('records the payment with the amount of one month', () async {
      final dataSource = buildDataSource((_, __) => jsonListResponse(201, []));

      await dataSource.recordPayment(draft);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, ApiConstants.payments);
      expect(request.data, {
        'memberId': 1,
        'paidByMemberId': 2,
        'amount': 15000,
        'periodsCovered': ['2026-09-01', '2026-10-01'],
        'paymentMethod': 'CASH',
      });
    });

    test('a payer outside the family group comes back as a validation error',
        () {
      final dataSource = buildDataSource((_, __) => jsonResponse(400));

      expect(
        dataSource.recordPayment(draft),
        throwsA(isA<ValidationException>()),
      );
    });

    test('voids a payment sending the reason', () async {
      final dataSource = buildDataSource((_, __) => jsonResponse(200));

      await dataSource.voidPayment(10, reason: 'Socio equivocado');

      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, ApiConstants.paymentVoiding(10));
      expect(request.data, {'reason': 'Socio equivocado'});
    });

    test('a payment already voided comes back as a conflict', () {
      final dataSource = buildDataSource((_, __) => jsonResponse(409));

      expect(dataSource.voidPayment(10), throwsA(isA<ConflictException>()));
    });
  });
}
