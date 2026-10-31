import 'package:equatable/equatable.dart';

class FamilyGroup extends Equatable {
  final int id;
  final String? name;

  const FamilyGroup({required this.id, this.name});

  static const int nameMaxLength = 150;

  bool get hasName => name != null && name!.trim().isNotEmpty;

  @override
  List<Object?> get props => [id, name];
}
