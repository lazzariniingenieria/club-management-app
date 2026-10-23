import 'dart:math';

import '../../../../core/errors/exceptions.dart';
import '../../../members/data/datasources/member_remote_data_source.dart';
import '../../../members/domain/entities/member.dart';
import '../../domain/entities/billing_month.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_draft.dart';
import '../../domain/entities/payment_method.dart';
import '../models/member_ledger_model.dart';
import '../models/payment_model.dart';
import '../models/payment_precheck_model.dart';
import 'payment_remote_data_source.dart';

typedef DelinquencyListener = void Function(int memberId, int daysOverdue);

class PaymentFakeDataSource implements PaymentRemoteDataSource {
  PaymentFakeDataSource({
    required MemberRemoteDataSource members,
    this.onDelinquencyChanged,
    this.latency = const Duration(milliseconds: 600),
    DateTime Function() clock = DateTime.now,
  })  : _members = members,
        _clock = clock;

  final MemberRemoteDataSource _members;
  final DelinquencyListener? onDelinquencyChanged;
  final Duration latency;
  final DateTime Function() _clock;

  static const int defaultMonthlyFeeCents = 1500000;
  static const int _seededMonths = 6;
  static const int _monthsSinceInactiveLastPaid = 4;

  final List<Payment> _payments = [];
  bool _isSeeded = false;
  int _lastId = 0;

  @override
  Future<MemberLedgerModel> fetchLedger(int memberId) async {
    final roster = await _seededRoster();

    return MemberLedgerModel.fromRoster(
      memberId: memberId,
      roster: roster,
      payments: _paymentsOf(memberId),
    );
  }

  @override
  Future<PaymentPrecheckModel> fetchPrecheck(int memberId) async {
    final roster = await _seededRoster();

    return PaymentPrecheckModel(
      isActive: _memberIn(roster, memberId).isActive,
      paidMonths: _paidMonthsOf(memberId),
    );
  }

  @override
  Future<void> recordPayment(PaymentDraft draft) async {
    final roster = await _seededRoster();
    final member = _memberIn(roster, draft.memberId);
    _rejectInvalid(draft, member, roster);

    for (final month in draft.months) {
      _payments.add(_paymentFor(draft, month));
    }
    _announceDelinquency(member);
  }

  @override
  Future<void> voidPayment(int paymentId, {String? reason}) async {
    final roster = await _seededRoster();
    final index = _payments.indexWhere((payment) => payment.id == paymentId);
    if (index < 0) throw NotFoundException('Unknown payment $paymentId');

    final payment = _payments[index];
    if (payment.isVoided) throw ConflictException('Payment already voided');

    _payments[index] = _voided(payment, reason);
    _announceDelinquency(_memberIn(roster, payment.memberId));
  }

  Future<List<Member>> _seededRoster() async {
    await Future<void>.delayed(latency);
    final roster = await _members.fetchMembers();
    if (!_isSeeded) _seed(roster);
    _isSeeded = true;

    return roster;
  }

  List<Payment> _paymentsOf(int memberId) =>
      _payments.where((payment) => payment.memberId == memberId).toList();

  Set<BillingMonth> _paidMonthsOf(int memberId) => {
        for (final payment in _paymentsOf(memberId))
          if (!payment.isVoided) payment.month,
      };

  Member _memberIn(List<Member> roster, int memberId) {
    for (final member in roster) {
      if (member.id == memberId) return member;
    }

    throw NotFoundException('Member $memberId is not in the club');
  }

  void _rejectInvalid(PaymentDraft draft, Member member, List<Member> roster) {
    if (draft.months.toSet().length != draft.months.length) {
      throw ValidationException('periodsCovered has duplicates');
    }
    if (draft.months.any(_paidMonthsOf(member.id).contains)) {
      throw ConflictException('A period is already paid');
    }

    final payerId = draft.paidByMemberId;
    if (payerId == null || payerId == member.id) return;

    if (!member.sharesFamilyGroupWith(_memberIn(roster, payerId))) {
      throw ValidationException('paidByMemberId is outside the family group');
    }
  }

  Payment _paymentFor(PaymentDraft draft, BillingMonth month) {
    final payerId = draft.paidByMemberId;

    return PaymentModel(
      id: ++_lastId,
      memberId: draft.memberId,
      paidByMemberId: payerId == draft.memberId ? null : payerId,
      amountCents: draft.amountCents,
      month: month,
      method: draft.method,
      paidAt: _clock().toUtc(),
    );
  }

  Payment _voided(Payment payment, String? reason) {
    return PaymentModel(
      id: payment.id,
      memberId: payment.memberId,
      paidByMemberId: payment.paidByMemberId,
      amountCents: payment.amountCents,
      month: payment.month,
      method: payment.method,
      paidAt: payment.paidAt,
      voidedAt: _clock().toUtc(),
      voidReason: reason,
    );
  }

  void _announceDelinquency(Member member) {
    onDelinquencyChanged?.call(member.id, _daysOverdueOf(member));
  }

  int _daysOverdueOf(Member member) {
    final paidMonths = BillingMonth.sorted(
      _paymentsOf(member.id)
          .where((payment) => !payment.isVoided)
          .map((payment) => payment.month),
    );
    final coverageStart = paidMonths.isEmpty
        ? BillingMonth.of(member.joinedAt ?? _clock())
        : paidMonths.last.next;

    return max(0, _today().difference(coverageStart.firstDay).inDays);
  }

  DateTime _today() {
    final now = _clock();

    return DateTime(now.year, now.month, now.day);
  }

  void _seed(List<Member> roster) {
    for (final member in roster) {
      final lastPaid = _seededLastPaidMonth(member);
      var month = lastPaid;

      for (var count = 0; count < _seededMonths; count++) {
        _payments.add(_seededPayment(member, month, roster));
        month = month.previous;
      }
    }
  }

  BillingMonth _seededLastPaidMonth(Member member) {
    final currentMonth = BillingMonth.of(_clock());
    if (!member.isActive) {
      return _monthsBefore(currentMonth, _monthsSinceInactiveLastPaid);
    }
    if (!member.isOverdue) return currentMonth;

    final coverageStart = _today().subtract(
      Duration(days: member.daysOverdue),
    );

    return BillingMonth.of(coverageStart).previous;
  }

  static BillingMonth _monthsBefore(BillingMonth month, int count) {
    var result = month;
    for (var step = 0; step < count; step++) {
      result = result.previous;
    }

    return result;
  }

  Payment _seededPayment(
    Member member,
    BillingMonth month,
    List<Member> roster,
  ) {
    final relative = _relativeOf(member, roster);

    return PaymentModel(
      id: ++_lastId,
      memberId: member.id,
      paidByMemberId: month.month.isEven ? relative?.id : null,
      amountCents: defaultMonthlyFeeCents,
      month: month,
      method: PaymentMethod.values[month.month % PaymentMethod.values.length],
      paidAt: month.firstDay.add(const Duration(days: 4)).toUtc(),
    );
  }

  static Member? _relativeOf(Member member, List<Member> roster) {
    for (final other in roster) {
      if (member.sharesFamilyGroupWith(other)) return other;
    }

    return null;
  }
}
