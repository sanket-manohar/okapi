// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import UIKit

// MARK: - Camera & microphone

#if !OKAPI_EXCLUDE_CAMERA || !OKAPI_EXCLUDE_MICROPHONE
import AVFoundation

final class CaptureHandler: OkapiHandler {
    private func media(_ p: String) -> AVMediaType { p == "camera" ? .video : .audio }

    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: media(p)) {
        case .authorized: done(OkapiCode.granted)
        case .denied: done(OkapiCode.permanentlyDenied)
        case .restricted: done(OkapiCode.restricted)
        case .notDetermined: done(OkapiCode.denied)
        @unknown default: done(OkapiCode.denied)
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        AVCaptureDevice.requestAccess(for: media(p)) { _ in self.status(p, done) }
    }
}
#endif

// MARK: - Photos

#if !OKAPI_EXCLUDE_PHOTOS
import Photos

final class PhotosHandler: OkapiHandler {
    private func map(_ s: PHAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return OkapiCode.granted
        case .limited: return OkapiCode.limited
        case .denied: return OkapiCode.permanentlyDenied
        case .restricted: return OkapiCode.restricted
        case .notDetermined: return OkapiCode.denied
        @unknown default: return OkapiCode.denied
        }
    }

    @available(iOS 14, *)
    private func level(_ p: String) -> PHAccessLevel { p == "photosAddOnly" ? .addOnly : .readWrite }

    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        if #available(iOS 14, *) {
            done(map(PHPhotoLibrary.authorizationStatus(for: level(p))))
        } else {
            done(map(PHPhotoLibrary.authorizationStatus()))
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: level(p)) { done(self.map($0)) }
        } else {
            PHPhotoLibrary.requestAuthorization { done(self.map($0)) }
        }
    }
}
#endif

// MARK: - Location

#if !OKAPI_EXCLUDE_LOCATION
import CoreLocation

final class LocationHandler: NSObject, OkapiHandler, CLLocationManagerDelegate {
    private lazy var manager: CLLocationManager = {
        let m = CLLocationManager()
        m.delegate = self
        return m
    }()
    private var pending: ((Int) -> Void)?
    private var pendingPermission = ""
    private var resignToken: NSObjectProtocol?
    private var activeToken: NSObjectProtocol?

    private var auth: CLAuthorizationStatus {
        if #available(iOS 14, *) { return manager.authorizationStatus }
        return CLLocationManager.authorizationStatus()
    }

    private var reduced: Bool {
        if #available(iOS 14, *) { return manager.accuracyAuthorization == .reducedAccuracy }
        return false
    }

    private func code(for p: String) -> Int {
        let always = p == "locationAlways"
        switch auth {
        case .notDetermined: return OkapiCode.denied
        case .restricted: return OkapiCode.restricted
        case .denied: return OkapiCode.permanentlyDenied
        case .authorizedAlways: return reduced ? OkapiCode.limited : OkapiCode.granted
        case .authorizedWhenInUse:
            if always {
                // iOS shows the "Change to Always" prompt only once.
                return OkapiDefaults.asked("locationAlways")
                    ? OkapiCode.permanentlyDenied : OkapiCode.denied
            }
            return reduced ? OkapiCode.limited : OkapiCode.granted
        @unknown default: return OkapiCode.denied
        }
    }

    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        DispatchQueue.main.async { done(self.code(for: p)) }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        DispatchQueue.main.async {
            let always = p == "locationAlways"
            let current = self.auth
            if current == .denied || current == .restricted || current == .authorizedAlways {
                done(self.code(for: p))
                return
            }
            self.pending = done
            self.pendingPermission = p
            if current == .notDetermined {
                if always {
                    OkapiDefaults.setAsked("locationAlways")
                    self.manager.requestAlwaysAuthorization()
                } else {
                    self.manager.requestWhenInUseAuthorization()
                }
                return
            }
            // When-in-use -> Always upgrade. If the user keeps "While Using",
            // iOS sends no callback, so resolve when the app is active again.
            if always && !OkapiDefaults.asked("locationAlways") {
                OkapiDefaults.setAsked("locationAlways")
                self.watchForSilentAnswer()
                self.manager.requestAlwaysAuthorization()
            } else {
                self.finish()
            }
        }
    }

    private func watchForSilentAnswer() {
        var promptShown = false
        resignToken = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
        ) { _ in promptShown = true }
        activeToken = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self?.finish() }
        }
        // No prompt at all (already asked on this device): resolve quickly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            if !promptShown { self?.finish() }
        }
    }

    private func finish() {
        [resignToken, activeToken].compactMap { $0 }.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        resignToken = nil
        activeToken = nil
        guard let done = pending else { return }
        pending = nil
        done(code(for: pendingPermission))
    }

    private func authorizationChanged() {
        // Ignore the callback iOS sends when the manager is first created.
        if auth == .notDetermined { return }
        finish()
    }

    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationChanged()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        if #available(iOS 14, *) { return } // Handled above.
        authorizationChanged()
    }

    func serviceEnabled(_ done: @escaping (Bool) -> Void) {
        // Apple warns against calling this on the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            let on = CLLocationManager.locationServicesEnabled()
            DispatchQueue.main.async { done(on) }
        }
    }
}
#endif

