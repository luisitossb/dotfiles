#!/bin/bash
# Display a random Gen 1 Pokemon sprite normalized to a fixed height
TARGET=22

OUTPUT=$(pokemon-colorscripts --no-title -r 1)
ACTUAL=$(echo "$OUTPUT" | wc -l)
PAD=$(( (TARGET - ACTUAL) / 2 ))

if (( PAD > 0 )); then
    for ((i=0; i<PAD; i++)); do echo; done
    echo "$OUTPUT"
    for ((i=0; i<PAD; i++)); do echo; done
else
    echo "$OUTPUT"
fi
