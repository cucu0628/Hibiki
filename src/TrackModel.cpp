#include "TrackModel.h"

#include "LibraryRepository.h"

#include <QDateTime>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QtConcurrent/QtConcurrentRun>

#include <utility>

namespace {
// Reads one audio file and its sidecar metadata. Runs on a worker thread, so
// it must not touch the model or the database.
QVariantMap readTrack(const QFileInfo &audio) {
  const QString base =
      audio.absolutePath() + QLatin1Char('/') + audio.completeBaseName();
  QFile infoFile(base + QStringLiteral(".info.json"));
  QJsonObject metadata;
  if (infoFile.open(QIODevice::ReadOnly))
    metadata = QJsonDocument::fromJson(infoFile.readAll()).object();

  QString coverPath;
  for (const QString &extension :
       {QStringLiteral(".jpg"), QStringLiteral(".png"),
        QStringLiteral(".webp")}) {
    if (QFileInfo::exists(base + extension)) {
      coverPath = base + extension;
      break;
    }
  }

  QString title = metadata.value(QStringLiteral("title")).toString();
  if (title.isEmpty()) {
    title = audio.completeBaseName();
    static const QRegularExpression videoIdSuffix(
        QStringLiteral(" \\[[A-Za-z0-9_-]{6,}\\]$"));
    title.remove(videoIdSuffix);
  }

  return QVariantMap{
      {QStringLiteral("source_id"),
       metadata.value(QStringLiteral("id")).toString()},
      {QStringLiteral("title"), title},
      {QStringLiteral("artist"),
       metadata.value(QStringLiteral("artist"))
           .toString(metadata.value(QStringLiteral("uploader")).toString())},
      {QStringLiteral("album"),
       metadata.value(QStringLiteral("playlist_title")).toString()},
      {QStringLiteral("duration"),
       qRound64(metadata.value(QStringLiteral("duration")).toDouble() * 1000.0)},
      {QStringLiteral("file_path"), audio.absoluteFilePath()},
      {QStringLiteral("cover_path"), coverPath},
      {QStringLiteral("source_url"),
       metadata.value(QStringLiteral("webpage_url")).toString()},
      {QStringLiteral("added_at"), audio.birthTime().toSecsSinceEpoch()},
      {QStringLiteral("file_mtime"), audio.lastModified().toMSecsSinceEpoch()},
      {QStringLiteral("file_size"), audio.size()}};
}

// Walks the music directory and returns only the tracks whose file changed
// since the last scan, so a warm start reads no sidecar files at all.
QVariantList scanDirectory(
    const QString &musicDirectory,
    const QHash<QString, LibraryRepository::FileStamp> &knownStamps) {
  QVariantList imported;
  QDirIterator iterator(musicDirectory,
                        {QStringLiteral("*.opus"), QStringLiteral("*.ogg"),
                         QStringLiteral("*.m4a"), QStringLiteral("*.mp3"),
                         QStringLiteral("*.flac")},
                        QDir::Files, QDirIterator::Subdirectories);
  while (iterator.hasNext()) {
    iterator.next();
    const QFileInfo audio = iterator.fileInfo();
    const LibraryRepository::FileStamp stamp{
        audio.lastModified().toMSecsSinceEpoch(), audio.size()};
    const auto known = knownStamps.constFind(audio.absoluteFilePath());
    if (known != knownStamps.constEnd() && *known == stamp)
      continue;
    imported.append(readTrack(audio));
  }
  return imported;
}
} // namespace

TrackModel::TrackModel(QObject *parent)
    : QAbstractListModel(parent),
      m_repository(std::make_unique<LibraryRepository>()) {
  connect(&m_scanWatcher, &QFutureWatcher<QVariantList>::finished, this,
          [this] { applyScanResult(m_scanWatcher.result()); });
}

TrackModel::~TrackModel() {
  if (m_scanWatcher.isRunning())
    m_scanWatcher.waitForFinished();
}

int TrackModel::rowCount(const QModelIndex &parent) const {
  return parent.isValid() ? 0 : m_tracks.size();
}

