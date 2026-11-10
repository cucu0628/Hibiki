#pragma once

#include <QAudioOutput>
#include <QMediaPlayer>
#include <QObject>
#include <QSettings>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

#include <memory>

class QAudioBuffer;
class QAudioBufferOutput;
class TrackModel;

class PlayerController final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString title READ title NOTIFY trackChanged)
  Q_PROPERTY(QString artist READ artist NOTIFY trackChanged)
  Q_PROPERTY(QString album READ album NOTIFY trackChanged)
  Q_PROPERTY(QUrl coverUrl READ coverUrl NOTIFY trackChanged)
  Q_PROPERTY(QString coverPath READ coverPath NOTIFY trackChanged)
  Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
  Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
  Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
  Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
  Q_PROPERTY(bool shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
  Q_PROPERTY(int repeatMode READ repeatMode WRITE setRepeatMode NOTIFY
                 repeatModeChanged)
  Q_PROPERTY(int currentIndex READ currentIndex NOTIFY trackChanged)
  Q_PROPERTY(QString currentFilePath READ currentFilePath NOTIFY trackChanged)
  Q_PROPERTY(QVariantList visualizerLevels READ visualizerLevels NOTIFY
                 visualizerLevelsChanged)

public:
  explicit PlayerController(TrackModel *model, QObject *parent = nullptr);
  ~PlayerController() override;

  QString title() const;
  QString artist() const;
  QString album() const;
  QUrl coverUrl() const;
  QString coverPath() const;
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
  QString currentFilePath() const;
  QVariantList visualizerLevels() const { return m_visualizerLevels; }
  QVariantMap currentTrack() const { return m_currentTrack; }
  // Audio analysis only runs while something can show the levels.
  void setVisualizerActive(bool active);

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
  void visualizerLevelsChanged();
  void playbackError(const QString &message);

private:
  void loadCurrent(bool autoplay);
  void playQueueIndex(int index);
  void restorePlaybackState();
  void resolveCurrentIndex();
  void savePlaybackState();
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
  void analyzeAudioBuffer(const QAudioBuffer &buffer);
#endif
  int nextIndex(bool forward) const;

  TrackModel *m_model;
  QMediaPlayer m_player;
  QAudioOutput m_audioOutput;
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
  std::unique_ptr<QAudioBufferOutput> m_audioBufferOutput;
#endif
  QSettings m_settings;
  QTimer m_positionSaveTimer;
  QVariantMap m_currentTrack;
  QVariantList m_queue;
  QVector<int> m_history;
  QVariantList m_visualizerLevels{0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
  int m_currentIndex{-1};
  qint64 m_pendingRestorePosition{-1};
  bool m_shuffle{false};
  int m_repeatMode{0};
};
