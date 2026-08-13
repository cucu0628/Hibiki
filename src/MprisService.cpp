#include "MprisService.h"

#include "PlayerController.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QFileInfo>

MprisRootAdaptor::MprisRootAdaptor(QObject *parent)
    : QDBusAbstractAdaptor(parent) {}

void MprisRootAdaptor::Raise() {
  if (auto *service = qobject_cast<MprisService *>(parent()))
    emit service->raiseRequested();
}

void MprisRootAdaptor::Quit() {
  if (auto *service = qobject_cast<MprisService *>(parent()))
    emit service->quitRequested();
}

MprisPlayerAdaptor::MprisPlayerAdaptor(QObject *parent,
                                       PlayerController *player)
    : QDBusAbstractAdaptor(parent), m_player(player) {}

QString MprisPlayerAdaptor::playbackStatus() const {
  if (m_player->currentIndex() < 0)
    return QStringLiteral("Stopped");
  return m_player->playing() ? QStringLiteral("Playing")
                             : QStringLiteral("Paused");
}

QString MprisPlayerAdaptor::loopStatus() const {
  if (m_player->repeatMode() == 1)
    return QStringLiteral("Track");
  if (m_player->repeatMode() == 2)
    return QStringLiteral("Playlist");
  return QStringLiteral("None");
}

void MprisPlayerAdaptor::setLoopStatus(const QString &status) {
  if (status == QStringLiteral("Track"))
    m_player->setRepeatMode(1);
  else if (status == QStringLiteral("Playlist"))
    m_player->setRepeatMode(2);
  else
    m_player->setRepeatMode(0);
}

bool MprisPlayerAdaptor::shuffle() const { return m_player->shuffle(); }
void MprisPlayerAdaptor::setShuffle(bool enabled) {
  m_player->setShuffle(enabled);
}

QVariantMap MprisPlayerAdaptor::metadata() const {
  const QVariantMap track = m_player->currentTrack();
  if (track.isEmpty())
    return {};
  QVariantMap result;
  result[QStringLiteral("mpris:trackid")] = QVariant::fromValue(QDBusObjectPath(
      QStringLiteral("/org/hibiki/track/%1")
          .arg(track.value(QStringLiteral("id")).toLongLong())));
  result[QStringLiteral("mpris:length")] =
      track.value(QStringLiteral("duration")).toLongLong() * 1000;
  result[QStringLiteral("xesam:title")] = track.value(QStringLiteral("title"));
  result[QStringLiteral("xesam:artist")] =
      QStringList{track.value(QStringLiteral("artist")).toString()};
  result[QStringLiteral("xesam:album")] = track.value(QStringLiteral("album"));
  const QString cover = track.value(QStringLiteral("coverPath")).toString();
  if (!cover.isEmpty())
    result[QStringLiteral("mpris:artUrl")] =
        QUrl::fromLocalFile(cover).toString();
  const QString source = track.value(QStringLiteral("sourceUrl")).toString();
  if (!source.isEmpty())
    result[QStringLiteral("xesam:url")] = source;
  return result;
}

double MprisPlayerAdaptor::volume() const { return m_player->volume(); }
void MprisPlayerAdaptor::setVolume(double value) { m_player->setVolume(value); }
qlonglong MprisPlayerAdaptor::position() const {
  return m_player->position() * 1000;
}
bool MprisPlayerAdaptor::canGoNext() const {
  return m_player->currentIndex() >= 0;
}
bool MprisPlayerAdaptor::canGoPrevious() const {
  return m_player->currentIndex() >= 0;
}
bool MprisPlayerAdaptor::canPlay() const {
  return m_player->currentIndex() >= 0;
}
bool MprisPlayerAdaptor::canPause() const {
  return m_player->currentIndex() >= 0;
}
bool MprisPlayerAdaptor::canSeek() const { return m_player->duration() > 0; }
void MprisPlayerAdaptor::Next() { m_player->next(); }
void MprisPlayerAdaptor::Previous() { m_player->previous(); }
void MprisPlayerAdaptor::Pause() { m_player->pause(); }
void MprisPlayerAdaptor::PlayPause() { m_player->toggle(); }
void MprisPlayerAdaptor::Stop() {
  m_player->pause();
  m_player->seek(0);
}
void MprisPlayerAdaptor::Play() { m_player->play(); }
void MprisPlayerAdaptor::Seek(qlonglong offset) {
  m_player->seekRelative(offset / 1000);
  emit Seeked(m_player->position() * 1000);
}
void MprisPlayerAdaptor::SetPosition(const QDBusObjectPath &, qlonglong value) {
  m_player->seek(value / 1000);
  emit Seeked(m_player->position() * 1000);
}
void MprisPlayerAdaptor::OpenUri(const QString &) {}

