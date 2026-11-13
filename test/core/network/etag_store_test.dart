import 'package:club_management_app/core/network/etag_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remembers a response with its fingerprint', () {
    final store = EtagStore()..remember('/members', '"v1"', ['roster']);

    final stored = store.lookup('/members');

    expect(stored?.eTag, '"v1"');
    expect(stored?.data, ['roster']);
  });

  test('a response without a fingerprint forgets the previous one', () {
    final store = EtagStore()
      ..remember('/members', '"v1"', ['roster'])
      ..remember('/members', null, ['roster']);

    expect(store.lookup('/members'), isNull);
  });

  test('past the limit, the least recently used path is dropped', () {
    final store = EtagStore(maxEntries: 2)
      ..remember('/members', '"members"', [])
      ..remember('/family-groups', '"groups"', []);
    store
      ..lookup('/members')
      ..remember('/clubs/me', '"club"', {});

    expect(store.lookup('/family-groups'), isNull);
    expect(store.lookup('/members')?.eTag, '"members"');
    expect(store.lookup('/clubs/me')?.eTag, '"club"');
  });
}
