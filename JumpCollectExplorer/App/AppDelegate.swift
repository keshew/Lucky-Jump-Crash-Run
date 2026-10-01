import AdjustSdk
import AppTrackingTransparency
import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

extension Notification.Name {
    static let firebaseTokenReady = Notification.Name("firebaseTokenReady")
    static let adjustAttributionReady = Notification.Name("adjustAttributionReady")
    static let remotePushClicked = Notification.Name("remotePushClicked")
    static let remoteURLUpdated = Notification.Name("remoteURLUpdated")
}

enum LaunchDataStore {
    static let clientUUIDKey = "remoteClientUUID"
    static let serviceLinkKey = "remoteServiceLink"
    static let responseLinkKey = "remoteResponseLink"
    static let firebaseTokenKey = "fcmToken"
    static let firebaseGoogleAppIDKey = "firebaseGoogleAppID"
    static let pushIDKey = "lastPushId"
    static let pendingPushKey = "isFromPushPending"
    static let adjustAttributionKey = "lastAdjustAttribution"

    private static let adjustKeys = [
        "adjust_adid", "adjust_tracker_token", "adjust_tracker_name", "adjust_network",
        "adjust_campaign", "adjust_adgroup", "adjust_creative", "adjust_click_label",
        "adjust_cost_type", "adjust_cost_amount", "adjust_cost_currency"
    ]
    private(set) static var adjustReadyThisLaunch = false

    static var clientUUID: String {
        if let saved = UserDefaults.standard.string(forKey: clientUUIDKey), !saved.isEmpty {
            return saved
        }
        let value = UUID().uuidString.lowercased()
        UserDefaults.standard.set(value, forKey: clientUUIDKey)
        return value
    }

    static var firebaseToken: String? {
        nonEmpty(UserDefaults.standard.string(forKey: firebaseTokenKey))
    }

    static var adjustPayload: [String: String]? {
        var result: [String: String] = [:]
        for key in adjustKeys {
            guard let value = nonEmpty(UserDefaults.standard.string(forKey: key)) else { return nil }
            result[key] = value
        }
        if let json = nonEmpty(UserDefaults.standard.string(forKey: "adjust_json")) {
            result["adjust_json"] = json
        }
        return result
    }

    static var normalizedAdjustPayload: [String: String] {
        adjustPayload ?? Dictionary(uniqueKeysWithValues: adjustKeys.map { ($0, "null") })
    }

    static var allLaunchDataReady: Bool {
        firebaseToken != nil && adjustReadyThisLaunch && adjustPayload != nil
    }

    static func save(attribution: ADJAttribution, adid: String) {
        let fallback = "null"
        let values: [String: String] = [
            "adjust_adid": adid,
            "adjust_tracker_token": normalized(attribution.trackerToken, fallback: fallback),
            "adjust_tracker_name": normalized(attribution.trackerName, fallback: fallback),
            "adjust_network": normalized(attribution.network, fallback: fallback),
            "adjust_campaign": normalized(attribution.campaign, fallback: fallback),
            "adjust_adgroup": normalized(attribution.adgroup, fallback: fallback),
            "adjust_creative": normalized(attribution.creative, fallback: fallback),
            "adjust_click_label": normalized(attribution.clickLabel, fallback: fallback),
            "adjust_cost_type": normalized(attribution.costType, fallback: fallback),
            "adjust_cost_amount": attribution.costAmount?.stringValue ?? fallback,
            "adjust_cost_currency": normalized(attribution.costCurrency, fallback: fallback)
        ]
        values.forEach { UserDefaults.standard.set($0.value, forKey: $0.key) }
        adjustReadyThisLaunch = true

        if let jsonResponse = attribution.jsonResponse,
           JSONSerialization.isValidJSONObject(jsonResponse),
           let data = try? JSONSerialization.data(withJSONObject: jsonResponse, options: [.sortedKeys]),
           let json = String(data: data, encoding: .utf8), !json.isEmpty {
            UserDefaults.standard.set(json, forKey: "adjust_json")
            UserDefaults.standard.set(json, forKey: adjustAttributionKey)
        } else {
            UserDefaults.standard.set("{}", forKey: "adjust_json")
            UserDefaults.standard.set("{}", forKey: adjustAttributionKey)
        }
    }

