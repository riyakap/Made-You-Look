#!/usr/bin/env python3
"""Builds MadeYouLook/Data/products.json and product images from scraped retailer data.

Usage:
  python3 scripts/build_catalog.py --existing existing.json --sephora sephora.json \
      --ulta ulta.json --images-out ProductImages/

Inputs are the JSON files saved by the Claude-in-Chrome collection step
(Sephora product pages and Ulta product pages). Curated fields that a retailer page
can't tell us (short card name, look styles, concerns) live in CURATED below.
"""
import argparse
import base64
import io
import json
import re
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

# key (Sephora search query or Ulta slug) -> curated fields
CURATED = {
    # Face
    "nars light reflecting foundation": dict(id="nars-light-reflecting", card="Light Reflecting Foundation", symbol="drop.halffull", styles=["natural", "softGlam", "light"], concerns=["unevenTone", "fineLines", "dryness", "texture"]),
    "too faced born this way foundation": dict(id="toofaced-born-this-way", card="Born This Way Foundation", symbol="drop.halffull", styles=["softGlam", "fullGlam"], concerns=["unevenTone", "redness", "acne"]),
    "rare beauty liquid touch weightless foundation": dict(id="rare-true-to-myself", card="True to Myself Foundation", symbol="drop.halffull", styles=["natural", "softGlam"], concerns=["oily", "unevenTone", "texture"]),
    "huda beauty easy bake loose setting powder": dict(id="huda-easy-bake", card="Easy Bake Powder", symbol="circle.dotted", styles=["softGlam", "fullGlam", "dark"], concerns=["oily", "texture", "fineLines"]),
    "fenty pro filtr soft matte foundation": dict(id="fenty-pro-filtr", card="Pro Filt'r Foundation", symbol="drop.halffull", styles=["softGlam", "fullGlam", "bronzy"], concerns=["oily", "acne", "texture", "unevenTone"]),
    "tarte shape tape concealer": dict(id="tarte-shape-tape", card="Shape Tape Concealer", symbol="pencil.tip", styles=["softGlam", "fullGlam"], concerns=["darkCircles", "acne", "redness"]),
    "mac studio fix fluid foundation": dict(id="mac-studio-fix", card="Studio Fix Fluid", symbol="drop.halffull", styles=["fullGlam", "softGlam", "dark"], concerns=["oily", "acne", "unevenTone"]),
    "infallible-up-32-hour-fresh-wear-foundation-pimprod2002481": dict(id="loreal-infallible-fresh-wear", card="Infallible Fresh Wear", symbol="drop.halffull", styles=["softGlam", "fullGlam"], concerns=["oily", "unevenTone", "texture"], how="Shake well, then blend from the center of the face outward with a brush or sponge."),
    "power-grip-primer-pimprod2030073": dict(id="elf-power-grip", card="Power Grip Primer", symbol="drop", styles=["natural", "softGlam", "fullGlam"], concerns=["dryness", "texture", "redness"], how="Smooth a thin layer over clean skin and let it get tacky before applying makeup."),
    "instant-age-rewind-eraser-treatment-foundation-pimprod2043641": dict(id="maybelline-age-rewind", card="Age Rewind Foundation", symbol="drop.halffull", styles=["natural", "softGlam"], concerns=["fineLines", "darkCircles", "unevenTone"], how="Twist the cushion applicator and dab onto skin, building coverage where needed."),
    # Cheeks
    "rhode pocket blush": dict(id="rhode-pocket-blush", card="Pocket Blush", symbol="circle.fill", styles=["natural", "light", "softGlam"], concerns=["dryness"]),
    "rhode pocket bronze": dict(id="rhode-pocket-bronze", card="Pocket Bronze", symbol="sun.haze.fill", styles=["bronzy", "natural"], concerns=["dryness"]),
    "nars blush": dict(id="nars-blush", card="Powder Blush", symbol="circle.lefthalf.filled", styles=["softGlam", "fullGlam", "natural"], concerns=["oily"]),
    "too faced chocolate soleil bronzer": dict(id="toofaced-chocolate-soleil", card="Chocolate Soleil Bronzer", symbol="sun.haze.fill", styles=["bronzy", "fullGlam"], concerns=["oily", "unevenTone"]),
    "rare beauty positive light liquid luminizer": dict(id="rare-positive-light", card="Positive Light Luminizer", symbol="sparkle", styles=["softGlam", "light", "natural"], concerns=["dryness", "fineLines"]),
    "fenty killawatt highlighter": dict(id="fenty-killawatt", card="Killawatt Highlighter", symbol="sparkles", styles=["fullGlam", "softGlam", "bronzy"], concerns=[]),
    "makeup by mario soft pop plumping blush veil": dict(id="mario-soft-pop", card="Soft Pop Blush Veil", symbol="circle.fill", styles=["natural", "softGlam", "light"], concerns=["dryness", "fineLines"]),
    "charlotte tilbury beauty light wand": dict(id="ct-beauty-light-wand", card="Beauty Light Wand", symbol="wand.and.stars", styles=["softGlam", "fullGlam", "light"], concerns=["dryness"]),
    "camo-liquid-blush-pimprod2042954": dict(id="elf-camo-liquid-blush", card="Camo Liquid Blush", symbol="drop.fill", styles=["natural", "softGlam", "light"], concerns=["dryness"], how="Dot a small amount onto cheeks and blend quickly with fingertips or a sponge."),
    "putty-blush-pimprod2020788": dict(id="elf-putty-blush", card="Putty Blush", symbol="circle.fill", styles=["natural", "light"], concerns=["dryness", "fineLines"], how="Tap onto the apples of the cheeks with fingers and blend upward."),
    "lumi-glotion-natural-glow-enhancer-xl-face-body-pimprod2055367": dict(id="loreal-lumi-glotion", card="Lumi Glotion", symbol="sun.max.fill", styles=["natural", "light", "bronzy"], concerns=["dryness", "unevenTone"], how="Wear alone, mix with foundation, or apply to high points for a glow."),
    "cloudtopia-cheek-lip-mousse-pimprod2055750": dict(id="maybelline-cloudtopia", card="Cloudtopia Cheek & Lip", symbol="cloud.fill", styles=["natural", "light", "softGlam"], concerns=["dryness"], how="Dab onto cheeks and lips and blur with fingertips."),
    # Eyes
    "too faced better than sex mascara": dict(id="toofaced-better-than-sex", card="Better Than Sex Mascara", symbol="eye.fill", styles=["softGlam", "fullGlam", "dark"], concerns=[]),
    "too faced natural nudes eyeshadow palette": dict(id="toofaced-natural-nudes", card="Natural Nudes Palette", symbol="square.grid.3x3.fill", styles=["natural", "softGlam", "bronzy"], concerns=[]),
    "nars climax mascara": dict(id="nars-climax", card="Climax Mascara", symbol="eye.fill", styles=["fullGlam", "dark"], concerns=[]),
    "rare beauty perfect strokes mascara": dict(id="rare-perfect-strokes-mascara", card="Perfect Strokes Mascara", symbol="eye.fill", styles=["natural", "softGlam"], concerns=[]),
    "rare beauty perfect strokes matte liquid liner": dict(id="rare-perfect-strokes-liner", card="Perfect Strokes Liner", symbol="pencil.line", styles=["softGlam", "fullGlam", "dark"], concerns=[]),
    "makeup by mario master mattes eyeshadow palette": dict(id="mario-master-mattes", card="Master Mattes Palette", symbol="square.grid.3x3.fill", styles=["softGlam", "fullGlam", "dark", "bronzy"], concerns=[]),
    "benefit precisely my brow pencil": dict(id="benefit-precisely-my-brow", card="Precisely, My Brow", symbol="pencil", styles=["natural", "softGlam", "fullGlam"], concerns=[]),
    "voluminous-panorama-washable-mascara-pimprod2042577": dict(id="loreal-panorama", card="Panorama Mascara", symbol="eye.fill", styles=["natural", "softGlam", "fullGlam"], concerns=[], how="Sweep from root to tip, wiggling outward to fan lashes."),
    "paradise-big-deal-volumizing-lengthening-washable-mascara-pimprod2049085": dict(id="loreal-paradise-big-deal", card="Paradise Big Deal Mascara", symbol="eye.fill", styles=["fullGlam", "softGlam", "dark"], concerns=[], how="Apply in zig-zag strokes from root to tip; layer for more volume."),
    "tattoo-studio-sharpenable-gel-pencil-eyeliner-pimprod2002765": dict(id="maybelline-tattoo-studio", card="Tattoo Studio Gel Pencil", symbol="pencil.line", styles=["softGlam", "fullGlam", "dark"], concerns=[], how="Line the lash line or waterline, then smudge within 30 seconds if you want a softer look."),
    "lash-n-roll-curling-lifting-mascara-pimprod2039885": dict(id="elf-lash-n-roll", card="Lash 'N Roll Mascara", symbol="eye.fill", styles=["natural", "softGlam"], concerns=[], how="Press the brush into the lash roots and roll upward to curl and lift."),
    "wow-brow-gel-pimprod2003078": dict(id="elf-wow-brow", card="Wow Brow Gel", symbol="pencil", styles=["natural", "softGlam"], concerns=[], how="Brush through brows in short upward strokes to shape and set."),
    "stay-all-day-inkwear-liquid-eye-liner-pimprod2053087": dict(id="stila-stay-all-day", card="Stay All Day Liner", symbol="pencil.line", styles=["softGlam", "fullGlam", "dark"], concerns=[], how="Draw along the upper lash line from inner to outer corner; flick out for a wing."),
    # Lips
    "rhode peptide lip tint": dict(id="rhode-lip-tint", card="Peptide Lip Tint", symbol="mouth.fill", styles=["natural", "light"], concerns=["dryness"]),
    "rhode peptide lip treatment": dict(id="rhode-lip-treatment", card="Peptide Lip Treatment", symbol="mouth.fill", styles=["natural", "light"], concerns=["dryness"]),
    "nars afterglow lip balm": dict(id="nars-afterglow-balm", card="Afterglow Lip Balm", symbol="mouth.fill", styles=["natural", "light", "softGlam"], concerns=["dryness"]),
    "too faced lip injection maximum plump": dict(id="toofaced-lip-injection", card="Lip Injection Plump", symbol="mouth.fill", styles=["softGlam", "fullGlam", "natural"], concerns=["dryness", "fineLines"]),
    "rare beauty soft pinch tinted lip oil": dict(id="rare-lip-oil", card="Soft Pinch Lip Oil", symbol="drop.fill", styles=["natural", "light"], concerns=["dryness"]),
    "rare beauty kind words matte lipstick": dict(id="rare-lip-oil-stick", card="Soft Pinch Lip Oil Stick", symbol="mouth.fill", styles=["natural", "softGlam"], concerns=["dryness"]),
    "laneige lip sleeping mask": dict(id="laneige-lip-mask", card="Lip Sleeping Mask", symbol="moon.fill", styles=["natural", "light"], concerns=["dryness"]),
    "dior lip glow oil": dict(id="dior-lip-glow-oil", card="Lip Glow Oil", symbol="drop.fill", styles=["natural", "light", "softGlam"], concerns=["dryness"]),
    "mac lip pencil": dict(id="mac-lip-pencil", card="Lip Pencil", symbol="pencil", styles=["softGlam", "fullGlam", "dark", "bronzy"], concerns=[]),
    "infallible-matte-resistance-liquid-lipstick-pimprod2039455": dict(id="loreal-matte-resistance", card="Matte Resistance Lipstick", symbol="mouth.fill", styles=["fullGlam", "dark", "softGlam"], concerns=[], how="Line and fill lips with the applicator; let set for a minute before blotting."),
    "super-stay-vinyl-ink-liquid-lipcolor-pimprod2031822": dict(id="maybelline-vinyl-ink", card="SuperStay Vinyl Ink", symbol="mouth.fill", styles=["fullGlam", "dark", "softGlam"], concerns=[], how="Shake for 5 seconds, then apply a thin layer starting at the center of the lips."),
    "lifter-gloss-with-hyaluronic-acid-pimprod2016411": dict(id="maybelline-lifter-gloss", card="Lifter Gloss", symbol="drop.fill", styles=["natural", "light", "softGlam"], concerns=["dryness"], how="Apply over bare lips or on top of lipstick or liner."),
    "glow-reviver-lip-oil-pimprod2042290": dict(id="elf-glow-reviver", card="Glow Reviver Lip Oil", symbol="drop.fill", styles=["natural", "light"], concerns=["dryness"], how="Swipe over bare lips for a sheer tint and glossy shine."),
}

