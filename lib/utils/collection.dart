/// A collection of items that can be added, removed, and retrieved by ID.
class Collection<T> {
  final Map<String, T> _items = {};

  /// Adds an item to the collection.
  void add(String id, T item, {bool override = false}) {
    if (!_items.containsKey(id) || override) _items[id] = item;
  }

  /// Removes an item from the collection.
  void remove(String id) {
    if (_items.containsKey(id)) _items.remove(id);
  }

  /// Checks if the collection contains an item with the given ID.
  bool contains(String id) => _items.containsKey(id);

  /// Gets an item from the collection by its ID.
  T? get(String id) => _items[id];

  /// Gets all items in the collection.
  List<T> all() => _items.values.toList();

  /// Clears the collection.
  void clear() => _items.clear();

  /// Iterates over all items in the collection.
  void forEach(void Function(T) f) => all().forEach(f);
}
