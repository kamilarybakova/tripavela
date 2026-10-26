"""Apply the local photo manifest without changing routes, text or progress."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / 'assets/images/place-photo-credits.json'

def manifest():
    return {p['key']: p for p in json.loads(MANIFEST.read_text())}

def apply_catalog_photos(catalog):
    photos = manifest()
    for place in catalog['places']:
        photo = photos['place:' + place['id']]
        place['image'] = photo['asset']
        place['imageCaption'] = photo.get('caption', 'Фотография места или его окрестностей')
    for route in catalog['routes']:
        route['image'] = photos['route:' + route['id']]['asset']
    existing = [p for p in catalog['city'].get('photoCredits', []) if not p['asset'].startswith(('place-', 'plan-', 'route-'))]
    catalog['city']['photoCredits'] = existing + [dict(asset=Path(p['asset']).name, label=('Городская прогулка · фото ' + str(int(p['key'].split(':')[1][1:]) + 1) if p['key'].startswith('place:') else p['label']), author=p['author'], license=p['license'], url=p['source']) for p in photos.values()]
    catalog['city']['imagesVersion'] = 'individual-photos-v1'
    return catalog

def apply_planning_photos(planning):
    photos = manifest()
    for poi in planning['pois']:
        photo = photos['plan:' + poi['id']]
        poi['image'] = photo['asset']
        poi['imageCaption'] = photo.get('caption', 'Фотография места или его окрестностей')
    return planning

if __name__ == '__main__':
    for filename, apply in [('catalog.json', apply_catalog_photos), ('planning.json', apply_planning_photos)]:
        file = ROOT / 'assets/data' / filename
        file.write_text(json.dumps(apply(json.loads(file.read_text())), ensure_ascii=False, indent=2) + '\n')
