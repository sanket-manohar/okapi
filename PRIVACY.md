# Okapi Privacy Notice

**Version 1.0.0 · Effective 25 October 2026**
**Author: Sanket Santosh Vidya Manohar**

This notice describes what the Okapi software package itself does with data. It does **not** describe the apps that use Okapi; each app's own privacy policy applies to that app.

## 1. Summary

| Question | Answer |
|---|---|
| Does Okapi collect personal data? | **No.** |
| Does Okapi make network requests? | **No.** |
| Does Okapi contain analytics, ads or tracking? | **No.** |
| Does Okapi access photos, location, contacts, camera, etc.? | **No.** It only asks the operating system for the permission status and shows the system dialog. |
| Does Okapi share data with the Author or third parties? | **No.** |
| Does Okapi store anything? | Only small on-device flags, listed in section 2. |

## 2. On-device storage

To tell "never asked" apart from "permanently denied", Okapi keeps these flags **on the device only**. They never leave the device and are deleted when the app is uninstalled.

| Platform | Storage | Key | Contents |
|---|---|---|---|
| Android | SharedPreferences file `dev.okapi.permissions` | `asked` | Names of Android permissions that were requested and refused |
| iOS | UserDefaults | `dev.okapi.permissions.locationAlways` | `true` once the "Always" location prompt was shown |
| iOS | UserDefaults | `dev.okapi.permissions.criticalAlerts` | `true` once critical alerts were requested |
| Both | SharedPreferences `dev.okapi.store` / UserDefaults `dev.okapi.store` | `okapi.launches` | How many times the app was opened (for the ask policy) |
| Both | same | `okapi.policy.<name>.<event>` | Time of the last "Not now", refusal or declined Settings, per permission (for the ask policy) |
| Both | same | `okapi.granted` | Names of permissions that were allowed, to notice when one is removed |
| Android | same | `okapi.background.confirmed` | The user's answer "Yes, it's on" in the background guide |

These flags contain no personal data and no identifier of the user or device. The debug panel's "Clear Okapi storage" button and uninstalling the app remove them.

### Device facts read but not stored

To show the right phone-maker guide, Okapi reads the phone's maker, brand, model, OS version and the app's own name from the system. These are used on the device only and are not stored or sent anywhere.

### Android package visibility

Okapi's Android manifest lists a few system apps in `<queries>` (for example `com.miui.securitycenter`) so it can check whether a phone maker's autostart or battery screen exists before opening it. This reveals nothing about the user and gives no access to those apps' data.

## 3. Apple privacy manifest

Okapi ships a `PrivacyInfo.xcprivacy` declaring: no tracking, no tracking domains, no collected data types, and UserDefaults access for reason `CA92.1` (data accessible only to the app itself).

## 4. Google Play Data safety

Okapi does not collect or share any data, so it adds nothing to your app's Data safety form. Your app must still declare whatever **it** does with the data the granted permissions give it.

## 5. Developer tools

`dart run okapi:doctor` and `dart run okapi:sync` run on the developer's computer, read the app's source and platform files, and (Sync only) edit AndroidManifest.xml, Info.plist and the Podfile. They make no network requests and send nothing anywhere.

## 6. Observers and logs

`OkapiObserver` callbacks and `debugLogs` run only inside the host app. Okapi does not send them anywhere. If you forward them to an analytics service, you are responsible for that processing.

## 7. Website

The Okapi website uses no cookies, no analytics and no third-party trackers, and loads its fonts from the site itself. It stores your light/dark theme choice in your browser's local storage only. The hosting provider (for example Vercel) may keep standard server logs under its own privacy policy.

## 8. Contact

Questions: https://sanketmanohar.com/ or https://github.com/sanket-manohar/okapi/issues

See also DISCLAIMER.md and TERMS.md for the full allocation of responsibility.
