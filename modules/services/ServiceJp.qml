pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property string serif: "Noto Serif CJK JP"
    readonly property string sans: "Noto Sans CJK JP"
    readonly property string mono: "Noto Sans Mono CJK JP"

    readonly property var _digits: ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
    readonly property var _weekdays: ["日", "月", "火", "水", "木", "金", "土"]

    readonly property var _dayIndex: ({
        "Sunday": 0, "Monday": 1, "Tuesday": 2, "Wednesday": 3,
        "Thursday": 4, "Friday": 5, "Saturday": 6
    })

    readonly property var _monthIndex: ({
        "January": 1, "February": 2, "March": 3, "April": 4,
        "May": 5, "June": 6, "July": 7, "August": 8,
        "September": 9, "October": 10, "November": 11, "December": 12
    })

    readonly property var _monthNames: [
        { jp: "睦月", romaji: "Mutsuki"    },
        { jp: "如月", romaji: "Kisaragi"   },
        { jp: "弥生", romaji: "Yayoi"      },
        { jp: "卯月", romaji: "Uzuki"      },
        { jp: "皐月", romaji: "Satsuki"    },
        { jp: "水無月", romaji: "Minazuki" },
        { jp: "文月", romaji: "Fumizuki"   },
        { jp: "葉月", romaji: "Hazuki"     },
        { jp: "長月", romaji: "Nagatsuki"  },
        { jp: "神無月", romaji: "Kannazuki" },
        { jp: "霜月", romaji: "Shimotsuki" },
        { jp: "師走", romaji: "Shiwasu"    }
    ]

    readonly property var _sekki: [
        { m: 1,  d: 5,  jp: "小寒", romaji: "Shōkan",   en: "minor cold" },
        { m: 1,  d: 20, jp: "大寒", romaji: "Daikan",   en: "major cold" },
        { m: 2,  d: 4,  jp: "立春", romaji: "Risshun",  en: "start of spring" },
        { m: 2,  d: 19, jp: "雨水", romaji: "Usui",     en: "rainwater" },
        { m: 3,  d: 5,  jp: "啓蟄", romaji: "Keichitsu", en: "insects awaken" },
        { m: 3,  d: 20, jp: "春分", romaji: "Shunbun",  en: "vernal equinox" },
        { m: 4,  d: 5,  jp: "清明", romaji: "Seimei",   en: "clear and bright" },
        { m: 4,  d: 20, jp: "穀雨", romaji: "Kokuu",    en: "grain rain" },
        { m: 5,  d: 5,  jp: "立夏", romaji: "Rikka",    en: "start of summer" },
        { m: 5,  d: 21, jp: "小満", romaji: "Shōman",   en: "grain full" },
        { m: 6,  d: 6,  jp: "芒種", romaji: "Bōshu",    en: "grain in ear" },
        { m: 6,  d: 21, jp: "夏至", romaji: "Geshi",    en: "summer solstice" },
        { m: 7,  d: 7,  jp: "小暑", romaji: "Shōsho",   en: "minor heat" },
        { m: 7,  d: 23, jp: "大暑", romaji: "Taisho",   en: "major heat" },
        { m: 8,  d: 7,  jp: "立秋", romaji: "Risshū",   en: "start of autumn" },
        { m: 8,  d: 23, jp: "処暑", romaji: "Shosho",   en: "limit of heat" },
        { m: 9,  d: 8,  jp: "白露", romaji: "Hakuro",   en: "white dew" },
        { m: 9,  d: 23, jp: "秋分", romaji: "Shūbun",   en: "autumnal equinox" },
        { m: 10, d: 8,  jp: "寒露", romaji: "Kanro",    en: "cold dew" },
        { m: 10, d: 23, jp: "霜降", romaji: "Sōkō",     en: "frost descends" },
        { m: 11, d: 7,  jp: "立冬", romaji: "Rittō",    en: "start of winter" },
        { m: 11, d: 22, jp: "小雪", romaji: "Shōsetsu", en: "minor snow" },
        { m: 12, d: 7,  jp: "大雪", romaji: "Taisetsu", en: "major snow" },
        { m: 12, d: 22, jp: "冬至", romaji: "Tōji",     en: "winter solstice" }
    ]

    readonly property var _haiku: [
        {
            lines: ["古池や", "蛙飛びこむ", "水の音"],
            author: "松尾芭蕉",
            authorRomaji: "Matsuo Bashō",
            kigo: "蛙",
            season: 0
        },
        {
            lines: ["菜の花や", "月は東に", "日は西に"],
            author: "与謝蕪村",
            authorRomaji: "Yosa Buson",
            kigo: "菜の花",
            season: 0
        },
        {
            lines: ["閑さや", "岩にしみ入る", "蝉の声"],
            author: "松尾芭蕉",
            authorRomaji: "Matsuo Bashō",
            kigo: "蝉",
            season: 1
        },
        {
            lines: ["柿くへば", "鐘が鳴るなり", "法隆寺"],
            author: "正岡子規",
            authorRomaji: "Masaoka Shiki",
            kigo: "柿",
            season: 2
        },
        {
            lines: ["旅に病んで", "夢は枯野を", "かけ廻る"],
            author: "松尾芭蕉",
            authorRomaji: "Matsuo Bashō",
            kigo: "枯野",
            season: 3
        }
    ]

    readonly property var _kanji: [
        { ch: "日", on: "ニチ・ジツ", kun: "ひ・か",     en: "sun, day" },
        { ch: "月", on: "ゲツ・ガツ", kun: "つき",       en: "moon, month" },
        { ch: "山", on: "サン",       kun: "やま",       en: "mountain" },
        { ch: "川", on: "セン",       kun: "かわ",       en: "river" },
        { ch: "空", on: "クウ",       kun: "そら",       en: "sky, empty" },
        { ch: "海", on: "カイ",       kun: "うみ",       en: "sea" },
        { ch: "森", on: "シン",       kun: "もり",       en: "forest" },
        { ch: "雨", on: "ウ",         kun: "あめ",       en: "rain" },
        { ch: "雪", on: "セツ",       kun: "ゆき",       en: "snow" },
        { ch: "風", on: "フウ",       kun: "かぜ",       en: "wind" },
        { ch: "花", on: "カ",         kun: "はな",       en: "flower" },
        { ch: "星", on: "セイ",       kun: "ほし",       en: "star" },
        { ch: "光", on: "コウ",       kun: "ひかり",     en: "light" },
        { ch: "夢", on: "ム",         kun: "ゆめ",       en: "dream" },
        { ch: "心", on: "シン",       kun: "こころ",     en: "heart, mind" },
        { ch: "道", on: "ドウ",       kun: "みち",       en: "road, way" },
        { ch: "静", on: "セイ",       kun: "しず",       en: "quiet, still" },
        { ch: "音", on: "オン",       kun: "おと",       en: "sound" },
        { ch: "時", on: "ジ",         kun: "とき",       en: "time" },
        { ch: "影", on: "エイ",       kun: "かげ",       en: "shadow" }
    ]

    readonly property var _weather: [
        { match: ["sunny", "clear"],                    jp: "晴れ",     romaji: "hare" },
        { match: ["partly cloudy", "partly"],           jp: "晴れ時々曇り", romaji: "hare tokidoki kumori" },
        { match: ["cloudy", "overcast"],                jp: "曇り",     romaji: "kumori" },
        { match: ["mist", "fog", "freezing fog"],       jp: "霧",       romaji: "kiri" },
        { match: ["thunder"],                           jp: "雷雨",     romaji: "raiu" },
        { match: ["heavy rain", "torrential"],          jp: "大雨",     romaji: "ōame" },
        { match: ["drizzle", "light rain", "patchy rain"], jp: "小雨",  romaji: "kosame" },
        { match: ["rain", "shower"],                    jp: "雨",       romaji: "ame" },
        { match: ["heavy snow", "blizzard"],            jp: "大雪",     romaji: "ōyuki" },
        { match: ["sleet"],                             jp: "みぞれ",   romaji: "mizore" },
        { match: ["snow"],                              jp: "雪",       romaji: "yuki" }
    ]

    function spell(text) {
        let out = ""
        for (let i = 0; i < text.length; i++) {
            const d = parseInt(text[i])
            out += isNaN(d) ? text[i] : root._digits[d]
        }
        return out
    }

    function count(n) {
        const v = Math.max(0, Math.round(n))
        if (v < 10)
            return root._digits[v]
        if (v < 20)
            return "十" + (v % 10 === 0 ? "" : root._digits[v % 10])
        return root._digits[Math.floor(v / 10)] + "十"
             + (v % 10 === 0 ? "" : root._digits[v % 10])
    }

    readonly property var _statusNames: ({
        "Weather": "天気",
        "Battery": "電池",
        "Network": "通信",
        "Notifications": "通知",
        "Music": "音楽",
        "Time": "時刻"
    })

    function status(name) {
        return root._statusNames[name] ?? name
    }

    function weatherFor(description) {
        const d = (description ?? "").toLowerCase()
        for (let i = 0; i < root._weather.length; i++) {
            const e = root._weather[i]
            for (let j = 0; j < e.match.length; j++)
                if (d.indexOf(e.match[j]) !== -1)
                    return e
        }
        return { jp: "—", romaji: "" }
    }

    readonly property int _dow: root._dayIndex[ServiceClock.day] ?? 0
    readonly property int _mon: root._monthIndex[ServiceClock.month] ?? 1
    readonly property int _dayNum: parseInt(ServiceClock.date)
    readonly property int _hour24: parseInt(ServiceClock.hour)

    readonly property string year: root.spell(ServiceClock.year) + "年"
    readonly property string monthDay:
        root.count(root._mon) + "月" + root.count(root._dayNum) + "日"
    readonly property string weekday: root._weekdays[root._dow] + "曜日"
    readonly property string dayKanji: root.count(root._dayNum)
    readonly property string dateShort:
        root._mon + "月" + root._dayNum + "日"
        + "（" + root._weekdays[root._dow] + "）"

    readonly property var monthName: root._monthNames[root._mon - 1]

    readonly property var sekki: {
        let found = root._sekki[root._sekki.length - 1]
        for (let i = 0; i < root._sekki.length; i++) {
            const s = root._sekki[i]
            if (root._mon > s.m || (root._mon === s.m && root._dayNum >= s.d))
                found = s
        }
        return found
    }

    readonly property int season: {
        const m = root._mon
        if (m >= 3 && m <= 5)  return 0
        if (m >= 6 && m <= 8)  return 1
        if (m >= 9 && m <= 11) return 2
        return 3
    }

    readonly property int _dayOfYear: {
        const start = new Date(parseInt(ServiceClock.year), 0, 0)
        const now = new Date(parseInt(ServiceClock.year), root._mon - 1, root._dayNum)
        return Math.floor((now - start) / 86400000)
    }

    readonly property var haiku: {
        const pool = root._haiku.filter(h => h.season === root.season)
        const list = pool.length > 0 ? pool : root._haiku
        return list[root._dayOfYear % list.length]
    }

    readonly property var kanji: root._kanji[root._dayOfYear % root._kanji.length]

    readonly property string period: {
        const h = root._hour24
        if (h < 4)  return "未明"
        if (h < 10) return "朝"
        if (h < 15) return "昼"
        if (h < 18) return "夕"
        if (h < 22) return "夜"
        return "深夜"
    }

    readonly property string periodRoman: {
        const h = root._hour24
        if (h < 4)  return "small hours"
        if (h < 10) return "morning"
        if (h < 15) return "midday"
        if (h < 18) return "evening"
        if (h < 22) return "night"
        return "late night"
    }
}
