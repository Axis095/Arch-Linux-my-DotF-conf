#!/bin/bash

DIR="$HOME/Pictures/wallpapers"

# Asegurar que swww-daemon esté vivo
if ! swww query > /dev/null 2>&1; then
    swww-daemon &
    sleep 0.5
fi

# 1. Generar listado con iconos reales para Rofi
listado=""
while IFS= read -r file; do
    name=$(basename "$file")
    listado+="${name}\x00icon\x1f${DIR}/${name}\n"
done < <(find "$DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \))

# 2. Selector Rofi
selected_raw=$(echo -ne "$listado" | rofi -dmenu -i -p " 󰸉 Selector " \
    -config ~/.config/rofi/config.rasi)

selected=$(echo "$selected_raw" | cut -d $'\0' -f 1)

if [ -n "$selected" ] && [ -f "$DIR/$selected" ]; then
    WALLPAPER_PATH="$DIR/$selected"

    # A. Cambiar Wallpaper
    swww img "$WALLPAPER_PATH" --transition-type outer --transition-step 90 --transition-fps 60

    # B. GENERAR ARCHIVOS FÍSICOS Y JSON (EDITADO)
    # Ejecutamos matugen sin --json primero para que cree los archivos .css, .rasi y .conf 
    # basados en tus plantillas del config.toml
    matugen -t scheme-vibrant image "$WALLPAPER_PATH"

    # Ahora sí, obtenemos el JSON para las variables rápidas del script
    MATUGEN_OUTPUT=$(matugen -t scheme-vibrant image "$WALLPAPER_PATH" --json hex)

    # C. Extraer el color para Hyprland
    COLOR_HEX=$(echo "$MATUGEN_OUTPUT" | jq -r '.colors.primary.default' | sed 's/#//')

    # D. Actualizar Hyprland al instante (Sin reload para no romper hyprshade)
    hyprctl keyword general:col.active_border "rgba(${COLOR_HEX}ff) 45deg"
    hyprctl keyword decoration:shadow:color "rgba(${COLOR_HEX}66)"

    # E. Notificación
    notify-send -a "Sistema" "Wallpaper Changed!" "Scheme: Vibrant" -i "$WALLPAPER_PATH"

    # F. Reinicio de Waybar y SwayNC
    pkill -x waybar
    while pgrep -x waybar > /dev/null; do sleep 0.1; done
    sleep 0.2
    waybar > /dev/null 2>&1 &
    swaync-client -R && swaync-client -rs

    # G. RE-APLICAR HYPRSHADE (CLAVE)
    # Aseguramos que después de todo el movimiento de Waybar y colores, 
    # la saturación siga activa.
    sleep 0.1
    hyprshade on vibrance
fi