BRAND_NAMES = {
    "rare beauty by selena gomez": "Rare Beauty", "fenty beauty by rihanna": "Fenty Beauty",
    "huda beauty": "Huda Beauty", "makeup by mario": "Makeup by Mario", "mac cosmetics": "MAC",
    "benefit cosmetics": "Benefit", "laneige": "Laneige", "dior": "Dior", "tarte": "Tarte",
    "e.l.f. cosmetics": "e.l.f.", "l'oréal": "L'Oréal", "l'oreal": "L'Oréal", "l'oréal paris": "L'Oréal",
    "maybelline": "Maybelline", "maybelline new york": "Maybelline", "stila": "Stila",
    "nars": "NARS", "too faced": "Too Faced", "rhode": "rhode", "charlotte tilbury": "Charlotte Tilbury",
}

COMPLEXION = re.compile(r"foundation|concealer|skin tint|tinted", re.I)
TONES = ["fair", "light", "lightMedium", "tan", "deep", "deepDark"]


def clean(text):
    text = (text or "").replace("​", "").replace("™", "").replace("®", "")
    return re.sub(r"\s+", " ", text).strip()


def brand_name(raw):
    return BRAND_NAMES.get(clean(raw).lower(), clean(raw))


def price_value(raw):
    match = re.search(r"[\d.]+", str(raw or "0"))
    return round(float(match.group()), 2) if match else 0.0


