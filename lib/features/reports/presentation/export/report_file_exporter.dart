import 'dart:typed_data';

import 'package:printing/printing.dart';

abstract class ReportFileExporter {
  Future<void> share(Uint8List bytes, String fileName);

  Future<void> preview(Uint8List bytes, String fileName);
}

class PrintingReportFileExporter implements ReportFileExporter {
  const PrintingReportFileExporter();

  @override
  Future<void> share(Uint8List bytes, String fileName) async {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  @override
  Future<void> preview(Uint8List bytes, String fileName) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
  }
}
