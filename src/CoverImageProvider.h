#pragma once

#include <QQuickImageProvider>

// Serves cover art already cropped to the requested size with its corners
// rounded, so artwork tiles need no per-item mask layer or shader effect.
//
// Image ids look like "<radius>/<percent-encoded path>", where <radius> is the
// corner radius as a fraction of the shorter side (0.5 gives a circle).
class CoverImageProvider final : public QQuickImageProvider {
public:
  CoverImageProvider();

  QImage requestImage(const QString &id, QSize *size,
                      const QSize &requestedSize) override;
};
