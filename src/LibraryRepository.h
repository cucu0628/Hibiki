#pragma once

#include <QHash>
#include <QSqlDatabase>
#include <QString>
#include <QVariantList>

#include <memory>

class QSqlQuery;

class LibraryRepository {
public:
  struct FileStamp {
    qint64 modified{0};
    qint64 size{0};

    bool operator==(const FileStamp &other) const {
      return modified == other.modified && size == other.size;
    }
  };

  explicit LibraryRepository(QString connectionName = {});
  ~LibraryRepository();

  bool open(const QString &databasePath);
  bool initialize();
  bool upsertTrack(const QVariantMap &track);
  bool removeTrack(qint64 id);
  QVariantList tracks() const;
  // File modification stamps keyed by absolute path, so a rescan can skip
  // files that have not changed since the previous run.
  QHash<QString, FileStamp> fileStamps() const;
  bool beginBatch();
  bool commitBatch();
  QString lastError() const;

private:
  bool addMissingColumns();

  QString m_connectionName;
  QSqlDatabase m_database;
  std::unique_ptr<QSqlQuery> m_upsertQuery;
  mutable QString m_lastError;
};