def first_sentences(text, count=2, limit=320):
    # Split on sentence ends, but not after short abbreviations like "e.l.f." or "Dr."
    parts = re.split(r"(?<=[a-z]{3}[.!])\s+(?=[A-Z])", clean(text))
    out = " ".join(parts[:count])
    return out[:limit].rsplit(" ", 1)[0] + "…" if len(out) > limit else out


def sephora_details(short):
    text = clean(short)
    match = re.search(r"(?i:what it is):\s*(.*?)(?=\s+(?:[A-Z][\w\s/&-]{2,40}:)|$)", text)
    return first_sentences(match.group(1) if match else text)


def sephora_usage(usage):
    text = clean(usage).replace("Suggested Usage:", "").strip(" -")
    steps = [s.strip(" -") for s in re.split(r"\s-\s|\s-(?=[A-Z])", text) if s.strip(" -")]
    return first_sentences(" ".join(steps[:2]) if steps else text)


def split_shade(value):
    value = clean(value)
    if " - " in value:
        name, detail = value.split(" - ", 1)
        return name.strip(), detail.strip()
    return value, ""


def luminance(hex_str):
    r, g, b = (int(hex_str[i:i + 2], 16) for i in (0, 2, 4))
    return 0.299 * r + 0.587 * g + 0.114 * b


