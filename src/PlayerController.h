#pragma once

#include <QAudioOutput>
#include <QMediaPlayer>
#include <QObject>
#include <QSettings>
#include <QTimer>
#include <QVariantMap>
#include <QVector>

class TrackModel;

class PlayerController final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString title READ title NOTIFY trackChanged)
  Q_PROPERTY(QString artist READ artist NOTIFY trackChanged)
  Q_PROPERTY(QString album READ album NOTIFY trackChanged)
  Q_PROPERTY(QUrl coverUrl READ coverUrl NOTIFY trackChanged)
  Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
  Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(bool shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
  Q_PROPERTY(int repeatMode READ repeatMode WRITE setRepeatMode NOTIFY
                 repeatModeChanged)
  Q_PROPERTY(int currentIndex READ currentIndex NOTIFY trackChanged)

public:
  explicit PlayerController(TrackModel *model, QObject *parent = nullptr);
  ~PlayerController() override;

  QString title() const;
  QString artist() const;
  QString album() const;
  QUrl coverUrl() const;
  bool playing() const;
  qint64 position() const { return m_player.position(); }
  qint64 duration() const { return m_player.duration(); }
  qreal volume() const { return m_audioOutput.volume(); }
  void setVolume(qreal volume);
  bool shuffle() const { return m_shuffle; }
  void setShuffle(bool enabled);
  int repeatMode() const { return m_repeatMode; }
  void setRepeatMode(int mode);
  int currentIndex() const { return m_currentIndex; }
  QVariantMap currentTrack() const { return m_currentTrack; }

  Q_INVOKABLE void playTrack(int index);
  Q_INVOKABLE void toggle();
  Q_INVOKABLE void play();
  Q_INVOKABLE void pause();
  Q_INVOKABLE void next();
  Q_INVOKABLE void previous();
  Q_INVOKABLE void seek(qint64 position);
  Q_INVOKABLE void seekRelative(qint64 offset);

signals:
  void trackChanged();
  void playingChanged();
  void positionChanged();
  void durationChanged();
  void volumeChanged();
  void shuffleChanged();
  void repeatModeChanged();
  void playbackError(const QString &message);

private:
  void loadCurrent(bool autoplay);
  void restorePlaybackState();
  void resolveCurrentIndex();
  void savePlaybackState();
  int nextIndex(bool forward) const;

  TrackModel *m_model;
  QMediaPlayer m_player;
  QAudioOutput m_audioOutput;
  QSettings m_settings;
  QTimer m_positionSaveTimer;
  QVariantMap m_currentTrack;
  QVector<int> m_history;
  int m_currentIndex{-1};
  qint64 m_pendingRestorePosition{-1};
  bool m_shuffle{false};
  int m_repeatMode{0};
};
