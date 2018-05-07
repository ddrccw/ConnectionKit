//
//  ConnectionKit.swift
//  ConnectionKit
//
//  Created by ddrccw on 23/10/15.
//  Copyright © 2017 ddrccw. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "ConnectionKit",
    products: [
        .library(name: "ConnectionKit", targets: ["ConnectionKit-iOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Hearst-DD/ObjectMapper.git", majorVersion: 2, minor: 2),
        .package(url: "https://github.com/krzysztofzablocki/Strongify.git", majorVersion: 1),

        .package(url: "https://github.com/ReactiveX/RxSwift.git", "4.0.0" ..< "5.0.0")

        .package(url: "https://github.com/apple/example-package-fisheryates.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/example-package-playingcard.git", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "ConnectionKit-iOS",
            dependencies: ["ObjectMapper", "Strongify", "RxSwift", "RxCocoa"])
    ]
    exclude: ["Tests"]
)
