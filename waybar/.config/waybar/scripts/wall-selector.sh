#!/bin/bash

DIR="$HOME/Pictures/wallpapers"

# 1. Verificar swww
if ! swww query > /dev/null 2>&1; then
    swww-daemon &
    sleep 0.5
fi

# 2. Generar lista con formato compatible para Rofi 2.0.0
# Usamos un bucle para construir cada línea con el prefijo thumbnail://
listado=""
while IFS= read -r file; do
    name=$(basename "$file")
    # Formato: Nombre\0icon\x1fthumbnail://RutaCompleta
    listado+="${name}\x00icon\x1fthumbnail://${DIR}/${name}\n"
done < <(find "$DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \))

# 3. Lanzar Rofi
# - Usamos echo -e para procesar los escapes \x00 y \n
selected_raw=$(echo -ne "$listado" | rofi -dmenu -i -p " Seleccionar Wallpaper " \
    -config ~/.config/rofi/config.rasi \
    -show-icons)

# 4. Limpiar selección (Rofi 2.0.0 a veces devuelve la línea completa con metadatos)
# Esto extrae solo el nombre del archivo antes del carácter nulo
selected=$(echo "$selected_raw" | cut -d $'\0' -f 1)

# 5. Aplicar con swww
if [ -n "$selected" ] && [ -f "$DIR/$selected" ]; then
    swww img "$DIR/$selected" \
        --transition-type wipe \
        --transition-step 90 \
        --transition-fps 60
fi
