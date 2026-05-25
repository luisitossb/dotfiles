#!/bin/bash
set -euo pipefail
printf '[Login]\nHandleLidSwitch=%s\n' "$1" | tee /etc/systemd/logind.conf.d/lid-mode.conf > /dev/null
systemctl kill -s HUP systemd-logind
