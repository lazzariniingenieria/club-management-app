import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'etag_store.dart';

class RevalidatingGet {
  static const int _ok = 200;
  static const int _notModified = 304;

  final Dio _dio;
  final EtagStore _store;

  RevalidatingGet(this._dio, {EtagStore? store})
      : _store = store ?? EtagStore();

  Future<Response<T>> fetch<T>(String path) async {
    final stored = _store.lookup(path);
    final response = await _dio.get<T>(path, options: _optionsFor(stored));
    if (stored != null && response.statusCode == _notModified) {
      return _fromStored(response, stored);
    }

    final eTag = response.headers.value(ApiConstants.eTagHeader);
    _store.remember(path, eTag, response.data);

    return response;
  }

  static Options? _optionsFor(StoredResponse? stored) {
    if (stored == null) return null;

    return Options(
      headers: {ApiConstants.ifNoneMatchHeader: stored.eTag},
      validateStatus: _acceptsNotModified,
    );
  }

  static bool _acceptsNotModified(int? status) {
    if (status == _notModified) return true;

    return status != null && status >= 200 && status < 300;
  }

  static Response<T> _fromStored<T>(
    Response<T> notModified,
    StoredResponse stored,
  ) {
    return Response<T>(
      requestOptions: notModified.requestOptions,
      data: stored.data as T?,
      statusCode: _ok,
      headers: notModified.headers,
    );
  }
}
