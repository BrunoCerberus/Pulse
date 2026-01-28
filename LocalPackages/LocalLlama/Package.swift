// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LocalLlama",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(name: "LocalLlama", targets: ["LocalLlama"]),
    ],
    targets: [
        .target(
            name: "LocalLlama",
            dependencies: ["LlamaFramework"]
        ),
        .binaryTarget(
            name: "LlamaFramework",
            url: "https://github.com/ggml-org/llama.cpp/releases/download/b5046/llama-b5046-xcframework.zip",
            checksum: "c19be78b5f00d8d29a25da41042cb7afa094cbf6280a225abe614b03b20029ab"
        ),
    ]
)
