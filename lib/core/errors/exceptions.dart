class ServerException implements Exception {
  final String? message;
  ServerException([this.message]);

  @override
  String toString() => message ?? 'ServerException';
}

class CacheException implements Exception {
  final String? message;
  CacheException([this.message]);

  @override
  String toString() => message ?? 'CacheException';
}

class NetworkException implements Exception {
  final String? message;
  NetworkException([this.message]);

  @override
  String toString() => message ?? 'NetworkException';
}

class UnauthorizedException implements Exception {
  final String? message;
  UnauthorizedException([this.message]);

  @override
  String toString() => message ?? 'UnauthorizedException';
}

class ValidationException implements Exception {
  final String? message;
  ValidationException([this.message]);

  @override
  String toString() => message ?? 'ValidationException';
}

class ConflictException implements Exception {
  final String? message;
  ConflictException([this.message]);

  @override
  String toString() => message ?? 'ConflictException';
}

class NotFoundException implements Exception {
  final String? message;
  NotFoundException([this.message]);

  @override
  String toString() => message ?? 'NotFoundException';
}

class ResponseTimeoutException extends NetworkException {
  ResponseTimeoutException([super.message]);

  @override
  String toString() => message ?? 'ResponseTimeoutException';
}
