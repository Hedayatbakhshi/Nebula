#include "shapes.h"

#include <QHash>
#include <QMutex>
#include <QMutexLocker>

#include <algorithm>
#include <cmath>
#include <limits>
#include <optional>
#include <set>

namespace mshape {

namespace {

constexpr double kDistanceEpsilon = 1e-4;
constexpr double kAngleEpsilon = 1e-6;
constexpr double kMaxSafe = 9007199254740991.0;
constexpr double kMinSafe = -9007199254740991.0;
constexpr double kPi = 3.14159265358979323846;

double interp(double a, double b, double f) { return (1 - f) * a + f * b; }
P interpP(const P &a, const P &b, double f) { return {a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f}; }
double distance(double x, double y) { return std::sqrt(x * x + y * y); }
P directionVector(double x, double y)
{
    const double d = distance(x, y);
    return {x / d, y / d};
}
P radialToCartesian(double radius, double angle) { return P {std::cos(angle), std::sin(angle)} * radius; }
bool convex(const P &prev, const P &cur, const P &next) { return (cur - prev).clockwise(next - cur); }
double positiveModulo(double v, double m) { return std::fmod(std::fmod(v, m) + m, m); }
double coerceIn(double v, double a, double b)
{
    const double lo = std::min(a, b), hi = std::max(a, b);
    return std::max(lo, std::min(hi, v));
}

}

double P::dist() const { return std::sqrt(x * x + y * y); }

P Cubic::pointOnCurve(double t) const
{
    const double u = 1 - t;
    return {a0x() * (u * u * u) + c0x() * (3 * t * u * u) + c1x() * (3 * t * t * u) + a1x() * (t * t * t),
            a0y() * (u * u * u) + c0y() * (3 * t * u * u) + c1y() * (3 * t * t * u) + a1y() * (t * t * t)};
}

bool Cubic::zeroLength() const
{
    return std::abs(a0x() - a1x()) < kDistanceEpsilon && std::abs(a0y() - a1y()) < kDistanceEpsilon;
}

void Cubic::bounds(double out[4], bool approximate) const
{
    if (zeroLength()) {
        out[0] = a0x();
        out[1] = a0y();
        out[2] = a0x();
        out[3] = a0y();
        return;
    }
    double minX = std::min(a0x(), a1x()), minY = std::min(a0y(), a1y());
    double maxX = std::max(a0x(), a1x()), maxY = std::max(a0y(), a1y());
    if (approximate) {
        out[0] = std::min(minX, std::min(c0x(), c1x()));
        out[1] = std::min(minY, std::min(c0y(), c1y()));
        out[2] = std::max(maxX, std::max(c0x(), c1x()));
        out[3] = std::max(maxY, std::max(c0y(), c1y()));
        return;
    }
    auto extrema = [this](double a0, double c0, double c1, double a1, bool isX, double &lo, double &hi) {
        const double a = -a0 + 3 * c0 - 3 * c1 + a1;
        const double b = 2 * a0 - 4 * c0 + 2 * c1;
        const double c = -a0 + c0;
        auto take = [&](double t) {
            if (t >= 0 && t <= 1) {
                const P pt = pointOnCurve(t);
                const double it = isX ? pt.x : pt.y;
                lo = std::min(lo, it);
                hi = std::max(hi, it);
            }
        };
        if (std::abs(a) < kDistanceEpsilon) {
            if (b != 0)
                take(2 * c / (-2 * b));
        } else {
            const double s = b * b - 4 * a * c;
            if (s >= 0) {
                take((-b + std::sqrt(s)) / (2 * a));
                take((-b - std::sqrt(s)) / (2 * a));
            }
        }
    };
    extrema(a0x(), c0x(), c1x(), a1x(), true, minX, maxX);
    extrema(a0y(), c0y(), c1y(), a1y(), false, minY, maxY);
    out[0] = minX;
    out[1] = minY;
    out[2] = maxX;
    out[3] = maxY;
}

std::pair<Cubic, Cubic> Cubic::split(double t) const
{
    const double u = 1 - t;
    const P pc = pointOnCurve(t);
    Cubic a {{a0x(), a0y(),
              a0x() * u + c0x() * t, a0y() * u + c0y() * t,
              a0x() * (u * u) + c0x() * (2 * u * t) + c1x() * (t * t),
              a0y() * (u * u) + c0y() * (2 * u * t) + c1y() * (t * t),
              pc.x, pc.y}};
    Cubic b {{pc.x, pc.y,
              c0x() * (u * u) + c1x() * (2 * u * t) + a1x() * (t * t),
              c0y() * (u * u) + c1y() * (2 * u * t) + a1y() * (t * t),
              c1x() * u + a1x() * t, c1y() * u + a1y() * t,
              a1x(), a1y()}};
    return {a, b};
}

Cubic Cubic::reverse() const
{
    return Cubic {{a1x(), a1y(), c1x(), c1y(), c0x(), c0y(), a0x(), a0y()}};
}

Cubic Cubic::transformed(const PointFn &f) const
{
    Cubic out = *this;
    for (int i = 0; i < 8; i += 2) {
        const P r = f(out.p[i], out.p[i + 1]);
        out.p[i] = r.x;
        out.p[i + 1] = r.y;
    }
    return out;
}

Cubic Cubic::make(const P &a0, const P &c0, const P &c1, const P &a1)
{
    return Cubic {{a0.x, a0.y, c0.x, c0.y, c1.x, c1.y, a1.x, a1.y}};
}

Cubic Cubic::straightLine(double x0, double y0, double x1, double y1)
{
    return Cubic {{x0, y0, interp(x0, x1, 1.0 / 3), interp(y0, y1, 1.0 / 3),
                   interp(x0, x1, 2.0 / 3), interp(y0, y1, 2.0 / 3), x1, y1}};
}

Cubic Cubic::circularArc(double cx, double cy, double x0, double y0, double x1, double y1)
{
    const P p0d = directionVector(x0 - cx, y0 - cy);
    const P p1d = directionVector(x1 - cx, y1 - cy);
    const P r0 = p0d.rot90();
    const P r1 = p1d.rot90();
    const bool clockwise = r0.dot(P {x1 - cx, y1 - cy}) >= 0;
    const double cosa = p0d.dot(p1d);
    if (cosa > 0.999)
        return straightLine(x0, y0, x1, y1);
    const double k = distance(x0 - cx, y0 - cy) * 4 / 3
        * (std::sqrt(2 * (1 - cosa)) - std::sqrt(1 - cosa * cosa)) / (1 - cosa) * (clockwise ? 1 : -1);
    return Cubic {{x0, y0, x0 + r0.x * k, y0 + r0.y * k, x1 - r1.x * k, y1 - r1.y * k, x1, y1}};
}

Feature Feature::transformed(const PointFn &f) const
{
    Feature out;
    out.corner = corner;
    out.convex = convex;
    out.cubics.reserve(cubics.size());
    for (const Cubic &c : cubics)
        out.cubics.push_back(c.transformed(f));
    return out;
}

namespace {

struct RoundedCorner {
    P p0, p1, p2;
    P center;
    P d1, d2;
    double cornerRadius = 0;
    double smoothing = 0;
    double cosAngle = 0;
    double sinAngle = 0;
    double expectedRoundCut = 0;

    RoundedCorner(const P &a, const P &b, const P &c, const Rounding &r)
        : p0(a), p1(b), p2(c)
    {
        const P v01 = p0 - p1;
        const P v21 = p2 - p1;
        const double d01 = v01.dist();
        const double d21 = v21.dist();
        if (d01 > 0 && d21 > 0) {
            d1 = v01 / d01;
            d2 = v21 / d21;
            cornerRadius = r.radius;
            smoothing = r.smoothing;
            cosAngle = d1.dot(d2);
            sinAngle = std::sqrt(1 - std::pow(cosAngle, 2));
            expectedRoundCut = sinAngle > 1e-3 ? cornerRadius * (cosAngle + 1) / sinAngle : 0;
        }
    }