    private static func normalized(_ value: String?, fallback: String) -> String {
        nonEmpty(value) ?? fallback
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, AdjustDelegate {
    private let adjustAppToken = "apjvi2blcq9s"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = LaunchDataStore.clientUUID
        configureFirebase()
        configureAdjust()

        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            savePushID(from: userInfo)
            UserDefaults.standard.set(true, forKey: LaunchDataStore.pendingPushKey)
        }
        return true
    }

    private func configureAdjust() {
        let environment = ADJEnvironmentProduction
        guard let config = ADJConfig(appToken: adjustAppToken, environment: environment) else { return }
        config.delegate = self
        config.enableCostDataInAttribution()
        config.logLevel = .info
        Adjust.initSdk(config)

        Adjust.attribution { [weak self] attribution in
            self?.adjustAttributionChanged(attribution)
        }
    }

    private func configureFirebase() {
        FirebaseApp.configure()
        if let googleAppID = FirebaseApp.app()?.options.googleAppID,
           UserDefaults.standard.string(forKey: LaunchDataStore.firebaseGoogleAppIDKey) != googleAppID {
            UserDefaults.standard.removeObject(forKey: LaunchDataStore.firebaseTokenKey)
            UserDefaults.standard.set(googleAppID, forKey: LaunchDataStore.firebaseGoogleAppIDKey)
        }
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
    }

    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution else { return }
        if #available(iOS 14, *),
           ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            return
        }
        persistCompleteAttribution(attribution)
    }

    private func persistCompleteAttribution(_ attribution: ADJAttribution, attempt: Int = 0) {
        Adjust.adid { [weak self] adid in
            guard let self else { return }
            guard let adid = adid?.trimmingCharacters(in: .whitespacesAndNewlines), !adid.isEmpty else {
                guard attempt < 15 else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.persistCompleteAttribution(attribution, attempt: attempt + 1)
                }
                return
            }
            LaunchDataStore.save(attribution: attribution, adid: adid)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .adjustAttributionReady, object: nil)
            }
        }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        storeFirebaseToken(fcmToken)
    }

    private func storeFirebaseToken(_ fcmToken: String?) {
        guard let token = fcmToken?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else { return }
        UserDefaults.standard.set(token, forKey: LaunchDataStore.firebaseTokenKey)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .firebaseTokenReady, object: nil)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { [weak self] token, error in
            if let error {
                print("FCM token after APNS failed:", error.localizedDescription)
                return
            }
            self?.storeFirebaseToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNS registration failed:", error.localizedDescription)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        savePushID(from: userInfo)
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Messaging.messaging().appDidReceiveMessage(userInfo)
        savePushID(from: userInfo)
        UserDefaults.standard.set(true, forKey: LaunchDataStore.pendingPushKey)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .remotePushClicked, object: nil)
        }
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        savePushID(from: userInfo)
        UserDefaults.standard.set(true, forKey: LaunchDataStore.pendingPushKey)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .remotePushClicked, object: nil)
        }
        completionHandler(.newData)
    }

    private func savePushID(from userInfo: [AnyHashable: Any]) {
        if let pushID = extractPushID(from: userInfo) {
            UserDefaults.standard.set(pushID, forKey: LaunchDataStore.pushIDKey)
        }
    }

    private func extractPushID(from object: Any) -> String? {
        if let dictionary = object as? [AnyHashable: Any] {
            for key in ["push_id", "gcm.notification.push_id"] {
                if let value = dictionary[key] {
                    let text = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty { return text }
                }
            }
            for key in ["push_data", "data"] {
                if let nested = dictionary[key], let value = extractPushID(from: nested) { return value }
            }
        } else if let dictionary = object as? [String: Any] {
            return extractPushID(from: Dictionary(uniqueKeysWithValues: dictionary.map { (AnyHashable($0.key), $0.value) }))
        } else if let text = object as? String,
                  let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) {
            return extractPushID(from: json)
        }
        return nil
    }
}
