#!/usr/bin/env bash
# Jump to next empty workspace, then open a Zen browser window
hyprctl --batch "dispatch workspace emptym ; dispatch exec zen-browser"