    double expectedCut() const { return (1 + smoothing) * expectedRoundCut; }

    double actualSmoothing(double allowedCut) const
    {
        if (allowedCut > expectedCut())
            return smoothing;
        if (allowedCut > expectedRoundCut)
            return smoothing * (allowedCut - expectedRoundCut) / (expectedCut() - expectedRoundCut);
        return 0;
    }

    static std::optional<P> lineIntersection(const P &q0, const P &e0, const P &q1, const P &e1)
    {
        const P rd1 = e1.rot90();
        const double den = e0.dot(rd1);
        if (std::abs(den) < kDistanceEpsilon)
            return std::nullopt;
        const double num = (q1 - q0).dot(rd1);
        if (std::abs(den) < kDistanceEpsilon * std::abs(num))
            return std::nullopt;
        return q0 + e0 * (num / den);
    }

    Cubic flanking(double roundCut, double smooth, const P &corner, const P &sideStart,
                   const P &hit, const P &otherHit, const P &circleCenter, double r) const
    {
        const P sideDirection = (sideStart - corner).dir();
        const P curveStart = corner + sideDirection * (roundCut * (1 + smooth));
        const P p = interpP(hit, (hit + otherHit) / 2, smooth);
        const P curveEnd = circleCenter + directionVector(p.x - circleCenter.x, p.y - circleCenter.y) * r;
        const P tangent = (curveEnd - circleCenter).rot90();
        const P anchorEnd = lineIntersection(sideStart, sideDirection, curveEnd, tangent).value_or(hit);
        const P anchorStart = (curveStart + anchorEnd * 2) / 3;
        return Cubic::make(curveStart, anchorStart, anchorEnd, curveEnd);
    }

