import 'package:crypto/crypto.dart';
import 'package:sembast/sembast.dart';

import 'account_api.dart';
import 'api_config.dart';
import 'database.dart';

const maxAtlasPhotoBytes = 20 * 1024 * 1024;
const _photoPrefix = 'photo:';
final _photoReference = RegExp(r'^photo:[a-f0-9]{64}$');
final _cache = stringMapStoreFactory.store('atlas_photo_cache');

bool isAtlasPhotoRef(String value) => _photoReference.hasMatch(value);

class AtlasPhotos {
  AtlasPhotos(this.db, this.api, this.session);

  final Database db;
  final AccountApi api;
  final AccountSession session;

  RecordRef<String, Map<String, Object?>> _record(String reference) => _cache
      .record('${tripavelaApiBase.origin}:${session.profile.id}:$reference');

  Future<Map<String, dynamic>> prepareVisitChanges(
    Map<String, dynamic> changes,
  ) async {
    final visits = changes['visits'] as Map?;
    if (visits == null) return changes;
    final uploaded = <String, String?>{};
    final prepared = <String, dynamic>{};
    for (final entry in visits.entries) {
      if (entry.value == null) {
        prepared[entry.key] = null;
        continue;
      }
      final visit = Map<String, dynamic>.from(entry.value as Map);
      final references = <String>{};
      for (final source in (visit['photos'] as List).cast<String>()) {
        if (!uploaded.containsKey(source)) {
          uploaded[source] = await _upload(source);
        }
        if (uploaded[source] case final reference?) references.add(reference);
      }
      prepared[entry.key] = {...visit, 'photos': references.toList()};
    }
    return {...changes, 'visits': prepared};
  }

  Future<String?> _upload(String source) async {
    if (isAtlasPhotoRef(source)) return source;
    final bytes = await readPhoto(source);
    if (bytes == null || bytes.isEmpty) return null;
    final id = sha256.convert(bytes).toString();
    final reference = '$_photoPrefix$id';
    await api.uploadAtlasPhoto(session.token, id, bytes);
    final record = _record(reference);
    final existing = await record.get(db);
    if (existing?['path'] case final String cached when cached != source) {
      // Keep the original file owned by its visit until synchronization succeeds.
      if (await readPhoto(cached) != null) return reference;
    }
    await record.put(db, {'path': source});
    return reference;
  }

  Future<List<int>?> readCached(String reference) async {
    final path = (await _record(reference).get(db))?['path'] as String?;
    return path == null ? null : readPhoto(path);
  }

  Future<List<int>?> read(String reference) async {
    final cached = await readCached(reference);
    if (cached != null) return cached;
    final id = reference.substring(_photoPrefix.length);
    final bytes = await api.downloadAtlasPhoto(session.token, id);
    if (sha256.convert(bytes).toString() != id) return null;
    try {
      final path = await persistPhoto(id, bytes);
      await _record(reference).put(db, {'path': path});
    } on Exception {
      // Downloaded bytes can still be displayed if the cache is unavailable.
    }
    return bytes;
  }

  Future<void> deleteCached(String reference) async {
    final record = _record(reference);
    if ((await record.get(db))?['path'] case final String path) {
      await deletePhotoFile(path);
      await record.delete(db);
    }
  }
}
