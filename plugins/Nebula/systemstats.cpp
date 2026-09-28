#include "systemstats.h"

#include <QDateTime>
#include <QDir>
#include <QFile>

#include <sys/statvfs.h>

namespace {

constexpr qreal kGiB = 1024.0 * 1024.0 * 1024.0;

QByteArray readFile(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    return f.readAll();
}

bool readNumber(const QString &path, qreal &out)
{
    const QByteArray data = readFile(path).trimmed();
    if (data.isEmpty())
        return false;
    bool ok = false;
    const qreal v = data.toDouble(&ok);
    if (ok)
        out = v;
    return ok;
}

template <typename T>
bool assign(T &field, const T &value)
{
    if (field == value)
        return false;
    field = value;
    return true;
}

quint64 field(const QList<QByteArray> &parts, int i)
{
    return i < parts.size() ? parts.at(i).toULongLong() : 0;
}

}

SystemStats::SystemStats(QObject *parent)
    : QObject(parent)
{
    m_statsTimer.setInterval(4000);
    m_netTimer.setInterval(2000);
    m_diskTimer.setInterval(30000);
    connect(&m_statsTimer, &QTimer::timeout, this, &SystemStats::sampleStats);
    connect(&m_netTimer, &QTimer::timeout, this, &SystemStats::sampleNet);
    connect(&m_diskTimer, &QTimer::timeout, this, &SystemStats::sampleDisk);

    resolvePaths();

    const QList<QByteArray> lines = readFile(QStringLiteral("/proc/cpuinfo")).split('\n');
    for (const QByteArray &line : lines) {
        if (line.startsWith("model name")) {
            const int sep = line.indexOf(':');
            if (sep >= 0)
                m_cpuName = QString::fromUtf8(line.mid(sep + 1).trimmed());
            break;
        }
    }

    qreal vramTotal = 0;
    if (!m_gpuDevicePath.isEmpty() && readNumber(m_gpuDevicePath + QStringLiteral("/mem_info_vram_total"), vramTotal))
        m_gpuVramTotalGb = vramTotal / kGiB;
}

