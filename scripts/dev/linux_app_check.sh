#!/usr/bin/env bash
# Builds and tests Linux-safe app files in a throwaway Swift package, so app logic
# (ViewModels, stores, text helpers) is checked on the Linux dev container before CI.
#
# Usage (from the repo root):
#   scripts/dev/linux_app_check.sh BJS/Shared/LastLaunch.swift ... BJSTests/LastLaunchStoreTests.swift ...
#
# Files under BJS/ become the package's `BJS` target (so `@testable import BJS` works);
# files under BJSTests/ become its `BJSTests` target. Only pass files that import nothing
# beyond Foundation, Observation, BJSCore and Testing. `AppLog` is replaced by a shim
# (os.Logger does not exist on Linux), so never pass BJS/Shared/AppLog.swift.
# Output: the `swift test` summary; exit status is non-zero on any failure.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="${BJS_APP_CHECK_DIR:-/tmp/bjs-app-check}"
rm -rf "$WORK/Sources" "$WORK/Tests"
mkdir -p "$WORK/Sources/BJS" "$WORK/Tests/BJSTests"

cat > "$WORK/Package.swift" <<SWIFT
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BJSAppCheck",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "$REPO/BJSCore")],
    targets: [
        .target(name: "BJS", dependencies: [.product(name: "BJSCore", package: "BJSCore")]),
        .testTarget(name: "BJSTests", dependencies: ["BJS"]),
    ]
)
SWIFT

# Linux stand-in for BJS/Shared/AppLog.swift: same call shape, messages go to stderr.
cat > "$WORK/Sources/BJS/AppLogShim.swift" <<'SWIFT'
import Foundation

enum LogPrivacy { case `public`, `private` }

struct LogMessage: ExpressibleByStringInterpolation {
    struct Interpolation: StringInterpolationProtocol {
        var text = ""
        init(literalCapacity: Int, interpolationCount: Int) {}
        mutating func appendLiteral(_ literal: String) { text += literal }
        mutating func appendInterpolation(_ value: String, privacy: LogPrivacy = .private) { text += value }
    }
    let text: String
    init(stringLiteral value: String) { text = value }
    init(stringInterpolation: Interpolation) { text = stringInterpolation.text }
}

struct ShimLogger: Sendable {
    let category: String
    func error(_ message: LogMessage) {
        FileHandle.standardError.write(Data("[\(category)] \(message.text)\n".utf8))
    }
}

enum AppLog {
    static let persistence = ShimLogger(category: "persistence")
    static let settings = ShimLogger(category: "settings")
}
SWIFT

for file in "$@"; do
    case "$file" in
        BJS/Shared/AppLog.swift) echo "skip $file (replaced by the shim)" ;;
        BJS/*) cp "$REPO/$file" "$WORK/Sources/BJS/" ;;
        BJSTests/*) cp "$REPO/$file" "$WORK/Tests/BJSTests/" ;;
        *) echo "unexpected path: $file" >&2; exit 2 ;;
    esac
done

cd "$WORK"
swift build --build-tests 2>&1 | grep -E "error:|warning:" || true
swift test 2>&1 | grep -E "✘|error:|Test run with"
