import 'dart:convert';

import '../models/pet_state.dart';
import 'pet_store_stub.dart' show PetStore;
import 'pet_store_stub.dart'
    if (dart.library.html) 'pet_store_web.dart'
    if (dart.library.io) 'pet_store_io.dart' as pet_store;

class PetSaveRepository {
  PetSaveRepository() : _store = pet_store.createPetStore();

  final PetStore _store;

  Future<PetSnapshot> load() async {
    final raw = await _store.read();
    if (raw == null || raw.trim().isEmpty) {
      return PetSnapshot.initial();
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PetSnapshot.fromJson(decoded);
    } catch (_) {
      return PetSnapshot.initial();
    }
  }

  Future<void> save(PetSnapshot snapshot) async {
    await _store.write(jsonEncode(snapshot.toJson()));
  }
}
