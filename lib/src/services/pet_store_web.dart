// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'pet_store_stub.dart';

const _storageKey = 'digi_pet_flutter_save';

PetStore createPetStore() => _WebPetStore();

class _WebPetStore implements PetStore {
  @override
  Future<String?> read() async {
    return html.window.localStorage[_storageKey];
  }

  @override
  Future<void> write(String value) async {
    html.window.localStorage[_storageKey] = value;
  }
}
