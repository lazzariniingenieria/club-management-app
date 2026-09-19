import 'user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      user: UserModel.fromJson(json),
    );
  }
}
