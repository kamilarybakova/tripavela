import 'dart:io';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';

Future<Database> openLocalDatabase() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return databaseFactoryIo.openDatabase(
    '${directory.path}/travel_roulette_istanbul.db',
    version: 1,
  );
}

Future<String> persistPhoto(String path, List<int> bytes) async {
  final directory = await getApplicationSupportDirectory();
  final photos = Directory('${directory.path}/photos');
  await photos.create(recursive: true);
  final file = File(
    '${photos.path}/${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> deletePhotoFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

Future<List<int>?> readPhoto(String path) async {
  final file = File(path);
  return await file.exists() ? file.readAsBytes() : null;
}
