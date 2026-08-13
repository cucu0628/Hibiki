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

Downloads are stored under the XDG Music directory in `hibiki`. Application metadata is stored in the XDG application data directory.

**Now Playing** is a full-size stage for the current track with large cover art, track details, transport controls, timeline and volume.

The window opens with the library already read from the database; the music directory is scanned on a worker thread afterwards and only files whose size or modification time changed are read again. New downloads therefore appear without a visible pause, and startup does not wait for the disk.

The interface follows the active Vellum Shell theme from `~/.config/quickshell/vellum_shell` and its visual language: square corners, hairline borders, accent section titles, and accent-filled primary controls. If the shell is unavailable, the Rose Pine palette is used.

## Discord Rich Presence

Create an application at `https://discord.com/developers/applications`, copy its Application ID, then enter it under **Settings > Discord RPC**. The integration can be disabled at any time and connects only to the local Discord or Vesktop IPC socket.

Only download media you are authorized to save and follow the applicable service terms and copyright laws.
