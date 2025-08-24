#!/usr/bin/env bash
STATE="/tmp/hypr_effects_off"

disable_effects() {
  hyprctl keyword decoration:blur:enabled false
  hyprctl keyword decoration:shadow:enabled false
  hyprctl keyword animations:enabled false
}

enable_effects() {
  hyprctl keyword decoration:blur:enabled true
  hyprctl keyword decoration:shadow:enabled true
  hyprctl keyword animations:enabled true
}

if [[ -f "$STATE" ]]; then
  enable_effects
  rm "$STATE"
  notify-send "Beauty Mode"
else
  disable_effects
  touch "$STATE"
  notify-send "Performance Mode"
fi
