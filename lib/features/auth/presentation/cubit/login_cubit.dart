import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../domain/usecases/login_with_credentials_use_case.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginWithCredentialsUseCase _loginUseCase;

  LoginCubit(this._loginUseCase) : super(const LoginInitial());

  Future<void> login(String dni, String password) async {
    emit(const LoginLoading());

    final result = await _loginUseCase(dni: dni, password: password);

    if (isClosed) return;

    emit(
      result.fold(
        (failure) => LoginFailure(failure.userMessage),
        LoginSuccess.new,
      ),
    );
  }
}
