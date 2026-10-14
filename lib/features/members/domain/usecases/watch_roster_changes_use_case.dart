import 'dart:async';

import '../../../payments/domain/repositories/payment_repository.dart';
import '../repositories/member_repository.dart';

class WatchRosterChangesUseCase {
  final MemberRepository memberRepository;
  final PaymentRepository paymentRepository;

  WatchRosterChangesUseCase(this.memberRepository, this.paymentRepository);

  Stream<void> call() {
    final subscriptions = <StreamSubscription<void>>[];
    late final StreamController<void> changes;

    changes = StreamController<void>(
      onListen: () => subscriptions.addAll([
        memberRepository.rosterChanges.listen(changes.add),
        paymentRepository.paymentChanges.listen(changes.add),
      ]),
      onCancel: () => Future.wait(
        subscriptions.map((subscription) => subscription.cancel()),
      ),
    );

    return changes.stream;
  }
}
