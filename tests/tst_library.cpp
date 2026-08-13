#include "LibraryRepository.h"

#include <QTemporaryDir>
#include <QtTest>

class LibraryRepositoryTest final : public QObject {
  Q_OBJECT

private slots:
  void storesUpdatesAndRemovesTrack();
};

void LibraryRepositoryTest::storesUpdatesAndRemovesTrack() {
  QTemporaryDir directory;
  QVERIFY(directory.isValid());

  LibraryRepository repository(QStringLiteral("library-test"));
  QVERIFY2(
      repository.open(directory.filePath(QStringLiteral("library.sqlite"))),
      qPrintable(repository.lastError()));
  QVERIFY2(repository.initialize(), qPrintable(repository.lastError()));

  QVariantMap track = {
      {QStringLiteral("source_id"), QStringLiteral("video-id")},
      {QStringLiteral("title"), QStringLiteral("First title")},
      {QStringLiteral("artist"), QStringLiteral("Artist")},
      {QStringLiteral("album"), QStringLiteral("Playlist")},
      {QStringLiteral("duration"), 123000},
      {QStringLiteral("file_path"),
       directory.filePath(QStringLiteral("track.opus"))},
      {QStringLiteral("cover_path"),
       directory.filePath(QStringLiteral("track.jpg"))},
      {QStringLiteral("source_url"),
       QStringLiteral("https://youtu.be/video-id")},
      {QStringLiteral("added_at"), 1}};
  QVERIFY2(repository.upsertTrack(track), qPrintable(repository.lastError()));
  QCOMPARE(repository.tracks().size(), 1);
  QCOMPARE(repository.tracks()
               .first()
               .toMap()
               .value(QStringLiteral("title"))
               .toString(),
           QStringLiteral("First title"));

  track[QStringLiteral("title")] = QStringLiteral("Updated title");
  QVERIFY(repository.upsertTrack(track));
  const QVariantMap stored = repository.tracks().first().toMap();
  QCOMPARE(stored.value(QStringLiteral("title")).toString(),
           QStringLiteral("Updated title"));
  QVERIFY(
      repository.removeTrack(stored.value(QStringLiteral("id")).toLongLong()));
  QVERIFY(repository.tracks().isEmpty());
}

QTEST_GUILESS_MAIN(LibraryRepositoryTest)
#include "tst_library.moc"
