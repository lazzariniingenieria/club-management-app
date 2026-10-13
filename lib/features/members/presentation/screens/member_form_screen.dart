import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../admin/presentation/widgets/admin_scaffold.dart';
import '../../domain/entities/member.dart';
import '../cubit/member_form_cubit.dart';
import '../widgets/member_form.dart';

class MemberFormScreen extends StatelessWidget {
  final Member? member;

  const MemberFormScreen({super.key, this.member});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemberFormCubit>(
      create: (_) => sl<MemberFormCubit>(),
      child: AdminScaffold(
        title: member == null
            ? AppStrings.memberFormCreateTitle
            : AppStrings.memberFormEditTitle,
        body: MemberForm(member: member),
      ),
    );
  }
}
