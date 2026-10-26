import 'dart:convert';
import 'package:sembast_web/sembast_web.dart';

Future<Database> openLocalDatabase() =>
    databaseFactoryWeb.openDatabase('travel_roulette_istanbul', version: 1);
Future<String> persistPhoto(String path, List<int> bytes) async =>
    'data:image/jpeg;base64,${base64Encode(bytes)}';
Future<void> deletePhotoFile(String path) async {}
Future<List<int>?> readPhoto(String path) async =>
    path.startsWith('data:') ? base64Decode(path.split(',').last) : null;
