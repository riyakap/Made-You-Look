#!/bin/zsh
# Copies PNG/JPG exports into the asset catalog as named image sets.
# Usage: scripts/import_figma_images.sh [folder]   (default: FigmaExports/)
set -euo pipefail
ROOT="${0:A:h:h}"
SRC="${1:-$ROOT/FigmaExports}"
DEST="$ROOT/MadeYouLook/Assets.xcassets/Images"
mkdir -p "$DEST"
[[ -f "$DEST/Contents.json" ]] || echo '{ "info" : { "author" : "xcode", "version" : 1 } }' > "$DEST/Contents.json"
count=0
for f in "$SRC"/*.(png|PNG|jpg|JPG|jpeg)(N); do
  ext="${f:e:l}"
  # Figma appends " 1", "@2x" etc. — strip those and normalise to snake_case.
  name="${${f:t:r}%@*}"
  name="${name// /_}"
  name="${name:l}"
  set_dir="$DEST/$name.imageset"
  rm -rf "$set_dir" && mkdir -p "$set_dir"
  cp "$f" "$set_dir/$name.$ext"
  cat > "$set_dir/Contents.json" <<JSON
{
  "images" : [ { "filename" : "$name.$ext", "idiom" : "universal" } ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
  echo "  + $name"
  count=$((count + 1))
done
echo "Imported $count image(s) into Assets.xcassets/Images"
