"""Собирает раздел Стамбула в assets/data/catalog.json из tool/istanbul_v2/*.json.

places.json  — полные объекты мест; для сохранённого старого места: {"keep": "p09", ...переопределения}
routes.json  — маршруты в редакторском виде (stops: 6 ID, остальное см. план)
photos.json  — авторство фото: {key: "place:<id>"|"route:<id>", asset, author, license, url, licenseUrl}

Запуск из папки «туризм»: python3 tool/rebuild_istanbul.py
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = Path(__file__).resolve().parent / "istanbul_v2"
CATALOG = ROOT / "assets/data/catalog.json"
CHECKED = "2026-11-16"
DIETS = ["Вегетарианское", "Веганское", "Без алкоголя"]
WALK = ("Оценка перехода по ориентировочным координатам с запасом на уличный обход. "
        "Уточните безопасный путь в картах.")
DEFAULT_HINTS = [("Первый вариант", "Короче и спокойнее."), ("Второй вариант", "Чуть длиннее, с другим видом.")]


def load_sources():
    return tuple(json.loads((SOURCES / f"{name}.json").read_text()) for name in ("places", "routes", "photos"))


def distance(a: dict, b: dict) -> float:
    x, y = math.radians(a["lat"]), math.radians(b["lat"])
    dl = math.radians(b["lon"] - a["lon"])
    return 6371000 * 2 * math.asin(math.sqrt(math.sin((y - x) / 2) ** 2 + math.cos(x) * math.cos(y) * math.sin(dl / 2) ** 2))


# Ориентировочная середина Босфора (широта, долгота) с юга на север.
BOSPHORUS = [(40.95, 29.000), (41.00, 28.995), (41.03, 29.008), (41.047, 29.035), (41.085, 29.062), (41.25, 29.12)]
FERRY = "Паром через Босфор по Istanbulkart (≈20 минут) плюс путь до причалов. Сверяйте расписание."


def asian(p: dict) -> bool:
    for (la1, lo1), (la2, lo2) in zip(BOSPHORUS, BOSPHORUS[1:]):
        if la1 <= p["lat"] <= la2:
            return p["lon"] > lo1 + (p["lat"] - la1) / (la2 - la1) * (lo2 - lo1)
    return p["lon"] > 29.0


def edge(a: dict, b: dict, ferries: dict) -> dict:
    key = tuple(sorted((a["id"], b["id"])))
    if key in ferries:
        return dict(ferries[key])
    meters = max(30, round(distance(a, b) * 1.3 / 25) * 25)
    if asian(a) != asian(b):
        # В метры входит только пешая часть (до причалов и от них), паром — во времени.
        return {"meters": 800, "minutes": 30 + math.ceil(meters / 400), "features": FERRY}
    return {"meters": meters, "minutes": max(1, math.ceil(meters / 65)), "features": WALK}


def resolve_places(places: list[dict], old: dict) -> list[dict]:
    previous = {p["id"]: p for p in old["places"]}
    result = []
    for item in places:
        if "keep" in item:
            place = {**previous[item["keep"]], **{k: v for k, v in item.items() if k != "keep"}}
        else:
            place = {"image": f'assets/images/place-{item["id"]}.jpg',
                     "imageCaption": "Фотография места или его окрестностей",
                     "checkedAt": CHECKED, **item}
            place.setdefault("tryIt", place.get("missionDetails", ""))
            place.setdefault("notice", place.get("missionDetails", ""))
        result.append(place)
    return result


def build_route(src: dict, P: dict) -> dict:
    ids = src["stops"]
    ferries = {tuple(sorted(f["pair"])): {k: v for k, v in f.items() if k != "pair"} for f in src.get("ferries", [])}
    edges = {f"{a}|{b}": edge(P[a], P[b], ferries) for a in ids for b in ids if a != b}
    a, b, end = ids[:3]
    lengths = [sum(edges[k]["meters"] for k in (f"{a}|{b}", f"{b}|{c}", f"{c}|{end}")) for c in ids[3:5]]
    meters = min(lengths)
    food_min, food_max = src["food"]
    req_min, req_max = src.get("required", [0, 0])
    hints = src.get("branchHints") or DEFAULT_HINTS
    budget = (f"Обязательные расходы — {'0 ₺' if req_max == 0 else f'примерно {req_min // 100}–{req_max // 100} ₺ на человека (билеты для иностранных гостей, цены на {CHECKED}; уточняйте на официальных сайтах)'}. "
              f"Перекус по желанию: ориентировочно {food_min // 100}–{food_max // 100} ₺ на человека, это не прайс конкретного заведения. Транспорт и покупки отдельно."
              + (f" Необязательно: {src['optional']}" if src.get("optional") else ""))
    route = {
        "id": src["id"], "name": src["name"], "description": src["description"],
        "theme": src["theme"], "mood": src["mood"], "image": f'assets/images/route-{src["id"]}.jpg',
        "minutes": src["minutes"], "maxMinutes": src["maxMinutes"], "meters": meters,
        "requiredMin": req_min, "requiredMax": req_max, "foodMin": food_min, "foodMax": food_max,
        "stairs": src.get("stairs", "unknown"), "lastStart": src["lastStart"], "earliestStart": src["earliestStart"],
        "family": src.get("family", True), "indoor": src.get("indoor", False), "rest": src.get("rest", True),
        "diets": src.get("diets", DIETS), "places": ids[:3], "branches": ids[3:5], "alternative": ids[5],
        "legs": [edges[f"{a}|{b}"]["meters"], edges[f"{b}|{ids[3]}"]["meters"], edges[f"{ids[3]}|{end}"]["meters"]],
        "branchDelta": [{"minutes": math.ceil((n - meters) / 65), "meters": n - meters, "cost": 0} for n in lengths],
        "missionIndices": [0, 1, 2], "transitions": edges, "area": src["area"],
        "gettingThere": src["gettingThere"], "practical": src["practical"], "stopMinutes": src.get("stopMinutes"),
        "closedWeekdays": src.get("closedWeekdays", []), "branchTitle": src["branchTitle"],
        "branchHints": [{"title": t, "description": d} for t, d in hints],
        "overview": "Две общие остановки, выбранный вами вариант и финал. Есть запасная точка, если место закрыто.",
        "budgetNote": budget,
        "distanceNote": ("Длина — приблизительная сумма пеших переходов по координатам с запасом на обход; "
                         "время включает паузы. Паромы и транспорт указаны отдельно. Сверяйте путь в картах."),
        "sources": list(dict.fromkeys(src.get("sources", []) + [u for i in ids for u in P[i].get("sources", [])])),
        "checkedAt": CHECKED, "archived": False, "cityId": "istanbul",
    }
    if route["stopMinutes"] is None:
        del route["stopMinutes"]
    return route


def build(places: list[dict], routes: list[dict], photos: list[dict], old: dict) -> dict:
    resolved = resolve_places(places, old)
    P = {p["id"]: p for p in resolved}
    built = [build_route(r, P) for r in routes]
    city = dict(old["city"])
    kept = {p["image"].rsplit("/", 1)[1] for p in resolved}
    credits = [c for c in city.get("photoCredits", [])
               if not c["asset"].startswith(("place-", "route-")) or c["asset"] in kept]
    new = {Path(p["asset"]).name for p in photos}
    credits = [c for c in credits if c["asset"] not in new] + [
        {"asset": Path(p["asset"]).name, "author": p["author"], "license": p["license"],
         "url": p["url"], "licenseUrl": p.get("licenseUrl", "")} for p in photos]
    city.update(photoCredits=credits, checkedAt=CHECKED, contentVersion="tourist-v2",
                description=f"{len(built)} маршрутов по главным местам Стамбула и планы поездок на 2–7 дней.")
    return {"city": city, "places": resolved, "routes": built}


if __name__ == "__main__":
    old = json.loads(CATALOG.read_text())
    CATALOG.write_text(json.dumps(build(*load_sources(), old=old), ensure_ascii=False, indent=2) + "\n")
    print("catalog.json обновлён")
