#!/usr/bin/env bash

killall hypridle
sleep 1
hypridle &

notify-send -u low -a Hypridle "Hypridle has been restarted."
