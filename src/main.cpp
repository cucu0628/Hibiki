#include "ApplicationController.h"
#include "DiscordPresence.h"
#include "DownloadManager.h"
#include "PlayerController.h"
#include "ThemeManager.h"
#include "TrackModel.h"

#include <QApplication>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusInterface>
#include <QDBusReply>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

int main(int argc, char *argv[]) {
  QApplication app(argc, argv);
  QApplication::setApplicationName(QStringLiteral("Hibiki"));
  QApplication::setApplicationDisplayName(QStringLiteral("Hibiki"));
  QApplication::setOrganizationName(QStringLiteral("Hibiki"));
  QApplication::setDesktopFileName(QStringLiteral("hibiki"));
  QApplication::setWindowIcon(QIcon(QStringLiteral(":/assets/hibiki.svg")));
  QApplication::setQuitOnLastWindowClosed(false);
  QQuickStyle::setStyle(QStringLiteral("Basic"));

  const QString mprisService = QStringLiteral("org.mpris.MediaPlayer2.hibiki");
  QDBusConnection sessionBus = QDBusConnection::sessionBus();
  const QDBusReply<bool> alreadyRunning =
      sessionBus.interface()->isServiceRegistered(mprisService);
  if (alreadyRunning.isValid() && alreadyRunning.value()) {
    QDBusInterface existingInstance(
        mprisService, QStringLiteral("/org/mpris/MediaPlayer2"),
        QStringLiteral("org.mpris.MediaPlayer2"), sessionBus);
    existingInstance.call(QStringLiteral("Raise"));
    return 0;
  }

  QQmlApplicationEngine engine;
  ApplicationController controller(&engine);
  if (!controller.initialize())
    return 1;

  engine.rootContext()->setContextProperty(QStringLiteral("App"), &controller);
  engine.rootContext()->setContextProperty(QStringLiteral("Tracks"),
                                           controller.tracks());
  engine.rootContext()->setContextProperty(QStringLiteral("Player"),
                                           controller.player());
  engine.rootContext()->setContextProperty(QStringLiteral("Downloads"),
                                           controller.downloads());
  engine.rootContext()->setContextProperty(QStringLiteral("Discord"),
                                           controller.discord());
  engine.rootContext()->setContextProperty(QStringLiteral("Theme"),
                                           controller.theme());
  engine.loadFromModule(QStringLiteral("Hibiki"), QStringLiteral("Main"));
  if (engine.rootObjects().isEmpty())
    return 2;
  return app.exec();
}
