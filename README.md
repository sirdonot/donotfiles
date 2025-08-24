## graphics-related packages

mesa vulkan-intel libva-intel-driver libva-utils mesa-utils vulkan-tools
libvdpau-va-gl

## set enviroment graphical variables
sudo nano /etc/environment

LIBVA_DRIVER_NAME=i965
VDPAU_DRIVER=va_gl


## run in terminal

XDG_MENU_PREFIX=arch- kbuildsycoca6 --noincremental


## set plymouth themes

https://github.com/adi1090x/plymouth-themes/blob/master/README.md

sudo plymouth-set-default-theme -l
sudo plymouth-set-default-theme -R "theme-name"

sudo nano /etc/mkinitcpio.conf
HOOKS=(... plymouth ...)

https://wiki.archlinux.org/title/Plymouth


## set autologin in tty

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo nano /etc/systemd/system/getty@tty1.service.d/autologin.conf

[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin "user" --noclear --noissue %I $TERM


## creating symlinks

ls -s ~/.cache/wal/colors-kitty.conf ~/.config/kitty/colors-kitty.conf

ls -s ~/.cache/wal/colors-waybar.css ~/.config/waybar/colors-waybar.css
