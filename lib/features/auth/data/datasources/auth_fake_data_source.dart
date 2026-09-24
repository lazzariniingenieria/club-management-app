import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class FakeAccount {
  final String dni;
  final UserModel user;

  const FakeAccount({required this.dni, required this.user});
}

class AuthFakeDataSource implements AuthRemoteDataSource {
  AuthFakeDataSource({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  static const String sharedPassword = '123456';

  static const List<FakeAccount> accounts = [
    FakeAccount(
      dni: '11111111',
      user: UserModel(id: 1, memberId: null, role: UserRole.admin),
    ),
    FakeAccount(
      dni: '22222222',
      user: UserModel(id: 2, memberId: null, role: UserRole.superAdmin),
    ),
    FakeAccount(
      dni: '33333333',
      user: UserModel(id: 3, memberId: 3001, role: UserRole.member),
    ),
  ];

  @override
  Future<AuthResponseModel> login(String dni, String password) async {
    await Future<void>.delayed(latency);

    final account = _findAccount(dni);
    if (account == null || password != sharedPassword) {
      throw UnauthorizedException('Invalid dni or password');
    }

    return AuthResponseModel(
      accessToken: 'fake-access-token-${account.user.id}',
      refreshToken: 'fake-refresh-token-${account.user.id}',
      user: account.user,
    );
  }

  FakeAccount? _findAccount(String dni) {
    final normalized = dni.trim();
    for (final account in accounts) {
      if (account.dni == normalized) return account;
    }
    return null;
  }
}
