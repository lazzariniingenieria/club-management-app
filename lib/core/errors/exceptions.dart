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
