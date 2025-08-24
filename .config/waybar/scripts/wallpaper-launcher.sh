#!/bin/bash
# Set some variables
wall_dir="${HOME}/.config/wallpaper"
cacheDir="${HOME}/.cache/wallpaper/${theme}"
rofi_command="rofi -x11 -dmenu -theme ${HOME}/.config/rofi/selector.rasi -theme-str ${rofi_override}"

# Create cache dir if not exists
if [ ! -d "${cacheDir}" ] ; then
    mkdir -p "${cacheDir}"
fi

physical_monitor_size=24
monitor_res=$(hyprctl monitors |grep -A2 Monitor |head -n 2 |awk '{print $1}' | grep -oE '^[0-9]+')
dotsperinch=$(echo "scale=2; $monitor_res / $physical_monitor_size" | bc | xargs printf "%.0f")
monitor_res=$(( $monitor_res * $physical_monitor_size / $dotsperinch ))
rofi_override="element-icon{size:${monitor_res}px;border-radius:0px;}"

# Convert images in directory and save to cache dir
for imagen in "$wall_dir"/*.{jpg,jpeg,png,webp}; do
    if [ -f "$imagen" ]; then
        file_name=$(basename "$imagen")
        if [ ! -f "${cacheDir}/${file_name}" ] ; then
            convert -strip "$imagen" -thumbnail 500x500^ -gravity center -extent 500x500 "${cacheDir}/${file_name}"
        fi
    fi
done

# Select a picture with rofi (hide extension in menu)
wall_selection=$(find "${wall_dir}" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -exec basename {} \; | sort | while read -r A ; do name_no_ext="${A%.*}"; echo -en "$name_no_ext\x00icon\x1f${cacheDir}/$A\n"; done | $rofi_command)

# Set the wallpaper
[[ -n "$wall_selection" ]] || exit 1

# Full path to selected wallpaper (restore original filename with extension)
wall_path=$(find "${wall_dir}" -maxdepth 1 -type f -iname "${wall_selection}.*" | head -n 1)

# Apply pywal (set colors)
wal -i "$wall_path" & killall eww &

sleep 1 && hyprctl reload &

# Set wallpaper with swww and transition options
sleep 2 & swww img "$wall_path" --transition-type outer --transition-pos 0.999,0.999 --transition-step 90 --transition-duration 1.5 &

# calls magick.sh in background
MAGICK_SCRIPT="$HOME/.config/waybar/scripts/magick.sh"
OUT="${HOME}/.cache/wal/background.png"

if [ -x "$MAGICK_SCRIPT" ]; then
  ("$MAGICK_SCRIPT" "$wall_path" "$OUT" >/dev/null 2>&1 &)
fi

exit 0



