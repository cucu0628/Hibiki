#include "ThemeManager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace {
QJsonObject readObject(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly))
    return {};
  const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
  return document.isObject() ? document.object() : QJsonObject{};
}
} // namespace

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
          [this] { reload(); });
  connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this,
          [this] { reload(); });
  reload();
}

QColor ThemeManager::color(const QJsonObject &colors, const char *key,
                           const QColor &fallback) {
  const QColor candidate(colors.value(QLatin1String(key)).toString());
  return candidate.isValid() ? candidate : fallback;
}

QColor ThemeManager::withAlpha(QColor value, qreal alpha) {
  value.setAlphaF(alpha);
  return value;
}

void ThemeManager::reload() {
  const QString config =
      QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) +
      QStringLiteral("/DankMaterialShell/settings.json");
  const QString cache =
      QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) +
      QStringLiteral("/DankMaterialShell/dms-colors.json");
  const QString stateRoot = qEnvironmentVariable(
      "XDG_STATE_HOME", QDir::homePath() + QStringLiteral("/.local/state"));
  const QString session =
      stateRoot + QStringLiteral("/DankMaterialShell/session.json");

  const QJsonObject settings = readObject(config);
  const QJsonObject palette = readObject(cache);
  const QString mode = palette.value(QStringLiteral("mode")).toString(
      QStringLiteral("dark"));
  const QJsonObject colors =
      palette.value(QStringLiteral("colors")).toObject().value(mode).toObject();

  if (!colors.isEmpty()) {
    m_background = color(colors, "background", m_background);
    m_foreground = color(colors, "on_surface", m_foreground);
    m_accent = color(colors, "primary", m_accent);
    m_accentText = color(colors, "on_primary", m_accentText);
    m_primaryContainer =
        color(colors, "primary_container", m_primaryContainer);
    m_surface = color(colors, "surface_container", m_surface);
    m_surfaceHigh = color(colors, "surface_container_high", m_surfaceHigh);
    m_surfaceHighest =
        color(colors, "surface_container_highest", m_surfaceHighest);
    m_muted = color(colors, "on_surface_variant", m_muted);
    m_outline = color(colors, "outline", m_outline);
    m_error = color(colors, "error", m_error);
  }

  const QString configuredName =
      settings.value(QStringLiteral("currentThemeName")).toString();
  if (!configuredName.isEmpty()) {
    if (configuredName == QStringLiteral("custom")) {
      const QString customThemePath =
          settings.value(QStringLiteral("customThemeFile")).toString();
      const QString customName =
          readObject(customThemePath).value(QStringLiteral("name")).toString();
      m_themeName = customName.isEmpty() ? QFileInfo(customThemePath).baseName()
                                         : customName;
    } else {
      m_themeName = configuredName;
    }
  }
  m_cornerRadius = qBound(
      0, settings.value(QStringLiteral("cornerRadius")).toInt(12), 32);

  const QString wallpaperPath =
      readObject(session).value(QStringLiteral("wallpaperPath")).toString();
  m_wallpaperUrl = QFileInfo::exists(wallpaperPath)
                       ? QUrl::fromLocalFile(wallpaperPath)
                       : QUrl{};

  QStringList watched{config, cache, session};
  const QString customTheme =
      settings.value(QStringLiteral("customThemeFile")).toString();
  if (!customTheme.isEmpty())
    watched << customTheme;
  watchFiles(watched);
  emit themeChanged();
}

void ThemeManager::watchFiles(const QStringList &paths) {
  const QStringList oldFiles = m_watcher.files();
  if (!oldFiles.isEmpty())
    m_watcher.removePaths(oldFiles);
  const QStringList oldDirectories = m_watcher.directories();
  if (!oldDirectories.isEmpty())
    m_watcher.removePaths(oldDirectories);

  QStringList files;
  QStringList directories;
  for (const QString &path : paths) {
    if (QFile::exists(path))
      files << path;
    else {
      const QString directory = QFileInfo(path).absolutePath();
      if (QDir(directory).exists() && !directories.contains(directory))
        directories << directory;
    }
  }
  if (!files.isEmpty())
    m_watcher.addPaths(files);
  if (!directories.isEmpty())
    m_watcher.addPaths(directories);
}
