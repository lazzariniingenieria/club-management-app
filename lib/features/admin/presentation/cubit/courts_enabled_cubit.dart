import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../club/domain/usecases/load_club_use_case.dart';

class CourtsEnabledCubit extends Cubit<bool> {
  final LoadClubUseCase _loadClub;

  CourtsEnabledCubit(this._loadClub) : super(false);

  Future<void> load() async {
    final result = await _loadClub();
    if (isClosed) return;

    emit(result.fold((_) => false, (club) => club.courtsEnabled));
  }
}
