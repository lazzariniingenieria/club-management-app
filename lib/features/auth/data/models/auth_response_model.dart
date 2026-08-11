import '../../domain/entities/auth_token.dart';
import 'user_model.dart';

class AuthResponseModel {
  final AuthToken token;
  final UserModel user;

  const AuthResponseModel({
    required this.token,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: AuthToken(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        tokenType: json['tokenType'] as String,
        expiresIn: json['expiresIn'] as int,
      ),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
