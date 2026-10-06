import '../../domain/entities/member.dart';
import '../models/member_model.dart';
import 'member_remote_data_source.dart';

class MemberFakeDataSource implements MemberRemoteDataSource {
  MemberFakeDataSource({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  static const int activeMembers = 230;
  static const int inactiveMembers = 15;
  static const int overdueMembers = 25;
  static const int totalMembers = activeMembers + inactiveMembers;

  static final List<MemberModel> roster = _buildRoster();

  @override
  Future<List<MemberModel>> fetchMembers() async {
    await Future<void>.delayed(latency);

    return roster;
  }

  static List<MemberModel> _buildRoster() {
    return [
      for (var index = 0; index < totalMembers; index++) _memberAt(index),
    ];
  }

  static MemberModel _memberAt(int index) {
    final isActive = index < activeMembers;

    return MemberModel(
      id: index + 1,
      firstName: _firstNames[index % _firstNames.length],
      lastName: _lastNames[(index ~/ _firstNames.length) % _lastNames.length],
      dni: '${20000000 + index * 13577}',
      status: isActive ? MemberStatus.active : MemberStatus.inactive,
      daysOverdue: isActive ? _daysOverdueAt(index) : 0,
    );
  }

  static int _daysOverdueAt(int index) {
    final isOverdue =
        index % _overdueEvery == 0 && index < overdueMembers * _overdueEvery;

    return isOverdue ? 12 + (index % 7) * 15 : 0;
  }

  static const int _overdueEvery = 9;

  static const List<String> _firstNames = [
    'Juan',
    'María',
    'Carlos',
    'Lucía',
    'Martín',
    'Sofía',
    'Diego',
    'Valentina',
    'Jorge',
    'Camila',
    'Pablo',
    'Agustina',
    'Nicolás',
    'Florencia',
    'Matías',
    'Julieta',
    'Federico',
    'Micaela',
    'Santiago',
    'Rocío',
    'Gonzalo',
    'Paula',
    'Emiliano',
    'Ana',
  ];

  static const List<String> _lastNames = [
    'Álvarez',
    'Gómez',
    'Fernández',
    'Rodríguez',
    'López',
    'Martínez',
    'Pérez',
    'Sánchez',
    'Romero',
    'Torres',
    'Benítez',
    'Acosta',
    'Medina',
    'Suárez',
    'Herrera',
    'Castro',
    'Ortiz',
    'Silva',
    'Molina',
    'Navarro',
    'Vega',
  ];
}
