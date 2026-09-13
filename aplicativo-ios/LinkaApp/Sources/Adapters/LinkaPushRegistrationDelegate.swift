import Foundation
import UserNotifications

enum LinkaStatusPushInbox {
    static let incidentIDKey = "linka.serviceStatus.pendingIncidentID"

    static func store(_ userInfo: [AnyHashable: Any]) {
        guard let id = userInfo["incident_id"] as? String, !id.isEmpty else { return }
        UserDefaults.standard.set(id, forKey: incidentIDKey)
        NotificationCenter.default.post(name: .linkaDidReceiveStatusIncident, object: id)
    }
}

extension Notification.Name {
    static let linkaDidRegisterPushToken = Notification.Name("linka.didRegisterPushToken")
    static let linkaDidFailPushRegistration = Notification.Name("linka.didFailPushRegistration")
    static let linkaDidReceiveStatusIncident = Notification.Name("linka.didReceiveStatusIncident")
}

#if os(iOS)
import UIKit

final class LinkaPushRegistrationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] { LinkaStatusPushInbox.store(userInfo) }
        return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .linkaDidRegisterPushToken, object: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .linkaDidFailPushRegistration, object: error)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        LinkaStatusPushInbox.store(notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        LinkaStatusPushInbox.store(response.notification.request.content.userInfo)
        completionHandler()
    }
}
#elseif os(macOS)
import AppKit

final class LinkaPushRegistrationDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationCenter.default.post(name: .linkaDidRegisterPushToken, object: deviceToken)
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationCenter.default.post(name: .linkaDidFailPushRegistration, object: error)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        LinkaStatusPushInbox.store(notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        LinkaStatusPushInbox.store(response.notification.request.content.userInfo)
        completionHandler()
    }
}
#endif
