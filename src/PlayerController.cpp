#include "PlayerController.h"

#include "TrackModel.h"

#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
#include <QAudioBuffer>
#include <QAudioBufferOutput>
#endif
#include <QFileInfo>
#include <QRandomGenerator>

#include <array>
#include <cmath>

PlayerController::PlayerController(TrackModel *model, QObject *parent)
    : QObject(parent), m_model(model),
      m_settings(QStringLiteral("Hibiki"), QStringLiteral("Hibiki")) {
  m_player.setAudioOutput(&m_audioOutput);
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
  m_audioBufferOutput = std::make_unique<QAudioBufferOutput>(this);
  m_player.setAudioBufferOutput(m_audioBufferOutput.get());
  connect(m_audioBufferOutput.get(), &QAudioBufferOutput::audioBufferReceived,
          this, &PlayerController::analyzeAudioBuffer);
#endif
  m_audioOutput.setVolume(
      m_settings.value(QStringLiteral("player/volume"), 0.72).toReal());
  m_shuffle =
      m_settings.value(QStringLiteral("player/shuffle"), false).toBool();
  m_repeatMode = m_settings.value(QStringLiteral("player/repeat"), 0).toInt();

  m_positionSaveTimer.setInterval(2000);
  connect(&m_positionSaveTimer, &QTimer::timeout, this,
          &PlayerController::savePlaybackState);
  m_positionSaveTimer.start();

  connect(&m_player, &QMediaPlayer::positionChanged, this,
          &PlayerController::positionChanged);
  connect(&m_player, &QMediaPlayer::durationChanged, this,
          &PlayerController::durationChanged);
  connect(&m_player, &QMediaPlayer::playbackStateChanged, this,
          [this](QMediaPlayer::PlaybackState state) {
            emit playingChanged();
            if (state != QMediaPlayer::PlayingState) {
              m_visualizerLevels = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
              emit visualizerLevelsChanged();
              savePlaybackState();
            }
          });
  connect(&m_audioOutput, &QAudioOutput::volumeChanged, this,
          &PlayerController::volumeChanged);
  // The library is now loaded from the database first and refined by a
  // background scan, so row numbers can move under the current track.
  connect(model, &QAbstractItemModel::modelReset, this,
          [this] { m_history.clear(); resolveCurrentIndex(); });
  connect(&m_player, &QMediaPlayer::errorOccurred, this,
          [this](QMediaPlayer::Error, const QString &message) {
            emit playbackError(message);
          });
  connect(&m_player, &QMediaPlayer::mediaStatusChanged, this,
          [this](QMediaPlayer::MediaStatus status) {
            if ((status == QMediaPlayer::LoadedMedia ||
                 status == QMediaPlayer::BufferedMedia) &&
                m_pendingRestorePosition >= 0) {
              const qint64 restoredPosition =
                  m_player.duration() > 0
                      ? qMin(m_pendingRestorePosition, m_player.duration())
                      : m_pendingRestorePosition;
              m_pendingRestorePosition = -1;
              m_player.setPosition(restoredPosition);
            }
            if (status == QMediaPlayer::EndOfMedia) {
              if (m_repeatMode == 1) {
                m_player.setPosition(0);
                m_player.play();
              } else {
                next();
              }
            }
          });
  restorePlaybackState();
}

PlayerController::~PlayerController() { savePlaybackState(); }

QString PlayerController::title() const {
  return m_currentTrack.value(QStringLiteral("title")).toString();
}
QString PlayerController::artist() const {
  return m_currentTrack.value(QStringLiteral("artist")).toString();
}
QString PlayerController::album() const {
  return m_currentTrack.value(QStringLiteral("album")).toString();
}
QUrl PlayerController::coverUrl() const {
  return QUrl::fromLocalFile(
      m_currentTrack.value(QStringLiteral("coverPath")).toString());
}
bool PlayerController::playing() const {
  return m_player.playbackState() == QMediaPlayer::PlayingState;
}

