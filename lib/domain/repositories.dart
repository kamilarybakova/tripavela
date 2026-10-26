import 'models.dart';

abstract interface class CatalogRepository {
  List<WalkRoute> get routes;
  Map<String, Place> get places;
  WalkRoute route(String id);
}

abstract interface class SessionRepository {
  Map<String, dynamic>? get active;
  List<Map<String, dynamic>> get sessions;
  Map<String, dynamic> session(String id);
  Future<String> start(String id, {bool reveal = false});
  Future<void> arrive(String id);
  Future<bool> advance(String id, {bool skip = false, String? reason});
  Future<void> pause(String id);
  Future<void> resume(String id);
  Future<void> end(String id);
}

abstract interface class AtlasRepository {
  List<Map<String, dynamic>> get visits;
  Future<void> note(String visitId, String text);
  Future<void> photo(String visitId, String path);
}

abstract interface class PreferencesRepository {
  Map<String, dynamic> get settings;
  Future<void> setting(String key, dynamic value);
}

abstract interface class FavoritesRepository {
  List<String> get favorites;
  Future<void> favorite(String id);
}
