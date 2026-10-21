// SPDX-FileCopyrightText: 2026 Kumulus contributors
// SPDX-License-Identifier: MIT

import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: root

    title: i18nc("@title:window", "Kumulus")

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: true
        actions: [
            Kirigami.Action {
                text: i18nc("@action:inmenu", "About Kumulus")
                icon.name: "help-about"
                onTriggered: root.pageStack.pushDialogLayer(Qt.createComponent("org.kde.kirigamiaddons.formcard", "AboutPage"))
            }
        ]
    }

    pageStack.initialPage: Kirigami.Page {
        title: i18nc("@title", "Kumulus")

        // Accounts and sync pairs come with #10.
        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            icon.name: "folder-cloud"
            text: i18nc("@info:placeholder", "No accounts yet")
        }
    }
}
