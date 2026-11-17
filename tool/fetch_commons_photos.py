"""Подбирает и скачивает фото Стамбула из Wikimedia Commons (только свободные лицензии).

Запуск из папки «туризм»: python3 tool/fetch_commons_photos.py [ключ ...]
Пишет assets/images/place-<id>.jpg (1280×1920), route-<id>.jpg (1600×900) и tool/istanbul_v2/photos.json.
"""
import html
import json
import re
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets/images"
MANIFEST = ROOT / "tool/istanbul_v2/photos.json"
API = "https://commons.wikimedia.org/w/api.php"
UA = {"User-Agent": "CatalogPhotoImport/1.0 (python-urllib)"}
LICENSES = ("CC0", "Public domain", "CC BY", "CC BY-SA", "FAL")
SKIP = re.compile(r"v[eé]nissieux|rosier|painting|map|plan|logo|drawing|engraving|sketch|diagram|panorama|interior detail|\.svg|\.png|19\d\d|18\d\d", re.I)
SIZES = {"place": (1280, 1920), "route": (1600, 900)}
# Слово, которое обязано быть в названии файла (без учёта регистра), иначе кандидат отбрасывается.
MUST = {
    "place:hagia-sophia": "hagia|ayasofya", "place:blue-mosque": "sultan ?ahmed|blue mosque|sultanahmet",
    "place:hippodrome": "obelisk|hippodrome", "place:arasta-bazaar": "arasta", "place:little-hagia-sophia": "hagia|sergius|ayasofya",
    "place:ahmed-fountain": "ahmed|ahmet", "place:topkapi-palace": "topkap", "place:archaeology-museums": "archaeolog|arkeoloji",
    "place:cemberlitas": "constantine|çemberlitaş|cemberlitas", "place:nuruosmaniye": "nuruosmaniye", "place:grand-bazaar": "grand bazaar|kapalı",
    "place:cevahir-bedesten": "bedest|grand bazaar|kapalı", "place:sahaflar": "sahaf", "place:beyazit-square": "beyaz|university",
    "place:suleymaniye-mosque": "süleymaniye|suleymaniye", "place:suleymaniye-terrace": "süleymaniye|suleymaniye|golden horn",
    "place:fasulyeciler": "fasulye", "place:rustem-pasa": "r[uü]stem", "place:spice-bazaar": "spice|mısır|misir",
    "place:new-mosque": "yeni cami|new mosque", "place:eminonu-pier": "balik|balık|eminön|eminon", "place:galata-bridge": "galata bridge|galata köprü",
    "place:karakoy-pier": "karak[oö]y", "place:galata-tower": "galata (tower|kulesi)", "place:tunel-square": "tram|t[uü]nel",
    "place:st-antoine": "anto|padua", "place:cicek-pasaji": "çiçek|cicek", "place:pera-museum": "pera", "place:galatasaray-gate": "galatasaray",
    "place:taksim-square": "taksim|republic monument", "place:dolmabahce-mosque": "dolmabah", "place:dolmabahce-palace": "dolmabah",
    "place:naval-museum": "naval|deniz müze|caique|kayık", "place:besiktas-pier": "be[sş]ikta", "place:yildiz-park": "y[iı]ld[iı]z",
    "place:ciragan-palace": "[cç][iı]ra[gğ]an", "place:ortakoy-kumpir": "kumpir", "place:rumeli-hisari": "rumeli",
    "place:rumelihisari-coast": "rumeli|fatih sultan mehmet bridge", "place:patriarchate": "patriarch|george|fener",
    "place:red-castle": "phanar|fener|greek", "place:kiremit-houses": "balat", "place:chora": "chora|kariye", "place:edirnekapi-walls": "wall|theodosian|surlar",
    "place:eyup-pier": "ey[uü]p", "place:eyup-mosque": "ey[uü]p", "place:eyup-square": "ey[uü]p", "place:eyup-teleferik": "teleferi|cable|pierre loti|ey[uü]p",
    "place:eyup-cemetery-path": "cemetery|mezarl|ey[uü]p", "place:pierre-loti": "pierre loti|golden horn", "place:uskudar-pier": "[uü]sk[uü]dar",
    "place:maidens-tower": "maiden|kız kulesi|kiz kulesi", "place:kadikoy-pier": "kad[iı]k[oö]y|ferry|seagull", "place:moda-coast": "moda",
    "route:r0": "hagia|sultan|blue mosque", "route:r1": "topkap", "route:r2": "ferry|vapur|bosphorus", "route:r3": "grand bazaar|kapalı",
    "route:r4": "süleymaniye|suleymaniye", "route:r5": "emin[oö]n|yeni cami|new mosque", "route:r6": "galata", "route:r7": "isti[kq]lal|tram",
    "route:r8": "dolmabah", "route:r9": "ortak[oö]y", "route:r10": "rumeli|bebek", "route:r11": "balat|fener", "route:r12": "chora|kariye",
    "route:r13": "pierre loti|golden horn|ey[uü]p", "route:r14": "maiden|kız kulesi|kiz kulesi",
}

