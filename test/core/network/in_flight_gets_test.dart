import 'dart:async';

import 'package:club_management_app/core/network/in_flight_gets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InFlightGets inFlightGets;
  late int calls;
  late Completer<String> completer;

  Future<String> trackedGet() {
    calls++;
    completer = Completer<String>();

    return completer.future;
  }

  setUp(() {
    inFlightGets = InFlightGets();
    calls = 0;
  });

  test('concurrent gets of the same path share one request', () async {
    final first = inFlightGets.share('/members', trackedGet);
    final second = inFlightGets.share('/members', trackedGet);
    completer.complete('roster');

    expect(await first, 'roster');
    expect(await second, 'roster');
    expect(calls, 1);
  });

  test('different paths are never shared', () async {
    final members = inFlightGets.share('/members', trackedGet);
    final membersCompleter = completer;
    final groups = inFlightGets.share('/family-groups', trackedGet);
    membersCompleter.complete('roster');
    completer.complete('groups');

    expect(await members, 'roster');
    expect(await groups, 'groups');
    expect(calls, 2);
  });

  test('a finished request is never reused', () async {
    final first = inFlightGets.share('/members', trackedGet);
    completer.complete('old roster');
    await first;

    final second = inFlightGets.share('/members', trackedGet);
    completer.complete('new roster');

    expect(await second, 'new roster');
    expect(calls, 2);
  });

  test('a failure reaches every waiter and the next get retries', () async {
    final first = inFlightGets.share('/members', trackedGet);
    final second = inFlightGets.share('/members', trackedGet);
    completer.completeError(StateError('offline'));

    await expectLater(first, throwsStateError);
    await expectLater(second, throwsStateError);

    final retry = inFlightGets.share('/members', trackedGet);
    completer.complete('roster');

    expect(await retry, 'roster');
    expect(calls, 2);
  });

  test('a get started after forgetAll does not join an older request',
      () async {
    final beforeWrite = inFlightGets.share('/members', trackedGet);
    final beforeWriteCompleter = completer;
    inFlightGets.forgetAll();
    final afterWrite = inFlightGets.share('/members', trackedGet);
    beforeWriteCompleter.complete('roster before the write');
    completer.complete('roster after the write');

    expect(await beforeWrite, 'roster before the write');
    expect(await afterWrite, 'roster after the write');
    expect(calls, 2);
  });

  test('an older request finishing late keeps the newer one shared',
      () async {
    final beforeWrite = inFlightGets.share('/members', trackedGet);
    final beforeWriteCompleter = completer;
    inFlightGets.forgetAll();
    final afterWrite = inFlightGets.share('/members', trackedGet);
    beforeWriteCompleter.complete('roster before the write');
    await beforeWrite;

    final joiner = inFlightGets.share('/members', trackedGet);
    completer.complete('roster after the write');

    expect(await afterWrite, 'roster after the write');
    expect(await joiner, 'roster after the write');
    expect(calls, 2);
  });
}
