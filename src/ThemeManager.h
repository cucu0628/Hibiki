#pragma once

#include <QColor>
#include <QFileSystemWatcher>
#include <QObject>

class ThemeManager final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QColor background READ background NOTIFY themeChanged)
  Q_PROPERTY(QColor foreground READ foreground NOTIFY themeChanged)
  Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
  Q_PROPERTY(QColor surface READ surface NOTIFY themeChanged)
  Q_PROPERTY(QColor muted READ muted NOTIFY themeChanged)
  Q_PROPERTY(QString themeName READ themeName NOTIFY themeChanged)
  // Fixed overlay tints, matching the values the shell paints its cards,
  // chips and hover states with.
  Q_PROPERTY(QColor outline READ outline CONSTANT)
  Q_PROPERTY(QColor line READ line CONSTANT)
  Q_PROPERTY(QColor hover READ hover CONSTANT)

public:
  explicit ThemeManager(QObject *parent = nullptr);

  QColor background() const { return m_background; }
  QColor foreground() const { return m_foreground; }
  QColor accent() const { return m_accent; }
  QColor surface() const { return m_surface; }
  QColor muted() const { return m_muted; }
  QString themeName() const { return m_themeName; }
  QColor outline() const { return QColor::fromRgbF(1, 1, 1, 0.07); }
  QColor line() const { return QColor::fromRgbF(1, 1, 1, 0.055); }
  QColor hover() const { return QColor::fromRgbF(1, 1, 1, 0.075); }

  Q_INVOKABLE void reload();

signals:
  void themeChanged();

private:
  QString shellDirectory() const;
  void watchFiles(const QString &themeFile);

  QFileSystemWatcher m_watcher;
  QColor m_background{QStringLiteral("#191724")};
  QColor m_foreground{QStringLiteral("#e0def4")};
  QColor m_accent{QStringLiteral("#ebbcba")};
  QColor m_surface{QStringLiteral("#1f1d2e")};
  QColor m_muted{QStringLiteral("#908caa")};
  QString m_themeName{QStringLiteral("rose-pine")};
};
