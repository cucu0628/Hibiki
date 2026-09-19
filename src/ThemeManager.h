#pragma once

#include <QColor>
#include <QFileSystemWatcher>
#include <QObject>
#include <QUrl>

class QJsonObject;

class ThemeManager final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QColor background READ background NOTIFY themeChanged)
  Q_PROPERTY(QColor foreground READ foreground NOTIFY themeChanged)
  Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
  Q_PROPERTY(QColor accentText READ accentText NOTIFY themeChanged)
  Q_PROPERTY(QColor primaryContainer READ primaryContainer NOTIFY themeChanged)
  Q_PROPERTY(QColor surface READ surface NOTIFY themeChanged)
  Q_PROPERTY(QColor surfaceHigh READ surfaceHigh NOTIFY themeChanged)
  Q_PROPERTY(QColor surfaceHighest READ surfaceHighest NOTIFY themeChanged)
  Q_PROPERTY(QColor muted READ muted NOTIFY themeChanged)
  Q_PROPERTY(QColor outline READ outline NOTIFY themeChanged)
  Q_PROPERTY(QColor line READ line NOTIFY themeChanged)
  Q_PROPERTY(QColor hover READ hover NOTIFY themeChanged)
  Q_PROPERTY(QColor error READ error NOTIFY themeChanged)
  Q_PROPERTY(QString themeName READ themeName NOTIFY themeChanged)
  Q_PROPERTY(int cornerRadius READ cornerRadius NOTIFY themeChanged)
  Q_PROPERTY(QUrl wallpaperUrl READ wallpaperUrl NOTIFY themeChanged)

public:
  explicit ThemeManager(QObject *parent = nullptr);

  QColor background() const { return m_background; }
  QColor foreground() const { return m_foreground; }
  QColor accent() const { return m_accent; }
  QColor accentText() const { return m_accentText; }
  QColor primaryContainer() const { return m_primaryContainer; }
  QColor surface() const { return m_surface; }
  QColor surfaceHigh() const { return m_surfaceHigh; }
  QColor surfaceHighest() const { return m_surfaceHighest; }
  QColor muted() const { return m_muted; }
  QColor outline() const { return m_outline; }
  QColor line() const { return withAlpha(m_outline, 0.35); }
  QColor hover() const { return withAlpha(m_accent, 0.12); }
  QColor error() const { return m_error; }
  QString themeName() const { return m_themeName; }
  int cornerRadius() const { return m_cornerRadius; }
  QUrl wallpaperUrl() const { return m_wallpaperUrl; }

  Q_INVOKABLE void reload();

signals:
  void themeChanged();

private:
  static QColor color(const QJsonObject &colors, const char *key,
                      const QColor &fallback);
  static QColor withAlpha(QColor value, qreal alpha);
  void watchFiles(const QStringList &paths);

  QFileSystemWatcher m_watcher;
  QColor m_background{QStringLiteral("#1e1e2e")};
  QColor m_foreground{QStringLiteral("#cdd6f4")};
  QColor m_accent{QStringLiteral("#cba6f7")};
  QColor m_accentText{QStringLiteral("#1e1e2e")};
  QColor m_primaryContainer{QStringLiteral("#55307f")};
  QColor m_surface{QStringLiteral("#181825")};
  QColor m_surfaceHigh{QStringLiteral("#1e1e2e")};
  QColor m_surfaceHighest{QStringLiteral("#313244")};
  QColor m_muted{QStringLiteral("#a6adc8")};
  QColor m_outline{QStringLiteral("#6c7086")};
  QColor m_error{QStringLiteral("#f38ba8")};
  QString m_themeName{QStringLiteral("DMS fallback")};
  int m_cornerRadius{12};
  QUrl m_wallpaperUrl;
};
