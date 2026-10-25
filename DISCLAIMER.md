# Okapi — Legal Disclaimer, Acceptable Use and Limitation of Liability

**Version 1.0.0 · Effective 25 October 2026**
**Author and owner: Sanket Santosh Vidya Manohar ("the Author")**

> **Read this document carefully.** By downloading, installing, integrating, compiling, distributing or otherwise using Okapi, you confirm that you have read, understood and accepted this Disclaimer together with the LICENSE, TERMS.md, PRIVACY.md and TRADEMARKS.md. If you do not accept them, do not use Okapi.

---

## 1. Definitions

- **1.1 "Okapi" or "the Package"** means the Okapi software package, including its Dart, Kotlin and Swift code, prebuilt user interface, command-line tools, example code, documentation, website and every version, update or copy of them.
- **1.2 "Integrator" or "you"** means any person or entity that incorporates the Package into, or uses it with, any software, together with that person's employer, client and affiliates where applicable.
- **1.3 "Host Application"** means any application, product or service in which the Package is included or used.
- **1.4 "End User"** means any person who installs or uses a Host Application.
- **1.5 "Device Permission"** means any operating-system permission, authorisation or special access, including camera, microphone, location, contacts, photos, media, storage, notifications, calendar, phone, SMS, sensors, Bluetooth, nearby devices, tracking, battery, overlay, alarms, installation of packages and any similar access.
- **1.6 "Protected Data"** means any data, signal, content or functionality that a Device Permission controls access to, including personal data and sensitive personal data as defined by any applicable law.
- **1.7 "Security Incident"** means any data breach, data leak, unauthorised access, acquisition, use, disclosure, alteration, loss or destruction of Protected Data or of any other data, however caused.

## 2. A development tool, not a decision-maker

- **2.1 Nature of the Package.** Okapi is strictly a software development package. It provides technical building blocks that let a developer (a) read the current state of a Device Permission from the operating system, (b) ask the operating system to show its own permission dialog, (c) open system and device-manufacturer settings screens, (d) show explanatory screens whose content the Integrator controls, (e) keep small technical records on the device to apply rules the Integrator chooses, and (f) check and edit the Integrator's project files through developer tools.
- **2.2 Okapi makes no decisions.** Okapi does not decide, recommend, approve or validate whether, when, why, how often or for what purpose any Device Permission should be requested, granted, used or retained. Every request is initiated solely by code written, configured or deployed by the Integrator. Default texts, examples, presets, suggestions and the output of Okapi Doctor and Okapi Sync are illustrations only; they are not advice and not a decision.
- **2.3 Okapi never touches Protected Data.** Okapi does not open the camera or microphone, read locations, contacts, photos, messages, call logs, calendars, health or sensor data, files or any other Protected Data. Granting a Device Permission only changes what the **Host Application** may do. What the Host Application then does with that access is entirely outside Okapi.
- **2.4 No collection or transmission.** Okapi makes no network requests, contains no analytics, advertising or tracking code, and sends no data to the Author or to any third party (see PRIVACY.md).
- **2.5 Not a compliance, legal or security product.** Okapi does not make any Host Application lawful, compliant, secure, approved or safe, and nothing in the Package, its documentation or its website is legal, regulatory, privacy, security or professional advice.

## 3. No responsibility for permissions or data

- **3.1 Permissions.** The Author is **not responsible and shall not be liable** for any Device Permission that is requested, granted, denied, revoked or used through, with the help of, or in connection with the Package, or for any consequence of such request, grant, denial, revocation or use.
- **3.2 Data and Security Incidents.** The Author is **not responsible and shall not be liable** for any Security Incident, or for any collection, processing, storage, sharing, sale, transfer, retention, misuse or loss of Protected Data or any other data, by any Host Application, any Integrator, any End User, any third-party service or any other person, including where the Security Incident relates to data that a Host Application could access because a Device Permission was granted.
- **3.3 No data role.** The Author is not a data controller, data processor, data fiduciary, significant data fiduciary, consent manager, service provider, contractor, business associate, sub-processor or any equivalent role under any law, including the Digital Personal Data Protection Act, 2023 (India) and its rules, the Information Technology Act, 2000 (India) and its rules, the EU and UK General Data Protection Regulation, the California Consumer Privacy Act as amended, the Children's Online Privacy Protection Act, HIPAA and any similar law anywhere ("Privacy Laws").
- **3.4 No access, no control.** The Author has no access to, control over or knowledge of any Host Application, End User or Protected Data, and cannot prevent, detect, investigate, notify or remedy any Security Incident.

