"""Shared helpers for the CP4 lookup table generator and its resolve_cp4_*
follow-up passes (see generate_cp4_table.py for the overall pipeline).

Not part of the app — these are one-time/rarely-rerun offline developer
tools, imported only by each other.
"""

from __future__ import annotations

import csv
import io
import json
import re
import time
import unicodedata
import urllib.parse
import urllib.request
from collections import Counter, defaultdict
from pathlib import Path

CTT_CSV_URL = (
    "https://raw.githubusercontent.com/centraldedados/codigos_postais/"
    "master/data/codigos_postais.csv"
)
OVERPASS_URL = "https://overpass-api.de/api/interpreter"
USER_AGENT = "LatitudeTracker-CP4TableGenerator/1.0 (one-time offline tool)"
OUTPUT_PATH = Path(__file__).resolve().parent.parent / "assets" / "data" / "cp4_coordinates.json"

STOPWORDS = {"de", "da", "do", "dos", "das", "e"}
PLACE_TYPE_RANK = ["city", "town", "village", "hamlet"]

# Rough bounding boxes (lat_min, lat_max, lon_min, lon_max) used only to
# disambiguate between multiple same-named OSM candidates by region.
REGION_BBOX = {
    "madeira": (32.5, 33.2, -17.3, -16.2),
    "azores": (36.8, 39.8, -31.5, -24.5),
    "mainland": (36.8, 42.3, -9.6, -6.0),
}

_ACCENT_CLASSES = {
    "a": "[aàáâã]", "e": "[eèéê]", "i": "[iìíî]", "o": "[oòóôõ]", "u": "[uùúû]",
    "c": "[cç]",
}


def region_hint(cp4: str) -> str | None:
    prefix = int(cp4[:2])
    if 90 <= prefix <= 92:
        return "madeira"
    if 95 <= prefix <= 99:
        return "azores"
    return "mainland"


def normalize(name: str) -> str:
    decomposed = unicodedata.normalize("NFKD", name)
    return "".join(c for c in decomposed if not unicodedata.combining(c)).lower()


def accent_flexible(word: str) -> str:
    """Builds a regex fragment matching [word] with any accent variant of
    each vowel/c — CTT and OSM don't always agree on Portuguese diacritics
    (e.g. "Pêra" vs OSM's current "Pera")."""
    out = []
    for ch in word:
        base = unicodedata.normalize("NFKD", ch.lower())[0]
        out.append(_ACCENT_CLASSES.get(base, re.escape(ch)))
    return "".join(out)


def significant_words(name: str) -> list[str]:
    words = re.findall(r"[A-Za-zÀ-ÿ]+", name)
    return [w for w in words if normalize(w) not in STOPWORDS]


def fetch(url: str, data: bytes | None = None) -> bytes:
    req = urllib.request.Request(url, data=data, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=90) as resp:
        return resp.read()


def overpass_query(query: str) -> list[dict]:
    body = urllib.parse.urlencode({"data": query}).encode("utf-8")
    return json.loads(fetch(OVERPASS_URL, body))["elements"]


def overpass_retrying(
    query: str,
    attempts: int = 4,
    base_wait: float = 4.0,
    log: bool = True,
) -> list[dict] | None:
    """Runs [query] against Overpass, retrying on failure with linear
    backoff. Returns None (rather than raising) if every attempt fails, so
    callers can treat a persistent failure the same as a real miss.
    """
    for attempt in range(1, attempts + 1):
        try:
            return overpass_query(query)
        except Exception as exc:  # noqa: BLE001 - one-time script
            wait = base_wait * attempt
            if log:
                print(f"    attempt {attempt} failed ({exc}), retrying in {wait}s...")
            time.sleep(wait)
    return None


def load_cp4_localities() -> dict[str, str]:
    """Returns {cp4: dominant locality name} from the CTT dataset — for each
    CP4 prefix, the locality name with the most matching rows is taken as
    the representative name (a CP4 can span several small localities).
    """
    raw = fetch(CTT_CSV_URL).decode("utf-8")
    reader = csv.DictReader(io.StringIO(raw))
    counts: dict[str, Counter[str]] = defaultdict(Counter)
    for row in reader:
        cp4 = row["num_cod_postal"].strip()
        locality = row["desig_postal"].strip()
        if cp4 and locality:
            counts[cp4][locality] += 1
    return {cp4: counter.most_common(1)[0][0] for cp4, counter in counts.items()}


def load_table() -> dict[str, dict]:
    return json.loads(OUTPUT_PATH.read_text(encoding="utf-8"))


def save_table(table: dict[str, dict]) -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(
        json.dumps(table, ensure_ascii=False, indent=2, sort_keys=True), encoding="utf-8"
    )
