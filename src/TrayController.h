#pragma once

#include <QObject>
#include <QSystemTrayIcon>

class PlayerController;

class TrayController final : public QObject {
  Q_OBJECT
public:
  explicit TrayController(PlayerController *player, QObject *parent = nullptr);
  void setWindow(QObject *window);
  void showWindow();
  void notify(const QString &title, const QString &message);

signals:
  void quitRequested();

private:
  QSystemTrayIcon m_tray;
  QObject *m_window{nullptr};
};
