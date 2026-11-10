#include "ThemeManager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTextStream>

namespace {
// Catppuccin Mocha, the palette Vellum Shell itself falls back to.
const QHash<QString, QColor> &fallbackColors() {
  static const QHash<QString, QColor> colors{
      {QStringLiteral("BACKGROUND"), QColor(QStringLiteral("#1e1e2e"))},
      {QStringLiteral("DARK_BACKGROUND"), QColor(QStringLiteral("#181825"))},
      {QStringLiteral("SURFACE"), QColor(QStringLiteral("#313244"))},
      {QStringLiteral("FOREGROUND"), QColor(QStringLiteral("#cdd6f4"))},
      {QStringLiteral("LIGHT_FOREGROUND"), QColor(QStringLiteral("#bac2de"))},
      {QStringLiteral("MUTED"), QColor(QStringLiteral("#9399b2"))},
      {QStringLiteral("ACCENT"), QColor(QStringLiteral("#cba6f7"))},
      {QStringLiteral("SELECTION"), QColor(QStringLiteral("#45475a"))},
      {QStringLiteral("RED"), QColor(QStringLiteral("#f38ba8"))},
  };
  return colors;
}

QString shellDirectory() {
  const QString configured = qEnvironmentVariable("VELLUM_SHELL_DIR");
  if (!configured.isEmpty())
    return configured;
  const QString configRoot = qEnvironmentVariable(
      "XDG_CONFIG_HOME", QDir::homePath() + QStringLiteral("/.config"));
  return configRoot + QStringLiteral("/quickshell/vellum_shell");
}

QString readLine(const QString &path) {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    return {};
  return QString::fromUtf8(file.readLine()).trimmed();
}
} // namespace

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {
  // A theme switch rewrites several files at once; settle before re-reading.
  m_reloadTimer.setSingleShot(true);
  m_reloadTimer.setInterval(120);
  connect(&m_reloadTimer, &QTimer::timeout, this, &ThemeManager::reload);
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, &m_reloadTimer,
          qOverload<>(&QTimer::start));
  connect(&m_watcher, &QFileSystemWatcher::directoryChanged, &m_reloadTimer,
          qOverload<>(&QTimer::start));
  reload();
}

QColor ThemeManager::value(const char *key) const {
  const QString name = QLatin1String(key);
  const QColor color = m_colors.value(name);
  return color.isValid() ? color : fallbackColors().value(name);
}

QColor ThemeManager::overlay(qreal alpha) const {
  // Vellum draws hover and divider layers as a thin white (or, on light
  // palettes, black) wash over whatever surface sits underneath.
  QColor wash = m_dark ? QColor(Qt::white) : QColor(Qt::black);
  wash.setAlphaF(m_dark ? alpha : alpha * 0.8);
  return wash;
}

QColor ThemeManager::mix(const QColor &from, const QColor &to, qreal amount) {
  return QColor::fromRgbF(from.redF() + (to.redF() - from.redF()) * amount,
                          from.greenF() + (to.greenF() - from.greenF()) * amount,
                          from.blueF() + (to.blueF() - from.blueF()) * amount);
}

void ThemeManager::reload() {
  const QString shellDir = shellDirectory();
  const QString currentTheme = shellDir + QStringLiteral("/current-theme");
  const QString currentWallpaper =
      shellDir + QStringLiteral("/current-wallpaper");
  const QString slug = readLine(currentTheme);
  const QString themeFile =
      slug.isEmpty() ? QString{}
                     : shellDir + QStringLiteral("/themes/") + slug +
                           QStringLiteral("/theme.conf");

  QHash<QString, QColor> colors;
  QString name;
  bool dark = true;
  QFile file(themeFile);
  if (!themeFile.isEmpty() &&
      file.open(QIODevice::ReadOnly | QIODevice::Text)) {
    QTextStream stream(&file);
    while (!stream.atEnd()) {
      const QString line = stream.readLine().trimmed();
      if (line.isEmpty() || line.startsWith(QLatin1Char('#')))
        continue;
      const qsizetype separator = line.indexOf(QLatin1Char('='));
      if (separator <= 0)
        continue;
      const QString key = line.left(separator).trimmed();
      const QString entry = line.mid(separator + 1).trimmed();
      if (key == QStringLiteral("NAME"))
        name = entry;
      else if (key == QStringLiteral("MODE"))
        dark = entry.compare(QStringLiteral("light"), Qt::CaseInsensitive) != 0;
      else if (const QColor color(entry); color.isValid())
        colors.insert(key, color);
    }
  }

  m_colors = colors;
  m_dark = dark;
  m_themeName = !name.isEmpty() ? name
                : !slug.isEmpty() ? slug
                                  : QStringLiteral("Vellum fallback");

  const QString wallpaperPath = readLine(currentWallpaper);
  m_wallpaperUrl = !wallpaperPath.isEmpty() && QFileInfo::exists(wallpaperPath)
                       ? QUrl::fromLocalFile(wallpaperPath)
                       : QUrl{};

  QStringList watched{currentTheme, currentWallpaper};
  if (!themeFile.isEmpty())
    watched << themeFile;
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

  // The backend replaces these files atomically, which drops a plain file
  // watch; the parent directories catch the rename as well.
  QStringList files;
  QStringList directories;
  for (const QString &path : paths) {
    if (QFile::exists(path))
      files << path;
    const QString directory = QFileInfo(path).absolutePath();
    if (QDir(directory).exists() && !directories.contains(directory))
      directories << directory;
  }
  if (!files.isEmpty())
    m_watcher.addPaths(files);
  if (!directories.isEmpty())
    m_watcher.addPaths(directories);
}
