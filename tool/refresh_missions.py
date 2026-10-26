"""Apply authored, place-specific experiences without changing routes or progress."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def apply_missions(catalog):
    ideas = json.loads((ROOT / 'tool/mission_ideas.json').read_text())
    assert set(ideas) == {p['id'] for p in catalog['places']}
    for place in catalog['places']:
        idea = ideas[place['id']]
        details = idea['details']
        # Keep the factual introduction, removing the old generated task and boilerplate.
        place['story'] = place['story'].split('\n\n')[0]
        if place['id'] == 'p12':
            place['story'] = 'Набережная Фенера проходит вдоль Золотого Рога. Здесь есть открытый вид на воду, а за береговой дорогой начинаются плотные кварталы Фенера и Балата.'
        if place['id'] == 'p97':
            place['story'] = 'Сиркеджи — исторический вокзал рядом с оживлёнными улицами старого города. На этой остановке смотрим здание снаружи; доступ в залы и на платформы зависит от режима вокзала.'
        place.update(
            mission=idea['title'], missionDetails=details,
            missionCategory=idea['category'], missionMinutes=idea['minutes'],
            missionPurchaseOptional=idea['purchaseOptional'],
            missionFreeAlternative=idea['freeAlternative'],
            notice=details, tryIt=details,
            missionType='Пробовать' if idea['purchaseOptional'] else (
                'Общаться' if 'спросите' in details.lower() else 'Наблюдать'),
        )
    catalog['city']['contentVersion'] = 'istanbul-20-experiences-v2'
    return catalog

if __name__ == '__main__':
    path = ROOT / 'assets/data/catalog.json'
    path.write_text(json.dumps(apply_missions(json.loads(path.read_text())), ensure_ascii=False, indent=2) + '\n')