QVariant TrackModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() < 0 || index.row() >= m_tracks.size())
    return {};
  const QVariantMap track = m_tracks.at(index.row()).toMap();
  static const QHash<int, QString> keys = {
      {IdRole, QStringLiteral("id")},
      {TitleRole, QStringLiteral("title")},
      {ArtistRole, QStringLiteral("artist")},
      {AlbumRole, QStringLiteral("album")},
      {DurationRole, QStringLiteral("duration")},
      {FilePathRole, QStringLiteral("filePath")},
      {CoverPathRole, QStringLiteral("coverPath")},
      {SourceUrlRole, QStringLiteral("sourceUrl")}};
  return track.value(keys.value(role));
}

QHash<int, QByteArray> TrackModel::roleNames() const {
  return {{IdRole, "trackId"},          {TitleRole, "title"},
          {ArtistRole, "artist"},       {AlbumRole, "album"},
          {DurationRole, "duration"},   {FilePathRole, "filePath"},
          {CoverPathRole, "coverPath"}, {SourceUrlRole, "sourceUrl"}};
}

bool TrackModel::initialize(const QString &databasePath,
                            const QString &musicDirectory) {
  m_musicDirectory = musicDirectory;
  if (!m_repository->open(databasePath) || !m_repository->initialize()) {
    emit errorOccurred(m_repository->lastError());
    return false;
  }
  // Show the stored library straight away; the disk scan happens in the
  // background once the window is up.
  refresh();
  return true;
}

QVariantMap TrackModel::trackAt(int index) const {
  return index >= 0 && index < m_tracks.size() ? m_tracks.at(index).toMap()
                                               : QVariantMap{};
}

int TrackModel::indexOfFilePath(const QString &filePath) const {
  for (int index = 0; index < m_tracks.size(); ++index) {
    if (m_tracks.at(index)
            .toMap()
            .value(QStringLiteral("filePath"))
            .toString() == filePath)
      return index;
  }
  return -1;
}

QVariantMap TrackModel::trackByFilePath(const QString &filePath) const {
  for (const QVariant &item : m_allTracks) {
    const QVariantMap track = item.toMap();
    if (track.value(QStringLiteral("filePath")).toString() == filePath)
      return track;
  }
  return {};
}

QString TrackModel::selectedPlaylistName() const {
  if (m_selectedPlaylistId < 0)
    return QStringLiteral("Library");
  for (const QVariant &item : m_playlists) {
    const QVariantMap playlist = item.toMap();
    if (playlist.value(QStringLiteral("id")).toLongLong() == m_selectedPlaylistId)
      return playlist.value(QStringLiteral("name")).toString();
  }
  return QStringLiteral("Library");
}

void TrackModel::setSelectedPlaylistId(qint64 id) {
  if (id == m_selectedPlaylistId)
    return;
  if (id >= 0) {
    bool found = false;
    for (const QVariant &item : m_playlists)
      found |= item.toMap().value(QStringLiteral("id")).toLongLong() == id;
    if (!found)
      return;
  }
  m_selectedPlaylistId = id;
  emit selectedPlaylistChanged();
  load();
}

void TrackModel::refreshPlaylists() {
  m_playlists = m_repository->playlists();
  emit playlistsChanged();
  emit selectedPlaylistChanged();
}

qint64 TrackModel::createPlaylist(const QString &name) {
  const QString trimmed = name.trimmed();
  if (trimmed.isEmpty())
    return -1;
  const qint64 id = m_repository->createPlaylist(trimmed);
  if (id < 0)
    emit errorOccurred(m_repository->lastError());
  else
    refreshPlaylists();
  return id;
}

bool TrackModel::renamePlaylist(qint64 id, const QString &name) {
  const QString trimmed = name.trimmed();
  if (trimmed.isEmpty() || !m_repository->renamePlaylist(id, trimmed))
    return false;
  refreshPlaylists();
  return true;
}

bool TrackModel::deletePlaylist(qint64 id) {
  if (!m_repository->deletePlaylist(id))
    return false;
  if (m_selectedPlaylistId == id)
    setSelectedPlaylistId(-1);
  refreshPlaylists();
  return true;
}

bool TrackModel::addToPlaylist(qint64 playlistId, qint64 trackId) {
  if (!m_repository->addToPlaylist(playlistId, trackId)) {
    emit errorOccurred(m_repository->lastError());
    return false;
  }
  refreshPlaylists();
  if (m_selectedPlaylistId == playlistId)
    load();
  return true;
}

