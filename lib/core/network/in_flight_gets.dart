import 'dart:async';

class InFlightGets {
  final Map<String, Future<Object?>> _pending = {};

  Future<T> share<T>(String path, Future<T> Function() get) {
    final pending = _pending[path];
    if (pending != null) return pending.then((response) => response as T);

    final request = get();
    _pending[path] = request;
    _forgetWhenDone(path, request);

    return request;
  }

  void forgetAll() => _pending.clear();

  void _forgetWhenDone(String path, Future<Object?> request) {
    void forget() {
      if (identical(_pending[path], request)) _pending.remove(path);
    }

    unawaited(
      request.then<void>((_) => forget(), onError: (Object _) => forget()),
    );
  }
}
