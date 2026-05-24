#!/usr/bin/env bash
default_sink=$(pactl get-default-sink 2>/dev/null)
default_source=$(pactl get-default-source 2>/dev/null)
sinks=$(pactl -f json list sinks 2>/dev/null | \
    jq --arg d "$default_sink" '[.[] | {name,desc:.description,active:(.name==$d)}]')
sources=$(pactl -f json list sources 2>/dev/null | \
    jq --arg d "$default_source" \
    '[.[] | select(.name | test("monitor") | not) | {name,desc:.description,active:(.name==$d)}]')
jq -n --argjson sinks "${sinks:-[]}" --argjson sources "${sources:-[]}" \
    '{sinks:$sinks,sources:$sources}'
