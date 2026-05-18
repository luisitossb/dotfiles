#!/usr/bin/env bash
# Jump to next empty workspace, then open a terminal running opencode
hyprctl --batch "dispatch workspace emptym ; dispatch exec kitty -- opencode"
