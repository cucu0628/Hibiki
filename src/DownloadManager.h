#pragma once

#include <QObject>
#include <QProcess>
#include <QQueue>
#include <QVariantList>

class DownloadManager final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QVariantList jobs READ jobs NOTIFY jobsChanged)
  Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
  Q_PROPERTY(bool toolsAvailable READ toolsAvailable CONSTANT)

public:
  explicit DownloadManager(QString musicDirectory, QObject *parent = nullptr);

  QVariantList jobs() const { return m_jobs; }
  bool busy() const { return m_process.state() != QProcess::NotRunning; }
  bool toolsAvailable() const;

  Q_INVOKABLE bool enqueue(const QString &url);
  Q_INVOKABLE void cancelCurrent();
  Q_INVOKABLE void clearFinished();

signals:
  void jobsChanged();
  void busyChanged();
  void libraryChanged();
  void notificationRequested(const QString &title, const QString &message);

private:
  void startNext();
  void startProcess(bool forbiddenFallback);
  void updateCurrent(const QString &status, double progress,
                     const QString &detail = {});
  bool isSupportedUrl(const QUrl &url) const;

  QString m_musicDirectory;
  QProcess m_process;
  QQueue<QString> m_queue;
  QVariantList m_jobs;
  int m_currentJob{-1};
  QString m_currentUrl;
  QByteArray m_stdoutBuffer;
  bool m_sawForbidden{false};
  bool m_retryingForbidden{false};
  bool m_cancelRequested{false};
};
