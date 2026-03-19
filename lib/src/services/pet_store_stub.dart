abstract class PetStore {
  Future<String?> read();
  Future<void> write(String value);
}

PetStore createPetStore() => _MemoryPetStore();

class _MemoryPetStore implements PetStore {
  String? _cache;

  @override
  Future<String?> read() async => _cache;

  @override
  Future<void> write(String value) async {
    _cache = value;
  }
}