## 4. The Integrator's sole responsibility

The Integrator alone is responsible and liable for, and the Author bears no responsibility for:

- **4.1** every decision to request a Device Permission, and its purpose, necessity, timing and proportionality;
- **4.2** obtaining every valid consent, giving every notice, honouring every withdrawal and every End-User right, and publishing an accurate privacy policy, as required by Privacy Laws;
- **4.3** the truthfulness and accuracy of every text shown to End Users, including rationale messages, Info.plist usage descriptions, Android explanations and any text passed to or customising Okapi's screens; Okapi's default texts must be reviewed and replaced where they do not accurately describe the Host Application;
- **4.4** the security of the Host Application and of all data it handles, including encryption, access control, secure storage, breach detection, breach notification to authorities and affected persons, and incident response;
- **4.5** compliance with Google Play policies (including User Data, Permissions, SMS and Call Log, All Files Access, Background Location, Photo and Video, Health, Families and Battery Optimisation policies), Apple's App Store Review Guidelines (including Guideline 5.1 and App Tracking Transparency) and the rules of any other store or platform;
- **4.6** all declarations in AndroidManifest.xml, Info.plist, privacy manifests, store "Data safety" and "App Privacy" forms, and any approvals a store requires;
- **4.7** additional obligations for children, students, patients, employees and other protected groups;
- **4.8** reviewing, testing and approving every change made by Okapi Sync, and testing the Host Application on every device, manufacturer and OS version it supports before release.

## 5. Acceptable use and misuse

- **5.1** You must not use Okapi, directly or through a Host Application, to:
  - (a) monitor, track, record, photograph, locate or surveil any person without that person's informed, freely given consent, or to stalk, harass, intimidate or harm anyone;
  - (b) build or distribute spyware, stalkerware, malware or any software that hides its purpose or presence;
  - (c) obtain a Device Permission through false, misleading or manipulative explanations, deceptive interface designs ("dark patterns"), or by pretending a permission is required when it is not;
  - (d) circumvent, disable or interfere with operating-system security or privacy controls;
  - (e) collect, use, sell or share Protected Data in breach of any law, contract, store policy or the End User's reasonable expectations; or
  - (f) commit, facilitate or promote any unlawful act.
- **5.2 Sole liability for misuse.** Any person who uses Okapi to request or obtain any Device Permission is solely responsible and liable for that request and for every use made of the access obtained, including any misuse described in clause 5.1. The Author is not responsible or liable in any way for any Device Permission requested through Okapi, or for any use or misuse of any feature, data or access obtained.
- **5.3** The Author may, without liability, publicly disassociate from, and report to stores, registries or authorities, any use the Author reasonably believes breaches this clause 5.

## 6. No warranty; no guarantee of results

