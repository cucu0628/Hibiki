#include "TrayController.h"

#include "PlayerController.h"

#include <QAction>
#include <QApplication>
#include <QIcon>
#include <QMenu>
#include <QWindow>

TrayController::TrayController(PlayerController *player, QObject *parent)
    : QObject(parent) {
  m_tray.setIcon(QIcon(QStringLiteral(":/assets/hibiki.svg")));
  m_tray.setToolTip(QStringLiteral("Hibiki"));
  auto *menu = new QMenu;
  QAction *showAction = menu->addAction(QStringLiteral("Open Hibiki"));
  QAction *toggleAction = menu->addAction(QStringLiteral("Play / Pause"));
  QAction *nextAction = menu->addAction(QStringLiteral("Next"));
  menu->addSeparator();
  QAction *quitAction = menu->addAction(QStringLiteral("Quit"));
  connect(showAction, &QAction::triggered, this, &TrayController::showWindow);
  connect(toggleAction, &QAction::triggered, player, &PlayerController::toggle);
  connect(nextAction, &QAction::triggered, player, &PlayerController::next);
  connect(quitAction, &QAction::triggered, this,
          &TrayController::quitRequested);
  connect(&m_tray, &QSystemTrayIcon::activated, this,
          [this](QSystemTrayIcon::ActivationReason reason) {
            if (reason == QSystemTrayIcon::Trigger ||
                reason == QSystemTrayIcon::DoubleClick)
              showWindow();
          });
  m_tray.setContextMenu(menu);
  m_tray.show();
}

void TrayController::setWindow(QObject *window) { m_window = window; }

void TrayController::showWindow() {
  if (!m_window)
    return;
  m_window->setProperty("visible", true);
  if (auto *window = qobject_cast<QWindow *>(m_window)) {
    window->show();
    window->raise();
    window->requestActivate();
  }
}

void TrayController::notify(const QString &title, const QString &message) {
  if (QSystemTrayIcon::supportsMessages())
    m_tray.showMessage(title, message, QSystemTrayIcon::Information, 3500);
}