#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
void PlayerController::analyzeAudioBuffer(const QAudioBuffer &buffer) {
  const QAudioFormat format = buffer.format();
  const int channels = format.channelCount();
  const int frameCount = buffer.frameCount();
  if (!format.isValid() || channels <= 0 || frameCount <= 0)
    return;

  const int sampleFrames = qMin(frameCount, 1024);
  QVector<double> samples;
  samples.reserve(sampleFrames);

  auto appendSamples = [&](const auto *data, double scale, double offset) {
    for (int frame = 0; frame < sampleFrames; ++frame) {
      double mono = 0;
      for (int channel = 0; channel < channels; ++channel)
        mono += (static_cast<double>(data[frame * channels + channel]) -
                 offset) /
                scale;
      samples.append(mono / channels);
    }
  };

  switch (format.sampleFormat()) {
  case QAudioFormat::UInt8:
    appendSamples(buffer.constData<quint8>(), 128.0, 128.0);
    break;
  case QAudioFormat::Int16:
    appendSamples(buffer.constData<qint16>(), 32768.0, 0.0);
    break;
  case QAudioFormat::Int32:
    appendSamples(buffer.constData<qint32>(), 2147483648.0, 0.0);
    break;
  case QAudioFormat::Float:
    appendSamples(buffer.constData<float>(), 1.0, 0.0);
    break;
  default:
    return;
  }

  if (samples.size() < 16)
    return;

  constexpr std::array<double, 6> frequencies{80, 180, 420,
                                               1000, 2600, 6500};
  QVariantList next;
  next.reserve(frequencies.size());
  const double sampleRate = format.sampleRate();
  const double pi = std::acos(-1.0);

  for (qsizetype band = 0; band < frequencies.size(); ++band) {
    double real = 0;
    double imaginary = 0;
    for (qsizetype i = 0; i < samples.size(); ++i) {
      const double window =
          0.5 - 0.5 * std::cos(2.0 * pi * i / (samples.size() - 1));
      const double angle = 2.0 * pi * frequencies[band] * i / sampleRate;
      real += samples[i] * window * std::cos(angle);
      imaginary -= samples[i] * window * std::sin(angle);
    }
    const double magnitude =
        2.0 * std::hypot(real, imaginary) / samples.size();
    const double target = qBound(0.0, std::sqrt(magnitude * 4.5), 1.0);
    const double previous = m_visualizerLevels.value(band).toDouble();
    const double smoothing = target > previous ? 0.68 : 0.2;
    next.append(previous + smoothing * (target - previous));
  }

  m_visualizerLevels = next;
  emit visualizerLevelsChanged();
}
#endif

void PlayerController::setVolume(qreal volume) {
  volume = qBound(0.0, volume, 1.0);
  m_audioOutput.setVolume(volume);
  m_settings.setValue(QStringLiteral("player/volume"), volume);
}

void PlayerController::setShuffle(bool enabled) {
  if (m_shuffle == enabled)
    return;
  m_shuffle = enabled;
  m_settings.setValue(QStringLiteral("player/shuffle"), enabled);
  emit shuffleChanged();
}

void PlayerController::setRepeatMode(int mode) {
  mode = qBound(0, mode, 2);
  if (m_repeatMode == mode)
    return;
  m_repeatMode = mode;
  m_settings.setValue(QStringLiteral("player/repeat"), mode);
  emit repeatModeChanged();
}

void PlayerController::playTrack(int index) {
  if (index < 0 || index >= m_model->rowCount())
    return;
  savePlaybackState();
  if (m_currentIndex >= 0 && m_currentIndex != index) {
    m_history.append(m_currentIndex);
    if (m_history.size() > 200)
      m_history.removeFirst();
  }
  m_currentIndex = index;
  loadCurrent(true);
}

