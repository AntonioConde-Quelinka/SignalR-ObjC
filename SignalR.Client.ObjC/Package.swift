// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SignalR-ObjC",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "SignalR-ObjC",
            targets: ["SignalR-ObjC"]
        )
    ],
    dependencies: [
        // AFNetworking - Nota: Necesitarás verificar si existe una versión compatible con SPM
        // SocketRocket - Nota: Necesitarás verificar si existe una versión compatible con SPM
        .package(url: "https://github.com/AFNetworking/AFNetworking.git", from: "4.0.1"),
        .package(url: "https://github.com/lisb/SocketRocket.git", branch: "lisb-direct")
    ],
    targets: [
        .target(
            name: "SignalR-ObjC",
            dependencies: [
                "AFNetworking",
                "SocketRocket"
            ],
            path: "SignalR.Client",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        )
    ]
)
