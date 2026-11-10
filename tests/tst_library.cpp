#include "LibraryRepository.h"
#include "TrackModel.h"

#include <QTemporaryDir>
#include <QtTest>

class LibraryRepositoryTest final : public QObject {
  Q_OBJECT

private slots:
  void storesUpdatesAndRemovesTrack();
  void storesIndependentPlaylists();
  void filtersTracksByPlaylistAndSearch();
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

void LibraryRepositoryTest::storesIndependentPlaylists() {
  QTemporaryDir directory;
  QVERIFY(directory.isValid());
  LibraryRepository repository(QStringLiteral("playlists-test"));
  QVERIFY2(repository.open(directory.filePath(QStringLiteral("library.sqlite"))),
           qPrintable(repository.lastError()));
  QVERIFY2(repository.initialize(), qPrintable(repository.lastError()));

  QVariantMap track = {
      {QStringLiteral("source_id"), QStringLiteral("first")},
      {QStringLiteral("title"), QStringLiteral("First")},
      {QStringLiteral("file_path"), directory.filePath(QStringLiteral("first.opus"))},
      {QStringLiteral("added_at"), 1}};
  QVERIFY(repository.upsertTrack(track));
  const qint64 firstTrack =
      repository.tracks().first().toMap().value(QStringLiteral("id")).toLongLong();
  track[QStringLiteral("source_id")] = QStringLiteral("second");
  track[QStringLiteral("title")] = QStringLiteral("Second");
  track[QStringLiteral("file_path")] = directory.filePath(QStringLiteral("second.opus"));
  QVERIFY(repository.upsertTrack(track));
  const qint64 secondTrack =
      repository.tracks().first().toMap().value(QStringLiteral("id")).toLongLong();

  const qint64 morning = repository.createPlaylist(QStringLiteral("Morning"));
  const qint64 evening = repository.createPlaylist(QStringLiteral("Evening"));
  QVERIFY(morning > 0);
  QVERIFY(evening > morning);
  QVERIFY(repository.addToPlaylist(morning, firstTrack));
  QVERIFY(repository.addToPlaylist(morning, secondTrack));
  QVERIFY(repository.addToPlaylist(morning, firstTrack));
  QVERIFY(repository.addToPlaylist(evening, secondTrack));
  QCOMPARE(repository.playlistTrackIds(morning), (QList<qint64>{firstTrack, secondTrack}));
  QCOMPARE(repository.playlistTrackIds(evening), (QList<qint64>{secondTrack}));
  QCOMPARE(repository.playlists().first().toMap().value(QStringLiteral("count")).toInt(), 2);

  QVERIFY(repository.renamePlaylist(evening, QStringLiteral("Night")));
  QCOMPARE(repository.playlists().last().toMap().value(QStringLiteral("name")).toString(),
           QStringLiteral("Night"));
  QVERIFY(repository.removeFromPlaylist(morning, firstTrack));
  QCOMPARE(repository.playlistTrackIds(morning), (QList<qint64>{secondTrack}));
  QVERIFY(repository.removeTrack(secondTrack));
  QVERIFY(repository.playlistTrackIds(morning).isEmpty());
  QVERIFY(repository.playlistTrackIds(evening).isEmpty());
  QVERIFY(repository.deletePlaylist(morning));
  QCOMPARE(repository.playlists().size(), 1);
  QCOMPARE(repository.tracks().size(), 1);
}

void LibraryRepositoryTest::filtersTracksByPlaylistAndSearch() {
  QTemporaryDir directory;
  QVERIFY(directory.isValid());
  const QString database = directory.filePath(QStringLiteral("library.sqlite"));
  {
    LibraryRepository repository(QStringLiteral("model-seed"));
    QVERIFY(repository.open(database));
    QVERIFY(repository.initialize());
    for (const QString &title : {QStringLiteral("Blue"), QStringLiteral("Red")}) {
      QVERIFY(repository.upsertTrack({
          {QStringLiteral("title"), title},
          {QStringLiteral("file_path"), directory.filePath(title + QStringLiteral(".opus"))},
          {QStringLiteral("added_at"), 1}}));
    }
  }

  TrackModel model;
  QVERIFY(model.initialize(database, directory.path()));
  QCOMPARE(model.libraryCount(), 2);
  QCOMPARE(model.rowCount(), 2);
  const qint64 blue = model.trackByFilePath(directory.filePath(QStringLiteral("Blue.opus")))
                           .value(QStringLiteral("id")).toLongLong();
  const qint64 red = model.trackByFilePath(directory.filePath(QStringLiteral("Red.opus")))
                          .value(QStringLiteral("id")).toLongLong();
  const qint64 first = model.createPlaylist(QStringLiteral("First"));
  const qint64 second = model.createPlaylist(QStringLiteral("Second"));
  QVERIFY(model.addToPlaylist(first, red));
  QVERIFY(model.addToPlaylist(first, blue));
  QVERIFY(model.addToPlaylist(second, blue));

  model.setSelectedPlaylistId(first);
  QCOMPARE(model.rowCount(), 2);
  QCOMPARE(model.trackAt(0).value(QStringLiteral("title")).toString(), QStringLiteral("Red"));
  model.setSearchText(QStringLiteral("blue"));
  QCOMPARE(model.rowCount(), 1);
  QCOMPARE(model.trackAt(0).value(QStringLiteral("title")).toString(), QStringLiteral("Blue"));
  model.setSearchText({});
  model.setSelectedPlaylistId(second);
  QCOMPARE(model.rowCount(), 1);
  QCOMPARE(model.selectedPlaylistName(), QStringLiteral("Second"));
  QVERIFY(model.removeFromPlaylist(second, blue));
  QCOMPARE(model.rowCount(), 0);
  QCOMPARE(model.libraryCount(), 2);
  model.setSelectedPlaylistId(-1);
  QCOMPARE(model.rowCount(), 2);
}

QTEST_GUILESS_MAIN(LibraryRepositoryTest)
#include "tst_library.moc"
