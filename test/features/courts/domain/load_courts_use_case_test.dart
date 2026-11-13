import 'package:club_management_app/features/courts/domain/entities/clock_time.dart';
import 'package:club_management_app/features/courts/domain/entities/court.dart';
import 'package:club_management_app/features/courts/domain/repositories/court_repository.dart';
import 'package:club_management_app/features/courts/domain/usecases/load_courts_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCourtRepository extends Mock implements CourtRepository {}

Court court(int id, String name, {bool isActive = true}) => Court(
      id: id,
      name: name,
      openingTime: const ClockTime(8, 0),
      closingTime: const ClockTime(23, 0),
      isActive: isActive,
    );

void main() {
  test('lists active courts first, each group by name ignoring case', () async {
    final repository = MockCourtRepository();
    when(() => repository.loadCourts()).thenAnswer(
      (_) async => Right([
        court(1, 'Tenis', isActive: false),
        court(2, 'pádel 2'),
        court(3, 'Fútbol 5'),
        court(4, 'Básquet', isActive: false),
        court(5, 'Pádel 1'),
      ]),
    );

    final result = await LoadCourtsUseCase(repository)();
    final ids = result.getRight().toNullable()!.map((court) => court.id);

    expect(ids, [3, 5, 2, 4, 1]);
  });
}
