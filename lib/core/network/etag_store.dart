class StoredResponse {
  final String eTag;
  final Object? data;

  const StoredResponse({required this.eTag, required this.data});
}

class EtagStore {
  static const int defaultMaxEntries = 64;

  final int maxEntries;
  final Map<String, StoredResponse> _entries = {};

  EtagStore({this.maxEntries = defaultMaxEntries});

  StoredResponse? lookup(String path) {
    final stored = _entries.remove(path);
    if (stored != null) _entries[path] = stored;

    return stored;
  }

  void remember(String path, String? eTag, Object? data) {
    _entries.remove(path);
    if (eTag == null) return;

    _entries[path] = StoredResponse(eTag: eTag, data: data);
    if (_entries.length > maxEntries) _entries.remove(_entries.keys.first);
  }
}
