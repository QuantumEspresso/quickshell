pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    // --- Główne właściwości ---
    property list<Notif> data: []
    property list<Notif> popups: data.filter(n => n.popup && !n.tracked)
    property list<Notif> history: data
    property bool enabled: true  // <- kontroluje wyświetlanie popupów

    // --- Funkcja toggle ---
    function toggle(): void {
        root.enabled = !root.enabled;

        // jeśli wyłączamy powiadomienia, chowamy wszystkie popupy
        if (!root.enabled) {
            for (const n of root.data) {
                n.popup = false;
            }
        }
    }

    // --- Serwer powiadomień ---
    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true;

            root.data.push(notifComp.createObject(root, {
                popup: root.enabled,  // <- tylko jeśli włączone
                notification: notif,
                shown: false
            }));
        }
    }

    // --- Funkcja do usuwania powiadomień ---
    function removeById(id) {
        const i = data.findIndex(n => n.notification.id === id);
        if (i >= 0) {
            data.splice(i, 1);
        }
    }

    // --- Komponent pojedynczego powiadomienia ---
    component Notif: QtObject {
        id: notif

        property bool popup
        readonly property date time: new Date()
        readonly property string timeStr: {
            const diff = Time.date.getTime() - time.getTime();
            const m = Math.floor(diff / 60000);
            const h = Math.floor(m / 60);

            if (h < 1 && m < 1)
                return "now";
            if (h < 1)
                return `${m}m`;
            return `${h}h`;
        }

        property bool shown: false
        required property Notification notification
        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string appIcon: (notification.appIcon !== undefined) ? String(notification.appIcon) : ""
        readonly property string appName: notification.appName
        readonly property string image: notification.image
        readonly property int urgency: notification.urgency
        readonly property list<NotificationAction> actions: notification.actions

        // --- Timer automatycznego chowania ---
        readonly property Timer timer: Timer {
            running: notif.actions.length >= 0 && root.enabled
            interval: notif.notification.expireTimeout > 0 ? notif.notification.expireTimeout : 5000
            onTriggered: {
                notif.popup = false;
            }
        }

        // --- Połączenia sygnałów z notyfikacji ---
        readonly property Connections conn: Connections {
            target: notif.notification.Retainable

            function onDropped(): void {
                root.data.splice(root.data.indexOf(notif), 1);
            }

            function onAboutToDestroy(): void {
                notif.destroy();
            }
        }

        readonly property Connections conn2: Connections {
            target: notif.notification

            function onClosed(reason) {
                root.data.splice(root.data.indexOf(notif), 1)
            }
        }

    }

    Component { id: notifComp; Notif {} }
}
