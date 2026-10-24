import 'package:equatable/equatable.dart';

import '../../../club/domain/entities/club.dart';
import '../../../members/domain/entities/member.dart';

enum ProfileClubStatus { loading, ready, offline, failed }

class AdminProfileState extends Equatable {
  final ProfileClubStatus clubStatus;
  final Club? club;
  final bool isLoadingMember;
  final Member? linkedMember;

  const AdminProfileState({
    this.clubStatus = ProfileClubStatus.loading,
    this.club,
    this.isLoadingMember = false,
    this.linkedMember,
  });

  bool get clubFailed =>
      clubStatus == ProfileClubStatus.offline ||
      clubStatus == ProfileClubStatus.failed;

  AdminProfileState withClub(Club club) => AdminProfileState(
        clubStatus: ProfileClubStatus.ready,
        club: club,
        isLoadingMember: isLoadingMember,
        linkedMember: linkedMember,
      );

  @override
  List<Object?> get props => [clubStatus, club, isLoadingMember, linkedMember];
}
