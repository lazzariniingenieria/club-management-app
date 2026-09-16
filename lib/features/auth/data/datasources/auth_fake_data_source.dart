import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/entities/user.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

class FakeAccount {
  final String email;
  final UserModel user;

  const FakeAccount({required this.email, required this.user});
}

class AuthFakeDataSource implements AuthRemoteDataSource {
  AuthFakeDataSource({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;

  static const String sharedPassword = '123456';

  static const List<FakeAccount> accounts = [
    FakeAccount(
      email: 'admin@club.com',
      user: UserModel(
        id: 'fake-admin',
        email: 'admin@club.com',
        fullName: 'Ana Gómez',
        role: UserRole.admin,
      ),
    ),
    FakeAccount(
      email: 'super@club.com',
      user: UserModel(
        id: 'fake-super-admin',
        email: 'super@club.com',
        fullName: 'Sofía Duarte',
        role: UserRole.superAdmin,
      ),
    ),
    FakeAccount(
      email: 'socio@club.com',
      user: UserModel(
        id: 'fake-member',
        email: 'socio@club.com',
        fullName: 'Marcos Ledesma',
        role: UserRole.member,
      ),
    ),
  ];

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    await Future<void>.delayed(latency);

    final account = _findAccount(email);
    if (account == null || password != sharedPassword) {
      throw UnauthorizedException('Invalid email or password');
    }

    return AuthResponseModel(token: _tokenFor(account), user: account.user);
  }

  FakeAccount? _findAccount(String email) {
    final normalized = email.trim().toLowerCase();
    for (final account in accounts) {
      if (account.email == normalized) return account;
    }
    return null;
  }

  AuthToken _tokenFor(FakeAccount account) {
    return AuthToken(
      accessToken: 'fake-access-token-${account.user.id}',
      refreshToken: 'fake-refresh-token-${account.user.id}',
      tokenType: 'Bearer',
      expiresIn: 86400,
    );
  }
}