MprisService::MprisService(PlayerController *player, QObject *parent)
    : QObject(parent), m_player(player) {
  new MprisRootAdaptor(this);
  m_playerAdaptor = new MprisPlayerAdaptor(this, player);

  connect(player, &PlayerController::trackChanged, this, [this] {
    sendPlayerProperties(
        {QStringLiteral("Metadata"), QStringLiteral("PlaybackStatus"),
         QStringLiteral("CanGoNext"), QStringLiteral("CanGoPrevious"),
         QStringLiteral("CanPlay"), QStringLiteral("CanPause"),
         QStringLiteral("CanSeek")});
  });
  connect(player, &PlayerController::playingChanged, this,
          [this] { sendPlayerProperties({QStringLiteral("PlaybackStatus")}); });
  connect(player, &PlayerController::durationChanged, this,
          [this] { sendPlayerProperties({QStringLiteral("CanSeek")}); });
  connect(player, &PlayerController::volumeChanged, this,
          [this] { sendPlayerProperties({QStringLiteral("Volume")}); });
  connect(player, &PlayerController::shuffleChanged, this,
          [this] { sendPlayerProperties({QStringLiteral("Shuffle")}); });
  connect(player, &PlayerController::repeatModeChanged, this,
          [this] { sendPlayerProperties({QStringLiteral("LoopStatus")}); });
}

void MprisService::sendPlayerProperties(const QStringList &propertyNames) {
  QVariantMap changed;
  for (const QString &name : propertyNames) {
    if (name == QStringLiteral("Metadata"))
      changed.insert(name, m_playerAdaptor->metadata());
    else if (name == QStringLiteral("PlaybackStatus"))
      changed.insert(name, m_playerAdaptor->playbackStatus());
    else if (name == QStringLiteral("LoopStatus"))
      changed.insert(name, m_playerAdaptor->loopStatus());
    else if (name == QStringLiteral("Shuffle"))
      changed.insert(name, m_playerAdaptor->shuffle());
    else if (name == QStringLiteral("Volume"))
      changed.insert(name, m_playerAdaptor->volume());
    else if (name == QStringLiteral("CanGoNext"))
      changed.insert(name, m_playerAdaptor->canGoNext());
    else if (name == QStringLiteral("CanGoPrevious"))
      changed.insert(name, m_playerAdaptor->canGoPrevious());
    else if (name == QStringLiteral("CanPlay"))
      changed.insert(name, m_playerAdaptor->canPlay());
    else if (name == QStringLiteral("CanPause"))
      changed.insert(name, m_playerAdaptor->canPause());
    else if (name == QStringLiteral("CanSeek"))
      changed.insert(name, m_playerAdaptor->canSeek());
  }

  QDBusMessage message = QDBusMessage::createSignal(
      QStringLiteral("/org/mpris/MediaPlayer2"),
      QStringLiteral("org.freedesktop.DBus.Properties"),
      QStringLiteral("PropertiesChanged"));
  message << QStringLiteral("org.mpris.MediaPlayer2.Player") << changed
          << QStringList{};
  QDBusConnection::sessionBus().send(message);
}

bool MprisService::registerService() {
  QDBusConnection connection = QDBusConnection::sessionBus();
  const QString serviceName = QStringLiteral("org.mpris.MediaPlayer2.hibiki");
  if (!connection.registerService(serviceName))
    return false;
  return connection.registerObject(QStringLiteral("/org/mpris/MediaPlayer2"),
                                   this, QDBusConnection::ExportAdaptors);
}
