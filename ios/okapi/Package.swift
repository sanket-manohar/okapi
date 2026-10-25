// swift-tools-version: 5.9
// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Licensed under the Okapi Software License (see LICENSE).

import PackageDescription

let package = Package(
    name: "okapi",
    platforms: [
        .iOS("12.0"),
    ],
    products: [
        .library(name: "okapi", targets: ["okapi"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "okapi",
            dependencies: [],
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy"),
            ]
        ),
    ]
)
