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
  int indexOfFilePath(const QString &filePath) const;
  QString searchText() const;
  void setSearchText(const QString &text);
  bool scanning() const { return m_scanning; }

  Q_INVOKABLE void refresh();
  Q_INVOKABLE void rescan();
  Q_INVOKABLE bool remove(int index, bool deleteFile = false);

signals:
  void countChanged();
  void searchTextChanged();
  void scanningChanged();
  void errorOccurred(const QString &message);

private:
  void load();
  void applyScanResult(const QVariantList &imported);
  void setScanning(bool scanning);
  bool matchesSearch(const QVariantMap &track) const;

  std::unique_ptr<LibraryRepository> m_repository;
  QFutureWatcher<QVariantList> m_scanWatcher;
  QVariantList m_allTracks;
  QVariantList m_tracks;
  QString m_musicDirectory;
  QString m_searchText;
  bool m_scanning{false};
  bool m_rescanQueued{false};
};
