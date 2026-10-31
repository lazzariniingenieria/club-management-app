import 'app_environment.dart';

class AppFeatures {
  final bool feeReceipts;

  const AppFeatures({required this.feeReceipts});

  factory AppFeatures.fromEnvironment() =>
      const AppFeatures(feeReceipts: AppEnvironment.feeReceiptsEnabled);
}
