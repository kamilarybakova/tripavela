import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Every Istanbul stop has a distinct practical idea and optional purchases have a free alternative',
    () {
      final catalog =
          jsonDecode(File('assets/data/catalog.json').readAsStringSync())
              as Map;
      final places = (catalog['places'] as List).cast<Map>();
      final titles = <String>{};
      for (final p in places) {
        final details = p['missionDetails'] as String;
        expect(titles.add(p['mission'] as String), isTrue, reason: p['id']);
        expect(details.length, inInclusiveRange(45, 360), reason: p['id']);
        expect(p['missionMinutes'], inInclusiveRange(1, 10));
        expect(p['missionCategory'], isNotEmpty);
        expect(p['notice'], details);
        expect(p['tryIt'], details);
        if (p['missionPurchaseOptional'] == true) {
          expect(
            (p['missionFreeAlternative'] as String).length,
            greaterThan(40),
          );
          expect(p['missionType'], 'Пробовать');
        }
        for (final stale in [
          'воображаем',
          'мысленно',
          'рифму',
          'тремя словами',
          'сохраните наблюдение словами',
          'частный двор, занимать',
        ]) {
          expect(
            '${p['mission']} $details ${p['story']}'.toLowerCase().contains(
              stale,
            ),
            isFalse,
            reason: '${p['id']}: $stale',
          );
        }
      }
      expect(titles.length, 109);
      expect(
        places.where((p) => p['missionCategory'] == 'Еда').length,
        greaterThan(15),
      );
      expect(
        places.firstWhere((p) => p['id'] == 'p97')['mission'],
        'Фото у вокзала Сиркеджи',
      );
    },
  );
}
