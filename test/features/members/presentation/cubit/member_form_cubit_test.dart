import 'package:club_management_app/core/constants/app_strings.dart';
import 'package:club_management_app/core/errors/failures.dart';
import 'package:club_management_app/features/members/domain/entities/member_draft.dart';
import 'package:club_management_app/features/members/domain/usecases/create_member_use_case.dart';
import 'package:club_management_app/features/members/domain/usecases/set_member_active_use_case.dart';
import 'package:club_management_app/features/members/domain/usecases/update_member_use_case.dart';
import 'package:club_management_app/features/members/presentation/cubit/member_form_cubit.dart';
import 'package:club_management_app/features/members/presentation/cubit/member_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateMemberUseCase extends Mock implements CreateMemberUseCase {}

class MockUpdateMemberUseCase extends Mock implements UpdateMemberUseCase {}

class MockSetMemberActiveUseCase extends Mock
    implements SetMemberActiveUseCase {}

void main() {
  late MockCreateMemberUseCase createMember;
  late MockUpdateMemberUseCase updateMember;
  late MockSetMemberActiveUseCase setMemberActive;
  late MemberFormCubit cubit;

  const draft = MemberDraft(
    firstName: '  Ana ',
    lastName: ' Álvarez',
    dni: ' 30111222 ',
    email: ' ana@club.com ',
  );

  const trimmedDraft = MemberDraft(
    firstName: 'Ana',
    lastName: 'Álvarez',
    dni: '30111222',
    email: 'ana@club.com',
  );

  setUpAll(() => registerFallbackValue(trimmedDraft));

  setUp(() {
    createMember = MockCreateMemberUseCase();
    updateMember = MockUpdateMemberUseCase();
    setMemberActive = MockSetMemberActiveUseCase();
    cubit = MemberFormCubit(
      createMember: createMember,
      updateMember: updateMember,
      setMemberActive: setMemberActive,
    );
  });

  tearDown(() => cubit.close());

  void stubCreate(Either<Failure, void> result) {
    when(() => createMember(any())).thenAnswer((_) async => result);
  }

  void stubUpdate(Either<Failure, void> result) {
    when(() => updateMember(any(), any())).thenAnswer((_) async => result);
  }

  void stubSetActive(Either<Failure, void> result) {
    when(() => setMemberActive(any(), isActive: any(named: 'isActive')))
        .thenAnswer((_) async => result);
  }

  test('starts on the form, with nothing in flight', () {
    expect(cubit.state, const MemberFormEditing());
  });

  test('creates the member with the draft already trimmed', () async {
    stubCreate(const Right(null));

    await cubit.save(draft);

    verify(() => createMember(trimmedDraft)).called(1);
    expect(cubit.state, const MemberFormSaved(MemberFormOutcome.created));
  });

  test('edits the member it was opened on, never creating a second one',
      () async {
    stubUpdate(const Right(null));

    await cubit.save(draft, memberId: 7);

    verify(() => updateMember(7, trimmedDraft)).called(1);
    verifyNever(() => createMember(any()));
    expect(cubit.state, const MemberFormSaved(MemberFormOutcome.updated));
  });

  test('passes through submitting so the button can show its spinner',
      () async {
    stubCreate(const Right(null));

    final states = <MemberFormState>[];
    cubit.stream.listen(states.add);

    await cubit.save(draft);
    await Future<void>.delayed(Duration.zero);

    expect(states.first, const MemberFormSubmitting());
  });

  test('ignores a second submit while the first one is still in flight',
      () async {
    stubCreate(const Right(null));

    await Future.wait([cubit.save(draft), cubit.save(draft)]);

    verify(() => createMember(any())).called(1);
  });

  test('turns a taken dni into the field error, not into a snack bar',
      () async {
    stubCreate(const Left(ConflictFailure('Duplicated dni')));

    await cubit.save(draft);

    expect(cubit.state, const MemberFormDuplicatedDni());
  });

  test('turns any other failure into its Spanish message', () async {
    stubCreate(const Left(NetworkFailure('Unreachable')));

    await cubit.save(draft);

    expect(
      cubit.state,
      const MemberFormFailure(AppStrings.loginNetworkError),
    );
  });

  group('the logical delete', () {
    test('reports the deactivation it just ran', () async {
      stubSetActive(const Right(null));

      await cubit.setActive(7, isActive: false);

      verify(() => setMemberActive(7, isActive: false)).called(1);
      expect(
        cubit.state,
        const MemberFormSaved(MemberFormOutcome.deactivated),
      );
    });

    test('reports the reactivation separately, so the copy can differ',
        () async {
      stubSetActive(const Right(null));

      await cubit.setActive(7, isActive: true);

      expect(
        cubit.state,
        const MemberFormSaved(MemberFormOutcome.reactivated),
      );
    });

    test('a failure keeps the admin on the form', () async {
      stubSetActive(const Left(ServerFailure('Boom')));

      await cubit.setActive(7, isActive: false);

      expect(cubit.state, isA<MemberFormFailure>());
    });
  });
}
