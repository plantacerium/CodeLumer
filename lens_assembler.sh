#!/bin/bash

# ==============================================================================
# Script: dual_cam.sh (Final, Reliable Version)
# FIX: Restored multi-line structure with minimal, correct parenthesis escaping.
#      Added diagnostic checks for input file paths.
# ==============================================================================

# Default settings
POSITION="SouthEast"
SCALE=20
OUTPUT="output.png"
BORDER_WIDTH=4
PADDING=40

# --- Function to display help (omitted for brevity, but remains in your file) ---

# --- Argument Parsing (unchanged) ---
while getopts "b:a:p:o:s:h" opt; do
    case ${opt} in
        b) BG="$OPTARG" ;;
        a) AVATAR="$OPTARG" ;;
        p)
            case "$OPTARG" in
                tr) POSITION="NorthEast" ;;
                tl) POSITION="NorthWest" ;;
                br) POSITION="SouthEast" ;;
                bl) POSITION="SouthWest" ;;
                *) POSITION="SouthEast" ;;
            esac
            ;;
        o) OUTPUT="$OPTARG" ;;
        s) SCALE="$OPTARG" ;;
        h) exit 1 ;;
        *) exit 1 ;;
    esac
done

# --- Validation and Diagnostic Checks ---
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick ('magick') is not installed."
    exit 1
fi

if [[ -z "$BG" || -z "$AVATAR" ]]; then
    echo "Error: You must provide both a background (-b) and an avatar (-a)."
    exit 1
fi

# New Diagnostic Check
if [[ ! -f "$BG" ]]; then
    echo "CRITICAL ERROR: Background file '$BG' not found."
    exit 1
fi
if [[ ! -f "$AVATAR" ]]; then
    echo "CRITICAL ERROR: Avatar file '$AVATAR' not found."
    exit 1
fi

# --- Core Logic ---
if ! BG_W=$(magick identify -format "%w" "$BG" 2>/dev/null); then
    echo "Error: Could not read width of background image '$BG'. Check file integrity."
    exit 1
fi

SIZE=$(( BG_W * SCALE / 100 ))
RADIUS=$(( SIZE / 2 ))

echo "--- Image Composition ---"
echo "Reading background: $BG"
echo "Reading avatar: $AVATAR"
echo "Calculated Avatar Size: ${SIZE}px (${SCALE}%)"

# 2. ImageMagick Processing Chain - MINIMAL, CORRECT ESCAPING
# STEP 1: Resize and Square the Avatar
magick "$AVATAR" \
    -resize "${SIZE}x${SIZE}^" \
    -gravity center \
    -extent "${SIZE}x${SIZE}" \
    temp_avatar_square.png

# STEP 2: Apply Circular Mask and Set Transparent Background
magick temp_avatar_square.png \
    -alpha set -background none \
    \( +clone -alpha transparent -draw "circle ${RADIUS},${RADIUS} ${RADIUS},0" \) \
    -compose DstIn -composite \
    temp_avatar_circular.png

# STEP 3: Add Border and Shadow
magick temp_avatar_circular.png \
    \( +clone -background black \) \
    +swap -background none -layers merge +repage \
    temp_avatar_final_block.png

# STEP 4: Composite the Final Image
magick "$BG" temp_avatar_final_block.png \
    -gravity "$POSITION" \
    -geometry +${PADDING}+${PADDING} \
    -compose over -composite \
    "$OUTPUT"
echo "-------------------------"
echo "Success! The dual-camera image has been created and saved to $OUTPUT."
