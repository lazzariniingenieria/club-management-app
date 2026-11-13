import 'dart:convert';

import 'package:club_management_app/core/constants/api_constants.dart';
import 'package:club_management_app/core/network/revalidating_get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/scripted_http_adapter.dart';

ResponseBody listWithETag(List<dynamic> body, String eTag) {
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ApiConstants.eTagHeader: [eTag],
    },
  );
}

ResponseBody notModified(String eTag) {
  return ResponseBody.fromString(
    '',
    304,
    headers: {
      ApiConstants.eTagHeader: [eTag],
    },
  );
}

void main() {
  late ScriptedHttpAdapter adapter;
  late RevalidatingGet revalidatingGet;

  void serve(Responder responder) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api'));
    adapter = ScriptedHttpAdapter(responder);
    dio.httpClientAdapter = adapter;
    revalidatingGet = RevalidatingGet(dio);
  }

  String? sentETag(int request) =>
      adapter.requests[request].headers[ApiConstants.ifNoneMatchHeader]
          as String?;

  test('the first read sends no fingerprint', () async {
    serve((_, __) => listWithETag(const ['roster'], '"v1"'));

    await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);

    expect(sentETag(0), isNull);
  });

  test('an unchanged list comes back from memory when the server says 304',
      () async {
    serve(
      (options, callCount) => callCount == 1
          ? listWithETag(const ['roster'], '"v1"')
          : notModified('"v1"'),
    );

    await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);
    final second =
        await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);

    expect(sentETag(1), '"v1"');
    expect(second.statusCode, 200);
    expect(second.data, ['roster']);
  });

  test('a changed list replaces the stored one and its fingerprint', () async {
    serve(
      (options, callCount) => switch (callCount) {
        1 => listWithETag(const ['old roster'], '"v1"'),
        2 => listWithETag(const ['new roster'], '"v2"'),
        _ => notModified('"v2"'),
      },
    );

    await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);
    final changed =
        await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);
    final unchanged =
        await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);

    expect(changed.data, ['new roster']);
    expect(sentETag(2), '"v2"');
    expect(unchanged.data, ['new roster']);
  });

  test('a response without a fingerprint is never stored', () async {
    serve((_, __) => jsonListResponse(200, const ['roster']));

    await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);
    await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);

    expect(sentETag(1), isNull);
  });

  test('each path keeps its own fingerprint', () async {
    serve(
      (options, _) => options.path == ApiConstants.members
          ? listWithETag(const ['roster'], '"members"')
          : listWithETag(const ['overdue'], '"delinquency"'),
    );

    await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);
    await revalidatingGet.fetch<List<dynamic>>(ApiConstants.paymentDelinquency);
    await revalidatingGet.fetch<List<dynamic>>(ApiConstants.members);

    expect(sentETag(1), isNull);
    expect(sentETag(2), '"members"');
  });
}
