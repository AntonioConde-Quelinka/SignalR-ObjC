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
        // AFNetworking - Nota: se coge de Fork con correcciones al oficial (que esta ya archvoda y sin soporte)
        // SocketRocket - Nota: Necesitarás verificar si existe una versión compatible con SPM
        .package(url: "https://github.com/AntonioConde-Quelinka/AFNetworking.git", branch: "master"),
        .package(url: "https://github.com/lisb/SocketRocket.git", branch: "lisb-direct")
    ],
    targets: [
        .target(
            name: "SignalR-ObjC",
            dependencies: [
                "AFNetworking",
                "SocketRocket"
            ],
            //path: "SignalR.Client",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath(".")
            ]
        )
    ]
)
