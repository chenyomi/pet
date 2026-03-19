import 'dart:io';

import 'pet_store_stub.dart';

PetStore createPetStore() => _FilePetStore();

class _FilePetStore implements PetStore {
  @override
  Future<String?> read() async {
    final file = _saveFile;
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final file = _saveFile;
    await file.parent.create(recursive: true);
    await file.writeAsString(value);
  }

  File get _saveFile {
    final home = Platform.environment['HOME'];
    final base = home != null ? Directory(home) : Directory.current;
    return File('${base.path}/.digi_pet_flutter_save.json');
  }
}
