import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_with_credentials_use_case.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginWithCredentialsUseCase _loginUseCase;

  LoginCubit(this._loginUseCase) : super(LoginInitial());

  Future<void> login(String email, String password) async {
    emit(LoginLoading());

    final result = await _loginUseCase(email: email, password: password);

    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) => emit(LoginSuccess()),
    );
  }
}
