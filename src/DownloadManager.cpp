#include "DownloadManager.h"

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QUrl>

#include <utility>

DownloadManager::DownloadManager(QString musicDirectory, QObject *parent)
    : QObject(parent), m_musicDirectory(std::move(musicDirectory)) {
  connect(&m_process, &QProcess::readyReadStandardOutput, this, [this] {
    m_stdoutBuffer += m_process.readAllStandardOutput();
    while (true) {
      const qsizetype newline = m_stdoutBuffer.indexOf('\n');
      if (newline < 0)
        break;
      const QString line =
          QString::fromUtf8(m_stdoutBuffer.left(newline)).trimmed();
      m_stdoutBuffer.remove(0, newline + 1);
      if (line.startsWith(QStringLiteral("HIBIKI_PROGRESS:"))) {
        const QStringList parts = line.mid(16).split(QLatin1Char('|'));
        QString percent = parts.value(0);
        percent.remove(QLatin1Char('%'));
        updateCurrent(QStringLiteral("downloading"),
                      percent.trimmed().toDouble() / 100.0,
                      parts.mid(1).join(QStringLiteral(" | ")));
      } else if (line.startsWith(QStringLiteral("HIBIKI_ITEM:"))) {
        updateCurrent(QStringLiteral("processing"), -1.0, line.mid(12));
      }
    }
  });
  connect(&m_process, &QProcess::readyReadStandardError, this, [this] {
    const QString error =
        QString::fromUtf8(m_process.readAllStandardError()).trimmed();
    if (error.contains(QStringLiteral("HTTP Error 403"), Qt::CaseInsensitive) ||
        error.contains(QStringLiteral("HTTP 403"), Qt::CaseInsensitive))
      m_sawForbidden = true;
    if (!error.isEmpty())
      updateCurrent(QStringLiteral("downloading"), -1.0,
                    error.section(QLatin1Char('\n'), -1));
  });
  connect(&m_process, &QProcess::started, this, &DownloadManager::busyChanged);
  connect(&m_process, &QProcess::finished, this,
          [this](int exitCode, QProcess::ExitStatus exitStatus) {
            const bool success = exitStatus == QProcess::NormalExit &&
                                 exitCode == 0 && !m_sawForbidden;
            if (!success && m_sawForbidden && !m_retryingForbidden &&
                !m_cancelRequested) {
              m_retryingForbidden = true;
              m_sawForbidden = false;
              updateCurrent(QStringLiteral("retrying"), -1.0,
                            QStringLiteral("403 received; retrying with a "
                                           "compatible YouTube client"));
              startProcess(true);
              return;
            }
            updateCurrent(success ? QStringLiteral("completed")
                                  : QStringLiteral("failed"),
                          success ? 1.0 : 0.0,
                          success ? QStringLiteral("Download completed")
                                  : QStringLiteral("Download failed"));
            if (success) {
              emit libraryChanged();
              emit notificationRequested(QStringLiteral("Hibiki"),
                                         QStringLiteral("Download completed"));
            }
            emit busyChanged();
            m_currentJob = -1;
            m_currentUrl.clear();
            startNext();
          });
}

bool DownloadManager::toolsAvailable() const {
  return !QStandardPaths::findExecutable(QStringLiteral("yt-dlp")).isEmpty() &&
         !QStandardPaths::findExecutable(QStringLiteral("ffmpeg")).isEmpty();
}

bool DownloadManager::isSupportedUrl(const QUrl &url) const {
  if (!url.isValid() || !url.scheme().startsWith(QStringLiteral("http")))
    return false;
  const QString host = url.host().toLower();
  return host == QStringLiteral("youtu.be") ||
         host.endsWith(QStringLiteral("youtube.com")) ||
         host.endsWith(QStringLiteral("music.youtube.com"));
}

bool DownloadManager::enqueue(const QString &urlText) {
  const QUrl url = QUrl::fromUserInput(urlText.trimmed());
  if (!isSupportedUrl(url)) {
    emit notificationRequested(
        QStringLiteral("Invalid link"),
        QStringLiteral("Enter a YouTube video or playlist URL."));
    return false;
  }
  if (!toolsAvailable()) {
    emit notificationRequested(
        QStringLiteral("Missing tools"),
        QStringLiteral("yt-dlp and FFmpeg are required."));
    return false;
  }
  QVariantMap job{{QStringLiteral("url"), url.toString()},
                  {QStringLiteral("title"), url.toString()},
                  {QStringLiteral("status"), QStringLiteral("queued")},
                  {QStringLiteral("progress"), 0.0},
                  {QStringLiteral("detail"), QString()}};
  m_jobs.append(job);
  m_queue.enqueue(url.toString());
  emit jobsChanged();
  startNext();
  return true;
}