QUERIES = {
    "place:hagia-sophia": "Hagia Sophia Istanbul exterior",
    "place:blue-mosque": "Sultan Ahmed Mosque exterior",
    "place:hippodrome": "Obelisk of Theodosius Istanbul",
    "place:arasta-bazaar": "Arasta Bazaar Istanbul",
    "place:little-hagia-sophia": "Little Hagia Sophia Istanbul",
    "place:ahmed-fountain": "Fountain of Ahmed III Istanbul",
    "place:topkapi-palace": "Topkapi Palace courtyard",
    "place:archaeology-museums": "Istanbul Archaeology Museum building",
    "place:cemberlitas": "Column of Constantine Cemberlitas",
    "place:nuruosmaniye": "Nuruosmaniye Mosque",
    "place:grand-bazaar": "Grand Bazaar Istanbul street",
    "place:cevahir-bedesten": "Grand Bazaar Istanbul old bedesten",
    "place:sahaflar": "Sahaflar Carsisi Istanbul",
    "place:beyazit-square": "Istanbul University gate Beyazit",
    "place:suleymaniye-mosque": "Suleymaniye Mosque Istanbul",
    "place:suleymaniye-terrace": "view from Suleymaniye Golden Horn",
    "place:fasulyeciler": "kuru fasulye pilav",
    "place:rustem-pasa": "Rustem Pasha Mosque tiles",
    "place:spice-bazaar": "Spice Bazaar Istanbul spices",
    "place:new-mosque": "Yeni Cami Eminonu",
    "place:eminonu-pier": "balik ekmek Eminonu",
    "place:galata-bridge": "Galata Bridge fishermen",
    "place:karakoy-pier": "Karakoy pier Istanbul",
    "place:galata-tower": "Galata Tower exterior",
    "place:tunel-square": "Istiklal nostalgic tram",
    "place:st-antoine": "St. Anthony of Padua Church Istiklal",
    "place:cicek-pasaji": "Cicek Pasaji Istanbul",
    "place:pera-museum": "Pera Museum Istanbul",
    "place:galatasaray-gate": "Galatasaray High School gate",
    "place:taksim-square": "Republic Monument Taksim",
    "place:dolmabahce-mosque": "Dolmabahce Mosque",
    "place:dolmabahce-palace": "Dolmabahce Palace facade",
    "place:naval-museum": "Istanbul Naval Museum caique",
    "place:besiktas-pier": "Besiktas pier ferry",
    "place:yildiz-park": "Yildiz Park Istanbul",
    "place:ciragan-palace": "Ciragan Palace Istanbul",
    "place:ortakoy-kumpir": "kumpir",
    "place:rumeli-hisari": "Rumelihisari fortress",
    "place:rumelihisari-coast": "Fatih Sultan Mehmet Bridge Rumelihisari",
    "place:patriarchate": "Church of St. George Fener Istanbul",
    "place:red-castle": "Phanar Greek Orthodox College",
    "place:kiremit-houses": "Balat colorful houses",
    "place:chora": "Chora Church mosaic",
    "place:edirnekapi-walls": "Theodosian Walls Istanbul",
    "place:eyup-pier": "Eyup Golden Horn pier",
    "place:eyup-mosque": "Eyüp Sultan Camii Istanbul",
    "place:eyup-square": "Eyüp Sultan square",
    "place:eyup-teleferik": "Eyüp teleferik",
    "place:eyup-cemetery-path": "Eyup cemetery Istanbul",
    "place:pierre-loti": "Pierre Loti hill Golden Horn view",
    "place:uskudar-pier": "Uskudar ferry pier",
    "place:maidens-tower": "Maiden's Tower Istanbul",
    "place:kadikoy-pier": "Kadikoy ferry seagulls",
    "place:moda-coast": "Moda Kadıköy",
    "route:r0": "Hagia Sophia Blue Mosque Sultanahmet",
    "route:r1": "Topkapi Palace Bosphorus",
    "route:r2": "Istanbul ferry Bosphorus",
    "route:r3": "Grand Bazaar Istanbul interior",
    "route:r4": "Süleymaniye Mosque Istanbul view",
    "route:r5": "Eminonu New Mosque",
    "route:r6": "Galata Tower Golden Horn",
    "route:r7": "Istiklal Avenue tram",
    "route:r8": "Dolmabahce Palace Bosphorus",
    "route:r9": "Ortakoy Mosque Bosphorus Bridge",
    "route:r10": "Rumeli Hisari Bosphorus",
    "route:r11": "Balat Istanbul street",
    "route:r12": "Chora Church Istanbul",
    "route:r13": "Pierre Loti Golden Horn",
    "route:r14": "Maiden's Tower sunset",
}


