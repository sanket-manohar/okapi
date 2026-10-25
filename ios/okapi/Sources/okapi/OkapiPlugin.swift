// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit

/// Status codes shared with Dart (see OkapiStatus.fromCode).
enum OkapiCode {
    static let denied = 0
    static let granted = 1
    static let restricted = 2
    static let limited = 3
    static let permanentlyDenied = 4
    static let provisional = 5
    static let notApplicable = 6
}

/// One family of permissions (camera, location...).
protocol OkapiHandler: AnyObject {
    func status(_ permission: String, _ done: @escaping (Int) -> Void)
    func request(_ permission: String, options: [String: Any], _ done: @escaping (Int) -> Void)
}

/// Okapi iOS plugin.
///
/// Every permission family is compiled in by default. To keep Apple from
/// asking about APIs you don't use, exclude families in your Podfile, for
/// example `OKAPI_EXCLUDE_CONTACTS` (see README "App Store tips").
public class OkapiPlugin: NSObject, FlutterPlugin {
    private var handlers: [String: OkapiHandler] = [:]
    #if !OKAPI_EXCLUDE_LOCATION
    private let location = LocationHandler()
    #endif
    #if !OKAPI_EXCLUDE_BLUETOOTH
    private let bluetooth = BluetoothHandler()
    #endif

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "dev.okapi/permissions",
            binaryMessenger: registrar.messenger()
        )
        let instance = OkapiPlugin()
        instance.buildHandlers()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    private func buildHandlers() {
        #if !OKAPI_EXCLUDE_CAMERA
        handlers["camera"] = CaptureHandler()
        #endif
        #if !OKAPI_EXCLUDE_MICROPHONE
        handlers["microphone"] = CaptureHandler()
        #endif
        #if !OKAPI_EXCLUDE_PHOTOS
        let photos = PhotosHandler()
        handlers["photos"] = photos
        handlers["videos"] = photos
        handlers["photosAddOnly"] = photos
        #endif
        #if !OKAPI_EXCLUDE_LOCATION
        handlers["location"] = location
        handlers["locationWhenInUse"] = location
        handlers["locationAlways"] = location
        #endif
        #if !OKAPI_EXCLUDE_NOTIFICATIONS
        let notifications = NotificationHandler()
        handlers["notification"] = notifications
        handlers["criticalAlerts"] = notifications
        #endif
        #if !OKAPI_EXCLUDE_CONTACTS
        handlers["contacts"] = ContactsHandler()
        #endif
        #if !OKAPI_EXCLUDE_CALENDAR
        let events = EventsHandler()
        handlers["calendarFullAccess"] = events
        handlers["calendarWriteOnly"] = events
        handlers["reminders"] = events
        #endif
        #if !OKAPI_EXCLUDE_SPEECH
        handlers["speech"] = SpeechHandler()
        #endif
        #if !OKAPI_EXCLUDE_MEDIA_LIBRARY
        handlers["mediaLibrary"] = MediaLibraryHandler()
        #endif
        #if !OKAPI_EXCLUDE_TRACKING
        handlers["appTrackingTransparency"] = TrackingHandler()
        #endif
        #if !OKAPI_EXCLUDE_SENSORS
        let motion = MotionHandler()
        handlers["sensors"] = motion
        handlers["activityRecognition"] = motion
        #endif
        #if !OKAPI_EXCLUDE_BLUETOOTH
        handlers["bluetooth"] = bluetooth
        handlers["bluetoothScan"] = bluetooth
        handlers["bluetoothConnect"] = bluetooth
        handlers["bluetoothAdvertise"] = bluetooth
        #endif
        handlers["backgroundRefresh"] = BackgroundRefreshHandler()
    }

    // MARK: - Info.plist

    /// Info.plist keys each permission needs (any one listed is enough when
    /// alternatives are given for older iOS versions).
    private func usageKeys(_ permission: String) -> [String] {
        switch permission {
        case "camera": return ["NSCameraUsageDescription"]
        case "microphone": return ["NSMicrophoneUsageDescription"]
        case "speech": return ["NSSpeechRecognitionUsageDescription"]
        case "photos", "videos": return ["NSPhotoLibraryUsageDescription"]
        case "photosAddOnly": return ["NSPhotoLibraryAddUsageDescription"]
        case "mediaLibrary": return ["NSAppleMusicUsageDescription"]
        case "location", "locationWhenInUse": return ["NSLocationWhenInUseUsageDescription"]
        case "locationAlways": return ["NSLocationAlwaysAndWhenInUseUsageDescription"]
        case "contacts": return ["NSContactsUsageDescription"]
        case "calendarFullAccess":
            if #available(iOS 17, *) { return ["NSCalendarsFullAccessUsageDescription"] }
            return ["NSCalendarsUsageDescription"]
        case "calendarWriteOnly":
            if #available(iOS 17, *) {
                return ["NSCalendarsWriteOnlyAccessUsageDescription",
                        "NSCalendarsFullAccessUsageDescription"]
            }
            return ["NSCalendarsUsageDescription"]
        case "reminders":
            if #available(iOS 17, *) { return ["NSRemindersFullAccessUsageDescription"] }
            return ["NSRemindersUsageDescription"]
        case "sensors", "activityRecognition": return ["NSMotionUsageDescription"]
        case "bluetooth", "bluetoothScan", "bluetoothConnect", "bluetoothAdvertise":
            return ["NSBluetoothAlwaysUsageDescription"]
        case "appTrackingTransparency": return ["NSUserTrackingUsageDescription"]
        default: return []
        }
    }

    private func isDeclared(_ permission: String) -> Bool {
        let keys = usageKeys(permission)
        if keys.isEmpty { return true }
        let info = Bundle.main.infoDictionary ?? [:]
        let ok = keys.contains { info[$0] != nil }
        if permission == "locationAlways" {
            return ok && info["NSLocationWhenInUseUsageDescription"] != nil
        }
        return ok
    }

    // MARK: - Method channel

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkStatus":
            let p = call.arguments as? String ?? ""
            status(p) { result($0) }

        case "request":
            let args = call.arguments as? [String: Any] ?? [:]
            let permissions = args["permissions"] as? [String] ?? []
            let options = args["options"] as? [String: Any] ?? [:]
            if let missing = permissions.first(where: { !isDeclared($0) }) {
                let keys = usageKeys(missing).joined(separator: " or ")
                result(FlutterError(
                    code: "not_declared",
                    message: "Okapi: \"\(missing)\" needs \(keys) in ios/Runner/Info.plist. "
                        + "Without it iOS would crash your app.",
                    details: ["permission": missing]))
                return
            }
            requestAll(permissions, options: options, collected: [:]) { result($0) }

        case "shouldShowRationale":
            result(false)

        case "checkServiceStatus":
            let p = call.arguments as? String ?? ""
            serviceStatus(p) { result($0) }

        case "openAppSettings", "openServiceSettings":
            // iOS does not allow apps to open the Location or Bluetooth pages
            // directly, so both go to this app's Settings page.
            openSettings { result($0) }

        case "isDeclared":
            result(isDeclared(call.arguments as? String ?? ""))

        case "loadStore":
            result(OkapiStore.load())

        case "writeStore":
            let args = call.arguments as? [String: Any] ?? [:]
            if let key = args["key"] as? String {
                OkapiStore.write(key, args["value"] as? String)
            }
            result(nil)

        case "deviceInfo":
            result(OkapiDevice.info())

        case "availableOemScreens":
            result([String]())   // Android only.

        case "openOemScreen", "openAutoResetSettings":
            result(false)        // Android only.

        case "autoResetStatus":
            result(0)            // Not available on iOS.

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func status(_ permission: String, _ done: @escaping (Int) -> Void) {
        guard let h = handlers[permission] else {
            done(OkapiCode.notApplicable)
            return
        }
        h.status(permission) { code in DispatchQueue.main.async { done(code) } }
    }

    private func requestAll(
        _ remaining: [String],
        options: [String: Any],
        collected: [String: Int],
        _ done: @escaping ([String: Int]) -> Void
    ) {
        guard let p = remaining.first else {
            done(collected)
            return
        }
        let rest = Array(remaining.dropFirst())
        let next: (Int) -> Void = { code in
            var c = collected
            c[p] = code
            DispatchQueue.main.async {
                self.requestAll(rest, options: options, collected: c, done)
            }
        }
        guard let h = handlers[p] else {
            next(OkapiCode.notApplicable)
            return
        }
        h.status(p) { current in
            DispatchQueue.main.async {
                if current == OkapiCode.granted || current == OkapiCode.notApplicable
                    || current == OkapiCode.restricted {
                    next(current)
                } else {
                    h.request(p, options: options, next)
                }
            }
        }
    }

    private func serviceStatus(_ permission: String, _ done: @escaping (Int) -> Void) {
        if permission.hasPrefix("location") {
            #if !OKAPI_EXCLUDE_LOCATION
            location.serviceEnabled { done($0 ? 1 : 0) }
            #else
            done(2)
            #endif
        } else if permission.hasPrefix("bluetooth") {
            #if !OKAPI_EXCLUDE_BLUETOOTH
            bluetooth.serviceStatus(done)
            #else
            done(2)
            #endif
        } else {
            done(2)
        }
    }

    private func openSettings(_ done: @escaping (Bool) -> Void) {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            done(false)
            return
        }
        UIApplication.shared.open(url, options: [:]) { done($0) }
    }
}