    std::vector<Cubic> cubics(double allowedCut0, double allowedCut1)
    {
        const double allowedCut = std::min(allowedCut0, allowedCut1);
        if (expectedRoundCut < kDistanceEpsilon || allowedCut < kDistanceEpsilon || cornerRadius < kDistanceEpsilon) {
            center = p1;
            return {Cubic::straightLine(p1.x, p1.y, p1.x, p1.y)};
        }
        const double roundCut = std::min(allowedCut, expectedRoundCut);
        const double s0 = actualSmoothing(allowedCut0);
        const double s1 = actualSmoothing(allowedCut1);
        const double r = cornerRadius * roundCut / expectedRoundCut;
        const double centerDistance = std::sqrt(std::pow(r, 2) + std::pow(roundCut, 2));
        center = p1 + ((d1 + d2) / 2).dir() * centerDistance;
        const P hit0 = p1 + d1 * roundCut;
        const P hit2 = p1 + d2 * roundCut;
        const Cubic f0 = flanking(roundCut, s0, p1, p0, hit0, hit2, center, r);
        const Cubic f2 = flanking(roundCut, s1, p1, p2, hit2, hit0, center, r).reverse();
        return {f0, Cubic::circularArc(center.x, center.y, f0.a1x(), f0.a1y(), f2.a0x(), f2.a0y()), f2};
    }
};

P calculateCenter(const std::vector<double> &v)
{
    double cx = 0, cy = 0;
    for (size_t i = 0; i + 1 < v.size(); i += 2) {
        cx += v[i];
        cy += v[i + 1];
    }
    const double n = double(v.size()) / 2;
    return {cx / n, cy / n};
}

Polygon fromFeatures(std::vector<Feature> features, double cx, double cy)
{
    std::vector<double> vertices;
    for (const Feature &f : features)
        for (const Cubic &c : f.cubics) {
            vertices.push_back(c.a0x());
            vertices.push_back(c.a0y());
        }
    if (std::isnan(cx))
        cx = calculateCenter(vertices).x;
    if (std::isnan(cy))
        cy = calculateCenter(vertices).y;
    Polygon poly;
    poly.features = std::move(features);
    poly.center = {cx, cy};
    poly.build();
    return poly;
}

Polygon fromVertices(const std::vector<double> &vertices, const Rounding &rounding,
                     const std::vector<Rounding> &perVertex, double centerX = kMinSafe, double centerY = kMaxSafe)
{
    const int n = int(vertices.size() / 2);
    std::vector<RoundedCorner> rc;
    rc.reserve(n);
    for (int i = 0; i < n; i++) {
        const Rounding &r = i < int(perVertex.size()) ? perVertex[i] : rounding;
        const int prev = ((i + n - 1) % n) * 2;
        const int next = ((i + 1) % n) * 2;
        rc.emplace_back(P {vertices[prev], vertices[prev + 1]}, P {vertices[i * 2], vertices[i * 2 + 1]},
                        P {vertices[next], vertices[next + 1]}, r);
    }

    std::vector<std::pair<double, double>> cutAdjusts(n);
    for (int ix = 0; ix < n; ix++) {
        const double expectedRoundCut = rc[ix].expectedRoundCut + rc[(ix + 1) % n].expectedRoundCut;
        const double expectedCut = rc[ix].expectedCut() + rc[(ix + 1) % n].expectedCut();
        const double sideSize = distance(vertices[ix * 2] - vertices[((ix + 1) % n) * 2],
                                         vertices[ix * 2 + 1] - vertices[((ix + 1) % n) * 2 + 1]);
        if (expectedRoundCut > sideSize)
            cutAdjusts[ix] = {sideSize / expectedRoundCut, 0};
        else if (expectedCut > sideSize)
            cutAdjusts[ix] = {1, (sideSize - expectedRoundCut) / (expectedCut - expectedRoundCut)};
        else
            cutAdjusts[ix] = {1, 1};
    }

    std::vector<std::vector<Cubic>> corners;
    corners.reserve(n);
    for (int i = 0; i < n; i++) {
        double allowed[2];
        for (int delta = 0; delta < 2; delta++) {
            const auto &adj = cutAdjusts[(i + n - 1 + delta) % n];
            allowed[delta] = rc[i].expectedRoundCut * adj.first + (rc[i].expectedCut() - rc[i].expectedRoundCut) * adj.second;
        }
        corners.push_back(rc[i].cubics(allowed[0], allowed[1]));
    }

    std::vector<Feature> features;
    features.reserve(n * 2);
    for (int i = 0; i < n; i++) {
        const int prev = (i + n - 1) % n;
        const int next = (i + 1) % n;
        const P cur {vertices[i * 2], vertices[i * 2 + 1]};
        const P pv {vertices[prev * 2], vertices[prev * 2 + 1]};
        const P nv {vertices[next * 2], vertices[next * 2 + 1]};
        Feature corner;
        corner.cubics = corners[i];
        corner.corner = true;
        corner.convex = convex(pv, cur, nv);
        features.push_back(std::move(corner));
        Feature edge;
        const Cubic &last = corners[i].back();
        const Cubic &first = corners[next].front();
        edge.cubics = {Cubic::straightLine(last.a1x(), last.a1y(), first.a0x(), first.a0y())};
        features.push_back(std::move(edge));
    }

    P center;
    if (centerX == kMinSafe || centerY == kMinSafe)
        center = calculateCenter(vertices);
    else
        center = {centerX, centerY};
    return fromFeatures(std::move(features), center.x, center.y);
}

Polygon fromNumVertices(int n, double radius, double cx, double cy, const Rounding &rounding)
{
    std::vector<double> v;
    for (int i = 0; i < n; i++) {
        const P p = radialToCartesian(radius, kPi / n * 2 * i) + P {cx, cy};
        v.push_back(p.x);
        v.push_back(p.y);
    }
    return fromVertices(v, rounding, {}, cx, cy);
}

Polygon circle(int n = 8, double radius = 1, double cx = 0, double cy = 0)
{
    const double theta = kPi / n;
    return fromNumVertices(n, radius / std::cos(theta), cx, cy, Rounding {radius, 0});
}

Polygon rectangle(double w, double h, const Rounding &rounding, const std::vector<Rounding> &perVertex,
                  double cx = 0, double cy = 0)
{
    const double left = cx - w / 2, top = cy - h / 2, right = cx + w / 2, bottom = cy + h / 2;
    return fromVertices({right, bottom, left, bottom, left, top, right, top}, rounding, perVertex, cx, cy);
}

Polygon star(int n, double radius, double inner, const Rounding &rounding, double cx = 0, double cy = 0)
{
    std::vector<double> v;
    for (int i = 0; i < n; i++) {
        P p = radialToCartesian(radius, kPi / n * 2 * i);
        v.push_back(p.x + cx);
        v.push_back(p.y + cy);
        p = radialToCartesian(inner, kPi / n * (2 * i + 1));
        v.push_back(p.x + cx);
        v.push_back(p.y + cy);
    }
    return fromVertices(v, rounding, {}, cx, cy);
}

}

void Polygon::build()
{
    cubics.clear();
    std::optional<Cubic> firstCubic, lastCubic;
    std::vector<Cubic> splitStart, splitEnd;
    const bool hasSplit = !features.empty() && features[0].cubics.size() == 3;
    if (hasSplit) {
        const auto halves = features[0].cubics[1].split(0.5);
        splitStart = {features[0].cubics[0], halves.first};
        splitEnd = {halves.second, features[0].cubics[2]};
    }
    for (size_t i = 0; i <= features.size(); i++) {
        const std::vector<Cubic> *fc = nullptr;
        if (i == 0 && hasSplit)
            fc = &splitEnd;
        else if (i == features.size()) {
            if (hasSplit)
                fc = &splitStart;
            else
                break;
        } else
            fc = &features[i].cubics;
        for (const Cubic &c : *fc) {
            if (!c.zeroLength()) {
                if (lastCubic)
                    cubics.push_back(*lastCubic);
                lastCubic = c;
                if (!firstCubic)
                    firstCubic = c;
            } else if (lastCubic) {
                lastCubic->p[6] = c.a1x();
                lastCubic->p[7] = c.a1y();
            }
        }
    }
    if (lastCubic && firstCubic) {
        Cubic closing = *lastCubic;
        closing.p[6] = firstCubic->a0x();
        closing.p[7] = firstCubic->a0y();
        cubics.push_back(closing);
    } else {
        cubics.push_back(Cubic {{center.x, center.y, center.x, center.y, center.x, center.y, center.x, center.y}});
    }
}

Polygon Polygon::transformed(const PointFn &f) const
{
    Polygon out;
    out.center = f(center.x, center.y);
    out.features.reserve(features.size());
    for (const Feature &ft : features)
        out.features.push_back(ft.transformed(f));
    out.build();
    return out;
}

Polygon Polygon::normalized() const
{
    double b[4];
    calculateBounds(b);
    const double w = b[2] - b[0];
    const double h = b[3] - b[1];
    const double side = std::max(w, h);
    const double ox = (side - w) / 2 - b[0];
    const double oy = (side - h) / 2 - b[1];
    return transformed([=](double x, double y) { return P {(x + ox) / side, (y + oy) / side}; });
}

void Polygon::calculateBounds(double out[4], bool approximate) const
{
    double minX = kMaxSafe, minY = kMaxSafe, maxX = kMinSafe, maxY = kMinSafe;
    double b[4];
    for (const Cubic &c : cubics) {
        c.bounds(b, approximate);
        minX = std::min(minX, b[0]);
        minY = std::min(minY, b[1]);
        maxX = std::max(maxX, b[2]);
        maxY = std::max(maxY, b[3]);
    }
    out[0] = minX;
    out[1] = minY;
    out[2] = maxX;
    out[3] = maxY;
}

P Matrix::map(double x, double y) const
{
    const double z = get(0, 3) * x + get(1, 3) * y + get(3, 3);
    const double inv = 1 / z;
    const double pz = std::isfinite(inv) ? inv : 0;
    return {pz * (get(0, 0) * x + get(1, 0) * y + get(3, 0)), pz * (get(0, 1) * x + get(1, 1) * y + get(3, 1))};
}

void Matrix::rotateZ(double degrees)
{
    const double r = degrees * (kPi / 180.0);
    const double s = std::sin(r), c = std::cos(r);
    for (int col = 0; col < 4; col++) {
        const double a0 = get(0, col), a1 = get(1, col);
        set(0, col, c * a0 + s * a1);
        set(1, col, -s * a0 + c * a1);
    }
}

void Matrix::scale(double x, double y, double z)
{
    for (int col = 0; col < 4; col++) {
        set(0, col, get(0, col) * x);
        set(1, col, get(1, col) * y);
        set(2, col, get(2, col) * z);
    }
}

PointFn Matrix::fn() const
{
    const Matrix m = *this;
    return [m](double x, double y) { return m.map(x, y); };
}

namespace {

struct MeasuredCubic {
    Cubic cubic;
    double start = 0;
    double end = 0;
    double size = 0;
};

std::pair<double, double> closestProgressTo(const Cubic &c, double threshold)
{
    constexpr int segments = 3;
    double total = 0;
    double remainder = threshold;
    P prev {c.a0x(), c.a0y()};
    for (int i = 1; i < segments; i++) {
        const double progress = double(i) / segments;
        const P pt = c.pointOnCurve(progress);
        const double seg = (pt - prev).dist();
        if (seg >= remainder)
            return {progress - (1.0 - remainder / seg) / segments, threshold};
        remainder -= seg;
        total += seg;
        prev = pt;
    }
    return {1.0, total};
}

double measureCubic(const Cubic &c) { return closestProgressTo(c, std::numeric_limits<double>::infinity()).second; }

MeasuredCubic makeMeasured(const Cubic &c, double start, double end) { return {c, start, end, measureCubic(c)}; }

std::pair<MeasuredCubic, MeasuredCubic> cutAtProgress(const MeasuredCubic &m, double cut)
{
    const double bounded = coerceIn(cut, m.start, m.end);
    const double rel = (bounded - m.start) / (m.end - m.start);
    const double t = closestProgressTo(m.cubic, rel * m.size).first;
    const auto halves = m.cubic.split(t);
    return {makeMeasured(halves.first, m.start, bounded), makeMeasured(halves.second, bounded, m.end)};
}

struct ProgFeature {
    double progress;
    int id;
    const Feature *feature;
};

struct MeasuredPolygon {
    std::vector<ProgFeature> features;
    std::vector<MeasuredCubic> cubics;

    MeasuredPolygon(std::vector<ProgFeature> f, const std::vector<Cubic> &cs, const std::vector<double> &outline)
        : features(std::move(f))
    {
        double start = 0;
        for (size_t i = 0; i < cs.size(); i++) {
            if (outline[i + 1] - outline[i] > kDistanceEpsilon) {
                cubics.push_back(makeMeasured(cs[i], start, outline[i + 1]));
                start = outline[i + 1];
            }
        }
        if (!cubics.empty())
            cubics.back().end = 1;
    }