// MARK: - Notifications

#if !OKAPI_EXCLUDE_NOTIFICATIONS
import UserNotifications

final class NotificationHandler: OkapiHandler {
    private let center = UNUserNotificationCenter.current()

    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        center.getNotificationSettings { s in
            if p == "criticalAlerts" {
                switch s.criticalAlertSetting {
                case .enabled: done(OkapiCode.granted)
                case .notSupported: done(OkapiCode.restricted) // Missing entitlement.
                default:
                    done(OkapiDefaults.asked("criticalAlerts")
                         ? OkapiCode.permanentlyDenied : OkapiCode.denied)
                }
                return
            }
            switch s.authorizationStatus {
            case .authorized: done(OkapiCode.granted)
            case .provisional: done(OkapiCode.provisional)
            case .ephemeral: done(OkapiCode.limited)
            case .denied: done(OkapiCode.permanentlyDenied)
            case .notDetermined: done(OkapiCode.denied)
            @unknown default: done(OkapiCode.denied)
            }
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        var opts: UNAuthorizationOptions = [.alert, .badge, .sound]
        if p == "criticalAlerts" {
            opts.insert(.criticalAlert)
            OkapiDefaults.setAsked("criticalAlerts")
        }
        if options["provisional"] as? Bool == true { opts.insert(.provisional) }
        center.requestAuthorization(options: opts) { _, _ in self.status(p, done) }
    }
}
#endif

// MARK: - Contacts

#if !OKAPI_EXCLUDE_CONTACTS
import Contacts

final class ContactsHandler: OkapiHandler {
    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        let s = CNContactStore.authorizationStatus(for: .contacts)
        if #available(iOS 18, *), s == .limited {
            done(OkapiCode.limited)
            return
        }
        switch s {
        case .authorized: done(OkapiCode.granted)
        case .denied: done(OkapiCode.permanentlyDenied)
        case .restricted: done(OkapiCode.restricted)
        case .notDetermined: done(OkapiCode.denied)
        @unknown default: done(OkapiCode.denied)
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        CNContactStore().requestAccess(for: .contacts) { _, _ in self.status(p, done) }
    }
}
#endif

// MARK: - Calendar & reminders

#if !OKAPI_EXCLUDE_CALENDAR
import EventKit

final class EventsHandler: OkapiHandler {
    private let store = EKEventStore()

    private func entity(_ p: String) -> EKEntityType { p == "reminders" ? .reminder : .event }

    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        let s = EKEventStore.authorizationStatus(for: entity(p))
        if #available(iOS 17, *) {
            switch s {
            case .fullAccess: done(OkapiCode.granted); return
            case .writeOnly:
                done(p == "calendarWriteOnly" ? OkapiCode.granted : OkapiCode.limited)
                return
            default: break
            }
        }
        switch s {
        case .denied: done(OkapiCode.permanentlyDenied)
        case .restricted: done(OkapiCode.restricted)
        case .notDetermined: done(OkapiCode.denied)
        default:
            // `.authorized` on iOS 16 and below.
            done(OkapiCode.granted)
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        let finish: (Bool, Error?) -> Void = { _, _ in self.status(p, done) }
        if #available(iOS 17, *) {
            switch p {
            case "calendarWriteOnly": store.requestWriteOnlyAccessToEvents(completion: finish)
            case "reminders": store.requestFullAccessToReminders(completion: finish)
            default: store.requestFullAccessToEvents(completion: finish)
            }
        } else {
            store.requestAccess(to: entity(p), completion: finish)
        }
    }
}
#endif

// MARK: - Speech

#if !OKAPI_EXCLUDE_SPEECH
import Speech

final class SpeechHandler: OkapiHandler {
    private func map(_ s: SFSpeechRecognizerAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return OkapiCode.granted
        case .denied: return OkapiCode.permanentlyDenied
        case .restricted: return OkapiCode.restricted
        case .notDetermined: return OkapiCode.denied
        @unknown default: return OkapiCode.denied
        }
    }

    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        done(map(SFSpeechRecognizer.authorizationStatus()))
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        SFSpeechRecognizer.requestAuthorization { done(self.map($0)) }
    }
}
#endif

// MARK: - Media library

#if !OKAPI_EXCLUDE_MEDIA_LIBRARY
import MediaPlayer

