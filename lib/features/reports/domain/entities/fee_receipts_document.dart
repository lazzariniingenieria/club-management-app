import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class FeeReceiptsDocument extends Equatable {
  final Uint8List bytes;
  final String fileName;

  const FeeReceiptsDocument({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
