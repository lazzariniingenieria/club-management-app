import '../../../../core/constants/api_constants.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list_reader.dart';
import '../../../../core/network/api_writer.dart';
import '../../domain/entities/recurring_slot_draft.dart';
import '../../domain/entities/recurring_slot_validity.dart';
import '../models/recurring_slot_model.dart';

abstract class RecurringSlotRemoteDataSource {
  Future<List<RecurringSlotModel>> fetchRecurringSlots();

  Future<RecurringSlotModel> createRecurringSlot(RecurringSlotDraft draft);

  Future<RecurringSlotModel> renewRecurringSlot(
    int recurringSlotId,
    RecurringSlotValidity validity,
  );

  Future<void> deactivateRecurringSlot(int recurringSlotId);
}

class RecurringSlotRemoteDataSourceImpl
    implements RecurringSlotRemoteDataSource {
  RecurringSlotRemoteDataSourceImpl(ApiClient apiClient, AppLogger logger)
      : _reader = ApiListReader(
          apiClient: apiClient,
          logger: logger,
          logContext: _logContext,
        ),
        _writer = ApiWriter(
          apiClient: apiClient,
          logger: logger,
          logContext: _logContext,
        );

  final ApiListReader _reader;
  final ApiWriter _writer;

  static const String _logContext = 'RecurringSlotRemoteDataSource';

  @override
  Future<List<RecurringSlotModel>> fetchRecurringSlots() {
    return _reader.readLists(
      paths: const [ApiConstants.recurringSlots],
      build: (responses) => [
        for (final row in responses.single)
          RecurringSlotModel.fromJson(row as Map<String, dynamic>),
      ],
    );
  }

  @override
  Future<RecurringSlotModel> createRecurringSlot(
    RecurringSlotDraft draft,
  ) async {
    final json = await _writer.postForObject(
      ApiConstants.recurringSlots,
      RecurringSlotModel.bodyFromDraft(draft),
    );

    return RecurringSlotModel.fromJson(json);
  }

  @override
  Future<RecurringSlotModel> renewRecurringSlot(
    int recurringSlotId,
    RecurringSlotValidity validity,
  ) async {
    final json = await _writer.postForObject(
      ApiConstants.recurringSlotRenewal(recurringSlotId),
      RecurringSlotModel.bodyFromValidity(validity),
    );

    return RecurringSlotModel.fromJson(json);
  }

  @override
  Future<void> deactivateRecurringSlot(int recurringSlotId) {
    return _writer.patch(
      ApiConstants.recurringSlotDeactivation(recurringSlotId),
    );
  }
}