void PlayerController::loadCurrent(bool autoplay) {
  m_currentTrack = m_model->trackAt(m_currentIndex);
  const QString path =
      m_currentTrack.value(QStringLiteral("filePath")).toString();
  if (path.isEmpty() || !QFileInfo::exists(path)) {
    emit playbackError(QStringLiteral("The audio file no longer exists."));
    return;
  }
  m_pendingRestorePosition = -1;
  m_player.setSource(QUrl::fromLocalFile(path));
  m_settings.setValue(QStringLiteral("player/currentFile"), path);
  m_settings.setValue(QStringLiteral("player/position"), 0);
  emit trackChanged();
  if (autoplay)
    m_player.play();
}

void PlayerController::restorePlaybackState() {
  if (m_currentIndex >= 0)
    return;
  const QString path =
      m_settings.value(QStringLiteral("player/currentFile")).toString();
  const int index = m_model->indexOfFilePath(path);
  if (index < 0 || !QFileInfo::exists(path))
    return;

  m_currentIndex = index;
  m_currentTrack = m_model->trackAt(index);
  m_pendingRestorePosition = qMax<qint64>(
      0, m_settings.value(QStringLiteral("player/position"), 0).toLongLong());
  m_player.setSource(QUrl::fromLocalFile(path));
  emit trackChanged();
}

void PlayerController::resolveCurrentIndex() {
  if (m_currentIndex < 0) {
    // The track from the previous session may only appear once the background
    // scan has filled the library.
    restorePlaybackState();
    return;
  }
  const int index = m_model->indexOfFilePath(
      m_currentTrack.value(QStringLiteral("filePath")).toString());
  if (index == m_currentIndex)
    return;
  m_currentIndex = index;
  if (index >= 0)
    m_currentTrack = m_model->trackAt(index);
  emit trackChanged();
}

void PlayerController::savePlaybackState() {
  if (m_currentTrack.isEmpty() || m_pendingRestorePosition >= 0)
    return;
  m_settings.setValue(
      QStringLiteral("player/currentFile"),
      m_currentTrack.value(QStringLiteral("filePath")).toString());
  m_settings.setValue(QStringLiteral("player/position"), m_player.position());
}

void PlayerController::toggle() {
  if (m_currentIndex < 0 && m_model->rowCount() > 0) {
    playTrack(0);
  } else if (playing()) {
    pause();
  } else {
    play();
  }
}

void PlayerController::play() {
  if (m_currentIndex >= 0)
    m_player.play();
}
void PlayerController::pause() { m_player.pause(); }

int PlayerController::nextIndex(bool forward) const {
  const int count = m_model->rowCount();
  if (count <= 0)
    return -1;
  if (m_shuffle && count > 1) {
    int index = m_currentIndex;
    while (index == m_currentIndex)
      index = QRandomGenerator::global()->bounded(count);
    return index;
  }
  int index = m_currentIndex + (forward ? 1 : -1);
  if (index >= count)
    return m_repeatMode == 2 ? 0 : -1;
  if (index < 0)
    return m_repeatMode == 2 ? count - 1 : 0;
  return index;
}

void PlayerController::next() {
  const int index = nextIndex(true);
  if (index >= 0)
    playTrack(index);
  else
    m_player.stop();
}

void PlayerController::previous() {
  if (m_player.position() > 4000) {
    m_player.setPosition(0);
    return;
  }
  if (m_shuffle) {
    if (m_history.isEmpty()) {
      m_player.setPosition(0);
      return;
    }
    savePlaybackState();
    m_currentIndex = m_history.takeLast();
    loadCurrent(true);
    return;
  }
  const int index = nextIndex(false);
  if (index >= 0)
    playTrack(index);
}

void PlayerController::seek(qint64 position) {
  m_player.setPosition(qBound<qint64>(0, position, duration()));
  savePlaybackState();
}
void PlayerController::seekRelative(qint64 offset) {
  seek(position() + offset);
}
