#include "CoverImageProvider.h"

#include <QImageReader>
#include <QPainter>
#include <QPainterPath>
#include <QUrl>

CoverImageProvider::CoverImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image,
                          QQmlImageProviderBase::ForceAsynchronousImageLoading) {}

QImage CoverImageProvider::requestImage(const QString &id, QSize *size,
                                        const QSize &requestedSize) {
  const qsizetype separator = id.indexOf(QLatin1Char('/'));
  if (separator < 0)
    return {};
  const qreal radius = qBound(0.0, id.left(separator).toDouble(), 0.5);
  QImageReader reader(QUrl::fromPercentEncoding(id.mid(separator + 1).toUtf8()));
  const QSize natural = reader.size();
  if (!natural.isValid())
    return {};

  // Square crop unless a different shape was asked for.
  QSize target = requestedSize;
  if (target.width() <= 0 && target.height() <= 0)
    target = QSize(qMin(natural.width(), natural.height()),
                   qMin(natural.width(), natural.height()));
  else if (target.width() <= 0)
    target.setWidth(target.height());
  else if (target.height() <= 0)
    target.setHeight(target.width());

  // Let the decoder scale down (JPEG does this during decoding) to the
  // smallest size that still covers the target, then crop the centre.
  const QSize covering = natural.scaled(target, Qt::KeepAspectRatioByExpanding);
  if (covering.width() < natural.width())
    reader.setScaledSize(covering);
  QImage decoded = reader.read();
  if (decoded.isNull())
    return {};
  if (decoded.size() != covering)
    decoded = decoded.scaled(covering, Qt::IgnoreAspectRatio,
                             Qt::SmoothTransformation);

  QImage result(target, QImage::Format_ARGB32_Premultiplied);
  result.fill(Qt::transparent);
  QPainter painter(&result);
  painter.setRenderHint(QPainter::Antialiasing);
  const qreal corner = radius * qMin(target.width(), target.height());
  QPainterPath shape;
  shape.addRoundedRect(QRectF(QPointF(0, 0), target), corner, corner);
  // Filling with an image brush keeps the edge antialiased; a clip path
  // would not be.
  QBrush brush(decoded);
  brush.setTransform(QTransform::fromTranslate(
      (target.width() - covering.width()) / 2,
      (target.height() - covering.height()) / 2));
  painter.fillPath(shape, brush);
  painter.end();

  if (size)
    *size = result.size();
  return result;
}
