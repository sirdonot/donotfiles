#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

[[ -z $DISPLAY && "$(tty)" == "/dev/tty1" ]] && exec Hyprland &> /dev/null

if [[ $(tty) == "/dev/tty2" ]]; then 
    gsteam
fi
