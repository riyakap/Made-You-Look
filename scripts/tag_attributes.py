#!/usr/bin/env python3
"""Adds research-relevant formula attributes to products.json.

Attributes come from the retailer descriptions collected earlier (Sephora lists finish,
skin type and ingredient claims; Ulta descriptions mention formula claims), plus a few
manual corrections in OVERRIDES. See MadeYouLook/Data/research.json for how each
attribute is used.

Usage:
  python3 scripts/tag_attributes.py --sephora sephora.json --ulta ulta.json
"""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "MadeYouLook/Data/products.json"

# attribute -> regex over product name + description (case-insensitive)
PATTERNS = {
    "matte": r"\bmatte\b|mattif",
    "luminous": r"dewy|glow|luminous|radian|light[- ]reflect|highlight|gloss|illuminat|shimmer",
    "hydrating": r"hydrat|hyaluronic|glycerin|shea|moistur|nourish|squalane|ceramide|balm|jojoba|dimethicone|\blip oil\b",
    "oilFree": r"oil[- ]free",
    "nonComedogenic": r"non-?comedogenic|won.?t clog|doesn.?t clog|not clog",
    "fragranceFree": r"fragrance[- ]free|free of fragrance|without fragrance",
    "mineral": r"\bmineral\b(?! oil)|zinc oxide|titanium dioxide",
    "spf": r"\bspf\b|sunscreen",
    "blurring": r"blur|soft[- ]focus|airbrush|pore",
    "oilControl": r"oil[- ]control|shine[- ]control|oil[- ]absorb|controls? (oil|shine)",
    "longWear": r"long[- ]?wear|\b\d{2}[- ]?h(ou)?r|transfer[- ]resist|budge|all[- ]day|smudge[- ]proof",
    "waterproof": r"waterproof|water[- ]resistant",
    "buildable": r"buildable",
    "brightening": r"brighten|illuminat|light[- ]reflect",
    "colorCorrecting": r"colou?r[- ]correct|neutraliz|green[- ]tint",
    "cream": r"\bcream\b|creamy|\bbalm\b|\bgel\b|putty|mousse|\bliquid\b|\boil\b|stick",
    "powder": r"\bpowder\b",
}

# Manual corrections where descriptions are too short or misleading.
OVERRIDES = {
    "la-roche-tinted": {"add": ["mineral", "spf", "fragranceFree", "nonComedogenic"]},
    "laura-mercier-powder": {"add": ["oilControl", "blurring", "powder"]},
    "huda-easy-bake": {"add": ["oilControl"]},
    "elf-power-grip": {"add": ["hydrating"], "remove": ["oilControl"]},
    "nars-radiant-creamy": {"add": ["brightening", "buildable"]},
    "mario-surrealskin": {"add": ["brightening"]},
    "tarte-shape-tape": {"add": ["matte", "longWear"]},
    "benefit-hoola": {"add": ["matte", "powder"], "remove": ["luminous"]},
    "loreal-infallible-fresh-wear": {"add": ["matte", "cream"]},
    "laneige-lip-mask": {"add": ["hydrating"]},
    "maybelline-vinyl-ink": {"add": ["longWear"], "remove": ["hydrating"]},
    "loreal-matte-resistance": {"add": ["matte", "longWear"]},
}

LABELS = ["What it is", "Coverage", "Finish", "Formulation", "Highlighted Ingredients",
          "Ingredient Callouts", "What Else You Need to Know", "Skin Type", "Skincare Concerns"]


def sephora_fields(short):
    """Splits Sephora's 'What it is: … Finish: … Formulation: …' text into labeled fields."""
    pattern = "(" + "|".join(re.escape(l) for l in LABELS) + "):"
    parts = re.split(pattern, short)
    return {label: value.strip() for label, value in zip(parts[1::2], parts[2::2])}


def describe(product, raw):
    """Returns (claim text to keyword-match, attributes stated in structured fields)."""
    attrs = set()
    if "sephora.com" not in (product.get("source") or ""):
        return raw, attrs
    f = sephora_fields(raw)
    finish = f.get("Finish", "").lower()
    if "matte" in finish:
        attrs.add("matte")
    if re.search(r"radiant|dewy|satin|shimmer|luminous|glossy|metallic", finish):
        attrs.add("luminous")
    formulation = f.get("Formulation", "").lower()
    if "powder" in formulation:
        attrs.add("powder")
    if re.search(r"liquid|cream|gel|oil|balm|stick|serum|lotion", formulation):
        attrs.add("cream")
    callouts = f.get("Ingredient Callouts", "")
    if re.search(r"free of[^.]*\bfragrance\b", callouts, re.I) and not re.search(r"synthetic fragrance", callouts, re.I):
        attrs.add("fragranceFree")
    # Claims only: the "free of …" list and usage tips would cause false matches.
    claims = " ".join(f.get(k, "") for k in ("What it is", "Highlighted Ingredients", "What Else You Need to Know"))
    return claims, attrs


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sephora", type=Path, required=True)
    parser.add_argument("--ulta", type=Path, required=True)
    args = parser.parse_args()

    catalog = json.loads(CATALOG.read_text())
    raw_by_source = {}
    for raw in json.loads(args.sephora.read_text()):
        raw_by_source[f"https://www.sephora.com/product/{raw['productId']}"] = raw.get("short", "")
    for raw in json.loads(args.ulta.read_text()):
        raw_by_source[f"https://www.ulta.com/p/{raw['slug']}"] = raw.get("description", "")
    structured = {"matte", "luminous", "powder", "cream", "fragranceFree"}
    for product in catalog:
        claims, attrs = describe(product, raw_by_source.get(product.get("source"), ""))
        text = " ".join([product["name"], product["details"], claims])
        attrs |= {name for name, pattern in PATTERNS.items() if name not in structured and re.search(pattern, text, re.I)}
        # Finish and formula from keywords only when the retailer didn't state them.
        if not {"matte", "luminous"} & attrs:
            attrs |= {name for name in ("matte", "luminous") if re.search(PATTERNS[name], text, re.I)}
        if not {"powder", "cream"} & attrs:
            attrs |= {name for name in ("powder", "cream") if re.search(PATTERNS[name], text, re.I)}
        if re.search(PATTERNS["fragranceFree"], text, re.I):
            attrs.add("fragranceFree")
        override = OVERRIDES.get(product["id"], {})
        attrs |= set(override.get("add", []))
        attrs -= set(override.get("remove", []))
        product["attributes"] = sorted(attrs)
        product.pop("skinTypes", None)
    CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    for p in catalog:
        print(f"{p['id'][:28]:28} {', '.join(p['attributes'])}")


if __name__ == "__main__":
    main()
