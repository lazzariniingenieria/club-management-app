import 'dart:async';

class SessionExpiryNotifier {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  void notifySessionExpired() {
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
