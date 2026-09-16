import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef Responder = ResponseBody Function(
    RequestOptions options, int callCount);

class ScriptedHttpAdapter implements HttpClientAdapter {
  ScriptedHttpAdapter(this._responder);

  final Responder _responder;
  final List<RequestOptions> requests = [];
  final Map<String, int> _callsByPath = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final callCount = (_callsByPath[options.path] ?? 0) + 1;
    _callsByPath[options.path] = callCount;
    return _responder(options, callCount);
  }

  int callsTo(String path) => _callsByPath[path] ?? 0;

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(int statusCode, [Map<String, dynamic>? body]) {
  return ResponseBody.fromString(
    jsonEncode(body ?? const <String, dynamic>{}),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
