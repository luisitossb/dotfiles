#!/usr/bin/env bash
# Jump to next empty workspace, then open a terminal running opencode
hyprctl dispatch workspace emptym
kitty -- opencode
