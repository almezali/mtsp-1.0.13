#!/bin/bash

# MTSP - Music Terminal Shell Player
# Dependencies: mpv, socat, jq, dialog (للواجهة التفاعلية)

# الألوان والتنسيق
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# المتغيرات العامة
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

# إنشاء المجلدات اللازمة
setup_directories() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$PLAYLISTS_DIR"
    touch "$CONFIG_DIR/history.txt"
    touch "$CONFIG_DIR/config.json"
}

# التحقق من المتطلبات
check_dependencies() {
    local missing_deps=0
    for cmd in mpv socat jq dialog; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}خطأ: $cmd غير مثبت${NC}"
            missing_deps=1
        fi
    done
    
    if [ $missing_deps -eq 1 ]; then
        echo -e "${YELLOW}الرجاء تثبيت المتطلبات المفقودة:${NC}"
        echo "sudo apt-get install mpv socat jq dialog"
        exit 1
    fi
}

# عرض شعار البرنامج
show_banner() {
    echo -e "${GREEN}"
    echo "███╗   ███╗████████╗███████╗██████╗"
    echo "████╗ ████║╚══██╔══╝██╔════╝██╔══██╗"
    echo "██╔████╔██║   ██║   ███████╗██████╔╝"
    echo "██║╚██╔╝██║   ██║   ╚════██║██╔═══╝"
    echo "██║ ╚═╝ ██║   ██║   ███████║██║"
    echo "╚═╝     ╚═╝   ╚═╝   ╚══════╝╚═╝"
    echo -e "${NC}"
    echo "Music Terminal Shell Player v0.2.0"
    echo "--------------------------------"
}

# استعراض الملفات
browse_files() {
    local selected_file
    selected_file=$(dialog --title "استعراض الملفات الموسيقية" \
                          --fselect "$MUSIC_DIR/" \
                          20 70 \
                          2>&1 >/dev/tty)
    
    if [ $? -eq 0 ] && [ -f "$selected_file" ]; then
        play_music "$selected_file"
    fi
}

# إدارة قوائم التشغيل
manage_playlists() {
    local options=(
        "1" "إنشاء قائمة تشغيل جديدة"
        "2" "تحميل قائمة تشغيل"
        "3" "إضافة مسار إلى قائمة التشغيل الحالية"
        "4" "عرض قائمة التشغيل الحالية"
        "5" "حفظ قائمة التشغيل الحالية"
    )
    
    local choice
    choice=$(dialog --title "إدارة قوائم التشغيل" \
                    --menu "اختر عملية:" \
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

# إنشاء قائمة تشغيل جديدة
create_playlist() {
    local name
    name=$(dialog --title "إنشاء قائمة تشغيل جديدة" \
                  --inputbox "أدخل اسم قائمة التشغيل:" \
                  8 40 \
                  2>&1 >/dev/tty)
    
    if [ $? -eq 0 ] && [ ! -z "$name" ]; then
        PLAYLIST=()
        CURRENT_PLAYLIST="$name"
        dialog --msgbox "تم إنشاء قائمة التشغيل: $name" 6 40
    fi
}

# تحميل قائمة تشغيل
load_playlist() {
    local playlists=()
    local files=("$PLAYLISTS_DIR"/*)
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            playlists+=("$(basename "$file")" "")
        fi
    done
    
    if [ ${#playlists[@]} -eq 0 ]; then
        dialog --msgbox "لا توجد قوائم تشغيل متاحة" 6 40
        return
    fi
    
    local selected
    selected=$(dialog --title "تحميل قائمة تشغيل" \
                     --menu "اختر قائمة تشغيل:" \
                     15 60 5 \
                     "${playlists[@]}" \
                     2>&1 >/dev/tty)
    
    if [ $? -eq 0 ] && [ -f "$PLAYLISTS_DIR/$selected" ]; then
        mapfile -t PLAYLIST < "$PLAYLISTS_DIR/$selected"
        CURRENT_PLAYLIST="$selected"
        dialog --msgbox "تم تحميل قائمة التشغيل: $selected" 6 40
    fi
}

# تشغيل الموسيقى
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
        
        dialog --title "جارِ التشغيل" \
               --msgbox "جارِ تشغيل: $(basename "$file")" 6 60
    else
        dialog --msgbox "خطأ: الملف غير موجود" 6 40
    fi
}

# إضافة إلى السجل
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

# عرض السجل
show_history() {
    local history_content
    history_content=$(cat "$CONFIG_DIR/history.txt" | nl | tac)
    dialog --title "سجل التشغيل" \
           --msgbox "$history_content" \
           20 60
}

# التحكم في مستوى الصوت
change_volume() {
    local change="$1"
    if [ "$change" = "+" ] && [ $VOLUME -lt 100 ]; then
        VOLUME=$((VOLUME + 5))
        mpv_command "set volume $VOLUME"
    elif [ "$change" = "-" ] && [ $VOLUME -gt 0 ]; then
        VOLUME=$((VOLUME - 5))
        mpv_command "set volume $VOLUME"
    fi
    
    dialog --title "مستوى الصوت" \
           --msgbox "مستوى الصوت: $VOLUME%" 6 40
}

# إرسال الأوامر إلى MPV
mpv_command() {
    echo "$1" | socat - /tmp/mpvsocket
}

# القائمة الرئيسية
show_main_menu() {
    local options=(
        "1" "تشغيل/إيقاف مؤقت"
        "2" "المسار التالي"
        "3" "المسار السابق"
        "4" "استعراض الملفات"
        "5" "إدارة قوائم التشغيل"
        "6" "عرض السجل"
        "7" "رفع مستوى الصوت"
        "8" "خفض مستوى الصوت"
        "9" "خروج"
    )
    
    local choice
    while true; do
        choice=$(dialog --title "MTSP - القائمة الرئيسية" \
                       --menu "اختر عملية:" \
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

# تبديل حالة التشغيل
toggle_playback() {
    if [ $IS_PLAYING -eq 1 ]; then
        mpv_command "cycle pause"
        dialog --msgbox "تم الإيقاف المؤقت" 6 40
    elif [ -n "$CURRENT_TRACK" ]; then
        play_music "$CURRENT_TRACK"
    fi
}

# تنظيف وخروج
cleanup_and_exit() {
    pkill mpv
    clear
    exit 0
}

# الدالة الرئيسية
main() {
    check_dependencies
    setup_directories
    show_banner
    show_main_menu
}

# بدء البرنامج
main