    MeasuredPolygon cutAndShift(double cut) const
    {
        if (cut < kDistanceEpsilon)
            return *this;
        int target = 0;
        for (size_t i = 0; i < cubics.size(); i++)
            if (cut >= cubics[i].start && cut <= cubics[i].end) {
                target = int(i);
                break;
            }
        const auto halves = cutAtProgress(cubics[target], cut);
        std::vector<Cubic> ret {halves.second.cubic};
        const int n = int(cubics.size());
        for (int i = 1; i < n; i++)
            ret.push_back(cubics[(i + target) % n].cubic);
        ret.push_back(halves.first.cubic);
        std::vector<double> outline;
        for (int i = 0; i < n + 2; i++) {
            if (i == 0)
                outline.push_back(0);
            else if (i == n + 1)
                outline.push_back(1);
            else
                outline.push_back(positiveModulo(cubics[(target + i - 1) % n].end - cut, 1));
        }
        std::vector<ProgFeature> nf;
        for (const ProgFeature &f : features)
            nf.push_back({positiveModulo(f.progress - cut, 1), f.id, f.feature});
        return MeasuredPolygon(std::move(nf), ret, outline);
    }

    static MeasuredPolygon measure(const Polygon &poly)
    {
        std::vector<Cubic> cs;
        std::vector<std::pair<const Feature *, int>> featureToCubic;
        for (const Feature &f : poly.features) {
            for (size_t ci = 0; ci < f.cubics.size(); ci++) {
                if (f.corner && ci == f.cubics.size() / 2)
                    featureToCubic.push_back({&f, int(cs.size())});
                cs.push_back(f.cubics[ci]);
            }
        }
        std::vector<double> measures {0};
        for (const Cubic &c : cs)
            measures.push_back(measures.back() + measureCubic(c));
        const double total = measures.back();
        std::vector<double> outline;
        for (double m : measures)
            outline.push_back(m / total);
        std::vector<ProgFeature> features;
        int id = 0;
        for (const auto &fc : featureToCubic) {
            const int ix = fc.second;
            features.push_back({positiveModulo((outline[ix] + outline[ix + 1]) / 2, 1), id++, fc.first});
        }
        return MeasuredPolygon(std::move(features), cs, outline);
    }
};

bool progressInRange(double p, double from, double to)
{
    if (to >= from)
        return p >= from && p <= to;
    return p >= from || p <= to;
}

double progressDistance(double a, double b)
{
    const double it = std::abs(a - b);
    return std::min(it, 1 - it);
}

struct DoubleMapper {
    std::vector<double> src;
    std::vector<double> dst;

