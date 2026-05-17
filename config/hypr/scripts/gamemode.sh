#!/usr/bin/env bash
#                                      __
#   ___ ____ ___ _  ___ __ _  ___  ___/ /__
#  / _ `/ _ `/  ' \/ -_)  ' \/ _ \/ _  / -_)
#  \_, /\_,_/_/_/_/\__/_/_/_/\___/\_,_/\__/
# /___/
#

cache_folder="$HOME/.cache/qs-dotfiles"
gamemode_monitor="$HOME/.config/hypr/conf/monitors/gamemode.conf"

if [ -f $HOME/.config/quickshell/state/gamemode-enabled ]; then
  if [ -f $cache_folder/last_monitor.conf ]; then
    cat $cache_folder/last_monitor.conf > $HOME/.config/hypr/conf/monitor.conf
    rm $cache_folder/last_monitor.conf
  fi
  hyprctl reload
  rm $HOME/.config/quickshell/state/gamemode-enabled
  notify-send -u low -i joystick -a System "Gamemode deactivated" "Animations and blur are now enabled."
else
  if [ -f $gamemode_monitor ]; then
    cat $HOME/.config/hypr/conf/monitor.conf > $cache_folder/last_monitor.conf
    echo "source = $gamemode_monitor" > $HOME/.config/hypr/conf/monitor.conf
  fi
  hyprctl --batch "\
    keyword animations:enabled 0;\
    keyword decoration:shadow:enabled 0;\
    keyword decoration:blur:enabled 0;\
    keyword general:gaps_in 0;\
    keyword general:gaps_out 0;\
    keyword general:border_size 1;\
    keyword decoration:active_opacity 1;\
    keyword decoration:inactive_opacity 1;\
    keyword decoration:fullscreen_opacity 1;\
    keyword decoration:rounding 0"
  touch $HOME/.config/quickshell/state/gamemode-enabled
  notify-send -u low -i joystick -a System "Gamemode activated" "Animations and blur are now disabled."
fi
