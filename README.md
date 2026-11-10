# Hibiki

Hibiki is a Qt 6 music player for Linux. It downloads YouTube videos and playlists as Opus audio, keeps a local library with cover art, integrates with MPRIS, and continues playing in the system tray.

## Requirements

- Qt 6.7 or newer with Quick, Multimedia, SQL, DBus, Concurrent, and Widgets
- CMake 3.24 or newer
- `yt-dlp`
- FFmpeg

## Build

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build --output-on-failure
./build/hibiki
```

To install the release build for the current user:

```sh
cmake --install build --prefix ~/.local
```

Downloads are stored under the XDG Music directory in `hibiki`. Application metadata is stored in the XDG application data directory.

**Now Playing** is a full-size stage for the current track with large cover art, track details, transport controls, timeline and volume.

Create playlists with the **+** button in the sidebar. Use the playlist button on a track to add it to any list, or open a list to remove tracks, rename it, and delete it. Playlists are saved in the library database; deleting one leaves the audio files in your library. Playback started from a playlist follows that playlist's track order even if you switch views.

The window opens with the library already read from the database; the music directory is scanned on a worker thread afterwards and only files whose size or modification time changed are read again. New downloads therefore appear without a visible pause, and startup does not wait for the disk.

The interface follows Vellum Shell's look and its active palette. It reads the theme slug from `~/.config/quickshell/vellum_shell/current-theme` (or `$VELLUM_SHELL_DIR`) and the colors from `themes/<slug>/theme.conf`, and updates when either file changes. Icons come from the Symbols Nerd Font that Vellum Shell installs. If Vellum Shell is unavailable, a Catppuccin Mocha palette is used.

The layout is built for a small window: below 620 px the page tabs collapse to icons, and from 1180 px the library shows the full player beside it. Shortcuts: Space plays or pauses, Ctrl+F searches the library, Ctrl+1–4 switch pages.

## Discord Rich Presence

Create an application at `https://discord.com/developers/applications`, copy its Application ID, then enter it under **Settings > Discord RPC**. The integration can be disabled at any time and connects only to the local Discord or Vesktop IPC socket.

Only download media you are authorized to save and follow the applicable service terms and copyright laws.
