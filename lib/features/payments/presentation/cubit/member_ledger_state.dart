import 'package:equatable/equatable.dart';

import '../../domain/entities/member_ledger.dart';

sealed class MemberLedgerState extends Equatable {
  const MemberLedgerState();

  @override
  List<Object?> get props => [];
}

class MemberLedgerLoading extends MemberLedgerState {
  const MemberLedgerLoading();
}

class MemberLedgerReady extends MemberLedgerState {
  final MemberLedger ledger;

  const MemberLedgerReady(this.ledger);

  @override
  List<Object?> get props => [ledger];
}

class MemberLedgerFailure extends MemberLedgerState {
  final bool isOffline;

  const MemberLedgerFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}

class MemberLedgerMissing extends MemberLedgerState {
  const MemberLedgerMissing();
}
