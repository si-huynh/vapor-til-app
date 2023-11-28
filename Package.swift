// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TILApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.83.1"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.2"),
		.package(url: "https://github.com/vapor/leaf.git", from: "4.2.4"),
		.package(url: "https://github.com/vapor-community/Imperial.git", .upToNextMajor(from: "1.2.0")),
		.package(url: "https://github.com/vapor/jwt.git", .upToNextMajor(from: "4.2.2")),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Vapor", package: "vapor"),
				.product(name: "Leaf", package: "leaf"),
				.product(name: "ImperialGoogle", package: "Imperial"),
				.product(name: "ImperialGitHub", package: "Imperial"),
				.product(name: "JWT", package: "jwt"),
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),

            // Workaround for https://github.com/apple/swift-package-manager/issues/6940
            .product(name: "Vapor", package: "vapor"),
            .product(name: "Fluent", package: "Fluent"),
            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
			.product(name: "Leaf", package: "leaf")
        ])
    ]
)
