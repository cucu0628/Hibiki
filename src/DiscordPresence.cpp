#include "DiscordPresence.h"

#include "PlayerController.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>
#include <QtEndian>

#include <cstring>
#include <utility>

namespace {
constexpr qint64 activityRateLimitMs = 4000;
constexpr int activityDebounceMs = 400;

QString cleanTrackTitle(QString title) {
  static const QRegularExpression promotionalSuffix(
      QStringLiteral(
          "\\s*[\\[(](?:official\\s+)?(?:music\\s+video|lyric\\s+video|"
          "lyrics?\\s+video|audio|video|visuali[sz]er|lyrics?|"
          "4k\\s+remaster)[^\\])]*[\\])]\\s*$"),
      QRegularExpression::CaseInsensitiveOption);
  while (title.contains(promotionalSuffix))
    title.remove(promotionalSuffix);
  return title.simplified();
}

QString spacedArtist(QString artist) {
  if (!artist.contains(QLatin1Char(' '))) {
    static const QRegularExpression camelCaseBoundary(
        QStringLiteral("([a-z])([A-Z])"));
    artist.replace(camelCaseBoundary, QStringLiteral("\\1 \\2"));
  }
  return artist.simplified();
}
} // namespace

DiscordPresence::DiscordPresence(PlayerController *player, QObject *parent)
    : QObject(parent), m_player(player),
      m_settings(QStringLiteral("Hibiki"), QStringLiteral("Hibiki")) {
  m_enabled =
      m_settings.value(QStringLiteral("discord/enabled"), false).toBool();
  m_applicationId =
      m_settings.value(QStringLiteral("discord/applicationId")).toString();

  m_retryTimer.setSingleShot(true);
  m_retryTimer.setInterval(10000);
  m_handshakeTimer.setSingleShot(true);
  m_handshakeTimer.setInterval(5000);
  m_updateTimer.setSingleShot(true);
  m_updateTimer.setInterval(activityDebounceMs);

  connect(&m_retryTimer, &QTimer::timeout, this,
          &DiscordPresence::connectToDiscord);
  connect(&m_handshakeTimer, &QTimer::timeout, this,
          &DiscordPresence::tryNextSocket);
  connect(&m_updateTimer, &QTimer::timeout, this,
          &DiscordPresence::sendActivity);
  connect(&m_socket, &QLocalSocket::connected, this, [this] {
    m_retryTimer.stop();
    setStatus(QStringLiteral("Connecting to Discord"));
    m_handshakeTimer.start();
    sendFrame(0, {{QStringLiteral("v"), 1},
                  {QStringLiteral("client_id"), m_applicationId}});
  });
  connect(&m_socket, &QLocalSocket::readyRead, this,
          &DiscordPresence::processIncoming);
  connect(&m_socket, &QLocalSocket::errorOccurred, this,
          [this](QLocalSocket::LocalSocketError) {
            if (m_tryingSockets) {
              tryNextSocket();
              return;
            }
            setReady(false);
            if (m_enabled) {
              setStatus(QStringLiteral("Discord is not running"));
              m_retryTimer.start();
            }
          });
  connect(&m_socket, &QLocalSocket::disconnected, this, [this] {
    setReady(false);
    if (m_enabled && !m_tryingSockets) {
      setStatus(QStringLiteral("Discord disconnected"));
      m_retryTimer.start();
    }
  });

  connect(player, &PlayerController::trackChanged, this,
          &DiscordPresence::scheduleActivityUpdate);
  connect(player, &PlayerController::playingChanged, this,
          &DiscordPresence::scheduleActivityUpdate);

  if (m_enabled)
    connectToDiscord();
}

void DiscordPresence::setEnabled(bool enabled) {
  if (m_enabled == enabled)
    return;
  m_enabled = enabled;
  m_settings.setValue(QStringLiteral("discord/enabled"), enabled);
  emit enabledChanged();
  if (enabled) {
    connectToDiscord();
  } else {
    m_retryTimer.stop();
    m_handshakeTimer.stop();
    m_updateTimer.stop();
    m_tryingSockets = false;
    clearActivity();
    m_socket.flush();
    m_socket.disconnectFromServer();
    setReady(false);
    setStatus(QStringLiteral("Disabled"));
  }
}

void DiscordPresence::setApplicationId(const QString &applicationId) {
  const QString normalized = applicationId.trimmed();
  if (m_applicationId == normalized)
    return;
  m_applicationId = normalized;
  m_settings.setValue(QStringLiteral("discord/applicationId"), normalized);
  emit applicationIdChanged();
  if (m_enabled)
    reconnect();
}