bool TrackModel::removeFromPlaylist(qint64 playlistId, qint64 trackId) {
  if (!m_repository->removeFromPlaylist(playlistId, trackId)) {
    emit errorOccurred(m_repository->lastError());
    return false;
  }
  refreshPlaylists();
  if (m_selectedPlaylistId == playlistId)
    load();
  return true;
}

QString TrackModel::searchText() const { return m_searchText; }

void TrackModel::setSearchText(const QString &text) {
  if (m_searchText == text)
    return;
  m_searchText = text;
  emit searchTextChanged();
  load();
}

void TrackModel::refresh() {
  m_allTracks = m_repository->tracks();
  refreshPlaylists();
  load();
}

void TrackModel::load() {
  beginResetModel();
  m_tracks.clear();
  if (m_selectedPlaylistId < 0) {
    for (const QVariant &item : std::as_const(m_allTracks)) {
      if (matchesSearch(item.toMap()))
        m_tracks.append(item);
    }
  } else {
    QHash<qint64, QVariant> byId;
    for (const QVariant &item : std::as_const(m_allTracks))
      byId.insert(item.toMap().value(QStringLiteral("id")).toLongLong(), item);
    for (qint64 id : m_repository->playlistTrackIds(m_selectedPlaylistId)) {
      const QVariant item = byId.value(id);
      if (item.isValid() && matchesSearch(item.toMap()))
        m_tracks.append(item);
    }
  }
  endResetModel();
  emit countChanged();
}

bool TrackModel::matchesSearch(const QVariantMap &track) const {
  if (m_searchText.trimmed().isEmpty())
    return true;
  const QString needle = m_searchText.trimmed();
  return track.value(QStringLiteral("title"))
             .toString()
             .contains(needle, Qt::CaseInsensitive) ||
         track.value(QStringLiteral("artist"))
             .toString()
             .contains(needle, Qt::CaseInsensitive) ||
         track.value(QStringLiteral("album"))
             .toString()
             .contains(needle, Qt::CaseInsensitive);
}

void TrackModel::rescan() {
  if (m_musicDirectory.isEmpty())
    return;
  if (m_scanWatcher.isRunning()) {
    // A download finished while a scan was running: repeat it afterwards.
    m_rescanQueued = true;
    return;
  }
  setScanning(true);
  const QHash<QString, LibraryRepository::FileStamp> knownStamps =
      m_repository->fileStamps();
  m_scanWatcher.setFuture(QtConcurrent::run(scanDirectory, m_musicDirectory,
                                            knownStamps));
}

void TrackModel::applyScanResult(const QVariantList &imported) {
  if (!imported.isEmpty()) {
    // One transaction for the whole batch instead of a disk flush per track.
    m_repository->beginBatch();
    for (const QVariant &value : imported) {
      if (!m_repository->upsertTrack(value.toMap())) {
        emit errorOccurred(m_repository->lastError());
        break;
      }
    }
    if (!m_repository->commitBatch())
      emit errorOccurred(m_repository->lastError());
    refresh();
  }
  setScanning(false);
  if (m_rescanQueued) {
    m_rescanQueued = false;
    rescan();
  }
}

void TrackModel::setScanning(bool scanning) {
  if (m_scanning == scanning)
    return;
  m_scanning = scanning;
  emit scanningChanged();
}

bool TrackModel::remove(int index, bool deleteFile) {
  const QVariantMap track = trackAt(index);
  if (track.isEmpty())
    return false;
  if (deleteFile) {
    const QFileInfo audio(track.value(QStringLiteral("filePath")).toString());
    const QString base =
        audio.absolutePath() + QLatin1Char('/') + audio.completeBaseName();
    QFile::remove(audio.absoluteFilePath());
    QFile::remove(base + QStringLiteral(".info.json"));
    QFile::remove(track.value(QStringLiteral("coverPath")).toString());
  }
  if (!m_repository->removeTrack(
          track.value(QStringLiteral("id")).toLongLong())) {
    emit errorOccurred(m_repository->lastError());
    return false;
  }
  refresh();
  return true;
}
