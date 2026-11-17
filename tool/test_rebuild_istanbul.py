"""Проверки собранного каталога Стамбула.

Запуск из папки «туризм»:
  ../туризм\\ backend/.venv/bin/python -m unittest tool/test_rebuild_istanbul.py
"""
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BACKEND = ROOT.parent / "туризм backend"
sys.path[:0] = [str(BACKEND), str(Path(__file__).resolve().parent)]

from backend.schemas import City, Place, Route  # noqa: E402
from rebuild_istanbul import asian, build, load_sources  # noqa: E402

THEMES = {"Еда", "Искусство", "История", "Архитектура", "Природа", "Книжные", "Городские детали"}
MOODS = {"Удивиться", "Замедлиться", "Попробовать новое", "Почувствовать город", "Провести время вместе", "Довериться случаю"}
MISSIONS = {"Наблюдать", "Пробовать", "Общаться"}
LICENSES = ("CC0", "Public domain", "CC BY", "CC BY-SA", "FAL")
PLACE_SIZE, ROUTE_SIZE = (1280, 1920), (1600, 900)


def image_size(path: Path) -> tuple[int, int]:
    out = subprocess.run(["sips", "-g", "pixelWidth", "-g", "pixelHeight", str(path)],
                         capture_output=True, text=True, check=True).stdout
    values = [int(line.split(":")[1]) for line in out.splitlines() if "pixel" in line]
    return values[0], values[1]


class CatalogTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        old = json.loads((ROOT / "assets/data/catalog.json").read_text())
        cls.catalog = build(*load_sources(), old=old)
        cls.places = {p["id"]: p for p in cls.catalog["places"]}
        cls.routes = cls.catalog["routes"]

    def test_counts(self):
        self.assertEqual(len(self.routes), 15)
        self.assertTrue(60 <= len(self.places) <= 85, len(self.places))

    def test_schema(self):
        City.model_validate(self.catalog["city"])
        for p in self.places.values():
            Place.model_validate(p)
        for r in self.routes:
            Route.model_validate(r)

    def test_enums(self):
        for p in self.places.values():
            self.assertIn(p["category"], THEMES, p["id"])
            self.assertIn(p["missionType"], MISSIONS, p["id"])
        for r in self.routes:
            self.assertIn(r["theme"], THEMES, r["id"])
            self.assertIn(r["mood"], MOODS, r["id"])
        self.assertEqual({r["mood"] for r in self.routes}, MOODS)

    def test_stops_exist_and_all_used(self):
        used = set()
        for r in self.routes:
            stops = r["places"] + r["branches"] + [r["alternative"]]
            self.assertEqual(len(set(stops)), 6, r["id"])
            for s in stops:
                self.assertIn(s, self.places, f'{r["id"]}: {s}')
            used |= set(stops)
        self.assertEqual(used, set(self.places))

    def test_images_exist_and_credited(self):
        credits = {c["asset"]: c for c in self.catalog["city"]["photoCredits"]}
        new = {p["asset"] for p in load_sources()[2]}
        items = [(p["image"], PLACE_SIZE) for p in self.places.values()] + [(r["image"], ROUTE_SIZE) for r in self.routes]
        for image, size in items:
            path = ROOT / image
            self.assertTrue(path.exists(), image)
            if image in new:  # сохранённые старые фото разного размера, приложение кадрирует их само
                self.assertEqual(image_size(path), size, image)
            credit = credits.get(path.name)
            self.assertIsNotNone(credit, f"нет автора для {image}")
            self.assertTrue(credit["license"].startswith(LICENSES), credit)

    def test_closed_and_budget(self):
        for r in self.routes:
            self.assertGreaterEqual(r["requiredMax"], r["requiredMin"], r["id"])
            if "topkapi" in " ".join(r["places"] + r["branches"]):
                self.assertIn(2, r["closedWeekdays"], r["id"])

    def test_cross_water_legs_flagged(self):
        """Переход между европейским и азиатским берегом Босфора должен быть паромом."""
        for r in self.routes:
            for key, edge in r["transitions"].items():
                a, b = (self.places[i] for i in key.split("|"))
                if asian(a) != asian(b):
                    self.assertIn("паром", edge["features"].lower(), f'{r["id"]} {key}')
                    self.assertGreaterEqual(edge["minutes"], 15, f'{r["id"]} {key}')

    def test_app_content_rules(self):
        """Те же правила, что в test/mission_content_test.dart и istanbul_catalog_test.dart."""
        titles = set()
        stale = ["воображаем", "мысленно", "рифму", "тремя словами", "сохраните наблюдение словами", "частный двор, занимать"]
        for p in self.places.values():
            self.assertNotIn(p["mission"], titles, p["id"])
            titles.add(p["mission"])
            self.assertTrue(45 <= len(p["missionDetails"]) <= 360, (p["id"], len(p["missionDetails"])))
            self.assertTrue(1 <= p["missionMinutes"] <= 10, p["id"])
            self.assertEqual(p["notice"], p["missionDetails"], p["id"])
            self.assertEqual(p["tryIt"], p["missionDetails"], p["id"])
            if p.get("missionPurchaseOptional"):
                self.assertGreater(len(p["missionFreeAlternative"]), 40, p["id"])
                self.assertEqual(p["missionType"], "Пробовать", p["id"])
            self.assertGreater(len(p["story"]), 70, p["id"])
            self.assertTrue(p["hours"] and p["access"] and p["cost"], p["id"])
            self.assertTrue(all(u.startswith("https://") for u in p["sources"]), p["id"])
            self.assertTrue(40.95 <= p["lat"] <= 41.2 and 28.9 <= p["lon"] <= 29.1, p["id"])
            text = f'{p["mission"]} {p["missionDetails"]} {p["story"]}'.lower()
            for word in stale:
                self.assertNotIn(word, text, p["id"])
        self.assertGreater(sum(p["missionCategory"] == "Еда" for p in self.places.values()), 15)
        for r in self.routes:
            for key in ("gettingThere", "practical", "budgetNote", "distanceNote"):
                self.assertGreater(len(r[key]), 40, (r["id"], key))
            for key, e in r["transitions"].items():
                self.assertTrue(25 <= e["meters"] <= 4000 and e["minutes"] > 0, (r["id"], key, e["meters"]))

    def test_asian_side_helper(self):
        self.assertTrue(asian({"lat": 40.9925, "lon": 29.0230}))   # Кадыкёй
        self.assertTrue(asian({"lat": 41.0270, "lon": 29.0150}))   # Ускюдар
        self.assertFalse(asian({"lat": 41.0175, "lon": 28.9735}))  # Эминёню
        self.assertFalse(asian({"lat": 41.0475, "lon": 29.0262}))  # Ортакёй
        self.assertFalse(asian({"lat": 41.0847, "lon": 29.0563}))  # Румелихисар


if __name__ == "__main__":
    unittest.main()
