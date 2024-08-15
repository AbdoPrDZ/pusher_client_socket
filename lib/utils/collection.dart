class Collection<T> {
  final Map<String, T> _items = {};

  void add(String id, T item, {bool override = false}) {
    if (!_items.containsKey(id) || override) _items[id] = item;
  }

  void remove(String id) {
    if (!_items.containsKey(id)) _items.remove(id);
  }

  bool contains(String id) => _items.containsKey(id);

  T? get(String id) => _items[id];

  List<T> all() => _items.values.toList();

  void clear() => _items.clear();
}