void DiscordPresence::reconnect() {
  m_retryTimer.stop();
  m_handshakeTimer.stop();
  m_updateTimer.stop();
  m_tryingSockets = true;
  m_socket.abort();
  m_tryingSockets = false;
  setReady(false);
  if (m_enabled)
    connectToDiscord();
}

void DiscordPresence::connectToDiscord() {
  if (!m_enabled)
    return;
  if (m_ready || m_socket.state() == QLocalSocket::ConnectedState ||
      m_socket.state() == QLocalSocket::ConnectingState)
    return;
  static const QRegularExpression applicationIdPattern(
      QStringLiteral("^[0-9]{17,20}$"));
  if (!applicationIdPattern.match(m_applicationId).hasMatch()) {
    setStatus(QStringLiteral("Enter a valid Discord Application ID"));
    return;
  }

  m_candidates = socketCandidates();
  m_candidateIndex = 0;
  m_tryingSockets = true;
  setStatus(QStringLiteral("Looking for Discord"));
  tryNextSocket();
}

void DiscordPresence::tryNextSocket() {
  m_handshakeTimer.stop();
  m_socket.abort();
  m_buffer.clear();
  if (m_candidateIndex >= m_candidates.size()) {
    m_tryingSockets = false;
    setStatus(m_candidates.isEmpty()
                  ? QStringLiteral("Discord is not running")
                  : QStringLiteral("Discord IPC did not respond"));
    m_retryTimer.start();
    return;
  }
  m_socket.connectToServer(m_candidates.at(m_candidateIndex++),
                           QIODevice::ReadWrite);
}

QStringList DiscordPresence::socketCandidates() const {
  QStringList directories;
  const QString runtime =
      QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
  if (!runtime.isEmpty()) {
    directories << runtime
                << runtime + QStringLiteral("/app/com.discordapp.Discord")
                << runtime + QStringLiteral("/app/dev.vencord.Vesktop");
  }
  directories << QDir::tempPath();

  QStringList candidates;
  for (const QString &directory : std::as_const(directories)) {
    for (int index = 0; index < 10; ++index) {
      const QString candidate =
          directory + QStringLiteral("/discord-ipc-%1").arg(index);
      if (QFileInfo::exists(candidate))
        candidates << candidate;
    }
  }
  return candidates;
}

void DiscordPresence::sendFrame(quint32 opcode, const QJsonObject &payload) {
  if (m_socket.state() != QLocalSocket::ConnectedState)
    return;
  const QByteArray json = QJsonDocument(payload).toJson(QJsonDocument::Compact);
  QByteArray frame(8, Qt::Uninitialized);
  qToLittleEndian(opcode, frame.data());
  qToLittleEndian(static_cast<quint32>(json.size()), frame.data() + 4);
  frame.append(json);
  m_socket.write(frame);
  m_socket.flush();
}

void DiscordPresence::processIncoming() {
  m_buffer += m_socket.readAll();
  while (m_buffer.size() >= 8) {
    const quint32 opcode = qFromLittleEndian<quint32>(m_buffer.constData());
    const quint32 length = qFromLittleEndian<quint32>(m_buffer.constData() + 4);
    if (m_buffer.size() < static_cast<qsizetype>(8 + length))
      return;
    const QByteArray payload = m_buffer.mid(8, length);
    m_buffer.remove(0, 8 + length);
    const QJsonObject message = QJsonDocument::fromJson(payload).object();
    if (opcode == 2) {
      const QString reason =
          message.value(QStringLiteral("message"))
              .toString(QStringLiteral("Discord closed the IPC connection"));
      setStatus(reason);
      qWarning() << "Discord IPC closed:" << reason;
      m_socket.abort();
      continue;
    }
    const QString event = message.value(QStringLiteral("evt")).toString();
    if (event == QStringLiteral("READY")) {
      m_handshakeTimer.stop();
      m_tryingSockets = false;
      setReady(true);
      setStatus(QStringLiteral("Connected"));
      m_lastActivitySent.invalidate();
      scheduleActivityUpdate();
    } else if (event == QStringLiteral("ERROR")) {
      const QJsonObject data = message.value(QStringLiteral("data")).toObject();
      const QString error = data.value(QStringLiteral("message"))
                                .toString(QStringLiteral("Discord RPC error"));
      setStatus(error);
      qWarning() << "Discord RPC error:" << error << "code"
                 << data.value(QStringLiteral("code")).toInt();
      if (error.contains(QStringLiteral("rate"), Qt::CaseInsensitive) ||
          data.value(QStringLiteral("code")).toInt() == 4008) {
        // Retry once the Discord rate-limit window has passed. The activity
        // is rebuilt from the current player state when this timer fires.
        m_updateTimer.start(static_cast<int>(activityRateLimitMs + 500));
      }
    } else if (event.isEmpty() &&
               message.value(QStringLiteral("cmd")).toString() ==
                   QStringLiteral("SET_ACTIVITY")) {
      setStatus(QStringLiteral("Connected"));
    }
  }
}

