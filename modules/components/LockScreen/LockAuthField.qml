pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.utils
import qs.modules.customComponents

// Password entry plus a reserved line beneath it for the failure message. The
// message lives outside the field so it stays readable once the user has
// started typing and the placeholder is gone.
//
// variant:
//   pill   — filled capsule
//   filled — filled rounded rectangle
//   line   — no fill, a rule along the bottom that thickens on focus
ColumnLayout {
    id: root

    property var context: null
    property alias input: passInput
    property real fieldWidth: 460
    property string variant: "pill"
    property bool showSubmit: true
    property bool submitAlways: false
    property color fieldColor: Colors.surfaceContainerHighest
    property real fieldRadius: -1
    property real fieldHeight: -1
    property color idleBorder: "transparent"
    property color accent: Colors.primary
    property color onAccent: Colors.primaryText
    property real submitRadius: -1
    property bool showLockIcon: true
    property string placeholder: "Enter password"
    property color placeholderColor: Colors.outline
    property string placeholderFamily: ""
    property int placeholderSize: 20
    property bool showFailureLine: true

    readonly property bool _line: root.variant === "line"
    readonly property bool _failed: root.context?.showFailure ?? false
    readonly property bool _busy: root.context?.unlockInProgress ?? false

    readonly property color _accent: root._failed
        ? Colors.error
        : passInput.activeFocus ? root.accent
                                : Qt.alpha(Colors.outlineVariant, 0.55)

    spacing: 8

    Rectangle {
        id: pill

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: root.fieldWidth
        Layout.preferredHeight: root.fieldHeight > 0 ? root.fieldHeight
            : root._line ? 52 : (root.variant === "filled" ? 58 : 64)

        radius: root.fieldRadius >= 0 ? root.fieldRadius
            : root._line ? 0 : (root.variant === "filled" ? 20 : height / 2)
        color: root._line ? "transparent" : root.fieldColor

        border.width: root._line ? 0
            : (root._failed || passInput.activeFocus) ? 2
            : root.idleBorder.a > 0 ? 1.5 : 0
        border.color: root._failed ? Colors.error
            : passInput.activeFocus ? root.accent : root.idleBorder

        Behavior on border.color { ColorAnimation { duration: 200 } }
        Behavior on border.width { NumberAnimation { duration: 160 } }

        // Shake on a rejected password. Translate rather than x so the layout
        // keeps ownership of the pill's real position.
        transform: Translate { id: shakeOffset }

        SequentialAnimation {
            id: shakeAnim
            loops: 2
            NumberAnimation { target: shakeOffset; property: "x"; to:  10; duration: 55; easing.type: Easing.OutSine }
            NumberAnimation { target: shakeOffset; property: "x"; to: -10; duration: 55; easing.type: Easing.OutSine }
            NumberAnimation { target: shakeOffset; property: "x"; to:   0; duration: 55; easing.type: Easing.OutSine }
        }

        Connections {
            target: root.context
            function onFailed() { shakeAnim.restart() }
        }

        // The rule that replaces the fill in `line`
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root._line
            height: (root._failed || passInput.activeFocus) ? 2 : 1
            color: root._accent

            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on height { NumberAnimation { duration: 160 } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root._line ? 2 : 18
            anchors.rightMargin: root._line ? 2 : 8
            spacing: 12

            MaterialIconSymbol {
                visible: root.showLockIcon
                content: root._busy ? "lock_open" : "lock"
                iconSize: 22
                customColor: root._failed
                    ? Colors.error
                    : root._busy ? root.accent : root.placeholderColor
            }

            CustomShapeInput {
                id: passInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: root.placeholder
                placeholderColor: root.placeholderColor
                placeholderFamily: root.placeholderFamily
                placeholderSize: root.placeholderSize
                accentColor: root.accent
                enabled: !root._busy

                onTextChanged: if (root.context) root.context.currentText = text
                onAccepted:    if (root.context) root.context.tryUnlock()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        passInput.text = root.context.currentText
                    }
                }
            }

            // Caps lock warning — slides in from the trailing edge
            Rectangle {
                Layout.preferredWidth: (root.context?.capsLockOn ?? false) ? capsRow.implicitWidth + 18 : 0
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                clip: true
                radius: 14
                color: Qt.alpha(Colors.tertiary, 0.2)
                opacity: (root.context?.capsLockOn ?? false) ? 1 : 0

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
                Behavior on opacity { NumberAnimation { duration: 180 } }

                RowLayout {
                    id: capsRow
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialIconSymbol {
                        content: "keyboard_capslock"
                        iconSize: 15
                        customColor: Colors.tertiary
                    }
                    CustomText {
                        content: "Caps"
                        size: 11; weight: 700
                        customColor: Colors.tertiary
                    }
                }
            }

            // Submit — appears once there is something to submit, and turns
            // into a spinner while PAM is thinking.
            Rectangle {
                id: submit
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignVCenter
                radius: root.submitRadius >= 0 ? root.submitRadius : height / 2
                color: "transparent"

                readonly property bool _wanted: root.showSubmit
                    && (root.submitAlways || (root.context?.currentText?.length ?? 0) > 0)

                opacity: submit._wanted ? 1 : 0
                visible: opacity > 0

                Behavior on opacity { NumberAnimation { duration: 160 } }

                Rectangle {
                    z: -1
                    anchors.centerIn: parent
                    width: submit._wanted ? submit.width : Math.round(submit.width * 0.7)
                    height: width
                    radius: root.submitRadius >= 0 ? root.submitRadius * width / Math.max(1, submit.width) : width / 2
                    color: root.accent
                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }
                }

                MaterialIconSymbol {
                    anchors.centerIn: parent
                    content: "arrow_forward"
                    iconSize: submit._wanted ? 22 : 15
                    Behavior on iconSize {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }
                    customColor: root.onAccent
                    visible: !root._busy
                }

                CustomCircularLoader {
                    anchors.centerIn: parent
                    size: 28
                    trackWidth: 3
                    value: -1
                    highlightColor: root.onAccent
                    trackColor: Qt.alpha(root.onAccent, 0.25)
                    visible: root._busy
                }

                CustomMouseArea {
                    radius: submit.radius
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root._busy
                    onClicked: if (root.context) root.context.tryUnlock()
                }
            }
        }
    }

    // Failure line. Height is reserved so the stack never jumps.
    CustomText {
        visible: root.showFailureLine
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 18
        content: (root.context?.failedAttempts ?? 0) > 1
            ? "Wrong password — attempt " + (root.context?.failedAttempts ?? 0)
            : "Wrong password — try again"
        size: 12
        weight: 600
        customColor: Colors.error
        opacity: root._failed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}
