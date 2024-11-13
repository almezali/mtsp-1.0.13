#!/bin/bash

# MTSP - Music Terminal Shell Player
# Dependencies: mpv, socat, jq, dialog (for interactive interface), xdotool (for multimedia keys)

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# General variables
MUSIC_DIR="$HOME/Music"
CURRENT_TRACK=""
IS_PLAYING=0
REPEAT_MODE=0
SHUFFLE_MODE=0
PLAYLIST=()
HISTORY=()
PLAYLISTS_DIR="$HOME/.mtsp/playlists"
CONFIG_DIR="$HOME/.mtsp"
CURRENT_PLAYLIST=""
VOLUME=100

# Set up necessary directories
setup_directories() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$PLAYLISTS_DIR"
    touch "$CONFIG_DIR/history.txt"
    touch "$CONFIG_DIR/config.json"
}

# Check for dependencies
check_dependencies() {
    local missing_deps=0
    for cmd in mpv socat jq dialog xdotool; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: $cmd is not installed${NC}"
            missing_deps=1
        fi
    done
    
    if [ $missing_deps -eq 1 ]; then
        echo -e "${YELLOW}Please install the missing dependencies:${NC}"
        echo "sudo apt-get install mpv socat jq dialog xdotool"
        exit 1
    fi
}

# Display program banner
show_banner() {
    echo -e "${GREEN}"
    echo "███╗   ███╗████████╗███████╗██████╗"
    echo "████╗ ████║╚══██╔══╝██╔════╝██╔══██╗"
    echo "██╔████╔██║   ██║   ███████╗██████╔╝"
    echo "██║╚██╔╝██║   ██║   ╚════██║██╔═══╝"
    echo "██║ ╚═╝ ██║   ██║   ███████║██║"
    echo "╚═╝     ╚═╝   ╚═╝   ╚══════╝╚═╝"
    echo -e "${NC}"
    echo "Music Terminal Shell Player v1.0.13"
    echo "--------------------------------"
}

# Browse files
browse_files() {
    local selected_file
    selected_file=$(dialog --title "Browse Music Files" \
                          --fselect "$MUSIC_DIR/" \
                          20 70 \
                          2>&1 >/dev/tty)
    
    if [ $? -eq 0 ] && [ -f "$selected_file" ]; then
        play_music "$selected_file"
    fi
}

# Manage playlists
manage_playlists() {
    local options=(
        "1" "Create a new playlist"
        "2" "Load a playlist"
        "3" "Add a track to the current playlist"
        "4" "View the current playlist"
        "5" "Save the current playlist"
    )
    
    local choice
    choice=$(dialog --title "Manage Playlists" \
                    --menu "Choose an operation:" \
                    15 60 5 \
                    "${options[@]}" \
                    2>&1 >/dev/tty)
    
    case $choice in
        1) create_playlist ;;
        2) load_playlist ;;
        3) add_to_playlist ;;
        4) show_current_playlist ;;
        5) save_playlist ;;
    esac
}

# Create a new playlist
create_playlist() {
    local name
    name=$(dialog --title "Create a New Playlist" \
                  --inputbox "Enter the playlist name:" \
                  8 40 \
                  2>&1 >/dev/tty)
    
    if [ $? -eq 0 ] && [ ! -z "$name" ]; then
        PLAYLIST=()
        CURRENT_PLAYLIST="$name"
        dialog --msgbox "Playlist created: $name" 6 40
    fi
}

