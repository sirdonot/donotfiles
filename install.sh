#!/usr/bin/env bash

#installing required packages
sudo pacman -Syu --needed git pipewire pipewire-alsa pipewire-jack pipewire-jack wireplumber
gstreamer gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly pamixer 
ffmpeg qt5-wayland qt6-wayland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk pavucontrol
xdg-user-dirs-gtk ttf-font-awesome ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd
networkmanager network-manager-applet bluez bluez-utils blueman pacman-contrib qt6ct qt5ct

#installing hyprland packages
sudo pacman -S --needed hyprpicker hyprlock waybar kitty cliphist

#installing other packages
sudo pacman -S --needed code dolphin ark cava fish rofi-wayland plymouth archlinux-xdg-menu

#installing yay
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
rm -rf yay

#yay packages
yay -S --needed zen-browser-bin wlogout rofi-games swaync swww