void DiscordPresence::scheduleActivityUpdate() {
  if (!m_enabled || !m_ready || m_updateTimer.isActive())
    return;

  int delay = activityDebounceMs;
  if (m_lastActivitySent.isValid()) {
    const qint64 remaining = activityRateLimitMs - m_lastActivitySent.elapsed();
    if (remaining > delay)
      delay = static_cast<int>(remaining);
  }
  m_updateTimer.start(delay);
}

void DiscordPresence::sendActivity() {
  if (!m_enabled || !m_ready)
    return;
  const QVariantMap track = m_player->currentTrack();
  if (track.isEmpty()) {
    clearActivity();
    return;
  }

  QString title = track.value(QStringLiteral("title")).toString();
  QString artist = track.value(QStringLiteral("artist")).toString();
  const qsizetype separator = title.indexOf(QStringLiteral(" - "));
  if (separator > 0) {
    artist = title.left(separator).simplified();
    title = title.mid(separator + 3);
  }
  title = cleanTrackTitle(title);
  artist = spacedArtist(artist);

  const bool isPlaying = m_player->playing();
  QJsonObject activity{
      {QStringLiteral("type"), isPlaying ? 2 : 0},
      {QStringLiteral("details"),
       title.size() >= 2 ? title.left(128) : QStringLiteral("Unknown track")},
      {QStringLiteral("instance"), false}};
  if (artist.size() >= 2) {
    activity.insert(QStringLiteral("state"),
                    isPlaying
                        ? artist.left(128)
                        : QStringLiteral("Paused - %1").arg(artist).left(128));
  } else if (!isPlaying) {
    activity.insert(QStringLiteral("state"), QStringLiteral("Paused"));
  }

  const QString sourceId = track.value(QStringLiteral("sourceId")).toString();
  static const QRegularExpression youtubeIdPattern(
      QStringLiteral("^[A-Za-z0-9_-]{6,}$"));
  if (youtubeIdPattern.match(sourceId).hasMatch()) {
    const QString artworkUrl =
        QStringLiteral("https://i.ytimg.com/vi/%1/hqdefault.jpg").arg(sourceId);
    activity.insert(
        QStringLiteral("assets"),
        QJsonObject{{QStringLiteral("large_image"), artworkUrl},
                    {QStringLiteral("large_text"), title.left(128)}});
  }

  if (isPlaying) {
    const qint64 started =
        QDateTime::currentSecsSinceEpoch() - (m_player->position() / 1000);
    activity.insert(QStringLiteral("timestamps"),
                    QJsonObject{{QStringLiteral("start"), started}});
  }

  const QString sourceUrl = track.value(QStringLiteral("sourceUrl")).toString();
  if (QUrl(sourceUrl).scheme().startsWith(QStringLiteral("http"))) {
    activity.insert(
        QStringLiteral("buttons"),
        QJsonArray{QJsonObject{
            {QStringLiteral("label"), QStringLiteral("Open on YouTube")},
            {QStringLiteral("url"), sourceUrl}}});
  }

  sendFrame(
      1,
      {{QStringLiteral("cmd"), QStringLiteral("SET_ACTIVITY")},
       {QStringLiteral("args"),
        QJsonObject{{QStringLiteral("pid"),
                     static_cast<qint64>(QCoreApplication::applicationPid())},
                    {QStringLiteral("activity"), activity}}},
       {QStringLiteral("nonce"), QString::number(++m_nonce)}});
  m_lastActivitySent.restart();
}

void DiscordPresence::clearActivity() {
  if (!m_ready)
    return;
  sendFrame(1,
            {{QStringLiteral("cmd"), QStringLiteral("SET_ACTIVITY")},
             {QStringLiteral("args"),
              QJsonObject{
                  {QStringLiteral("pid"),
                   static_cast<qint64>(QCoreApplication::applicationPid())},
                  {QStringLiteral("activity"), QJsonValue(QJsonValue::Null)}}},
             {QStringLiteral("nonce"), QString::number(++m_nonce)}});
  m_lastActivitySent.restart();
}

void DiscordPresence::setReady(bool ready) {
  if (m_ready == ready)
    return;
  m_ready = ready;
  emit connectedChanged();
}

void DiscordPresence::setStatus(const QString &status) {
  if (m_status == status)
    return;
  m_status = status;
  emit statusChanged();
}
