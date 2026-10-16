import 'package:club_management_app/core/errors/exceptions.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/core/logging/app_logger.dart';
import 'package:club_management_app/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:club_management_app/features/payments/data/models/member_ledger_model.dart';
import 'package:club_management_app/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:club_management_app/features/payments/domain/entities/billing_month.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_draft.dart';
import 'package:club_management_app/features/payments/domain/entities/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

class SilentLogger implements AppLogger {
  const SilentLogger();

  @override
  void info(String message, {String? context}) {}

  @override
  void warning(String message, {String? context}) {}

  @override
  void error(
    String message, {
    String? context,
    Object? cause,
    StackTrace? stackTrace,
  }) {}
}

class FailingWrites implements PaymentRemoteDataSource {
  final Exception error;

  FailingWrites(this.error);

  @override
  Future<MemberLedgerModel> fetchLedger(int memberId) =>
      throw UnimplementedError();

  @override
  Future<void> recordPayment(PaymentDraft draft) async => throw error;

  @override
  Future<void> voidPayment(int paymentId, {String? reason}) async =>
      throw error;
}

void main() {
  const draft = PaymentDraft(
    memberId: 1,
    months: [BillingMonth(2026, 9)],
    amountCents: 1500000,
    method: PaymentMethod.cash,
  );

  Future<List<void>> announcementsAfter(
    Exception error,
    Future<void> Function(PaymentRepositoryImpl repository) write,
  ) async {
    final repository = PaymentRepositoryImpl(
      remoteDataSource: FailingWrites(error),
      logger: const SilentLogger(),
    );
    final announcements = <void>[];
    repository.paymentChanges.listen(announcements.add);

    await write(repository);
    await Future<void>.delayed(Duration.zero);

    return announcements;
  }

  test('a write the server never answered is reported as a timeout', () async {
    final repository = PaymentRepositoryImpl(
      remoteDataSource: FailingWrites(ResponseTimeoutException()),
      logger: const SilentLogger(),
    );

    final result = await repository.recordPayment(draft);

    expect(result.getLeft().toNullable(), isA<ResponseTimeoutFailure>());
  });

  test('a write that may have landed still announces a change', () async {
    final payment = await announcementsAfter(
      ResponseTimeoutException(),
      (repository) => repository.recordPayment(draft),
    );
    final voiding = await announcementsAfter(
      ResponseTimeoutException(),
      (repository) => repository.voidPayment(7),
    );

    expect(payment, hasLength(1));
    expect(voiding, hasLength(1));
  });

  test('a void somebody else already applied announces a change', () async {
    final announcements = await announcementsAfter(
      ConflictException(),
      (repository) => repository.voidPayment(7),
    );

    expect(announcements, hasLength(1));
  });

  test('a payment the server rejected announces nothing', () async {
    final announcements = await announcementsAfter(
      ValidationException(),
      (repository) => repository.recordPayment(draft),
    );

    expect(announcements, isEmpty);
  });

  test('a write that never left the device announces nothing', () async {
    final announcements = await announcementsAfter(
      NetworkException(),
      (repository) => repository.recordPayment(draft),
    );

    expect(announcements, isEmpty);
  });
}
