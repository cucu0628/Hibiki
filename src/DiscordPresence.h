#pragma once

#include <QElapsedTimer>
#include <QLocalSocket>
#include <QObject>
#include <QSettings>
#include <QTimer>

class PlayerController;
class QJsonObject;

class DiscordPresence final : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
  Q_PROPERTY(QString applicationId READ applicationId WRITE setApplicationId
                 NOTIFY applicationIdChanged)
  Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
  Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
  explicit DiscordPresence(PlayerController *player, QObject *parent = nullptr);

  bool enabled() const { return m_enabled; }
  void setEnabled(bool enabled);
  QString applicationId() const { return m_applicationId; }
  void setApplicationId(const QString &applicationId);
  bool connected() const { return m_ready; }
  QString status() const { return m_status; }

  Q_INVOKABLE void reconnect();

signals:
  void enabledChanged();
  void applicationIdChanged();
  void connectedChanged();
  void statusChanged();

private:
  void connectToDiscord();
  void tryNextSocket();
  void processIncoming();
  void sendFrame(quint32 opcode, const QJsonObject &payload);
  void scheduleActivityUpdate();
  void sendActivity();
  void clearActivity();
  void setReady(bool ready);
  void setStatus(const QString &status);
  QStringList socketCandidates() const;

  PlayerController *m_player;
  QLocalSocket m_socket;
  QSettings m_settings;
  QTimer m_retryTimer;
  QTimer m_handshakeTimer;
  QTimer m_updateTimer;
  QElapsedTimer m_lastActivitySent;
  QByteArray m_buffer;
  QStringList m_candidates;
  int m_candidateIndex{0};
  quint64 m_nonce{0};
  bool m_enabled{false};
  bool m_ready{false};
  bool m_tryingSockets{false};
  QString m_applicationId;
  QString m_status{QStringLiteral("Disabled")};
};