def api(**params) -> dict:
    url = API + "?" + urllib.parse.urlencode({"format": "json", **params})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
                return json.load(r)
        except Exception:
            time.sleep(2 + attempt * 3)
    raise RuntimeError("Commons API недоступен")


def download(url: str) -> bytes:
    for attempt in range(6):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as exc:
            if exc.code != 429 or attempt == 5:
                raise
            time.sleep(60 * (attempt + 1))
    raise RuntimeError(url)


def text(meta: dict, key: str) -> str:
    value = meta.get(key, {}).get("value", "")
    return html.unescape(re.sub(r"<[^>]+>", "", value)).strip()


def candidates(query: str, used: set[str], must: str = "."):
    data = api(action="query", generator="search", gsrnamespace=6, gsrlimit=20,
               gsrsearch=f"{query} filetype:bitmap filew:>1200 filemime:image/jpeg",
               prop="imageinfo", iiprop="url|extmetadata|size", iiurlwidth=1920)
    pages = sorted(data.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 99))
    for page in pages:
        info = page["imageinfo"][0]
        meta = info.get("extmetadata", {})
        license = text(meta, "LicenseShortName")
        if (page["title"] in used or SKIP.search(page["title"]) or not re.search(must, page["title"], re.I)
                or not license.startswith(LICENSES)):
            continue
        thumb = info.get("thumburl") or info["url"]
        # Только стандартная миниатюра 1920 px: оригиналы и крупные размеры Wikimedia ограничивает по частоте.
        yield {"title": page["title"], "thumb": thumb, "width": info["width"],
               "height": info["height"], "author": text(meta, "Artist")[:120] or "Unknown",
               "license": license, "url": info["descriptionurl"], "licenseUrl": text(meta, "LicenseUrl")}


def save(src: Path, dest: Path, size: tuple[int, int]) -> None:
    width, height = size
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(src)], capture_output=True, text=True).stdout
    w, h = [int(line.split(":")[1]) for line in out.splitlines() if "pixel" in line]
    scale = max(width / w, height / h)
    tmp = dest.with_suffix(".tmp.jpg")
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "80", "-z", str(round(h * scale) + 1), str(round(w * scale) + 1),
                    str(src), "--out", str(tmp)], check=True, capture_output=True)
    subprocess.run(["sips", "-c", str(height), str(width), str(tmp), "--out", str(dest)], check=True, capture_output=True)
    tmp.unlink()


def main(keys: list[str]) -> None:
    manifest = {p["key"]: p for p in json.loads(MANIFEST.read_text())} if MANIFEST.exists() else {}
    used = {p["title"] for p in manifest.values() if "title" in p}
    # Не повторяем снимки, которые уже использует приложение (планировщик и старые места).
    app = ROOT / "assets/images/place-photo-credits.json"
    if app.exists():
        used |= {p["title"] for p in json.loads(app.read_text()) if p.get("title") and p["key"] not in manifest}
    for key in keys or [k for k in QUERIES if k not in manifest]:
        kind, id = key.split(":")
        dest = IMAGES / f"{kind}-{id}.jpg"
        for cand in candidates(QUERIES[key], used, MUST.get(key, ".")):
            with tempfile.TemporaryDirectory() as tmp:
                raw = Path(tmp) / "raw.jpg"
                raw.write_bytes(download(cand["thumb"]))
                save(raw, dest, SIZES[kind])
            used.add(cand["title"])
            manifest[key] = {"key": key, "asset": f"assets/images/{dest.name}", **{k: cand[k] for k in ("title", "author", "license", "url", "licenseUrl")}}
            print(f"{key}: {cand['title']} · {cand['license']} · {cand['author'][:40]}")
            break
        else:
            print(f"{key}: НЕ НАЙДЕНО", file=sys.stderr)
        MANIFEST.write_text(json.dumps(list(manifest.values()), ensure_ascii=False, indent=1) + "\n")
        time.sleep(10)


if __name__ == "__main__":
    main(sys.argv[1:])
