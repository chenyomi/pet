import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'pet_store_stub.dart';

PetStore createPetStore() => _FilePetStore();

class _FilePetStore implements PetStore {
  @override
  Future<String?> read() async {
    final file = await _saveFile;
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final file = await _saveFile;
    await file.parent.create(recursive: true);
    await file.writeAsString(value);
  }

  Future<File> get _saveFile async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/digi_pet_save.json');
  }
}
