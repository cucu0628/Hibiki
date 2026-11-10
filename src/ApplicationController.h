#pragma once

#include <QObject>

#include <memory>

class DownloadManager;
class DiscordPresence;
class MprisService;
class PlayerController;
class QQmlApplicationEngine;
class QQuickWindow;
class ThemeManager;
class TrackModel;
class TrayController;

class ApplicationController final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString musicDirectory READ musicDirectory CONSTANT)

public:
  explicit ApplicationController(QQmlApplicationEngine *engine,
                                 QObject *parent = nullptr);
  ~ApplicationController() override;

  bool initialize();
  QString musicDirectory() const { return m_musicDirectory; }

  TrackModel *tracks() const;
  PlayerController *player() const;
  DownloadManager *downloads() const;
  DiscordPresence *discord() const;
  ThemeManager *theme() const;

  Q_INVOKABLE void windowReady(QObject *window);
  Q_INVOKABLE void hideToTray();
  Q_INVOKABLE void quit();

private:
  void releaseHiddenWindow(QQuickWindow *window);

  QQmlApplicationEngine *m_engine;
  QString m_musicDirectory;
  std::unique_ptr<TrackModel> m_tracks;
  std::unique_ptr<PlayerController> m_player;
  std::unique_ptr<DownloadManager> m_downloads;
  std::unique_ptr<DiscordPresence> m_discord;
  std::unique_ptr<ThemeManager> m_theme;
  std::unique_ptr<TrayController> m_tray;
  std::unique_ptr<MprisService> m_mpris;
  QObject *m_window{nullptr};
};
