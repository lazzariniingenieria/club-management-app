import 'dart:developer' as developer;

abstract class AppLogger {
  void info(String message, {String? context});
  void warning(String message, {String? context});
  void error(String message,
      {String? context, Object? cause, StackTrace? stackTrace});
}

class DeveloperLogger implements AppLogger {
  const DeveloperLogger();

  static const String _loggerName = 'club_management_app';

  @override
  void info(String message, {String? context}) {
    _log(message, context: context, level: 800);
  }

  @override
  void warning(String message, {String? context}) {
    _log(message, context: context, level: 900);
  }

  @override
  void error(
    String message, {
    String? context,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    _log(
      message,
      context: context,
      level: 1000,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  void _log(
    String message, {
    required int level,
    String? context,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    developer.log(
      context == null ? message : '[$context] $message',
      name: _loggerName,
      level: level,
      error: cause,
      stackTrace: stackTrace,
    );
  }
}