// MARK: - Small helpers shared by handlers

enum OkapiDefaults {
    private static let prefix = "dev.okapi.permissions."

    static func asked(_ key: String) -> Bool {
        UserDefaults.standard.bool(forKey: prefix + key)
    }

    static func setAsked(_ key: String) {
        UserDefaults.standard.set(true, forKey: prefix + key)
    }
}

/// Runs [action] once the app is active (system prompts silently fail while
/// the app is launching or in the background).
func okapiWhenActive(_ action: @escaping () -> Void) {
    DispatchQueue.main.async {
        if UIApplication.shared.applicationState == .active {
            action()
            return
        }
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            if let t = token { NotificationCenter.default.removeObserver(t) }
            token = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: action)
        }
    }
}

// MARK: - On-device store

/// Okapi's small key-value store (timestamps, counters, flags) in
/// UserDefaults. Declared in the privacy manifest (reason CA92.1).
enum OkapiStore {
    private static let key = "dev.okapi.store"

    static func load() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    static func write(_ name: String, _ value: String?) {
        var all = load()
        all[name] = value
        UserDefaults.standard.set(all, forKey: key)
    }
}

// MARK: - Device info

enum OkapiDevice {
    static func info() -> [String: Any] {
        var system = utsname()
        uname(&system)
        let machine = withUnsafeBytes(of: &system.machine) { raw -> String in
            let bytes = raw.prefix { $0 != 0 }
            return String(decoding: bytes, as: UTF8.self)
        }
        let bundle = Bundle.main
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? ""
        return [
            "platform": "ios",
            "manufacturer": "Apple",
            "brand": "Apple",
            "model": machine.isEmpty ? UIDevice.current.model : machine,
            "osVersion": UIDevice.current.systemVersion,
            "sdkInt": 0,
            "appName": name,
        ]
    }
}
