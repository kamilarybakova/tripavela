"""Apply reviewed photo credits and editorial names after build_destinations.py."""
import json
from pathlib import Path
r=Path(__file__).resolve().parent.parent
credits=json.loads((r/'assets/images/destination-photo-credits.json').read_text())
by={p['asset']:p for p in credits}
names={
'baku':['Крепостные стены и чай в старом городе','Лавки Ичеришехера и каменные переулки','Старый Баку: неспешный круг','Низами и площадь Фонтанов','Витрины центра и кутабы','Центральные кварталы без суеты','Каспийский бульвар и Park Bulvar','Покупки у моря: Port Baku','Море и чай на бульваре','Музей ковра и Малая Венеция','Deniz Mall: покупки с видом на залив','Южный бульвар и чайная пауза','28 Мая: вокзал и магазины','Насими: покупки, кофе и парк','Зимний парк и городские улицы'],
'tbilisi':['Купола бань и берега Куры','Шардени: галереи и старые улицы','Старый город: два берега','Сололаки и городские фасады','Руставели и покупки в Galleria','Центр: искусство и зелёная пауза','Fabrika и пешеходный Агмашенебели','Локальный дизайн и кафе Чугурети','Марджанишвили: соседние кварталы','Сухой мост: вещи с историей','Винтаж, картины и прогулка в парке','Орбелиани и тихие улицы','Ваке: аллеи и городской ритм','Покупки и обед в Ваке','Парки и кофе без спешки'],
'dubai':['Ветряные башни и Dubai Creek','Ткани, чай и торговые ряды','Al Seef: вечер у воды','Downtown: архитектура и Dubai Mall','Souk Al Bahar и прогулка у озера','Башня, бульвар и городские виды','Марина: канал и город у воды','JBR: покупки и пляжный променад','Мосты Марины и ранний ужин','Мадинат: рынок и каналы','Керамика, ароматы и кофе в Souk','Виды Мадината без спешки','Al Barsha: покупки и пауза','Mall of the Emirates и соседние кварталы','Парк, кафе и спокойный Al Barsha'],
'nhatrang':['Лотос, море и центр Нячанга','Вечерний рынок и пляжные улицы','Набережная после жары','Рынок Дам и северный центр','Покупки в Nha Trang Center и море','Парк Йерсена и рыбный суп','Лонгшон и каменный собор','Рынок Соммой и городской завтрак','Вокзал и повседневный Нячанг','Хончонг: северная бухта','Байзыонг: пляж, кофе и магазины','Северная набережная без спешки','Фудонг и южный пляж','Пляжные покупки и немныонг','Вечер в южных кварталах']}
for city in names:
 p=r/f'assets/data/cities/{city}.json';d=json.loads(p.read_text())
 for item in d['places']:
  credit=by[item['image']]
  item['imageCaption']=credit.get('caption',f"Иллюстрация города {d['city']['name']}: {credit['title'].removeprefix('File:')}")
 for item,title in zip(d['routes'],names[city]):item['name']=title
 d['city']['photoCredits']=[dict(asset=p['asset'].split('/')[-1],label=f"{d['city']['name']} · фотография {i+1}",author=p['author'],license=p['license'],url=p['source'],licenseUrl=p['licenseUrl']) for i,p in enumerate(credits) if p['cityId']==city]
 # Hero is a city view, not a reused Turkish asset.
 d['city']['image']=d['places'][0]['image']
 p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
 p=r/f'assets/data/cities/{city}-planning.json';planning=json.loads(p.read_text())
 for poi in planning['pois']:poi['imageCaption']=next(x['imageCaption'] for x in d['places'] if x['id']==poi['id'])
 # Nha Trang's classical day should include its heritage quarter.
 if city=='nhatrang':
  for t in planning['themes']:
   if t['id'] in ['classic', 'sea']:
    t['id']='classic' if any(pid.startswith('nhatrang-heritage-') for pid in t['pois']) else 'sea'
 p.write_text(json.dumps(planning,ensure_ascii=False,indent=2)+'\n')
print('Applied 120 reviewed photos, 60 route titles and local credits')
