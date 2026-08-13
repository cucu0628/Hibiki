#include "ApplicationController.h"

#include "DiscordPresence.h"
#include "DownloadManager.h"
#include "MprisService.h"
#include "PlayerController.h"
#include "ThemeManager.h"
#include "TrackModel.h"
#include "TrayController.h"

#include <QApplication>
#include <QDir>
#include <QQmlApplicationEngine>
#include <QStandardPaths>
#include <QTimer>

ApplicationController::ApplicationController(QQmlApplicationEngine *engine,
                                             QObject *parent)
    : QObject(parent), m_engine(engine) {}

ApplicationController::~ApplicationController() = default;

bool ApplicationController::initialize() {
  QString musicRoot =
      QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
  if (musicRoot.isEmpty())
    musicRoot = QDir::homePath() + QStringLiteral("/Music");
  m_musicDirectory = musicRoot + QStringLiteral("/hibiki");
  const QString dataDirectory =
      QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation);
  if (!QDir().mkpath(m_musicDirectory) || !QDir().mkpath(dataDirectory))
    return false;

  m_theme = std::make_unique<ThemeManager>();

  m_tracks = std::make_unique<TrackModel>();
  if (!m_tracks->initialize(dataDirectory + QStringLiteral("/library.sqlite"),
                            m_musicDirectory))
    return false;
  m_player = std::make_unique<PlayerController>(m_tracks.get());
  m_downloads = std::make_unique<DownloadManager>(m_musicDirectory);
  m_discord = std::make_unique<DiscordPresence>(m_player.get());
  m_tray = std::make_unique<TrayController>(m_player.get());
  m_mpris = std::make_unique<MprisService>(m_player.get());
  m_mpris->registerService();

  connect(m_downloads.get(), &DownloadManager::libraryChanged, m_tracks.get(),
          &TrackModel::rescan);
  connect(m_downloads.get(), &DownloadManager::notificationRequested,
          m_tray.get(), &TrayController::notify);
  connect(m_player.get(), &PlayerController::playbackError, this,
          [this](const QString &error) {
            m_tray->notify(QStringLiteral("Playback error"), error);
          });
  connect(m_tray.get(), &TrayController::quitRequested, this,
          &ApplicationController::quit);
  connect(m_mpris.get(), &MprisService::raiseRequested, m_tray.get(),
          &TrayController::showWindow);
  connect(m_mpris.get(), &MprisService::quitRequested, this,
          &ApplicationController::quit);

  // The disk scan only refines what the database already provided, so it waits
  // for the event loop and therefore for the first frame.
  QTimer::singleShot(0, m_tracks.get(), &TrackModel::rescan);
  return true;
}

TrackModel *ApplicationController::tracks() const { return m_tracks.get(); }
PlayerController *ApplicationController::player() const {
  return m_player.get();
}
DownloadManager *ApplicationController::downloads() const {
  return m_downloads.get();
}
DiscordPresence *ApplicationController::discord() const {
  return m_discord.get();
}
ThemeManager *ApplicationController::theme() const { return m_theme.get(); }

void ApplicationController::windowReady(QObject *window) {
  m_window = window;
  m_tray->setWindow(window);
}

void ApplicationController::hideToTray() {
  if (m_window)
    m_window->setProperty("visible", false);
}

void ApplicationController::quit() { QApplication::quit(); }