- **6.1** Okapi is provided **"AS IS" and "AS AVAILABLE", with all faults**, without any warranty, condition, representation or guarantee of any kind, express, implied, statutory or otherwise, including any implied warranty of merchantability, satisfactory quality, fitness for a particular purpose, accuracy, security, availability, compatibility, non-infringement or freedom from errors, viruses or defects.
- **6.2 No guarantee of correct results.** Permission behaviour is controlled by Google, Apple, device manufacturers and End Users, and differs between OS versions, manufacturers, custom ROMs, enterprise and parental controls. The Author does not guarantee that any status, result, detection or prompt reported or shown by Okapi is correct, complete or current, including the detection of "permanently denied", "limited", "restricted", service, auto-reset or removed-permission states, or whether a system dialog was displayed.
- **6.3 Device manufacturers.** Background-reliability guidance, manufacturer screen names, step-by-step instructions and the screens Okapi tries to open are based on publicly observed behaviour of third-party devices, can differ by model, region and software version, and may change or stop working at any time. The Author does not guarantee that any such screen exists or opens, that the instructions are accurate, or that following them will keep any Host Application running, delivering notifications or performing any task. Whether a user confirmed a setting is the user's own answer and is not verified by Okapi.
- **6.4 Developer tools.** Okapi Doctor and Okapi Sync give automated suggestions and edits based on patterns in source code. A clean Doctor report does not mean a Host Application complies with any law or policy. Okapi Sync modifies project files; the Integrator must keep backups or version control and review every change.
- **6.5 Ask policy and records.** Timing rules, launch counts and removed-permission detection depend on records kept on the device and on operating-system behaviour, may be inaccurate (for example after app data is cleared), and are provided without guarantee.
- **6.6 No guarantee of approval.** The Author does not guarantee that any Host Application using Okapi will be accepted, approved or kept by any store, or will comply with any law or policy.
- **6.7 No obligation to support.** The Author has no obligation to update, support, maintain, fix or keep Okapi compatible with any platform version, and may discontinue it at any time.

## 7. Limitation of liability

- **7.1** To the maximum extent permitted by law, in no event shall the Author or any contributor be liable to the Integrator, any End User or any third party for any loss or damage of any kind, whether direct, indirect, incidental, special, exemplary, punitive or consequential, including loss of data, Security Incidents, loss of privacy, identity theft, regulatory investigation, fines or penalties, compensation to data principals or data subjects, loss of profits, revenue, business, goodwill or reputation, removal or rejection of any application, device damage, personal injury or business interruption, arising out of or in connection with Okapi, its documentation, its website, any Host Application, any Device Permission or this Disclaimer, however caused and on any theory of liability (contract, tort including negligence, strict liability, statute or otherwise), even if advised of the possibility of such loss or damage.
- **7.2** Where liability cannot be excluded by law, the Author's total aggregate liability for all claims shall not exceed the amount actually paid by the claimant to the Author for Okapi. Okapi is provided free of charge, so that amount is nil (INR 0).
- **7.3** Nothing in this Disclaimer excludes liability that cannot lawfully be excluded.

## 8. Indemnity

To the maximum extent permitted by law, the Integrator shall defend, indemnify and hold harmless the Author and contributors from and against all claims, demands, proceedings, investigations, losses, damages, fines, penalties, costs and expenses (including reasonable legal fees) arising out of or related to: (a) any Host Application; (b) any Device Permission requested by or through the Integrator; (c) any collection, processing or use of Protected Data; (d) any Security Incident affecting a Host Application or its data; (e) any breach of this Disclaimer, the LICENSE, TERMS.md, any law or any store policy by the Integrator; or (f) any misuse described in clause 5.

## 9. Third parties

Android, Google Play, iOS, Apple, the App Store and the names of device manufacturers are trademarks of their respective owners. The Author has no affiliation with them and is not responsible for their software, services, decisions or policies. Mentioning a manufacturer does not imply endorsement by or of that manufacturer.

## 10. General

- **10.1 Governing law.** This Disclaimer is governed by the laws of India, without regard to conflict-of-law rules.
- **10.2 Jurisdiction.** Subject to any non-waivable right of a consumer, the courts of competent jurisdiction in India have exclusive jurisdiction over any dispute arising out of or in connection with Okapi or this Disclaimer.
- **10.3 Severability.** If any provision is held invalid or unenforceable, it shall be enforced to the maximum extent permissible and the remaining provisions remain in full force.
- **10.4 No waiver.** A failure or delay in enforcing any provision is not a waiver of it.
- **10.5 Order of precedence.** If documents conflict, the LICENSE prevails on the scope of permitted use, and this Disclaimer prevails on responsibility, warranty and liability.
- **10.6 Changes.** The Author may update this Disclaimer. The version published with the version of Okapi you use applies to that use.
- **10.7 Survival.** Clauses 2 to 8 and 10 survive any end of your use of Okapi.

---

© 2026 Sanket Santosh Vidya Manohar. "Okapi" and the Okapi logo are trademarks of Sanket Santosh Vidya Manohar.
