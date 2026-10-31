import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_contract_guard.dart';
import '../../../../core/network/api_object_reader.dart';
import '../models/club_model.dart';

abstract class ClubRemoteDataSource {
  Future<ClubModel> fetchClub();

  Future<ClubModel> updateMonthlyFee(int? monthlyFeeCents);
}

class ClubRemoteDataSourceImpl implements ClubRemoteDataSource {
  ClubRemoteDataSourceImpl(this._apiClient, this._logger)
      : _reader = ApiObjectReader(
          apiClient: _apiClient,
          logger: _logger,
          logContext: _logContext,
        );

  final ApiClient _apiClient;
  final AppLogger _logger;
  final ApiObjectReader _reader;

  static const String _logContext = 'ClubRemoteDataSource';

  @override
  Future<ClubModel> fetchClub() {
    return _reader.readObject(
      path: ApiConstants.currentClub,
      build: ClubModel.fromJson,
    );
  }

  @override
  Future<ClubModel> updateMonthlyFee(int? monthlyFeeCents) {
    return guardContract(
      () async {
        final Response<Map<String, dynamic>> response =
            await _apiClient.dio.patch<Map<String, dynamic>>(
          ApiConstants.currentClub,
          data: ClubModel.bodyForMonthlyFee(monthlyFeeCents),
        );

        return ClubModel.fromJson(response.data ?? const {});
      },
      logger: _logger,
      logContext: _logContext,
    );
  }
}
