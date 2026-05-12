#!/bin/bash
MODE=$(cat "$HOME/.config/mode/current" 2>/dev/null || echo "laptop")
if [ "$MODE" = "server" ]; then
    printf '{"text":" SERVER","tooltip":"Server mode: lid close → screen off only, no auto-suspend","class":"server"}\n'
else
    printf '{"text":" LAPTOP","tooltip":"Laptop mode: lid close → suspend","class":"laptop"}\n'
fi
