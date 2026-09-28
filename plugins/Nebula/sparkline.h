#pragma once

#include <QColor>
#include <QList>
#include <QQuickPaintedItem>
#include <QtQml/qqml.h>

class QPainterPath;

class Sparkline : public QQuickPaintedItem
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QList<qreal> values READ values WRITE setValues NOTIFY valuesChanged)
    Q_PROPERTY(int maxPoints READ maxPoints WRITE setMaxPoints NOTIFY styleChanged)
    Q_PROPERTY(QColor lineColor READ lineColor WRITE setLineColor NOTIFY styleChanged)
    Q_PROPERTY(QColor areaColor READ areaColor WRITE setAreaColor NOTIFY styleChanged)
    Q_PROPERTY(qreal lineWidth READ lineWidth WRITE setLineWidth NOTIFY styleChanged)
    Q_PROPERTY(bool filled READ filled WRITE setFilled NOTIFY styleChanged)
    Q_PROPERTY(qreal maxOverride READ maxOverride WRITE setMaxOverride NOTIFY styleChanged)
    Q_PROPERTY(qreal cornerRadius READ cornerRadius WRITE setCornerRadius NOTIFY styleChanged)
    Q_PROPERTY(bool gradientFill READ gradientFill WRITE setGradientFill NOTIFY styleChanged)
    Q_PROPERTY(bool logScale READ logScale WRITE setLogScale NOTIFY styleChanged)
    Q_PROPERTY(bool bars READ bars WRITE setBars NOTIFY styleChanged)
    Q_PROPERTY(qreal barWidth READ barWidth WRITE setBarWidth NOTIFY styleChanged)
    Q_PROPERTY(qreal barGap READ barGap WRITE setBarGap NOTIFY styleChanged)

public:
    explicit Sparkline(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    QList<qreal> values() const { return m_values; }
    void setValues(const QList<qreal> &values);
    int maxPoints() const { return m_maxPoints; }
    void setMaxPoints(int v);
    QColor lineColor() const { return m_lineColor; }
    void setLineColor(const QColor &v);
    QColor areaColor() const { return m_areaColor; }
    void setAreaColor(const QColor &v);
    qreal lineWidth() const { return m_lineWidth; }
    void setLineWidth(qreal v);
    bool filled() const { return m_filled; }
    void setFilled(bool v);
    qreal maxOverride() const { return m_maxOverride; }
    void setMaxOverride(qreal v);
    qreal cornerRadius() const { return m_cornerRadius; }
    void setCornerRadius(qreal v);
    bool gradientFill() const { return m_gradientFill; }
    void setGradientFill(bool v);
    bool logScale() const { return m_logScale; }
    void setLogScale(bool v);
    bool bars() const { return m_bars; }
    void setBars(bool v);
    qreal barWidth() const { return m_barWidth; }
    void setBarWidth(qreal v);
    qreal barGap() const { return m_barGap; }
    void setBarGap(qreal v);

signals:
    void valuesChanged();
    void styleChanged();

private:
    template <typename T>
    void setStyle(T &field, const T &value);
    qreal norm(qreal v, qreal maxVal) const;
    void paintBars(QPainter *painter, qreal maxVal);
    void paintLine(QPainter *painter, qreal maxVal);

    QList<qreal> m_values;
    int m_maxPoints = 30;
    QColor m_lineColor = Qt::white;
    QColor m_areaColor = QColor(255, 255, 255, 38);
    qreal m_lineWidth = 1.5;
    bool m_filled = true;
    qreal m_maxOverride = 0;
    qreal m_cornerRadius = 6;
    bool m_gradientFill = true;
    bool m_logScale = false;
    bool m_bars = false;
    qreal m_barWidth = 2;
    qreal m_barGap = 1.5;
};
