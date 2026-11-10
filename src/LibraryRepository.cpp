#include "LibraryRepository.h"

#include <QFileInfo>
#include <QSqlError>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QUuid>

namespace {
const QStringList &upsertKeys() {
  static const QStringList keys = {
      QStringLiteral("source_id"),  QStringLiteral("title"),
      QStringLiteral("artist"),     QStringLiteral("album"),
      QStringLiteral("duration"),   QStringLiteral("file_path"),
      QStringLiteral("cover_path"), QStringLiteral("source_url"),
      QStringLiteral("added_at"),   QStringLiteral("file_mtime"),
      QStringLiteral("file_size")};
  return keys;
}
} // namespace

LibraryRepository::LibraryRepository(QString connectionName)
    : m_connectionName(
          connectionName.isEmpty()
              ? QStringLiteral("hibiki-%1")
                    .arg(QUuid::createUuid().toString(QUuid::WithoutBraces))
              : std::move(connectionName)) {}

LibraryRepository::~LibraryRepository() {
  m_upsertQuery.reset();
  if (m_database.isValid())
    m_database.close();
  m_database = {};
  QSqlDatabase::removeDatabase(m_connectionName);
}

bool LibraryRepository::open(const QString &databasePath) {
  m_database =
      QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
  m_database.setDatabaseName(databasePath);
  if (!m_database.open()) {
    m_lastError = m_database.lastError().text();
    return false;
  }
  // Write-ahead logging with relaxed syncing keeps the library scan from
  // paying a full disk flush per track.
  QSqlQuery pragma(m_database);
  pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
  pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
  return true;
}

bool LibraryRepository::initialize() {
  QSqlQuery query(m_database);
  if (!query.exec(QStringLiteral(
          "CREATE TABLE IF NOT EXISTS tracks ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "source_id TEXT UNIQUE, title TEXT NOT NULL, artist TEXT, album TEXT,"
          "duration INTEGER DEFAULT 0, file_path TEXT UNIQUE NOT NULL,"
          "cover_path TEXT, source_url TEXT, added_at INTEGER NOT NULL,"
          "file_mtime INTEGER DEFAULT 0, file_size INTEGER DEFAULT 0)"))) {
    m_lastError = query.lastError().text();
    return false;
  }
  if (!addMissingColumns())
    return false;
  if (!query.exec(QStringLiteral(
          "CREATE TABLE IF NOT EXISTS playlists ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)")) ||
      !query.exec(QStringLiteral(
          "CREATE TABLE IF NOT EXISTS playlist_tracks ("
          "playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,"
          "track_id INTEGER NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,"
          "position INTEGER NOT NULL, PRIMARY KEY(playlist_id, track_id))"))) {
    m_lastError = query.lastError().text();
    return false;
  }
  QSqlQuery foreignKeys(m_database);
  if (!foreignKeys.exec(QStringLiteral("PRAGMA foreign_keys=ON"))) {
    m_lastError = foreignKeys.lastError().text();
    return false;
  }
  return true;
}

bool LibraryRepository::addMissingColumns() {
  QSqlQuery columns(m_database);
  if (!columns.exec(QStringLiteral("PRAGMA table_info(tracks)"))) {
    m_lastError = columns.lastError().text();
    return false;
  }
  QStringList existing;
  while (columns.next())
    existing << columns.value(1).toString();

  static const QStringList added = {
      QStringLiteral("file_mtime INTEGER DEFAULT 0"),
      QStringLiteral("file_size INTEGER DEFAULT 0")};
  for (const QString &definition : added) {
    const QString name = definition.section(QLatin1Char(' '), 0, 0);
    if (existing.contains(name))
      continue;
    QSqlQuery alter(m_database);
    if (!alter.exec(QStringLiteral("ALTER TABLE tracks ADD COLUMN ") +
                    definition)) {
      m_lastError = alter.lastError().text();
      return false;
    }
  }
  return true;
}

bool LibraryRepository::upsertTrack(const QVariantMap &track) {
  if (!m_upsertQuery) {
    m_upsertQuery = std::make_unique<QSqlQuery>(m_database);
    m_upsertQuery->prepare(QStringLiteral(
        "INSERT INTO "
        "tracks(source_id,title,artist,album,duration,file_path,cover_path,"
        "source_url,added_at,file_mtime,file_size) "
        "VALUES(:source_id,:title,:artist,:album,:duration,:file_path,:cover_"
        "path,:source_url,:added_at,:file_mtime,:file_size) "
        "ON CONFLICT(file_path) DO UPDATE SET "
        "source_id=excluded.source_id,title=excluded.title,"
        "artist=excluded.artist,album=excluded.album,duration=excluded.duration,"
        "cover_path=excluded.cover_path,source_url=excluded.source_url,"
        "file_mtime=excluded.file_mtime,file_size=excluded.file_size"));
  }

  for (const QString &key : upsertKeys()) {
    const bool numeric = key == QStringLiteral("file_mtime") ||
                         key == QStringLiteral("file_size");
    m_upsertQuery->bindValue(QLatin1Char(':') + key,
                             track.value(key, numeric ? QVariant(0)
                                                      : QVariant()));
  }

  if (!m_upsertQuery->exec()) {
    m_lastError = m_upsertQuery->lastError().text();
    return false;
  }
  m_upsertQuery->finish();
  return true;
}

bool LibraryRepository::removeTrack(qint64 id) {
  QSqlQuery query(m_database);
  query.prepare(QStringLiteral("DELETE FROM tracks WHERE id=:id"));
  query.bindValue(QStringLiteral(":id"), id);
  if (!query.exec()) {
    m_lastError = query.lastError().text();
    return false;
  }
  return true;
}