void DownloadManager::startNext() {
  if (m_process.state() != QProcess::NotRunning || m_queue.isEmpty())
    return;
  m_currentUrl = m_queue.dequeue();
  for (int i = 0; i < m_jobs.size(); ++i) {
    if (m_jobs.at(i).toMap().value(QStringLiteral("url")).toString() ==
            m_currentUrl &&
        m_jobs.at(i).toMap().value(QStringLiteral("status")).toString() ==
            QStringLiteral("queued")) {
      m_currentJob = i;
      break;
    }
  }
  QDir().mkpath(m_musicDirectory);
  m_sawForbidden = false;
  m_retryingForbidden = false;
  m_cancelRequested = false;
  startProcess(false);
}

void DownloadManager::startProcess(bool forbiddenFallback) {
  const QString output =
      m_musicDirectory +
      QStringLiteral("/%(playlist_title|Singles)s/%(title)s [%(id)s].%(ext)s");
  QStringList arguments = {
      QStringLiteral("--newline"),
      QStringLiteral("--ignore-errors"),
      QStringLiteral("--retries"),
      QStringLiteral("10"),
      QStringLiteral("--fragment-retries"),
      QStringLiteral("10"),
      QStringLiteral("--retry-sleep"),
      QStringLiteral("http:linear=1::2"),
      QStringLiteral("--no-overwrites"),
      QStringLiteral("--download-archive"),
      m_musicDirectory + QStringLiteral("/.download-archive"),
      QStringLiteral("--extract-audio"),
      QStringLiteral("--audio-format"),
      QStringLiteral("opus"),
      QStringLiteral("--audio-quality"),
      QStringLiteral("0"),
      QStringLiteral("--write-thumbnail"),
      QStringLiteral("--convert-thumbnails"),
      QStringLiteral("jpg"),
      QStringLiteral("--write-info-json"),
      QStringLiteral("--progress-template"),
      QStringLiteral("download:HIBIKI_PROGRESS:%(progress._percent_str)s|%("
                     "progress._speed_str)s|%(progress._eta_str)s"),
      QStringLiteral("--print"),
      QStringLiteral("before_dl:HIBIKI_ITEM:%(title)s"),
      QStringLiteral("--output"),
      output};
  if (forbiddenFallback) {
    arguments << QStringLiteral("--extractor-args")
              << QStringLiteral("youtube:player_client=android_vr")
              << QStringLiteral("--impersonate") << QStringLiteral("chrome");
  }
  arguments << m_currentUrl;
  if (!forbiddenFallback)
    updateCurrent(QStringLiteral("starting"), 0.0,
                  QStringLiteral("Reading metadata"));
  m_stdoutBuffer.clear();
  m_process.start(QStringLiteral("yt-dlp"), arguments);
}

void DownloadManager::updateCurrent(const QString &status, double progress,
                                    const QString &detail) {
  if (m_currentJob < 0 || m_currentJob >= m_jobs.size())
    return;
  QVariantMap job = m_jobs.at(m_currentJob).toMap();
  job[QStringLiteral("status")] = status;
  if (progress >= 0.0)
    job[QStringLiteral("progress")] = progress;
  if (!detail.isEmpty()) {
    job[QStringLiteral("detail")] = detail;
    if (status == QStringLiteral("processing"))
      job[QStringLiteral("title")] = detail;
  }
  m_jobs[m_currentJob] = job;
  emit jobsChanged();
}

void DownloadManager::cancelCurrent() {
  if (m_process.state() != QProcess::NotRunning) {
    m_cancelRequested = true;
    m_process.terminate();
    if (!m_process.waitForFinished(1500))
      m_process.kill();
  }
}

void DownloadManager::clearFinished() {
  QVariantList remaining;
  for (const QVariant &value : std::as_const(m_jobs)) {
    const QString status =
        value.toMap().value(QStringLiteral("status")).toString();
    if (status != QStringLiteral("completed") &&
        status != QStringLiteral("failed"))
      remaining.append(value);
  }
  m_jobs = remaining;
  emit jobsChanged();
}
