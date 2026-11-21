import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/member_draft.dart';
import '../../domain/usecases/create_member_use_case.dart';
import '../../domain/usecases/set_member_active_use_case.dart';
import '../../domain/usecases/update_member_use_case.dart';
import 'member_form_state.dart';

class MemberFormCubit extends Cubit<MemberFormState> {
  final CreateMemberUseCase _createMember;
  final UpdateMemberUseCase _updateMember;
  final SetMemberActiveUseCase _setMemberActive;

  MemberFormCubit({
    required CreateMemberUseCase createMember,
    required UpdateMemberUseCase updateMember,
    required SetMemberActiveUseCase setMemberActive,
  })  : _createMember = createMember,
        _updateMember = updateMember,
        _setMemberActive = setMemberActive,
        super(const MemberFormEditing());

  Future<void> save(
    MemberDraft draft, {
    int? memberId,
    MemberDraft? original,
  }) async {
    if (state is MemberFormSubmitting) return;
    emit(const MemberFormSubmitting());

    final trimmed = draft.trimmed();
    final result = memberId == null
        ? await _createMember(trimmed)
        : await _updateMember(memberId, trimmed);

    _emitOutcome(
      result,
      memberId == null ? MemberFormOutcome.created : MemberFormOutcome.updated,
      conflict: _conflictOf(trimmed, original?.trimmed()),
    );
  }

  static MemberFormState _conflictOf(MemberDraft sent, MemberDraft? original) {
    if (sent.dni.isEmpty || sent.dni == original?.dni) {
      return const MemberFormDuplicatedName();
    }
    if (original != null && _haveSameFullName(sent, original)) {
      return const MemberFormDuplicatedDni();
    }

    return const MemberFormDuplicatedDniOrName();
  }

  static bool _haveSameFullName(MemberDraft sent, MemberDraft original) {
    final sameFirstName =
        sent.firstName.toLowerCase() == original.firstName.toLowerCase();
    final sameLastName =
        sent.lastName.toLowerCase() == original.lastName.toLowerCase();

    return sameFirstName && sameLastName;
  }

  Future<void> setActive(int memberId, {required bool isActive}) async {
    if (state is MemberFormSubmitting) return;
    emit(const MemberFormSubmitting());

    final result = await _setMemberActive(memberId, isActive: isActive);

    _emitOutcome(
      result,
      isActive
          ? MemberFormOutcome.reactivated
          : MemberFormOutcome.deactivated,
    );
  }

  void _emitOutcome(
    Either<Failure, void> result,
    MemberFormOutcome outcome, {
    MemberFormState? conflict,
  }) {
    if (isClosed) return;

    final MemberFormState next = result.fold(
      (failure) => _failureFrom(failure, conflict),
      (_) => MemberFormSaved(outcome),
    );

    emit(next);
  }

  MemberFormState _failureFrom(Failure failure, MemberFormState? conflict) {
    if (failure is ConflictFailure && conflict != null) return conflict;

    return MemberFormFailure(failure.userMessage);
  }
}