QVariantList LibraryRepository::tracks() const {
  QVariantList result;
  QSqlQuery query(m_database);
  query.setForwardOnly(true);
  if (!query.exec(
          QStringLiteral("SELECT "
                         "id,source_id,title,artist,album,duration,file_path,"
                         "cover_path,source_url "
                         "FROM tracks ORDER BY added_at DESC, id DESC"))) {
    m_lastError = query.lastError().text();
    return result;
  }

  while (query.next()) {
    QVariantMap track;
    track[QStringLiteral("id")] = query.value(0);
    track[QStringLiteral("sourceId")] = query.value(1);
    track[QStringLiteral("title")] = query.value(2);
    track[QStringLiteral("artist")] = query.value(3);
    track[QStringLiteral("album")] = query.value(4);
    track[QStringLiteral("duration")] = query.value(5);
    track[QStringLiteral("filePath")] = query.value(6);
    track[QStringLiteral("coverPath")] = query.value(7);
    track[QStringLiteral("sourceUrl")] = query.value(8);
    result.append(track);
  }
  return result;
}

QVariantList LibraryRepository::playlists() const {
  QVariantList result;
  QSqlQuery query(m_database);
  if (!query.exec(QStringLiteral(
          "SELECT p.id,p.name,COUNT(pt.track_id) FROM playlists p "
          "LEFT JOIN playlist_tracks pt ON pt.playlist_id=p.id "
          "GROUP BY p.id ORDER BY p.id"))) {
    m_lastError = query.lastError().text();
    return result;
  }
  while (query.next())
    result.append(QVariantMap{{QStringLiteral("id"), query.value(0)},
                              {QStringLiteral("name"), query.value(1)},
                              {QStringLiteral("count"), query.value(2)}});
  return result;
}

QList<qint64> LibraryRepository::playlistTrackIds(qint64 playlistId) const {
  QList<qint64> result;
  QSqlQuery query(m_database);
  query.prepare(QStringLiteral("SELECT track_id FROM playlist_tracks WHERE "
                               "playlist_id=:id ORDER BY position, rowid"));
  query.bindValue(QStringLiteral(":id"), playlistId);
  if (!query.exec()) {
    m_lastError = query.lastError().text();
    return result;
  }
  while (query.next())
    result.append(query.value(0).toLongLong());
  return result;
}

qint64 LibraryRepository::createPlaylist(const QString &name) {
  QSqlQuery query(m_database);
  query.prepare(QStringLiteral("INSERT INTO playlists(name) VALUES(:name)"));
  query.bindValue(QStringLiteral(":name"), name);
  if (!query.exec()) {
    m_lastError = query.lastError().text();
    return -1;
  }
  return query.lastInsertId().toLongLong();
}

bool LibraryRepository::renamePlaylist(qint64 id, const QString &name) {
  QSqlQuery query(m_database);
  query.prepare(QStringLiteral("UPDATE playlists SET name=:name WHERE id=:id"));
  query.bindValue(QStringLiteral(":name"), name);
  query.bindValue(QStringLiteral(":id"), id);
  if (query.exec())
    return query.numRowsAffected() > 0;
  m_lastError = query.lastError().text();
  return false;
}

bool LibraryRepository::deletePlaylist(qint64 id) {
  QSqlQuery query(m_database);
  query.prepare(QStringLiteral("DELETE FROM playlists WHERE id=:id"));
  query.bindValue(QStringLiteral(":id"), id);
  if (query.exec())
    return query.numRowsAffected() > 0;
  m_lastError = query.lastError().text();
  return false;
}

bool LibraryRepository::addToPlaylist(qint64 playlistId, qint64 trackId) {
  QSqlQuery query(m_database);
  query.prepare(QStringLiteral(
      "INSERT OR IGNORE INTO playlist_tracks(playlist_id,track_id,position) "
      "SELECT :playlist_id,:track_id,COALESCE(MAX(position)+1,0) "
      "FROM playlist_tracks WHERE playlist_id=:position_id"));
  query.bindValue(QStringLiteral(":playlist_id"), playlistId);
  query.bindValue(QStringLiteral(":track_id"), trackId);
  query.bindValue(QStringLiteral(":position_id"), playlistId);
  if (query.exec())
    return true;
  m_lastError = query.lastError().text();
  return false;
}

bool LibraryRepository::removeFromPlaylist(qint64 playlistId, qint64 trackId) {
  QSqlQuery query(m_database);
  query.prepare(QStringLiteral("DELETE FROM playlist_tracks WHERE "
                               "playlist_id=:playlist_id AND track_id=:track_id"));
  query.bindValue(QStringLiteral(":playlist_id"), playlistId);
  query.bindValue(QStringLiteral(":track_id"), trackId);
  if (query.exec())
    return true;
  m_lastError = query.lastError().text();
  return false;
}

QHash<QString, LibraryRepository::FileStamp>
LibraryRepository::fileStamps() const {
  QHash<QString, FileStamp> stamps;
  QSqlQuery query(m_database);
  query.setForwardOnly(true);
  if (!query.exec(QStringLiteral(
          "SELECT file_path,file_mtime,file_size FROM tracks"))) {
    m_lastError = query.lastError().text();
    return stamps;
  }
  while (query.next()) {
    stamps.insert(query.value(0).toString(),
                  FileStamp{query.value(1).toLongLong(),
                            query.value(2).toLongLong()});
  }
  return stamps;
}

bool LibraryRepository::beginBatch() { return m_database.transaction(); }

bool LibraryRepository::commitBatch() {
  if (m_database.commit())
    return true;
  m_lastError = m_database.lastError().text();
  return false;
}

QString LibraryRepository::lastError() const { return m_lastError; }
