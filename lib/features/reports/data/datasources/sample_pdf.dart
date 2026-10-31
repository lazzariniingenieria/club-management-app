import 'dart:convert';
import 'dart:typed_data';

abstract final class SamplePdf {
  static Uint8List withText(String asciiText) {
    final content = 'BT /F1 18 Tf 72 770 Td ($asciiText) Tj ET';
    final objects = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
          '/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
      '<< /Length ${content.length} >>\nstream\n$content\nendstream',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ];

    return ascii.encode(_assemble(objects));
  }

  static String _assemble(List<String> objects) {
    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[];

    for (var index = 0; index < objects.length; index++) {
      offsets.add(buffer.length);
      buffer.write('${index + 1} 0 obj\n${objects[index]}\nendobj\n');
    }

    final xrefOffset = buffer.length;
    buffer
      ..write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n')
      ..writeAll(offsets.map((offset) => '${_padded(offset)} 00000 n \n'))
      ..write('trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n')
      ..write('startxref\n$xrefOffset\n%%EOF\n');

    return buffer.toString();
  }

  static String _padded(int offset) => offset.toString().padLeft(10, '0');
}
