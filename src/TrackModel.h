#pragma once

#include <QAbstractListModel>
#include <QFutureWatcher>
#include <QVariantMap>

#include <memory>

class LibraryRepository;

class TrackModel final : public QAbstractListModel {
  Q_OBJECT
  Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY
                 searchTextChanged)
  Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
  Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
  Q_PROPERTY(int libraryCount READ libraryCount NOTIFY countChanged)
  Q_PROPERTY(QVariantList playlists READ playlists NOTIFY playlistsChanged)
  Q_PROPERTY(qint64 selectedPlaylistId READ selectedPlaylistId WRITE
                 setSelectedPlaylistId NOTIFY selectedPlaylistChanged)
  Q_PROPERTY(QString selectedPlaylistName READ selectedPlaylistName NOTIFY
                 selectedPlaylistChanged)

public:
  enum Roles {
    IdRole = Qt::UserRole + 1,
    TitleRole,
    ArtistRole,
    AlbumRole,
    DurationRole,
    FilePathRole,
    CoverPathRole,
    SourceUrlRole
  };

  explicit TrackModel(QObject *parent = nullptr);
  ~TrackModel() override;

  int rowCount(const QModelIndex &parent = {}) const override;
  QVariant data(const QModelIndex &index, int role) const override;
  QHash<int, QByteArray> roleNames() const override;

  bool initialize(const QString &databasePath, const QString &musicDirectory);
  QVariantMap trackAt(int index) const;
  Q_INVOKABLE int indexOfFilePath(const QString &filePath) const;
  QString searchText() const;
  void setSearchText(const QString &text);
  bool scanning() const { return m_scanning; }
  int libraryCount() const { return m_allTracks.size(); }
  QVariantList playlists() const { return m_playlists; }
  qint64 selectedPlaylistId() const { return m_selectedPlaylistId; }
  QString selectedPlaylistName() const;
  void setSelectedPlaylistId(qint64 id);
  QVariantList visibleTracks() const { return m_tracks; }
  QVariantList libraryTracks() const { return m_allTracks; }
  QVariantMap trackByFilePath(const QString &filePath) const;

  Q_INVOKABLE void refresh();
  Q_INVOKABLE void rescan();
  Q_INVOKABLE bool remove(int index, bool deleteFile = false);
  Q_INVOKABLE qint64 createPlaylist(const QString &name);
  Q_INVOKABLE bool renamePlaylist(qint64 id, const QString &name);
  Q_INVOKABLE bool deletePlaylist(qint64 id);
  Q_INVOKABLE bool addToPlaylist(qint64 playlistId, qint64 trackId);
  Q_INVOKABLE bool removeFromPlaylist(qint64 playlistId, qint64 trackId);

signals:
  void countChanged();
  void searchTextChanged();
  void scanningChanged();
  void errorOccurred(const QString &message);
  void playlistsChanged();
  void selectedPlaylistChanged();

private:
  void load();
  void applyScanResult(const QVariantList &imported);
  void setScanning(bool scanning);
  bool matchesSearch(const QVariantMap &track) const;
  void refreshPlaylists();

  std::unique_ptr<LibraryRepository> m_repository;
  QFutureWatcher<QVariantList> m_scanWatcher;
  QVariantList m_allTracks;
  QVariantList m_tracks;
  QVariantList m_playlists;
  qint64 m_selectedPlaylistId{-1};
  QString m_musicDirectory;
  QString m_searchText;
  bool m_scanning{false};
  bool m_rescanQueued{false};
};
