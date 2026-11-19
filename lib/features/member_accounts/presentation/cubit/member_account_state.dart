import 'package:equatable/equatable.dart';

import '../../domain/entities/member_account.dart';

sealed class MemberAccountState extends Equatable {
  const MemberAccountState();

  @override
  List<Object?> get props => [];
}

class MemberAccountLoading extends MemberAccountState {
  const MemberAccountLoading();
}

class MemberAccountDisabled extends MemberAccountState {
  const MemberAccountDisabled();
}

class MemberAccountReady extends MemberAccountState {
  final MemberAccount? account;

  const MemberAccountReady(this.account);

  @override
  List<Object?> get props => [account];
}

class MemberAccountFailure extends MemberAccountState {
  final bool isOffline;

  const MemberAccountFailure({required this.isOffline});

  @override
  List<Object?> get props => [isOffline];
}