def assign_tones(shades):
    ordered = sorted(range(len(shades)), key=lambda i: -luminance(shades[i]["hex"]))
    for rank, index in enumerate(ordered):
        shades[index]["tone"] = TONES[min(len(TONES) - 1, rank * len(TONES) // len(ordered))]


def remove_background(image, tolerance=24):
    """Makes a flat studio background transparent, then trims and pads to a square."""
    rgba = image.convert("RGBA")
    if rgba.getchannel("A").getextrema()[0] < 250:  # already has transparency
        trimmed = rgba
    else:
        width, height = rgba.size
        work = rgba.convert("RGB")
        for seed in [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1),
                     (width // 2, 0), (width // 2, height - 1), (0, height // 2), (width - 1, height // 2)]:
            ImageDraw.floodfill(work, seed, (255, 0, 255), thresh=tolerance)
        r, g, b = work.split()
        mask = ImageChops.multiply(ImageChops.multiply(r.point(lambda v: 255 if v == 255 else 0),
                                                       g.point(lambda v: 255 if v == 0 else 0)),
                                   b.point(lambda v: 255 if v == 255 else 0))
        rgba.putalpha(ImageChops.invert(mask).filter(ImageFilter.GaussianBlur(1)))
        trimmed = rgba
    bbox = trimmed.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox()
    if bbox:
        trimmed = trimmed.crop(bbox)
    w, h = trimmed.size
    side = int(max(w, h) * 1.08)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(trimmed, ((side - w) // 2, (side - h) // 2), trimmed)
    canvas.thumbnail((800, 800))
    return canvas


def download(url, dest):
    subprocess.run(["curl", "-sL", "-m", "30", "-A", "Mozilla/5.0 (Macintosh) AppleWebKit/537.36 Chrome/130 Safari/537.36",
                    "-o", str(dest), url], check=True)
    return dest


def average_hex(path):
    image = Image.open(path).convert("RGB")
    w, h = image.size
    crop = image.crop((int(w * 0.3), int(h * 0.3), int(w * 0.7), int(h * 0.7)))
    pixels = [p for p in crop.getdata() if not all(c > 245 for c in p)] or list(crop.getdata())
    return "".join(f"{round(sum(p[i] for p in pixels) / len(pixels)):02X}" for i in range(3))


def build(existing, sephora, ulta, images_out):
    images_out.mkdir(parents=True, exist_ok=True)
    products = list(existing)
    seen_ids = {p["id"] for p in products}
    tmp = Path(tempfile.mkdtemp())

    for raw in sephora:
        cur = CURATED[raw["query"]]
        shades = []
        for s in raw["shades"]:
            if re.search(r"\boz\b|\bml\b|\bg\b/", s["name"], re.I):  # a size option, not a shade
                continue
            name, detail = split_shade(s["name"])
            shades.append({"name": name, "detail": detail, "hex": (s.get("hex") or "B86F79").upper()})
        image = Image.open(io.BytesIO(base64.b64decode(raw["image"]["data"])))
        products.append(entry(cur, brand_name(raw["brand"]), clean(raw["name"]), raw["category"], price_value(raw["price"]),
                              raw["rating"], raw["reviews"], shades, sephora_details(raw["short"]),
                              sephora_usage(raw["usage"]) or cur.get("how", ""),
                              f"https://www.sephora.com/product/{raw['productId']}"))
        remove_background(image).save(images_out / f"product_{cur['id']}.png", optimize=True)

    for raw in ulta:
        cur = CURATED[raw["slug"]]
        product_name = clean(raw["name"])
        shades = []
        swatches = raw["swatches"]
        if len(swatches) > 16:  # sample evenly so the whole shade range is represented
            swatches = [swatches[int(i * len(swatches) / 16)] for i in range(16)]
        for i, sw in enumerate(swatches):
            path = download(sw["url"] + "?w=120", tmp / f"{cur['id']}_{i}.jpg")
            try:
                hex_value = average_hex(path)
            except Exception:
                hex_value = "B86F79"
            name = clean(sw["desc"].replace(product_name, "")) or f"Shade {i + 1}"
            shades.append({"name": name, "detail": "", "hex": hex_value})
        image_path = download(raw["image"] + "?w=800", tmp / f"{cur['id']}_main.jpg")
        products.append(entry(cur, brand_name(raw["brand"]), product_name, raw["category"], price_value(raw["price"]),
                              float(raw["rating"] or 0), int(raw["reviews"] or 0), shades,
                              first_sentences(raw["description"]), cur.get("how", ""),
                              f"https://www.ulta.com/p/{raw['slug']}"))
        remove_background(Image.open(image_path)).save(images_out / f"product_{cur['id']}.png", optimize=True)

    for p in products:
        assert p["id"] not in seen_ids or p in existing, f"duplicate id {p['id']}"
        seen_ids.add(p["id"])
    return products


def entry(cur, brand, name, category, price, rating, reviews, shades, details, how, source):
    if category == "face" and COMPLEXION.search(name) and len(shades) >= 4:
        assign_tones(shades)
    return {
        "id": cur["id"], "brand": brand, "name": name, "cardName": cur["card"], "category": category,
        "price": price, "rating": round(float(rating), 1), "reviewCount": int(reviews),
        "imageName": f"product_{cur['id']}", "symbol": cur["symbol"], "shades": shades,
        "concerns": cur["concerns"], "styles": cur["styles"], "details": details,
        "howToUse": how or "Apply as desired and build to your preferred intensity.", "source": source,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--existing", type=Path, required=True)
    parser.add_argument("--sephora", type=Path, required=True)
    parser.add_argument("--ulta", type=Path, required=True)
    parser.add_argument("--images-out", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parent.parent / "MadeYouLook/Data/products.json")
    args = parser.parse_args()
    catalog = build(json.loads(args.existing.read_text()), json.loads(args.sephora.read_text()),
                    json.loads(args.ulta.read_text()), args.images_out)
    args.out.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    counts = {c: sum(p["category"] == c for p in catalog) for c in ("face", "cheeks", "eyes", "lips")}
    print(f"Wrote {len(catalog)} products to {args.out}: {counts}")
