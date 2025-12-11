#!/bin/bash

# ==============================================================================
# CODE-Lumer: Batch Code to Image Converter
# ==============================================================================

VERSION="1.0.0"

# --- Default Configuration ---
DEFAULT_WIDTH=1920
DEFAULT_FONT="Hack; Noto Color Emoji" # Fallback to Emoji font for icons
DEFAULT_FONT_SIZE=39
DEFAULT_THEME="Dracula" # Options: Dracula, Nord, Monokai Extended, etc.
DEFAULT_PAD_HORIZ=80
DEFAULT_PAD_VERT=100
DEFAULT_SHADOW_BLUR=30
DEFAULT_SHADOW_OFFSET_Y=10
DEFAULT_BG_COLOR="#282a36" # Matches Dracula background

# --- Variables ---
INPUT_PATH=""
OUTPUT_DIR="snapshots"
WIDTH="$DEFAULT_WIDTH"
FONT="$DEFAULT_FONT"
FONT_SIZE="$DEFAULT_FONT_SIZE"
THEME="$DEFAULT_THEME"
WINDOW_CONTROLS="true"
LINE_NUMBERS="true"

# --- Helper Functions ---

print_banner() {
    echo -e "\033[1;36m"
    
    echo "  $$$$$$\                  $$\            "
    echo " $$  __$$\                 $$ |           "
    echo " $$ /  \__| $$$$$$\   $$$$$$$ | $$$$$$\   "
    echo " $$ |      $$  __$$\ $$  __$$ |$$  __$$\  "
    echo " $$ |      $$ /  $$ |$$ /  $$ |$$$$$$$$ | "
    echo " $$ |  $$\ $$ |  $$ |$$ |  $$ |$$   ____| "
    echo " \$$$$$$  |\$$$$$$  |\$$$$$$$ |\$$$$$$$\  "
    echo "  \______/  \______/  \_______| \_______| "
    echo "                                          "
    echo "                                          "
    echo "                                          "
    echo " $$\                                                  "
    echo " $$ |                                                 "
    echo " $$ |     $$\   $$\ $$$$$$\$$$$\   $$$$$$\   $$$$$$\  "
    echo " $$ |     $$ |  $$ |$$  _$$  _$$\ $$  __$$\ $$  __$$\ "
    echo " $$ |     $$ |  $$ |$$ / $$ / $$ |$$$$$$$$ |$$ |  \__|"
    echo " $$ |     $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |      "
    echo " $$$$$$$$\\$$$$$$  |$$ | $$ | $$ |\$$$$$$$\ $$ |      "
    echo " \________|\______/ \__| \__| \__| \_______|\__|      "
    echo "                                                      "
    echo "                                                      "
    echo "                                                      "

    echo -e "  v$VERSION | Code Lumer Screenshots\033[0m"
    echo ""
}

show_help() {
    print_banner
    echo "Usage: $(basename "$0") [OPTIONS] <FILE_OR_DIRECTORY>"
    echo ""
    echo "Options:"
    echo "  -w, --width <px>       Output image width (default: $DEFAULT_WIDTH)"
    echo "  -f, --font <name>      Font family (default: '$DEFAULT_FONT')"
    echo "  -s, --size <pt>        Font size (default: $DEFAULT_FONT_SIZE)"
    echo "  -t, --theme <name>     Syntax theme (default: $DEFAULT_THEME)"
    echo "  -o, --output <dir>     Output directory (default: ./snapshots)"
    echo "  --no-window            Disable macOS-style window controls"
    echo "  --no-line-numbers      Disable line numbers"
    echo "  --list-themes          List available themes"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") main.py"
    echo "  $(basename "$0") -w 2560 -t Nord ./src/"
    echo ""
}

check_dependencies() {
    if ! command -v silicon &> /dev/null; then
        echo -e "\033[1;31m[Error] 'silicon' is not installed.\033[0m"
        echo "Please install it via: 'brew install silicon' or 'cargo install silicon'"
        exit 1
    fi
}

list_themes() {
    echo -e "\033[1;32mAvailable Themes:\033[0m"
    silicon --list-themes
    exit 0
}

generate_screenshot() {
    local file="$1"
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    local output_file="${OUTPUT_DIR}/${filename%.*}.png"

    # Skip non-text files or binary files loosely
    if [[ "$extension" == "png" || "$extension" == "jpg" || "$extension" == "exe" ]]; then
        return
    fi

    echo -e "Processing: \033[0;33m$file\033[0m -> $output_file"

    local FONT_ARG="$FONT:$FONT_SIZE"
    
    # Build the argument list
    local args=(
        "--font" "$FONT_ARG"
        "--theme" "$THEME"
        "--pad-horiz" "$DEFAULT_PAD_HORIZ"
        "--pad-vert" "$DEFAULT_PAD_VERT"
        "--shadow-blur-radius" "$DEFAULT_SHADOW_BLUR"
        "--shadow-offset-y" "$DEFAULT_SHADOW_OFFSET_Y"
        "--background" "$DEFAULT_BG_COLOR"
        "--output" "$output_file"
    )


    # Line Numbers Logic
    if [ "$LINE_NUMBERS" == "false" ]; then
        args+=("--no-line-number")
    fi

    # Width Logic: Silicon doesn't stretch text, it pads background. 
    # To enforce a minimum width, we calculate padding dynamically? 
    # No, silicon handles background fill.
    # Note: Silicon uses automatic width based on text usually, 
    # but we can assume the background color fills the view.

    # Execute generation
    silicon "${args[@]}" "$file"
}

# --- Main Logic ---

check_dependencies

# Argument Parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--width) WIDTH="$2"; shift 2 ;;
        -f|--font) FONT="$2"; shift 2 ;;
        -s|--size) FONT_SIZE="$2"; shift 2 ;;
        -t|--theme) THEME="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        --no-window) WINDOW_CONTROLS="false"; shift ;;
        --no-line-numbers) LINE_NUMBERS="false"; shift ;;
        --list-themes) list_themes ;;
        -h|--help) show_help; exit 0 ;;
        -*|--*) echo "Unknown option $1"; exit 1 ;;
        *) INPUT_PATH="$1"; shift ;;
    esac
done

if [ -z "$INPUT_PATH" ]; then
    echo -e "\033[1;31m[Error] No input file or directory provided.\033[0m"
    show_help
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

print_banner

if [ -f "$INPUT_PATH" ]; then
    # Single File Mode
    generate_screenshot "$INPUT_PATH"
elif [ -d "$INPUT_PATH" ]; then
    # Directory Mode (Read ALL files, excluding directories themselves)
    echo -e "Scanning directory: \033[1;34m$INPUT_PATH\033[0m (Reading all files)"
    
    # FIND: Find only files (-type f) up to 2 levels deep, excluding the output directory
    find "$INPUT_PATH" -maxdepth 2 -type f -not -path "$OUTPUT_DIR/*" | while read -r file; do
        generate_screenshot "$file"
    done
else
    echo "Error: Input path does not exist."
    exit 1
fi

echo ""
echo -e "\033[1;32mDone! Screenshots saved in '$OUTPUT_DIR'\033[0m"