void SystemStats::resolvePaths()
{
    static const QStringList cpuSensors = {
        QStringLiteral("k10temp"), QStringLiteral("zenpower"),
        QStringLiteral("coretemp"), QStringLiteral("cpu_thermal"),
    };

    const QDir hwmonRoot(QStringLiteral("/sys/class/hwmon"));
    for (const QString &entry : hwmonRoot.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
        const QString dir = hwmonRoot.filePath(entry);
        const QString name = QString::fromUtf8(readFile(dir + QStringLiteral("/name")).trimmed());
        if (m_cpuTempPath.isEmpty() && cpuSensors.contains(name) && QFile::exists(dir + QStringLiteral("/temp1_input")))
            m_cpuTempPath = dir + QStringLiteral("/temp1_input");
    }

    const QDir drmRoot(QStringLiteral("/sys/class/drm"));
    for (const QString &entry : drmRoot.entryList({QStringLiteral("card*")}, QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
        if (entry.contains(QLatin1Char('-')))
            continue;
        const QString device = drmRoot.filePath(entry) + QStringLiteral("/device");
        if (!QFile::exists(device + QStringLiteral("/gpu_busy_percent")))
            continue;
        m_gpuDevicePath = device;
        const QDir hw(device + QStringLiteral("/hwmon"));
        const QStringList hws = hw.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        if (!hws.isEmpty())
            m_gpuHwmonPath = hw.filePath(hws.first());
        break;
    }
}

void SystemStats::setRunning(bool running)
{
    if (m_running == running)
        return;
    m_running = running;
    if (running) {
        m_statsTimer.start();
        m_netTimer.start();
        m_diskTimer.start();
        sampleNow();
    } else {
        m_statsTimer.stop();
        m_netTimer.stop();
        m_diskTimer.stop();
        resetNetBaseline();
    }
    emit runningChanged();
}

void SystemStats::setInterval(int ms)
{
    ms = qMax(250, ms);
    if (m_statsTimer.interval() == ms)
        return;
    m_statsTimer.setInterval(ms);
    emit intervalChanged();
}

void SystemStats::setNetInterval(int ms)
{
    ms = qMax(250, ms);
    if (m_netTimer.interval() == ms)
        return;
    m_netTimer.setInterval(ms);
    emit netIntervalChanged();
}

void SystemStats::setDiskInterval(int ms)
{
    ms = qMax(1000, ms);
    if (m_diskTimer.interval() == ms)
        return;
    m_diskTimer.setInterval(ms);
    emit diskIntervalChanged();
}

void SystemStats::setNetInterface(const QString &iface)
{
    if (m_netInterface == iface)
        return;
    m_netInterface = iface;
    resetNetBaseline();
    m_netDown = 0;
    m_netUp = 0;
    m_netRx = 0;
    m_netTx = 0;
    emit netChanged();
    emit netInterfaceChanged();
}

void SystemStats::resetNetBaseline()
{
    m_havePrevNet = false;
    m_lastNetMs = 0;
}

void SystemStats::sampleNow()
{
    sampleStats();
    sampleNet();
    sampleDisk();
}

void SystemStats::sampleStats()
{
    sampleCpu();
    sampleMem();
    sampleTemps();
    sampleGpu();
}

void SystemStats::sampleCpu()
{
    const QList<QByteArray> lines = readFile(QStringLiteral("/proc/stat")).split('\n');
    if (lines.isEmpty() || !lines.first().startsWith("cpu"))
        return;

    auto parse = [](const QByteArray &line) {
        const QList<QByteArray> p = line.simplified().split(' ');
        CpuTimes t;
        const quint64 idle = field(p, 4);
        const quint64 iowait = field(p, 5);
        t.total = field(p, 1) + field(p, 2) + field(p, 3) + idle + iowait + field(p, 6) + field(p, 7);
        t.idle = idle + iowait;
        return t;
    };

    bool changed = false;
    const CpuTimes all = parse(lines.first());
    if (m_havePrevCpu) {
        const qreal dt = qreal(all.total) - qreal(m_prevCpu.total);
        const qreal di = qreal(all.idle) - qreal(m_prevCpu.idle);
        changed |= assign(m_cpuUsage, dt > 0 ? (dt - di) / dt : 0.0);
    }
    m_prevCpu = all;
    m_havePrevCpu = true;

    QList<CpuTimes> next;
    QVariantList cores;
    for (int i = 1; i < lines.size() && lines.at(i).startsWith("cpu"); i++) {
        const CpuTimes t = parse(lines.at(i));
        const int idx = next.size();
        next.append(t);
        if (idx < m_prevCores.size()) {
            const CpuTimes &pc = m_prevCores.at(idx);
            const qreal dt = qreal(t.total) - qreal(pc.total);
            const qreal di = qreal(t.idle) - qreal(pc.idle);
            cores.append(dt > 0 ? (dt - di) / dt : 0.0);
        }
    }
    m_prevCores = next;
    if (!cores.isEmpty())
        changed |= assign(m_cpuCores, cores);

    if (changed)
        emit cpuChanged();
}

void SystemStats::sampleMem()
{
    const QList<QByteArray> lines = readFile(QStringLiteral("/proc/meminfo")).split('\n');
    qreal total = 0, available = 0, cached = 0, reclaim = 0, buffers = 0;
    auto value = [](const QByteArray &line) {
        return line.simplified().split(' ').value(1).toDouble();
    };
    for (const QByteArray &line : lines) {
        if (line.startsWith("MemTotal:"))
            total = value(line);
        else if (line.startsWith("MemAvailable:"))
            available = value(line);
        else if (line.startsWith("Cached:"))
            cached = value(line);
        else if (line.startsWith("SReclaimable:"))
            reclaim = value(line);
        else if (line.startsWith("Buffers:"))
            buffers = value(line);
    }

    bool changed = false;
    changed |= assign(m_memCacheFrac, total > 0 ? qMin(available, cached + reclaim) / total : 0.0);
    changed |= assign(m_memBuffersFrac, total > 0 ? buffers / total : 0.0);
    changed |= assign(m_memTotalGb, total / (1024.0 * 1024.0));
    changed |= assign(m_memUsedGb, (total - available) / (1024.0 * 1024.0));
    changed |= assign(m_memUsage, total > 0 ? (total - available) / total : 0.0);
    if (changed)
        emit memChanged();
}

void SystemStats::sampleTemps()
{
    qreal v = 0;
    if (!m_cpuTempPath.isEmpty() && readNumber(m_cpuTempPath, v) && assign(m_cpuTemp, v / 1000.0))
        emit cpuTempChanged();
}

void SystemStats::sampleGpu()
{
    if (m_gpuDevicePath.isEmpty())
        return;

    bool changed = false;
    qreal v = 0;
    if (readNumber(m_gpuDevicePath + QStringLiteral("/gpu_busy_percent"), v))
        changed |= assign(m_gpuUsage, v / 100.0);
    if (!m_gpuHwmonPath.isEmpty()) {
        if (readNumber(m_gpuHwmonPath + QStringLiteral("/temp1_input"), v))
            changed |= assign(m_gpuTemp, v / 1000.0);
        if (readNumber(m_gpuHwmonPath + QStringLiteral("/freq1_input"), v))
            changed |= assign(m_gpuClockMhz, v / 1000000.0);
    }
    if (readNumber(m_gpuDevicePath + QStringLiteral("/mem_info_vram_used"), v)) {
        changed |= assign(m_gpuVramUsedGb, v / kGiB);
        if (m_gpuVramTotalGb > 0)
            changed |= assign(m_gpuVramUsage, v / (m_gpuVramTotalGb * kGiB));
    }
    if (changed)
        emit gpuChanged();
}

void SystemStats::sampleNet()
{
    auto clearReadings = [this] {
        bool changed = assign(m_netDown, 0.0);
        changed |= assign(m_netUp, 0.0);
        return changed;
    };

    if (m_netInterface.isEmpty()) {
        resetNetBaseline();
        if (clearReadings())
            emit netChanged();
        emit netSampled();
        return;
    }

    const QByteArray prefix = m_netInterface.toUtf8() + ':';
    qreal rx = -1, tx = -1;
    const QList<QByteArray> lines = readFile(QStringLiteral("/proc/net/dev")).split('\n');
    for (const QByteArray &raw : lines) {
        const QByteArray line = raw.trimmed();
        if (!line.startsWith(prefix))
            continue;
        const QList<QByteArray> parts = line.mid(prefix.size()).simplified().split(' ');
        if (parts.size() > 8) {
            rx = parts.at(0).toDouble();
            tx = parts.at(8).toDouble();
        }
        break;
    }

    if (rx < 0 || tx < 0) {
        resetNetBaseline();
        if (clearReadings())
            emit netChanged();
        emit netSampled();
        return;
    }

    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const qreal dt = (now - m_lastNetMs) / 1000.0;
    const bool usable = m_havePrevNet && rx >= m_prevRx && tx >= m_prevTx && dt > 0
        && dt < (m_netTimer.interval() / 1000.0) * 3;

    bool changed = false;
    if (usable) {
        changed |= assign(m_netDown, (rx - m_prevRx) / dt);
        changed |= assign(m_netUp, (tx - m_prevTx) / dt);
    } else {
        changed |= clearReadings();
    }
    changed |= assign(m_netRx, rx);
    changed |= assign(m_netTx, tx);

    m_prevRx = rx;
    m_prevTx = tx;
    m_havePrevNet = true;
    m_lastNetMs = now;

    if (changed)
        emit netChanged();
    emit netSampled();
}

void SystemStats::sampleDisk()
{
    struct statvfs s {};
    if (statvfs("/", &s) != 0)
        return;
    const qreal frsize = qreal(s.f_frsize);
    const qreal total = qreal(s.f_blocks) * frsize;
    const qreal used = qreal(s.f_blocks - s.f_bfree) * frsize;

    bool changed = false;
    changed |= assign(m_diskUsedGb, used / kGiB);
    changed |= assign(m_diskTotalGb, total / kGiB);
    changed |= assign(m_diskUsage, total > 0 ? used / total : 0.0);
    if (changed)
        emit diskChanged();
}
