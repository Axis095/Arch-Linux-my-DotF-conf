#!/bin/bash

pkill -f "playerctl metadata"

playerctl metadata --format '{{title}} - {{artist}}' --follow | while read line; do
    # Extraer la carátula a un archivo temporal
    artUrl=$(playerctl metadata mpris:artUrl | sed 's/file:\/\///')
    title=$(playerctl metadata xesam:title)
    artist=$(playerctl metadata xesam:artist)
    
    if [ -n "$artUrl" ]; then
        notify-send -i "$artUrl" "Now plays:" "$title\n$artist" -h string:x-canonical-private-synchronous:music
    else
        notify-send "Now plays:" "$title\n$artist" -h string:x-canonical-private-synchronous:music
    fi
done