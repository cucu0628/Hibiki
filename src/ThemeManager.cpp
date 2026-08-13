#include "ThemeManager.h"

#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QStandardPaths>

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
          [this] { reload(); });
  reload();
}

QString ThemeManager::shellDirectory() const {
  return QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) +
         QStringLiteral("/quickshell/vellum_shell");
}

void ThemeManager::reload() {
  const QString currentThemePath =
      shellDirectory() + QStringLiteral("/current-theme");
  QFile currentTheme(currentThemePath);
  if (currentTheme.open(QIODevice::ReadOnly | QIODevice::Text)) {
    const QString name = QString::fromUtf8(currentTheme.readAll()).trimmed();
    if (!name.isEmpty())
      m_themeName = name;
  }

  const QString themeFilePath = shellDirectory() + QStringLiteral("/themes/") +
                                m_themeName + QStringLiteral("/theme.conf");
  QFile themeFile(themeFilePath);
  if (themeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
    const QRegularExpression linePattern(QStringLiteral(
        "^([A-Z_]+)\\s*=\\s*[\"']?([^\"'\\s#]+|#[0-9A-Fa-f]{6,8})"));
    while (!themeFile.atEnd()) {
      const QString line = QString::fromUtf8(themeFile.readLine()).trimmed();
      const auto match = linePattern.match(line);
      if (!match.hasMatch())
        continue;
      const QString key = match.captured(1);
      const QColor value(match.captured(2));
      if (!value.isValid())
        continue;
      if (key == QStringLiteral("BACKGROUND"))
        m_background = value;
      else if (key == QStringLiteral("FOREGROUND"))
        m_foreground = value;
      else if (key == QStringLiteral("ACCENT") ||
               key == QStringLiteral("BORDER_FOREGROUND"))
        m_accent = value;
      else if (key == QStringLiteral("SURFACE"))
        m_surface = value;
      else if (key == QStringLiteral("MUTED"))
        m_muted = value;
    }
  }
  watchFiles(themeFilePath);
  emit themeChanged();
}

void ThemeManager::watchFiles(const QString &themeFile) {
  const QStringList oldPaths = m_watcher.files();
  if (!oldPaths.isEmpty())
    m_watcher.removePaths(oldPaths);
  const QString currentThemePath =
      shellDirectory() + QStringLiteral("/current-theme");
  QStringList paths;
  if (QFile::exists(currentThemePath))
    paths << currentThemePath;
  if (QFile::exists(themeFile))
    paths << themeFile;
  if (!paths.isEmpty())
    m_watcher.addPaths(paths);
}
