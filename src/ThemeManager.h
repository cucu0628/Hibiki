#pragma once

#include <QColor>
#include <QFileSystemWatcher>
#include <QHash>
#include <QObject>
#include <QTimer>
#include <QUrl>

// Follows the active Vellum Shell palette: `current-theme` names a slug and
// `themes/<slug>/theme.conf` holds the KEY=#rrggbb colors. Both files are
// watched, so switching themes (or a regenerated Matugen palette) restyles
// the player live.
class ThemeManager final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QColor background READ background NOTIFY themeChanged)
  Q_PROPERTY(QColor backgroundDeep READ backgroundDeep NOTIFY themeChanged)
  Q_PROPERTY(QColor surface READ surface NOTIFY themeChanged)
  Q_PROPERTY(QColor raised READ raised NOTIFY themeChanged)
  Q_PROPERTY(QColor foreground READ foreground NOTIFY themeChanged)
  Q_PROPERTY(QColor muted READ muted NOTIFY themeChanged)
  Q_PROPERTY(QColor outline READ outline NOTIFY themeChanged)
  Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
  Q_PROPERTY(QColor accentText READ accentText NOTIFY themeChanged)
  Q_PROPERTY(QColor selection READ selection NOTIFY themeChanged)
  Q_PROPERTY(QColor hover READ hover NOTIFY themeChanged)
  Q_PROPERTY(QColor line READ line NOTIFY themeChanged)
  Q_PROPERTY(QColor error READ error NOTIFY themeChanged)
  Q_PROPERTY(bool dark READ dark NOTIFY themeChanged)
  Q_PROPERTY(QString themeName READ themeName NOTIFY themeChanged)
  Q_PROPERTY(QUrl wallpaperUrl READ wallpaperUrl NOTIFY themeChanged)

public:
  explicit ThemeManager(QObject *parent = nullptr);

  QColor background() const { return value("BACKGROUND"); }
  QColor backgroundDeep() const { return value("DARK_BACKGROUND"); }
  QColor surface() const { return value("SURFACE"); }
  QColor raised() const { return mix(surface(), foreground(), 0.07); }
  QColor foreground() const { return value("FOREGROUND"); }
  // Vellum's naming is crossed on purpose: LIGHT_FOREGROUND is the readable
  // secondary text, MUTED the quieter outline tone.
  QColor muted() const { return value("LIGHT_FOREGROUND"); }
  QColor outline() const { return value("MUTED"); }
  QColor accent() const { return value("ACCENT"); }
  QColor accentText() const { return background(); }
  QColor selection() const { return value("SELECTION"); }
  QColor hover() const { return overlay(0.075); }
  QColor line() const { return overlay(0.08); }
  QColor error() const { return value("RED"); }
  bool dark() const { return m_dark; }
  QString themeName() const { return m_themeName; }
  QUrl wallpaperUrl() const { return m_wallpaperUrl; }

  Q_INVOKABLE void reload();

signals:
  void themeChanged();

private:
  QColor value(const char *key) const;
  QColor overlay(qreal alpha) const;
  static QColor mix(const QColor &from, const QColor &to, qreal amount);
  void watchFiles(const QStringList &paths);

  QFileSystemWatcher m_watcher;
  QTimer m_reloadTimer;
  QHash<QString, QColor> m_colors;
  bool m_dark{true};
  QString m_themeName{QStringLiteral("Vellum fallback")};
  QUrl m_wallpaperUrl;
};