# Load a playlist
load_playlist() {
    local playlists=()
    local files=("$PLAYLISTS_DIR"/*)
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            playlists+=("$(basename "$file")" "")
        fi
    done
    
    if [ ${#playlists[@]} -eq 0 ]; then
        dialog --msgbox "No playlists available" 6 40
        return
    fi
    
    local selected
    selected=$(dialog --title "Load Playlist" \
                     --menu "Choose a playlist:" \
                     15 60 5 \
                     "${playlists[@]}" \
                     2>&1 >/dev/tty)
    
    if [ $? -eq 0 ] && [ -f "$PLAYLISTS_DIR/$selected" ]; then
        mapfile -t PLAYLIST < "$PLAYLISTS_DIR/$selected"
        CURRENT_PLAYLIST="$selected"
        dialog --msgbox "Playlist loaded: $selected" 6 40
    fi
}

# Add to playlist
add_to_playlist() {
    if [ -z "$CURRENT_PLAYLIST" ]; then
        dialog --msgbox "No playlist is currently loaded." 6 40
        return
    fi
    
    local selected_file
    selected_file=$(dialog --title "Add to Playlist" \
                          --fselect "$MUSIC_DIR/" \
                          20 70 \
                          2>&1 >/dev/tty)
    
    if [ $? -eq 0 ] && [ -f "$selected_file" ]; then
        PLAYLIST+=("$selected_file")
        dialog --msgbox "Added $selected_file to the '$CURRENT_PLAYLIST' playlist." 6 60
    fi
}

# Show current playlist
show_current_playlist() {
    if [ -z "$CURRENT_PLAYLIST" ]; then
        dialog --msgbox "No playlist is currently loaded." 6 40
        return
    fi
    
    local playlist_content
    playlist_content=$(printf "%s\n" "${PLAYLIST[@]}")
    dialog --title "$CURRENT_PLAYLIST" \
           --msgbox "$playlist_content" \
           20 60
}

# Save playlist
save_playlist() {
    if [ -z "$CURRENT_PLAYLIST" ]; then
        dialog --msgbox "No playlist is currently loaded." 6 40
        return
    fi
    
    printf "%s\n" "${PLAYLIST[@]}" > "$PLAYLISTS_DIR/$CURRENT_PLAYLIST"
    dialog --msgbox "Playlist '$CURRENT_PLAYLIST' saved." 6 40
}

# Play music
play_music() {
    local file="$1"
    if [ -f "$file" ]; then
        if [ $IS_PLAYING -eq 1 ]; then
            pkill mpv
        fi
        
        CURRENT_TRACK="$file"
        mpv --no-video --input-ipc-server=/tmp/mpvsocket "$file" &
        IS_PLAYING=1
        add_to_history "$file"
        
        dialog --title "Playing" \
               --msgbox "Playing: $(basename "$file")" 6 60
    else
        dialog --msgbox "Error: File not found" 6 40
    fi
}

# Add to history
add_to_history() {
    local track="$1"
    echo "$track" >> "$CONFIG_DIR/history.txt"
    HISTORY+=("$track")
    if [ ${#HISTORY[@]} -gt 10 ]; then
        HISTORY=("${HISTORY[@]:1}")
        tail -n 10 "$CONFIG_DIR/history.txt" > "$CONFIG_DIR/history.txt.tmp"
        mv "$CONFIG_DIR/history.txt.tmp" "$CONFIG_DIR/history.txt"
    fi
}

# Show history
show_history() {
    local history_content
    history_content=$(cat "$CONFIG_DIR/history.txt" | nl | tac)
    dialog --title "Play History" \
           --msgbox "$history_content" \
           20 60
}

# Control volume
change_volume() {
    local change="$1"
    if [ "$change" = "+" ] && [ $VOLUME -lt 100 ]; then
        VOLUME=$((VOLUME + 5))
        mpv_command "set volume $VOLUME"
    elif [ "$change" = "-" ] && [ $VOLUME -gt 0 ]; then
        VOLUME=$((VOLUME - 5))
        mpv_command "set volume $VOLUME"
    fi
    
    dialog --title "Volume" \
           --msgbox "Volume: $VOLUME%" 6 40
}

# Handle multimedia key events
handle_multimedia_keys() {
    local key="$1"
    case $key in
        "XF86AudioPlay")
            toggle_playback
            ;;
        "XF86AudioNext")
            next_track
            ;;
        "XF86AudioPrev")
            previous_track
            ;;
        "XF86AudioRaiseVolume")
            change_volume "+"
            ;;
        "XF86AudioLowerVolume")
            change_volume "-"
            ;;
    esac
}

# Send commands to MPV
mpv_command() {
    echo "$1" | socat - /tmp/mpvsocket
}

# Toggle playback
toggle_playback() {
    if [ $IS_PLAYING -eq 1 ]; then
        mpv_command "cycle pause"
        dialog --msgbox "Paused" 6 40
    elif [ -n "$CURRENT_TRACK" ]; then
        play_music "$CURRENT_TRACK"
    fi
}

# Next track
next_track() {
    if [ $SHUFFLE_MODE -eq 1 ]; then
        play_music "${PLAYLIST[$RANDOM % ${#PLAYLIST[@]}]}"
    elif [ ${#PLAYLIST[@]} -gt 0 ]; then
        local index=$(printf '%s\n' "${PLAYLIST[@]}" | grep -n "$CURRENT_TRACK" | cut -d':' -f1)
        local next_index=$((index + 1))
        if [ $next_index -lt ${#PLAYLIST[@]} ]; then
            play_music "${PLAYLIST[$next_index]}"
        else
            play_music "${PLAYLIST[0]}"
        fi
    elif [ -n "$CURRENT_TRACK" ]; then
        play_music "$CURRENT_TRACK"
    fi
}

# Previous track
previous_track() {
    if [ $SHUFFLE_MODE -eq 1 ]; then
        play_music "${PLAYLIST[$RANDOM % ${#PLAYLIST[@]}]}"
    elif [ ${#PLAYLIST[@]} -gt 0 ]; then
        local index=$(printf '%s\n' "${PLAYLIST[@]}" | grep -n "$CURRENT_TRACK" | cut -d':' -f1)
        local prev_index=$((index - 1))
        if [ $prev_index -ge 0 ]; then
            play_music "${PLAYLIST[$prev_index]}"
        else
            play_music "${PLAYLIST[$((${#PLAYLIST[@]} - 1))]}"
        fi
    elif [ -n "$CURRENT_TRACK" ]; then
        play_music "$CURRENT_TRACK"
    fi
}

# Clean up and exit
cleanup_and_exit() {
    pkill mpv
    clear
    exit 0
}

# Main menu
show_main_menu() {
    local options=(
        "1" "Play/Pause"
        "2" "Next track"
        "3" "Previous track"
        "4" "Browse files"
        "5" "Manage playlists"
        "6" "Show history"
        "7" "Increase volume"
        "8" "Decrease volume"
        "9" "Exit"
    )
    
    local choice
    while true; do
        choice=$(dialog --title "MTSP - Main Menu" \
                       --menu "Choose an operation:" \
                       15 60 9 \
                       "${options[@]}" \
                       2>&1 >/dev/tty)
        
        case $choice in
            1) toggle_playback ;;
            2) next_track ;;
            3) previous_track ;;
            4) browse_files ;;
            5) manage_playlists ;;
            6) show_history ;;
            7) change_volume "+" ;;
            8) change_volume "-" ;;
            9) cleanup_and_exit ;;
            *) break ;;
        esac
    done
}

# Main function
main() {
    check_dependencies
    setup_directories
    show_banner
    
    # Listen for multimedia key events
    while true; do
        local key=$(xdotool waitkey --onlykey --delay 0 2>/dev/null)
        handle_multimedia_keys "$key"
        show_main_menu
    done
}

# Start the program
main
