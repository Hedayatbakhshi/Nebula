#pragma once

#include <QPointF>
#include <QString>
#include <QStringList>

#include <array>
#include <functional>
#include <memory>
#include <vector>

namespace mshape {

struct P {
    double x = 0;
    double y = 0;
    P operator+(const P &o) const { return {x + o.x, y + o.y}; }
    P operator-(const P &o) const { return {x - o.x, y - o.y}; }
    P operator*(double k) const { return {x * k, y * k}; }
    P operator/(double k) const { return {x / k, y / k}; }
    double dist() const;
    double distSq() const { return x * x + y * y; }
    double dot(const P &o) const { return x * o.x + y * o.y; }
    bool clockwise(const P &o) const { return x * o.y - y * o.x > 0; }
    P dir() const { return *this / dist(); }
    P rot90() const { return {-y, x}; }
};

using PointFn = std::function<P(double, double)>;

struct Cubic {
    std::array<double, 8> p {};
    double a0x() const { return p[0]; }
    double a0y() const { return p[1]; }
    double c0x() const { return p[2]; }
    double c0y() const { return p[3]; }
    double c1x() const { return p[4]; }
    double c1y() const { return p[5]; }
    double a1x() const { return p[6]; }
    double a1y() const { return p[7]; }
    P pointOnCurve(double t) const;
    bool zeroLength() const;
    void bounds(double out[4], bool approximate) const;
    std::pair<Cubic, Cubic> split(double t) const;
    Cubic reverse() const;
    Cubic transformed(const PointFn &f) const;
    static Cubic make(const P &a0, const P &c0, const P &c1, const P &a1);
    static Cubic straightLine(double x0, double y0, double x1, double y1);
    static Cubic circularArc(double cx, double cy, double x0, double y0, double x1, double y1);
};

struct Rounding {
    double radius = 0;
    double smoothing = 0;
};

struct Feature {
    std::vector<Cubic> cubics;
    bool corner = false;
    bool convex = false;
    Feature transformed(const PointFn &f) const;
};

struct Polygon {
    std::vector<Feature> features;
    P center;
    std::vector<Cubic> cubics;
    void build();
    Polygon transformed(const PointFn &f) const;
    Polygon normalized() const;
    void calculateBounds(double out[4], bool approximate = true) const;
};

struct Matrix {
    std::array<double, 16> v {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};
    double get(int r, int c) const { return v[r * 4 + c]; }
    void set(int r, int c, double x) { v[r * 4 + c] = x; }
    P map(double x, double y) const;
    void rotateZ(double degrees);
    void scale(double x, double y, double z = 1);
    PointFn fn() const;
};

class Morph {
public:
    Morph(const Polygon &start, const Polygon &end);
    std::vector<Cubic> asCubics(double progress) const;

private:
    std::vector<std::pair<Cubic, Cubic>> m_match;
};

const Polygon *shape(const QString &name);
std::shared_ptr<const Morph> morph(const QString &from, const QString &to);
QStringList shapeNames();

std::vector<QPointF> ringPoints(const std::vector<Cubic> &cubics, double size, double strokeWidth);
double ringProgressAt(const std::vector<QPointF> &ring, double px, double py);
bool ringPointAt(const std::vector<QPointF> &ring, double progress, QPointF &out);
bool ringNear(const std::vector<QPointF> &ring, double px, double py, double tolerance);

}