    static double linearMap(const std::vector<double> &xs, const std::vector<double> &ys, double x)
    {
        int start = -1;
        for (size_t i = 0; i < xs.size(); i++) {
            if (progressInRange(x, xs[i], xs[(i + 1) % xs.size()])) {
                start = int(i);
                break;
            }
        }
        if (start < 0)
            return x;
        const int end = (start + 1) % int(xs.size());
        const double sizeX = positiveModulo(xs[end] - xs[start], 1);
        const double sizeY = positiveModulo(ys[end] - ys[start], 1);
        const double pos = sizeX < 0.001 ? 0.5 : positiveModulo(x - xs[start], 1) / sizeX;
        return positiveModulo(ys[start] + sizeY * pos, 1);
    }
    double map(double x) const { return linearMap(src, dst, x); }
    double mapBack(double x) const { return linearMap(dst, src, x); }
};

P representativePoint(const Feature &f)
{
    const Cubic &a = f.cubics.front();
    const Cubic &b = f.cubics.back();
    return {(a.a0x() + b.a1x()) / 2, (a.a0y() + b.a1y()) / 2};
}

DoubleMapper featureMapper(const std::vector<ProgFeature> &f1, const std::vector<ProgFeature> &f2)
{
    struct Dv {
        double d;
        const ProgFeature *a;
        const ProgFeature *b;
    };
    std::vector<Dv> list;
    for (const ProgFeature &a : f1) {
        if (!a.feature->corner)
            continue;
        for (const ProgFeature &b : f2) {
            if (!b.feature->corner)
                continue;
            if (a.feature->convex != b.feature->convex)
                continue;
            list.push_back({(representativePoint(*a.feature) - representativePoint(*b.feature)).distSq(), &a, &b});
        }
    }
    std::stable_sort(list.begin(), list.end(), [](const Dv &x, const Dv &y) { return x.d < y.d; });

    DoubleMapper m;
    if (list.empty()) {
        m.src = {0, 0.5};
        m.dst = {0, 0.5};
        return m;
    }
    if (list.size() == 1) {
        const double p1 = list[0].a->progress, p2 = list[0].b->progress;
        m.src = {p1, std::fmod(p1 + 0.5, 1)};
        m.dst = {p2, std::fmod(p2 + 0.5, 1)};
        return m;
    }

    std::vector<std::pair<double, double>> mapping;
    std::set<int> used1, used2;
    for (const Dv &dv : list) {
        if (used1.count(dv.a->id) || used2.count(dv.b->id))
            continue;
        const auto pos = std::lower_bound(mapping.begin(), mapping.end(), dv.a->progress,
                                          [](const std::pair<double, double> &e, double v) { return e.first < v; });
        if (pos != mapping.end() && pos->first == dv.a->progress)
            continue;
        const int insertion = int(pos - mapping.begin());
        const int n = int(mapping.size());
        if (n >= 1) {
            const auto &before = mapping[(insertion + n - 1) % n];
            const auto &after = mapping[insertion % n];
            if (progressDistance(dv.a->progress, before.first) < kDistanceEpsilon
                || progressDistance(dv.a->progress, after.first) < kDistanceEpsilon
                || progressDistance(dv.b->progress, before.second) < kDistanceEpsilon
                || progressDistance(dv.b->progress, after.second) < kDistanceEpsilon)
                continue;
            if (n > 1 && !progressInRange(dv.b->progress, before.second, after.second))
                continue;
        }
        mapping.insert(mapping.begin() + insertion, {dv.a->progress, dv.b->progress});
        used1.insert(dv.a->id);
        used2.insert(dv.b->id);
    }
    for (const auto &e : mapping) {
        m.src.push_back(e.first);
        m.dst.push_back(e.second);
    }
    return m;
}

}

Morph::Morph(const Polygon &start, const Polygon &end)
{
    const MeasuredPolygon m1 = MeasuredPolygon::measure(start);
    const MeasuredPolygon m2 = MeasuredPolygon::measure(end);
    const DoubleMapper mapper = featureMapper(m1.features, m2.features);
    const double cut2 = mapper.map(0);
    const MeasuredPolygon &bs1 = m1;
    const MeasuredPolygon bs2 = m2.cutAndShift(cut2);

    size_t i1 = 0, i2 = 0;
    std::optional<MeasuredCubic> b1, b2;
    if (i1 < bs1.cubics.size())
        b1 = bs1.cubics[i1];
    i1++;
    if (i2 < bs2.cubics.size())
        b2 = bs2.cubics[i2];
    i2++;

    while (b1 && b2) {
        const double b1a = i1 == bs1.cubics.size() ? 1 : b1->end;
        const double b2a = i2 == bs2.cubics.size() ? 1 : mapper.mapBack(positiveModulo(b2->end + cut2, 1));
        const double minb = std::min(b1a, b2a);

        MeasuredCubic seg1, seg2;
        std::optional<MeasuredCubic> nb1, nb2;
        if (b1a > minb + kAngleEpsilon) {
            const auto c = cutAtProgress(*b1, minb);
            seg1 = c.first;
            nb1 = c.second;
        } else {
            seg1 = *b1;
            if (i1 < bs1.cubics.size())
                nb1 = bs1.cubics[i1];
            i1++;
        }
        if (b2a > minb + kAngleEpsilon) {
            const auto c = cutAtProgress(*b2, positiveModulo(mapper.map(minb) - cut2, 1));
            seg2 = c.first;
            nb2 = c.second;
        } else {
            seg2 = *b2;
            if (i2 < bs2.cubics.size())
                nb2 = bs2.cubics[i2];
            i2++;
        }
        m_match.push_back({seg1.cubic, seg2.cubic});
        b1 = nb1;
        b2 = nb2;
    }
}

std::vector<Cubic> Morph::asCubics(double progress) const
{
    std::vector<Cubic> ret;
    ret.reserve(m_match.size());
    for (const auto &pair : m_match) {
        Cubic c;
        for (int i = 0; i < 8; i++)
            c.p[i] = interp(pair.first.p[i], pair.second.p[i], progress);
        ret.push_back(c);
    }
    if (!ret.empty()) {
        ret.back().p[6] = ret.front().a0x();
        ret.back().p[7] = ret.front().a0y();
    }
    return ret;
}

namespace {

struct PNR {
    P o;
    Rounding r;
};

Rounding R(double radius, double smoothing = 0) { return {radius, smoothing}; }

Matrix rot(double deg)
{
    Matrix m;
    m.rotateZ(deg);
    return m;
}

Matrix scaled(double x, double y)
{
    Matrix m;
    m.scale(x, y);
    return m;
}

P rotateDegrees(const P &p, double angle, const P &center)
{
    const double a = angle * kPi / 180;
    const P off = p - center;
    const double c = std::cos(a), s = std::sin(a);
    return P {off.x * c - off.y * s, off.x * s + off.y * c} + center;
}

Polygon custom(const std::vector<PNR> &pnr, int reps = 1, P center = {0.5, 0.5})
{
    const int np = int(pnr.size());
    std::vector<double> v;
    std::vector<Rounding> per;
    for (int i = 0; i < np * reps; i++) {
        const P pt = rotateDegrees(pnr[i % np].o, std::floor(double(i) / np) * 360 / reps, center);
        v.push_back(pt.x);
        v.push_back(pt.y);
        per.push_back(pnr[i % np].r);
    }
    return fromVertices(v, Rounding {}, per, center.x, center.y);
}

Polygon crescent()
{
    const P c1 {0.5, 0.5}, c2 {0.72, 0.36};
    const double r1 = 0.5, r2 = 0.42;
    const P dv = c2 - c1;
    const double d = dv.dist();
    const double a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
    const double h = std::sqrt(r1 * r1 - a * a);
    const P base = c1 + dv * (a / d);
    const P perp = P {-dv.y, dv.x} / d;
    const P pa = base + perp * h;
    const P pb = base - perp * h;

    auto arcCubics = [](const P &c, double r, double from, double to, int segs) {
        std::vector<Cubic> out;
        for (int i = 0; i < segs; i++) {
            const double t0 = from + (to - from) * i / segs;
            const double t1 = from + (to - from) * (i + 1) / segs;
            out.push_back(Cubic::circularArc(c.x, c.y, c.x + r * std::cos(t0), c.y + r * std::sin(t0),
                                             c.x + r * std::cos(t1), c.y + r * std::sin(t1)));
        }
        return out;
    };

    const double oa = std::atan2(pa.y - c1.y, pa.x - c1.x);
    double ob = std::atan2(pb.y - c1.y, pb.x - c1.x);
    const double away = std::atan2(-dv.y, -dv.x);
    auto between = [](double s, double e, double m) {
        const double span = std::fmod(e - s + 4 * kPi, 2 * kPi);
        return std::fmod(m - s + 4 * kPi, 2 * kPi) <= span;
    };
    if (between(oa, ob, away)) {
        while (ob < oa)
            ob += 2 * kPi;
    } else {
        while (ob > oa)
            ob -= 2 * kPi;
    }
    const double ia = std::atan2(pb.y - c2.y, pb.x - c2.x);
    double ib = std::atan2(pa.y - c2.y, pa.x - c2.x);
    const double toward = std::atan2(c1.y - c2.y, c1.x - c2.x);
    if (between(ia, ib, toward)) {
        while (ib < ia)
            ib += 2 * kPi;
    } else {
        while (ib > ia)
            ib -= 2 * kPi;
    }

    Feature outer;
    outer.cubics = arcCubics(c1, r1, oa, ob, 6);
    Feature tip1;
    tip1.corner = true;
    tip1.convex = true;
    tip1.cubics = {Cubic::straightLine(pb.x, pb.y, pb.x, pb.y)};
    Feature inner;
    inner.cubics = arcCubics(c2, r2, ia, ib, 4);
    Feature tip2;
    tip2.corner = true;
    tip2.convex = true;
    tip2.cubics = {Cubic::straightLine(pa.x, pa.y, pa.x, pa.y)};
    return fromFeatures({outer, tip1, inner, tip2}, 0.5, 0.5).normalized();
}

Polygon build(const QString &name)
{
    const Rounding r15 = R(0.15), r20 = R(0.2), r30 = R(0.3), r50 = R(0.5), r100 = R(1.0);
    const Rounding none;

    if (name == QLatin1String("notch"))
        return custom({{{0.0, 0.0}, none}, {{1.0, 0.0}, none}, {{1.0, 1.0}, R(0.4)}, {{0.0, 1.0}, R(0.4)}}, 1).normalized();
    if (name == QLatin1String("circle"))
        return circle(10).transformed(rot(45).fn()).normalized();
    if (name == QLatin1String("square"))
        return rectangle(1, 1, r30, {}).normalized();
    if (name == QLatin1String("slanted"))
        return custom({{{0.926, 0.970}, R(0.189, 0.811)}, {{-0.021, 0.967}, R(0.187, 0.057)}}, 2).normalized();
    if (name == QLatin1String("arch"))
        return rectangle(1, 1, none, {r20, r20, r100, r100}).normalized();
    if (name == QLatin1String("fan"))
        return custom({{{1.004, 1.000}, R(0.148, 0.417)}, {{0.000, 1.000}, R(0.151)},
                       {{0.000, -0.003}, R(0.148)}, {{0.978, 0.020}, R(0.803)}}, 1).normalized();
    if (name == QLatin1String("arrow"))
        return custom({{{1.225, 1.060}, R(0.211)}, {{0.500, 0.892}, R(0.313)},
                       {{-0.216, 1.050}, R(0.207)}, {{0.499, -0.160}, R(0.215, 1.000)}}, 1).normalized();
    if (name == QLatin1String("semiCircle"))
        return rectangle(1.6, 1, none, {r20, r20, r100, r100}).normalized();
    if (name == QLatin1String("oval"))
        return circle().transformed(rot(-90).fn()).transformed(scaled(1, 0.64).fn()).transformed(rot(135).fn()).normalized();
    if (name == QLatin1String("pill"))
        return custom({{{0.428, -0.001}, R(0.426)}, {{0.961, 0.039}, R(0.426)},
                       {{1.001, 0.428}, none}, {{1.000, 0.609}, R(1.000)}}, 2)
            .transformed(rot(180).fn()).normalized();
    if (name == QLatin1String("triangle"))
        return fromNumVertices(3, 1, 0.5, 0.5, r20).transformed(rot(30).fn()).normalized();
    if (name == QLatin1String("diamond"))
        return custom({{{0.500, 1.096}, R(0.151, 0.524)}, {{0.040, 0.500}, R(0.159)}}, 2).normalized();
    if (name == QLatin1String("clamShell"))
        return custom({{{0.829, 0.841}, R(0.159)}, {{0.171, 0.841}, R(0.159)}, {{-0.020, 0.500}, R(0.140)}}, 2).normalized();
    if (name == QLatin1String("pentagon"))
        return custom({{{0.828, 0.970}, R(0.169)}, {{0.172, 0.970}, R(0.169)}, {{-0.030, 0.365}, R(0.164)},
                       {{0.500, -0.009}, R(0.172)}, {{1.030, 0.365}, R(0.164)}}, 1).normalized();
    if (name == QLatin1String("gem"))
        return custom({{{1.005, 0.792}, R(0.208)}, {{0.5, 1.023}, R(0.241, 0.778)}, {{-0.005, 0.792}, R(0.208)},
                       {{0.073, 0.258}, R(0.228)}, {{0.5, 0.000}, R(0.241, 0.778)}, {{0.927, 0.258}, R(0.228)}}, 1).normalized();
    if (name == QLatin1String("sunny"))
        return star(8, 1, 0.8, r15).transformed(rot(45).fn()).normalized();
    if (name == QLatin1String("verySunny"))
        return custom({{{0.500, 1.080}, R(0.085)}, {{0.358, 0.843}, R(0.085)}}, 8).transformed(rot(-45).fn()).normalized();
    if (name == QLatin1String("cookie4"))
        return custom({{{1.237, 1.236}, R(0.258)}, {{0.500, 0.918}, R(0.233)}}, 4).normalized();
    if (name == QLatin1String("cookie6"))
        return custom({{{0.723, 0.884}, R(0.394)}, {{0.500, 1.099}, R(0.398)}}, 6).normalized();
    if (name == QLatin1String("cookie7")) {
        Polygon p = star(7, 1, 0.75, r50).normalized();
        const PointFn f = rot(360.0 / 28).fn();
        for (int i = 0; i < 5; i++)
            p = p.transformed(f);
        return p.normalized();
    }
    if (name == QLatin1String("cookie9"))
        return star(9, 1, 0.8, r50).transformed(rot(30).fn()).normalized();
    if (name == QLatin1String("cookie12"))
        return star(12, 1, 0.8, r50).transformed(rot(30).fn()).normalized();
    if (name == QLatin1String("ghostish"))
        return custom({{{1.000, 1.140}, R(0.254, 0.106)}, {{0.575, 0.906}, R(0.253)}, {{0.425, 0.906}, R(0.253)},
                       {{0.000, 1.140}, R(0.254, 0.106)}, {{0.000, 0.000}, R(1.0)}, {{0.500, 0.000}, R(1.0)},
                       {{1.000, 0.000}, R(1.0)}}, 1).normalized();
    if (name == QLatin1String("clover4"))
        return custom({{{1.099, 0.725}, R(0.476)}, {{0.725, 1.099}, R(0.476)}, {{0.500, 0.926}, none}}, 4).normalized();
    if (name == QLatin1String("clover8"))
        return custom({{{0.758, 1.101}, R(0.209)}, {{0.500, 0.964}, none}}, 8).normalized();
    if (name == QLatin1String("burst"))
        return custom({{{0.592, 0.842}, R(0.006)}, {{0.500, 1.006}, R(0.006)}}, 12)
            .transformed(rot(-30).fn()).transformed(rot(-30).fn()).normalized();
    if (name == QLatin1String("softBurst"))
        return custom({{{0.193, 0.277}, R(0.053)}, {{0.176, 0.055}, R(0.053)}}, 10).transformed(rot(180).fn()).normalized();
    if (name == QLatin1String("boom"))
        return custom({{{0.457, 0.296}, R(0.007)}, {{0.500, -0.051}, R(0.007)}}, 15).transformed(rot(120).fn()).normalized();
    if (name == QLatin1String("softBoom"))
        return custom({{{0.733, 0.454}, none}, {{0.839, 0.437}, R(0.532)}, {{0.949, 0.449}, R(0.439, 1.000)},
                       {{0.998, 0.478}, R(0.174)}, {{0.998, 0.522}, R(0.174)}, {{0.949, 0.551}, R(0.439, 1.000)},
                       {{0.839, 0.563}, R(0.532)}, {{0.733, 0.546}, none}}, 16)
            .transformed(rot(45).fn()).transformed(rot(-360.0 / 16).fn()).normalized();
    if (name == QLatin1String("flower"))
        return custom({{{0.370, 0.187}, none}, {{0.416, 0.049}, R(0.381)}, {{0.479, 0.001}, R(0.095)},
                       {{0.521, 0.001}, R(0.095)}, {{0.584, 0.049}, R(0.381)}, {{0.630, 0.187}, none}}, 8)
            .transformed(rot(135).fn()).normalized();
    if (name == QLatin1String("puffy"))
        return custom({{{1.003, 0.563}, R(0.255)}, {{0.940, 0.656}, R(0.126)}, {{0.881, 0.654}, none},
                       {{0.926, 0.711}, R(0.660)}, {{0.914, 0.851}, R(0.660)}, {{0.777, 0.998}, R(0.360)},
                       {{0.722, 0.872}, none}, {{0.717, 0.934}, R(0.574)}, {{0.670, 1.035}, R(0.426)},
                       {{0.545, 1.040}, R(0.405)}, {{0.500, 0.947}, none},
                       {{0.500, 1 - 0.053}, none}, {{1 - 0.545, 1 + 0.040}, R(0.405)}, {{1 - 0.670, 1 + 0.035}, R(0.426)},
                       {{1 - 0.717, 1 - 0.066}, R(0.574)}, {{1 - 0.722, 1 - 0.128}, none}, {{1 - 0.777, 1 - 0.002}, R(0.360)},
                       {{1 - 0.914, 1 - 0.149}, R(0.660)}, {{1 - 0.926, 1 - 0.289}, R(0.660)}, {{1 - 0.881, 1 - 0.346}, none},
                       {{1 - 0.940, 1 - 0.344}, R(0.126)}, {{1 - 1.003, 1 - 0.437}, R(0.255)}}, 2)
            .transformed(scaled(1, 0.742).fn()).normalized();
    if (name == QLatin1String("puffyDiamond"))
        return custom({{{0.870, 0.130}, R(0.146)}, {{0.818, 0.357}, none}, {{1.000, 0.332}, R(0.853)},
                       {{1.000, 1 - 0.332}, R(0.853)}, {{0.818, 1 - 0.357}, none}}, 4)
            .transformed(rot(90).fn()).normalized();
    if (name == QLatin1String("pixelCircle"))
        return custom({{{1.000, 0.704}, none}, {{0.926, 0.704}, none}, {{0.926, 0.852}, none}, {{0.843, 0.852}, none},
                       {{0.843, 0.935}, none}, {{0.704, 0.935}, none}, {{0.704, 1.000}, none}, {{0.500, 1.000}, none},
                       {{1 - 0.704, 1.000}, none}, {{1 - 0.704, 0.935}, none}, {{1 - 0.843, 0.935}, none},
                       {{1 - 0.843, 0.852}, none}, {{1 - 0.926, 0.852}, none}, {{1 - 0.926, 0.704}, none},
                       {{1 - 1.000, 0.704}, none}}, 2).normalized();
    if (name == QLatin1String("pixelTriangle"))
        return custom({{{0.888, 1 - 0.439}, none}, {{0.789, 1 - 0.439}, none}, {{0.789, 1 - 0.344}, none},
                       {{0.675, 1 - 0.344}, none}, {{0.674, 1 - 0.265}, none}, {{0.560, 1 - 0.265}, none},
                       {{0.560, 1 - 0.170}, none}, {{0.421, 1 - 0.170}, none}, {{0.421, 1 - 0.087}, none},
                       {{0.287, 1 - 0.087}, none}, {{0.287, 1 - 0.000}, none}, {{0.113, 1 - 0.000}, none},
                       {{0.110, 0.500}, none}, {{0.113, 0.000}, none}, {{0.287, 0.000}, none},
                       {{0.287, 0.087}, none}, {{0.421, 0.087}, none}, {{0.421, 0.170}, none},
                       {{0.560, 0.170}, none}, {{0.560, 0.265}, none}, {{0.674, 0.265}, none},
                       {{0.675, 0.344}, none}, {{0.789, 0.344}, none}, {{0.789, 0.439}, none},
                       {{0.888, 0.439}, none}}, 1).normalized();
    if (name == QLatin1String("bun"))
        return custom({{{0.796, 0.500}, none}, {{0.853, 0.518}, r100}, {{0.992, 0.631}, r100}, {{0.968, 1.000}, r100},
                       {{0.032, 1 - 0.000}, r100}, {{0.008, 1 - 0.369}, r100}, {{0.147, 1 - 0.482}, r100},
                       {{0.204, 1 - 0.500}, none}}, 2).normalized();
    if (name == QLatin1String("heart"))
        return custom({{{0.782, 0.611}, none}, {{0.499, 0.946}, R(0.000)}, {{0.2175, 0.611}, none},
                       {{-0.064, 0.276}, R(1.000)}, {{0.208, -0.066}, R(0.958)}, {{0.500, 0.268}, R(0.016)},
                       {{0.792, -0.066}, R(0.958)}, {{1.064, 0.276}, R(1.000)}}, 1).normalized();
    if (name == QLatin1String("hexagon"))
        return fromNumVertices(6, 1, 0, 0, R(0.2)).normalized();
    if (name == QLatin1String("octagon"))
        return fromNumVertices(8, 1, 0, 0, R(0.16)).transformed(rot(22.5).fn()).normalized();
    if (name == QLatin1String("star5"))
        return star(5, 1, 0.5, R(0.1)).transformed(rot(-90).fn()).normalized();
    if (name == QLatin1String("sparkle")) {
        const double k = 0.19 * std::sqrt(0.5);
        return custom({{{0.5, 0.0}, R(0.08)}, {{0.5 + k, 0.5 - k}, R(0.4)}}, 4).normalized();
    }
    if (name == QLatin1String("cookie3"))
        return star(3, 1, 0.72, r50).transformed(rot(-90).fn()).normalized();
    if (name == QLatin1String("cookie5"))
        return star(5, 1, 0.78, r50).transformed(rot(-90).fn()).normalized();
    if (name == QLatin1String("cookie8"))
        return star(8, 1, 0.82, r50).transformed(rot(-90).fn()).normalized();
    if (name == QLatin1String("cookie10"))
        return star(10, 1, 0.85, r50).transformed(rot(-90).fn()).normalized();
    if (name == QLatin1String("scallop"))
        return star(16, 1, 0.9, R(0.35)).transformed(rot(-90).fn()).normalized();
    if (name == QLatin1String("clover3"))
        return custom({{{0.275, -0.056}, R(0.5)}, {{0.725, -0.056}, R(0.5)}, {{0.725, 0.37}, none}}, 3).normalized();
    if (name == QLatin1String("cross")) {
        const double a = 0.32, b = 0.68;
        const Rounding o = R(0.1), in = R(0.08);
        return custom({{{a, 0}, o}, {{b, 0}, o}, {{b, a}, in}, {{1, a}, o}, {{1, b}, o}, {{b, b}, in},
                       {{b, 1}, o}, {{a, 1}, o}, {{a, b}, in}, {{0, b}, o}, {{0, a}, o}, {{a, a}, in}}, 1).normalized();
    }
    if (name == QLatin1String("squircle"))
        return rectangle(1, 1, R(0.36, 1.0), {}).normalized();
    if (name == QLatin1String("pebble"))
        return rectangle(1, 0.78, R(0.39, 0.6), {}).transformed(rot(-14).fn()).normalized();
    if (name == QLatin1String("blob"))
        return custom({{{0.86, 0.22}, R(0.4)}, {{1.02, 0.7}, R(0.5)}, {{0.55, 1.02}, R(0.46)},
                       {{0.04, 0.76}, R(0.42)}, {{0.18, 0.12}, R(0.44)}}, 1).normalized();
    if (name == QLatin1String("leaf"))
        return rectangle(1, 1, none, {R(0.03), R(1.0), R(0.03), R(1.0)}).normalized();
    if (name == QLatin1String("drop"))
        return custom({{{0.5, -0.08}, R(0.02)}, {{1.0, 0.62}, R(0.62)}, {{0.5, 1.06}, R(0.62)}, {{0.0, 0.62}, R(0.62)}}, 1).normalized();
    if (name == QLatin1String("shield"))
        return custom({{{0.0, 0.0}, R(0.14)}, {{1.0, 0.0}, R(0.14)}, {{1.0, 0.52}, R(0.3)},
                       {{0.5, 1.0}, R(0.12)}, {{0.0, 0.52}, R(0.3)}}, 1).normalized();
    if (name == QLatin1String("bolt"))
        return custom({{{0.54, 0.40}, R(0.04)}, {{0.88, 0.40}, R(0.05)}, {{0.36, 1.0}, R(0.05)},
                       {{0.46, 0.58}, R(0.04)}, {{0.12, 0.58}, R(0.05)}, {{0.62, 0.0}, R(0.05)}}, 1).normalized();
    if (name == QLatin1String("chevron"))
        return custom({{{0.5, 0.1}, R(0.1)}, {{1.0, 0.6}, R(0.1)}, {{0.78, 0.82}, R(0.1)},
                       {{0.5, 0.54}, R(0.08)}, {{0.22, 0.82}, R(0.1)}, {{0.0, 0.6}, R(0.1)}}, 1).normalized();
    if (name == QLatin1String("moon"))
        return crescent();
    if (name == QLatin1String("pixelHeart")) {
        const std::vector<std::pair<double, double>> g {{1, 0}, {3, 0}, {3, 1}, {5, 1}, {5, 0}, {7, 0}, {7, 1}, {8, 1},
            {8, 3}, {7, 3}, {7, 4}, {6, 4}, {6, 5}, {5, 5}, {5, 6}, {3, 6}, {3, 5}, {2, 5}, {2, 4}, {1, 4},
            {1, 3}, {0, 3}, {0, 1}, {1, 1}};
        std::vector<PNR> pts;
        for (const auto &q : g)
            pts.push_back({{q.first / 8, q.second / 8}, none});
        return custom(pts, 1).normalized();
    }
    if (name == QLatin1String("cookie4ExpandedTL"))
        return custom({{{1.00, 1.00}, R(0.175)}, {{0.50, 0.82}, R(0.175)}, {{0.00, 1.00}, R(0.175)},
                       {{0.28, 0.68}, R(0.175)}, {{0.00, 0.00}, R(0.38)}, {{0.68, 0.28}, R(0.175)},
                       {{1.00, 0.00}, R(0.175)}, {{0.82, 0.50}, R(0.175)}}, 1);
    return {};
}

QMutex cacheMutex;
QHash<QString, std::shared_ptr<const Polygon>> &shapeCache()
{
    static QHash<QString, std::shared_ptr<const Polygon>> cache;
    return cache;
}
QHash<QString, std::shared_ptr<const Morph>> &morphCache()
{
    static QHash<QString, std::shared_ptr<const Morph>> cache;
    return cache;
}

std::shared_ptr<const Polygon> shapeLocked(const QString &name)
{
    auto &cache = shapeCache();
    auto it = cache.constFind(name);
    if (it != cache.constEnd())
        return it.value();
    Polygon p = build(name);
    std::shared_ptr<const Polygon> ptr = p.cubics.empty() ? nullptr : std::make_shared<const Polygon>(std::move(p));
    cache.insert(name, ptr);
    return ptr;
}

}

const Polygon *shape(const QString &name)
{
    if (name.isEmpty())
        return nullptr;
    QMutexLocker lock(&cacheMutex);
    return shapeLocked(name).get();
}

std::shared_ptr<const Morph> morph(const QString &from, const QString &to)
{
    if (to.isEmpty())
        return nullptr;
    const QString src = from.isEmpty() ? to : from;
    const QString key = src + QLatin1Char('\n') + to;
    QMutexLocker lock(&cacheMutex);
    auto &cache = morphCache();
    auto it = cache.constFind(key);
    if (it != cache.constEnd())
        return it.value();
    const auto a = shapeLocked(src);
    const auto b = shapeLocked(to);
    std::shared_ptr<const Morph> m = (a && b) ? std::make_shared<const Morph>(*a, *b) : nullptr;
    cache.insert(key, m);
    return m;
}

QStringList shapeNames()
{
    return {QStringLiteral("circle"), QStringLiteral("square"), QStringLiteral("slanted"), QStringLiteral("arch"),
            QStringLiteral("fan"), QStringLiteral("arrow"), QStringLiteral("semiCircle"), QStringLiteral("oval"),
            QStringLiteral("pill"), QStringLiteral("triangle"), QStringLiteral("diamond"), QStringLiteral("clamShell"),
            QStringLiteral("pentagon"), QStringLiteral("gem"), QStringLiteral("sunny"), QStringLiteral("verySunny"),
            QStringLiteral("cookie4"), QStringLiteral("cookie6"), QStringLiteral("cookie7"), QStringLiteral("cookie9"),
            QStringLiteral("cookie12"), QStringLiteral("ghostish"), QStringLiteral("clover4"), QStringLiteral("clover8"),
            QStringLiteral("burst"), QStringLiteral("softBurst"), QStringLiteral("boom"), QStringLiteral("softBoom"),
            QStringLiteral("flower"), QStringLiteral("puffy"), QStringLiteral("puffyDiamond"), QStringLiteral("pixelCircle"),
            QStringLiteral("pixelTriangle"), QStringLiteral("bun"), QStringLiteral("heart"),
            QStringLiteral("hexagon"), QStringLiteral("octagon"), QStringLiteral("star5"), QStringLiteral("sparkle"),
            QStringLiteral("cross"), QStringLiteral("cookie3"), QStringLiteral("cookie5"), QStringLiteral("cookie8"),
            QStringLiteral("cookie10"), QStringLiteral("scallop"), QStringLiteral("clover3"), QStringLiteral("squircle"),
            QStringLiteral("pebble"), QStringLiteral("blob"), QStringLiteral("leaf"), QStringLiteral("drop"),
            QStringLiteral("shield"), QStringLiteral("bolt"), QStringLiteral("chevron"), QStringLiteral("moon"),
            QStringLiteral("pixelHeart"), QStringLiteral("notch"), QStringLiteral("cookie4ExpandedTL")};
}

std::vector<QPointF> ringPoints(const std::vector<Cubic> &cubics, double size, double strokeWidth)
{
    const double inset = strokeWidth / 2;
    const double span = size - strokeWidth;
    constexpr int steps = 16;
    std::vector<QPointF> pts;
    pts.reserve(cubics.size() * steps + 1);
    for (const Cubic &c : cubics) {
        for (int i = 0; i < steps; i++) {
            const double t = double(i) / steps;
            const double u = 1 - t;
            const double x = u * u * u * c.a0x() + 3 * u * u * t * c.c0x() + 3 * u * t * t * c.c1x() + t * t * t * c.a1x();
            const double y = u * u * u * c.a0y() + 3 * u * u * t * c.c0y() + 3 * u * t * t * c.c1y() + t * t * t * c.a1y();
            pts.emplace_back(inset + x * span, inset + y * span);
        }
    }
    if (pts.size() < 3)
        return {};
    double area = 0;
    for (size_t i = 0; i < pts.size(); i++) {
        const QPointF &a = pts[i];
        const QPointF &b = pts[(i + 1) % pts.size()];
        area += a.x() * b.y() - b.x() * a.y();
    }
    if (area < 0)
        std::reverse(pts.begin(), pts.end());
    double top = std::numeric_limits<double>::infinity();
    for (const QPointF &p : pts)
        top = std::min(top, p.y());
    const double cx = inset + span / 2;
    size_t start = 0;
    double best = std::numeric_limits<double>::infinity();
    for (size_t i = 0; i < pts.size(); i++) {
        const double d = (pts[i].x() - cx) * (pts[i].x() - cx) + (pts[i].y() - top) * (pts[i].y() - top);
        if (d < best) {
            best = d;
            start = i;
        }
    }
    std::vector<QPointF> ring(pts.begin() + long(start), pts.end());
    ring.insert(ring.end(), pts.begin(), pts.begin() + long(start));
    ring.push_back(ring.front());
    return ring;
}

namespace {

std::vector<double> cumulative(const std::vector<QPointF> &ring, double &total)
{
    std::vector<double> lens {0};
    total = 0;
    for (size_t i = 1; i < ring.size(); i++) {
        total += std::hypot(ring[i].x() - ring[i - 1].x(), ring[i].y() - ring[i - 1].y());
        lens.push_back(total);
    }
    return lens;
}

}

double ringProgressAt(const std::vector<QPointF> &ring, double px, double py)
{
    if (ring.size() < 3)
        return -1;
    double total = 0;
    const std::vector<double> lens = cumulative(ring, total);
    if (total <= 0)
        return -1;
    double bestD = std::numeric_limits<double>::infinity();
    double bestLen = 0;
    for (size_t i = 1; i < ring.size(); i++) {
        const QPointF &a = ring[i - 1];
        const QPointF &b = ring[i];
        const double dx = b.x() - a.x(), dy = b.y() - a.y();
        const double seg = dx * dx + dy * dy;
        double t = seg > 0 ? ((px - a.x()) * dx + (py - a.y()) * dy) / seg : 0;
        t = std::max(0.0, std::min(1.0, t));
        const double qx = a.x() + dx * t, qy = a.y() + dy * t;
        const double d = (px - qx) * (px - qx) + (py - qy) * (py - qy);
        if (d < bestD) {
            bestD = d;
            bestLen = lens[i - 1] + std::hypot(qx - a.x(), qy - a.y());
        }
    }
    return std::max(0.0, std::min(1.0, bestLen / total));
}

bool ringPointAt(const std::vector<QPointF> &ring, double progress, QPointF &out)
{
    if (ring.size() < 2)
        return false;
    double total = 0;
    const std::vector<double> lens = cumulative(ring, total);
    if (total <= 0)
        return false;
    const double want = std::max(0.0, std::min(1.0, progress)) * total;
    for (size_t i = 1; i < ring.size(); i++) {
        if (lens[i] >= want) {
            const double segLen = lens[i] - lens[i - 1];
            const double t = segLen > 0 ? (want - lens[i - 1]) / segLen : 0;
            out = ring[i - 1] + (ring[i] - ring[i - 1]) * t;
            return true;
        }
    }
    out = ring.back();
    return true;
}

bool ringNear(const std::vector<QPointF> &ring, double px, double py, double tolerance)
{
    if (ring.size() < 3)
        return false;
    double bestD = std::numeric_limits<double>::infinity();
    for (size_t i = 1; i < ring.size(); i++) {
        const QPointF &a = ring[i - 1];
        const QPointF &b = ring[i];
        const double dx = b.x() - a.x(), dy = b.y() - a.y();
        const double seg = dx * dx + dy * dy;
        double t = seg > 0 ? ((px - a.x()) * dx + (py - a.y()) * dy) / seg : 0;
        t = std::max(0.0, std::min(1.0, t));
        bestD = std::min(bestD, std::hypot(px - (a.x() + dx * t), py - (a.y() + dy * t)));
    }
    return bestD <= tolerance;
}

}
