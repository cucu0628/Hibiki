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
  return addMissingColumns();
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
