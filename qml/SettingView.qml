import QtQuick
import QtQuick.Controls
import Updater
import Controller

Item {
    signal backClicked;

    property bool lock: false

    function reload() {
        setting.loadConfig()
        lock = true
        keyInput.text = setting.apiKey
        serverInput.text = setting.apiServer
        shortcutText.text = setting.shortCut
        modelInput.text = setting.model
        lock = false
    }

    function saveConfig() {
        if (lock) {
            return
        }
        setting.apiServer = serverInput.text.trim()
        setting.apiKey = keyInput.text
        setting.shortCut = shortcutText.text
        setting.model = modelInput.text
        setting.updateConfig()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            shortcutRect.focus = false;
            if (shortcutText.text.length > 0) {
                hotkey.setShortcut(shortcutText.text)
            }
        }
    }



    Item{
        id:header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right:parent.right
        anchors.margins: 15
        height:30


        IconButton{
            width: 20
            height:20
            anchors.left: parent.left
            anchors.top: parent.top
            normalUrl:"qrc:///res/back1.png"
            hoveredUrl:"qrc:///res/back1.png"
            pressedUrl:"qrc:///res/back2.png"
            onClicked: {
                backClicked();
            }
        }

    }
    Text{
        id:serverText
        anchors.left: header.left
        anchors.top:header.bottom
        anchors.topMargin: 10
        text:"API Server"
        font.bold: true
        color:"green"
    }

    Item {
        id:serverItem
        anchors.left: header.left
        anchors.right: header.right
        anchors.top:serverText.bottom
        anchors.topMargin: 10
        height:30
        Rectangle {
            color: "#E6E7E7"
            anchors.fill: parent
            radius: 5
        }

        TextInput {
            id:serverInput
            anchors.fill: parent
            padding:7
            text: "http://ipads.chat.gpt:3006"
            onTextChanged: {
                saveConfig()
            }
        }
    }

    Text {
        id: apiText
        anchors.left: header.left
        anchors.top: serverItem.bottom
        anchors.topMargin: 20
        text: "API Key"
        font.bold: true
        color: "green"
    }

    ScrollView {
        id: keyInputScroll
        anchors.left: header.left
        anchors.right: header.right
        anchors.top: apiText.bottom
        anchors.topMargin: 10
        height: 80
        contentWidth: width
        contentHeight: keyInput.contentHeight + 20
        ScrollBar.vertical: ScrollBar {
            width: (parent.contentHeight >= parent.height) ? 10 : 0
            height: parent.height
            anchors.right: parent.right
            policy: ScrollBar.AlwaysOn
        }
        TextArea {
            id: keyInput
            height: 80
            font.pixelSize: 14
            y: 20
            wrapMode: Text.WrapAnywhere
            onTextChanged: {
                saveConfig()
            }
            background: Rectangle {
                color: "#E6E7E7"
                radius: 5
            }
        }
    }

    Text {
        id: modelText
        anchors.left: header.left
        anchors.top: keyInputScroll.bottom
        anchors.topMargin: 20
        text: "Model"
        font.bold: true
        color: "green"
    }

    Item {
        id: inputRow
        anchors.left: header.left
        anchors.right: header.right
        anchors.top: modelText.bottom
        anchors.topMargin: 10
        Rectangle {
            color: "#E6E7E7"
            anchors.fill: parent
            radius: 5
        }
        TextInput {
                id: modelInput
                anchors.fill: parent
                padding: 7
                text: "gpt-4o-mini"
                onTextChanged: {
                        saveConfig()
                }
        }
        height: 40
        width: parent
    }


    Text {
        id: shortCutText
        anchors.left: header.left
        anchors.top: inputRow.bottom
        anchors.topMargin: 20
        text: "Shortcut"
        font.bold: true
        color: "green"
    }

    Item {
        id: shortcutItem
        anchors.left: header.left
        anchors.top: shortCutText.bottom
        anchors.topMargin: 10
        width: 100
        height: 30
        Rectangle {
            id: shortcutRect
            color: "#E6E7E7"
            anchors.fill: parent
            radius: 5
            border.width: 1
            border.color: color
            onActiveFocusChanged: {}

            onFocusChanged: {
                if (focus) {
                    border.color = "green"
                    shortcutRect.forceActiveFocus()
                    shortcutText.text = ""
                    hotkey.setShortcut("")
                } else {
                    border.color = color
                }
            }

            Text {
                id: shortcutText
                anchors.centerIn: parent
                text: ""
                onTextChanged: {
                    saveConfig()
                }
            }

            Keys.onPressed: (event) => {
                if (!shortcutRect.focus) {
                    return
                }

                shortcutText.text = ""
                var valid = false
                var haveCtrl = false

                if (Qt.platform.os === "macos" || Qt.platform.os === "osx") {
                    if (event.modifiers & Qt.ControlModifier) {
                        shortcutText.text = "Ctrl+"
                        haveCtrl = true
                    }
                    if (event.modifiers & Qt.MetaModifier) {
                        shortcutText.text = "Meta+"
                        haveCtrl = true
                    }
                } else {
                    if (event.modifiers & Qt.ControlModifier) {
                        shortcutText.text = "Ctrl+"
                        haveCtrl = true
                    }
                }

                if (event.modifiers & Qt.AltModifier) {
                    shortcutText.text = "Alt+"
                    haveCtrl = true
                }
                if (event.modifiers & Qt.ShiftModifier) {
                    shortcutText.text = "Shift+"
                    haveCtrl = true
                }

                if (shortCutText.text.length > 0) {
                    switch (event.key) {
                        case Qt.Key_F1: shortcutText.text = "F1"; valid = true; break;
                        case Qt.Key_F2: shortcutText.text = "F2"; valid = true; break;
                        case Qt.Key_F3: shortcutText.text = "F3"; valid = true; break;
                        case Qt.Key_F4: shortcutText.text = "F4"; valid = true; break;
                        case Qt.Key_F5: shortcutText.text = "F5"; valid = true; break;
                        case Qt.Key_F6: shortcutText.text = "F6"; valid = true; break;
                        case Qt.Key_F7: shortcutText.text = "F7"; valid = true; break;
                        case Qt.Key_F8: shortcutText.text = "F8"; valid = true; break;
                        case Qt.Key_F9: shortcutText.text = "F9"; valid = true; break;
                        case Qt.Key_F10: shortcutText.text = "F10"; valid = true; break;
                        case Qt.Key_F11: shortcutText.text = "F11"; valid = true; break;
                        case Qt.Key_F12: shortcutText.text = "F12"; valid = true; break;
                    }
                    if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                        if (haveCtrl) {
                            shortcutText.text += String.fromCharCode(event.key)
                            valid = true
                        }
                    } else if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                        if (haveCtrl) {
                            shortcutText.text += String.fromCharCode(event.key)
                            valid = true
                        }
                    }
                }

                if (valid) {
                    shortcutRect.focus = false;
                    if (shortcutText.text.length > 0) {
                        if (hotkey.setShortcut(shortcutText.text) == false) {
                            shortcutRect.focus = false;
                            shortcutText.text = ""
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                shortcutRect.focus = true
            }
        }
    }

    Text {
        id: about
        anchors.left: header.left
        anchors.top: shortcutItem.bottom
        anchors.topMargin: 20
        text: "About"
        font.bold: true
        color: "green"
    }

    Column {
        spacing: 10
        anchors.top: about.bottom
        anchors.topMargin: 15
        anchors.left: header.left
        anchors.right: header.right
        Image {
            id: icon
            anchors.horizontalCenter: parent.horizontalCenter
            source: "qrc:///res/logo/logo.ico"
            height: 40
            width: 40
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.openUrlExternally("https://github.com/JesseGuoX/GPT-Translator")
                }
            }
        }

        Text {
            id: version
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 15
            text: "Current version:" + Qt.application.version
            font.bold: true
            font.pixelSize: 12
            color: "green"
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            height: checkBtn.height
            width: parent.width
            Button {
                id: checkBtn
                text: "check update"
                font.capitalization: Font.MixedCase
                height: 40
                anchors.horizontalCenter: parent.horizontalCenter
                Material.background: Material.Green
                Material.foreground: (Qt.platform.os === "linux") ? "black" : "white" //linux can't display button use software render
                onClicked: {
                    updater.check()
                }
            }
            BusyIndicator {
                anchors.verticalCenter: checkBtn.verticalCenter
                anchors.left: checkBtn.right
                anchors.leftMargin: 10
                running: updater.isRequesting
                visible: updater.isRequesting
                width: checkBtn.height - 10
                height: width
            }
        }

        Text {
            id: linkText
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !updater.isRequesting
            text: "<u><a href='" + "https://www.google.com" + "'>" + updater.requestResult + "</a></u>"
            onLinkActivated: Qt.openUrlExternally(updater.updateLink)
        }

        TextArea {
            width: parent.width
            visible: !updater.isRequesting
            text: updater.releaseNote
            readOnly: true
            wrapMode: Text.WrapAnywhere
            y: 30
            background: Rectangle {}
        }
    }

    APIUpdater {
        id: updater
        onIsRequestingChanged: {
            if (isRequesting) {
                checkBtn.enabled = false
            } else {
                checkBtn.enabled = true
                if (updater.updateLink.length > 0) {
                    linkText.text = "<u><a  href='" + updater.updateLink + "'>" + updater.requestResult + "</a></u>"
                } else {
                    linkText.text = requestResult
                }
            }
        }
    }
}