final class MediaLibraryHandler: OkapiHandler {
    private func map(_ s: MPMediaLibraryAuthorizationStatus) -> Int {
        switch s {
        case .authorized: return OkapiCode.granted
        case .denied: return OkapiCode.permanentlyDenied
        case .restricted: return OkapiCode.restricted
        case .notDetermined: return OkapiCode.denied
        @unknown default: return OkapiCode.denied
        }
    }

    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        done(map(MPMediaLibrary.authorizationStatus()))
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        MPMediaLibrary.requestAuthorization { done(self.map($0)) }
    }
}
#endif

// MARK: - App Tracking Transparency

#if !OKAPI_EXCLUDE_TRACKING
import AppTrackingTransparency

final class TrackingHandler: OkapiHandler {
    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        guard #available(iOS 14, *) else {
            done(OkapiCode.granted)
            return
        }
        done(map(ATTrackingManager.trackingAuthorizationStatus))
    }

    @available(iOS 14, *)
    private func map(_ s: ATTrackingManager.AuthorizationStatus) -> Int {
        switch s {
        case .authorized: return OkapiCode.granted
        case .denied: return OkapiCode.permanentlyDenied
        case .restricted: return OkapiCode.restricted
        case .notDetermined: return OkapiCode.denied
        @unknown default: return OkapiCode.denied
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        guard #available(iOS 14, *) else {
            done(OkapiCode.granted)
            return
        }
        // The ATT prompt silently fails unless the app is active.
        okapiWhenActive {
            ATTrackingManager.requestTrackingAuthorization { s in done(self.map(s)) }
        }
    }
}
#endif

// MARK: - Motion & fitness

#if !OKAPI_EXCLUDE_SENSORS
import CoreMotion

final class MotionHandler: OkapiHandler {
    private var manager: CMMotionActivityManager?

    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        guard CMMotionActivityManager.isActivityAvailable() else {
            done(OkapiCode.restricted) // No motion hardware.
            return
        }
        switch CMMotionActivityManager.authorizationStatus() {
        case .authorized: done(OkapiCode.granted)
        case .denied: done(OkapiCode.permanentlyDenied)
        case .restricted: done(OkapiCode.restricted)
        case .notDetermined: done(OkapiCode.denied)
        @unknown default: done(OkapiCode.denied)
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        let m = CMMotionActivityManager()
        manager = m
        // Querying is the only way to trigger the motion prompt.
        m.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, _ in
            self.manager = nil
            self.status(p, done)
        }
    }
}
#endif

// MARK: - Bluetooth

#if !OKAPI_EXCLUDE_BLUETOOTH
import CoreBluetooth

final class BluetoothHandler: NSObject, OkapiHandler, CBCentralManagerDelegate {
    private var central: CBCentralManager?
    private var waiting: [() -> Void] = []

    private func code() -> Int {
        guard #available(iOS 13.1, *) else { return OkapiCode.granted }
        switch CBManager.authorization {
        case .allowedAlways: return OkapiCode.granted
        case .denied: return OkapiCode.permanentlyDenied
        case .restricted: return OkapiCode.restricted
        case .notDetermined: return OkapiCode.denied
        @unknown default: return OkapiCode.denied
        }
    }

    func status(_ p: String, _ done: @escaping (Int) -> Void) { done(code()) }

    private func withCentral(_ then: @escaping () -> Void) {
        DispatchQueue.main.async {
            if let c = self.central, c.state != .unknown, c.state != .resetting {
                then()
                return
            }
            self.waiting.append(then)
            if self.central == nil {
                // Creating a manager triggers the permission prompt.
                self.central = CBCentralManager(
                    delegate: self,
                    queue: nil,
                    options: [CBCentralManagerOptionShowPowerAlertKey: false]
                )
            }
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        withCentral { done(self.code()) }
    }

    /// 1 = on, 0 = off, 2 = unknown (not authorised yet, or no hardware).
    func serviceStatus(_ done: @escaping (Int) -> Void) {
        guard code() == OkapiCode.granted else {
            done(2)
            return
        }
        withCentral {
            switch self.central?.state {
            case .poweredOn: done(1)
            case .poweredOff: done(0)
            default: done(2)
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .unknown || central.state == .resetting { return }
        let callbacks = waiting
        waiting.removeAll()
        callbacks.forEach { $0() }
    }
}
#endif

// MARK: - Background App Refresh (read-only)

final class BackgroundRefreshHandler: OkapiHandler {
    func status(_ p: String, _ done: @escaping (Int) -> Void) {
        DispatchQueue.main.async {
            switch UIApplication.shared.backgroundRefreshStatus {
            case .available: done(OkapiCode.granted)
            case .denied: done(OkapiCode.permanentlyDenied)
            case .restricted: done(OkapiCode.restricted)
            @unknown default: done(OkapiCode.denied)
            }
        }
    }

    func request(_ p: String, options: [String: Any], _ done: @escaping (Int) -> Void) {
        status(p, done) // Apps cannot request it.
    }
}
