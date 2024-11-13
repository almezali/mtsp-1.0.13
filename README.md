                                                  
     ███╗   ███╗████████╗███████╗██████╗"     
     ████╗ ████║╚══██╔══╝██╔════╝██╔══██╗"     
     ██╔████╔██║   ██║   ███████╗██████╔╝"     
     ██║╚██╔╝██║   ██║   ╚════██║██╔═══╝"     
     ██║ ╚═╝ ██║   ██║   ███████║██║"          
     ╚═╝     ╚═╝   ╚═╝   ╚══════╝╚═╝"          
                                                  
Music Terminal Shell Player


# MTSP - Music Terminal Shell Player

A feature-rich, terminal-based music player designed for Linux distributions. MTSP provides an interactive interface for managing and playing music files directly from the terminal with various playback options.

## Features

- **Interactive Interface**: Browse and play music files from a dialog-based interface.
- **Playlist Management**: Create, load, save, and manage playlists.
- **Playback History**: Tracks and displays recently played files.
- **Multimedia Key Support**: Control playback with multimedia keys (Play/Pause, Next, Previous, Volume).
- **Volume Control**: Adjust volume directly within the app.
- **Repeat & Shuffle Modes**: Toggle repeat and shuffle for enhanced listening experience.

## Screenshots

### Main Interface
![Main Interface](https://github.com/almezali/mtsp-1.0.13/raw/main/Screenshot_01.png)

### Playlist Management
![Playlist Management](https://github.com/almezali/mtsp-1.0.13/raw/main/Screenshot_02.png)

## Requirements

Ensure the following dependencies are installed:
- `mpv`: Audio player backend.
- `socat`: For inter-process communication with mpv.
- `jq`: Command-line JSON processor.
- `dialog`: For building interactive text interfaces.
- `xdotool`: To capture multimedia key events.

### Installation

#### Debian/Ubuntu
```bash
sudo apt-get install mpv socat jq dialog xdotool
```

#### Fedora
```bash
sudo dnf install mpv socat jq dialog xdotool
```

#### Arch Linux
```bash
sudo pacman -S mpv socat jq dialog xdotool
```

#### openSUSE
```bash
sudo zypper install mpv socat jq dialog xdotool
```

#### Solus
```bash
sudo eopkg install mpv socat jq dialog xdotool
```

## Usage
Run the following command to start MTSP:
```bash
./music-player_v1.0.13.sh
```
