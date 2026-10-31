import '../../domain/entities/admin.dart';
import '../../domain/entities/admin_draft.dart';

class AdminModel extends Admin {
  const AdminModel({
    required super.id,
    required super.dni,
    required super.isActive,
    super.email,
    super.memberId,
  });

  static const String _idKey = 'id';
  static const String _dniKey = 'dni';
  static const String _emailKey = 'email';
  static const String _memberIdKey = 'memberId';
  static const String _activeKey = 'active';
  static const String _passwordKey = 'password';
  static const String newPasswordKey = 'newPassword';

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: (json[_idKey] as num).toInt(),
      dni: json[_dniKey] as String,
      email: json[_emailKey] as String?,
      memberId: (json[_memberIdKey] as num?)?.toInt(),
      isActive: json[_activeKey] as bool? ?? true,
    );
  }

  static Map<String, dynamic> bodyFromDraft(AdminDraft draft) {
    return {
      _dniKey: draft.dni,
      _emailKey: draft.email.isEmpty ? null : draft.email,
      _memberIdKey: draft.memberId,
    };
  }

  static Map<String, dynamic> bodyForCreation(
    AdminDraft draft,
    String password,
  ) =>
      {...bodyFromDraft(draft), _passwordKey: password};

  static Map<String, dynamic> bodyForPassword(String newPassword) =>
      {newPasswordKey: newPassword};
}
