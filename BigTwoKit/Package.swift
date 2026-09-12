// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "BigTwoKit",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(name: "BigTwoKit", targets: ["BigTwoKit"])
  ],
  targets: [
    .target(name: "BigTwoKit"),
    .testTarget(name: "BigTwoKitTests", dependencies: ["BigTwoKit"]),
  ]
)
