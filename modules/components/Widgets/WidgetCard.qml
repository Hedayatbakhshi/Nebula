import QtQuick
import qs.modules.utils

Rectangle {
    id: card

    readonly property real pad: WidgetSizes.padFor(card.width)

    radius: WidgetSizes.radius
    color: WidgetSizes.cardColor
}
