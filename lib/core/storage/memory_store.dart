class MemoryStore<T> {
  T? _value;

  T? read() => _value;

  Future<void> write(T value) async {
    _value = value;
  }

  Future<void> clear() async {
    _value = null;
  }
}
