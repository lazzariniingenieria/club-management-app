import 'dart:async';

class ChangeReloader {
  static const Duration defaultDelay = Duration(seconds: 2);

  final Future<void> Function() _reload;
  final Duration _delay;
  Timer? _timer;
  bool _isVisible = true;
  bool _isStale = false;

  ChangeReloader({
    required Future<void> Function() reload,
    Duration delay = defaultDelay,
  })  : _reload = reload,
        _delay = delay;

  void changed() {
    if (!_isVisible) return _markStale();

    _timer?.cancel();
    _timer = Timer(_delay, () => unawaited(_reload()));
  }

  void visibilityChanged({required bool isVisible}) {
    if (_isVisible == isVisible) return;

    _isVisible = isVisible;
    if (!isVisible) return _pauseIfPending();
    if (_isStale) _reloadNow();
  }

  void dispose() => _timer?.cancel();

  void _markStale() => _isStale = true;

  void _pauseIfPending() {
    if (_timer?.isActive ?? false) _markStale();
    _timer?.cancel();
  }

  void _reloadNow() {
    _isStale = false;
    unawaited(_reload());
  }
}
