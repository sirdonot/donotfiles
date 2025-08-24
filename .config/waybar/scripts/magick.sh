#!/usr/bin/env bash
# Crop & scale an input image so the most detailed region fills a 1200x900 box.
# Defaults to only downscale (no upscaling). Requires ImageMagick (magick or convert).

set -euo pipefail

# ---------------------------------------------------------
# Configurable defaults
BOX_W=1200
BOX_H=900
GRID_X=20   # grid columns (20) and rows (15) ~ 4:3 grid
GRID_Y=15
MAP_MAX_DIM=600  # maximum size (px) for the temporary edge map (keeps processing fast)
NO_UPSCALE=1     # 1 = do NOT upscale, only downscale; set 0 if you want forced upscaling
# ---------------------------------------------------------

progname="$(basename "$0")"

usage(){
  cat <<EOF
Usage: $progname INPUT_IMAGE OUTPUT_IMAGE [BOX_W BOX_H]

Finds the most detailed area and fits it into a box of BOX_W x BOX_H (defaults 1200x900),
cropping to the box aspect ratio then resizing (will not upscale by default).
EOF
  exit 1
}

if [[ $# -lt 2 ]]; then
  usage
fi

IN="$1"
OUT="$2"
if [[ $# -ge 4 ]]; then
  BOX_W="$3"
  BOX_H="$4"
fi

# Detect ImageMagick command
if command -v magick >/dev/null 2>&1; then
  IM=magick
elif command -v convert >/dev/null 2>&1; then
  IM=convert
else
  echo "Error: ImageMagick not found (magick or convert)." >&2
  exit 2
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# create small edge / detail map (grayscale, resized)
MAP="$TMPDIR/edges.png"
# Resize to at most MAP_MAX_DIM for faster processing, keep aspect
"$IM" "$IN" -colorspace Gray -resize "${MAP_MAX_DIM}x${MAP_MAX_DIM}\>" -morphology Convolve Laplacian:0 -normalize "$MAP"

# map and orig sizes
read MAP_W MAP_H <<< $("$IM" "$MAP" -format "%w %h" info:)
read ORIG_W ORIG_H <<< $("$IM" "$IN" -format "%w %h" info:)

# compute tile size (grid)
tile_w=$(( MAP_W / GRID_X ))
tile_h=$(( MAP_H / GRID_Y ))
if [[ $tile_w -lt 2 || $tile_h -lt 2 ]]; then
  echo "Image too small for grid; reduce GRID_X/GRID_Y or increase MAP_MAX_DIM." >&2
  exit 3
fi

best_score=-1
best_x=0
best_y=0

# iterate tiles, compute mean brightness (edge energy)
for (( gy=0; gy<GRID_Y; gy++ )); do
  for (( gx=0; gx<GRID_X; gx++ )); do
    xoff=$(( gx * tile_w ))
    yoff=$(( gy * tile_h ))
    # crop tile and ask ImageMagick for mean (0..1)
    # use fx:mean which returns 0..1
    score=$("$IM" "$MAP" -crop "${tile_w}x${tile_h}+${xoff}+${yoff}" +repage -format "%[fx:mean]" info: 2>/dev/null)
    # score can be like 0.0023 ; convert to numeric compare using awk
    # keep maximum
    is_greater=$(awk -v s="$score" -v b="$best_score" 'BEGIN { if (s+0 > b+0) print 1; else print 0 }')
    if [[ $is_greater -eq 1 ]]; then
      best_score="$score"
      # center of this tile in MAP coords
      best_x=$(( xoff + tile_w/2 ))
      best_y=$(( yoff + tile_h/2 ))
    fi
  done
done

# Map center back to original image coordinates
scale_x=$(awk -v ow="$ORIG_W" -v mw="$MAP_W" 'BEGIN{printf "%f", ow/mw}')
scale_y=$(awk -v oh="$ORIG_H" -v mh="$MAP_H" 'BEGIN{printf "%f", oh/mh}')
center_x_orig=$(awk -v bx="$best_x" -v sx="$scale_x" 'BEGIN{printf "%f", bx*sx}')
center_y_orig=$(awk -v by="$best_y" -v sy="$scale_y" 'BEGIN{printf "%f", by*sy}')

# Determine maximum crop rectangle with BOX aspect ratio that fits inside original:
# target_ar = BOX_W / BOX_H
target_ar=$(awk -v w="$BOX_W" -v h="$BOX_H" 'BEGIN{printf "%f", w/h}')
orig_ar=$(awk -v w="$ORIG_W" -v h="$ORIG_H" 'BEGIN{printf "%f", w/h}')

if awk -v oa="$orig_ar" -v ta="$target_ar" 'BEGIN{exit !(oa >= ta)}'; then
  # image is wider than target ar -> full height, width limited
  crop_h="$ORIG_H"
  crop_w=$(awk -v ch="$crop_h" -v ar="$target_ar" 'BEGIN{printf "%d", int(ch*ar + 0.5)}')
else
  crop_w="$ORIG_W"
  crop_h=$(awk -v cw="$crop_w" -v ar="$target_ar" 'BEGIN{printf "%d", int(cw/ar + 0.5)}')
fi

# ensure integers
crop_w=${crop_w%.*}
crop_h=${crop_h%.*}

# center crop around (center_x_orig, center_y_orig), clamp to image bounds
left=$(awk -v cx="$center_x_orig" -v cw="$crop_w" 'BEGIN{printf "%d", int(cx - cw/2 + 0.5)}')
top=$(awk -v cy="$center_y_orig" -v ch="$crop_h" 'BEGIN{printf "%d", int(cy - ch/2 + 0.5)}')

# clamp
if (( left < 0 )); then left=0; fi
if (( top < 0 )); then top=0; fi
if (( left + crop_w > ORIG_W )); then left=$(( ORIG_W - crop_w )); fi
if (( top + crop_h > ORIG_H )); then top=$(( ORIG_H - crop_h )); fi

# final crop and resize (do not upscale if NO_UPSCALE=1)
if [[ "$NO_UPSCALE" -eq 1 ]]; then
  # \> prevents upscaling
  resize_arg="${BOX_W}x${BOX_H}\\>"
else
  # force to exact box (may upscale)
  resize_arg="${BOX_W}x${BOX_H}!"
fi

echo "Input: $IN (${ORIG_W}x${ORIG_H})"
echo "Edge map size: ${MAP_W}x${MAP_H}"
echo "Best detail center (map coords): ${best_x},${best_y}  -> orig coords: ${center_x_orig},${center_y_orig}"
echo "Crop (w x h + left + top): ${crop_w}x${crop_h}+${left}+${top}"
echo "Resizing to: ${BOX_W}x${BOX_H}  (no-upscale=${NO_UPSCALE})"

# perform crop & resize
"$IM" "$IN" -crop "${crop_w}x${crop_h}+${left}+${top}" +repage -resize "$resize_arg" "$OUT"

echo "Saved -> $OUT"
