import Foundation
import Testing

@Suite("Project conventions")
struct ConventionsTests {
    @Test("Application sources contain only permitted comments")
    func permittedCommentsOnly() throws {
        var violations: [String] = []

        for file in try Self.scannedSwiftFiles() {
            let source = try String(contentsOf: file, encoding: .utf8)
            violations += Self.commentViolations(in: source, file: file)
        }

        #expect(violations.isEmpty, Comment(rawValue: violations.joined(separator: "\n")))
    }

    @Test("Every AppColor token has a colorset with an explicit dark variant")
    func colorTokensHaveDarkVariants() throws {
        let source = try String(
            contentsOf: Self.repoRoot.appending(
                path: "packages/MiniinKit/Sources/MiniinKit/DesignSystem/AppColor.swift"
            ),
            encoding: .utf8
        )
        let catalog = Self.repoRoot.appending(
            path: "packages/MiniinKit/Sources/MiniinKit/Resources/Colors.xcassets"
        )
        let names = Self.matches(
            in: source, pattern: #"Color\("([^"]+)", bundle: \.module\)"#, group: 1
        )

        #expect(!names.isEmpty)

        for name in names {
            let contents = catalog.appending(path: "\(name).colorset/Contents.json")
            guard let json = try? String(contentsOf: contents, encoding: .utf8) else {
                Issue.record("Missing colorset for AppColor token \(name)")
                continue
            }
            #expect(
                json.contains("\"value\" : \"dark\""),
                Comment(rawValue: "\(name) has no dark appearance")
            )
        }
    }
}

extension ConventionsTests {
    static let repoRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    static let scannedRoots = ["packages/MiniinKit/Sources", "apps/Miniin/Miniin"]

    static func scannedSwiftFiles() throws -> [URL] {
        var files: [URL] = []
        for root in scannedRoots {
            let directory = repoRoot.appending(path: root)
            guard FileManager.default.fileExists(atPath: directory.path()) else { continue }
            guard
                let walker = FileManager.default.enumerator(
                    at: directory, includingPropertiesForKeys: nil
                )
            else {
                continue
            }
            for case let url as URL in walker where url.pathExtension == "swift" {
                files.append(url)
            }
        }
        return files.sorted { $0.path() < $1.path() }
    }

    // ponytail: naive literal stripping, upgrade to SwiftSyntax if a false positive ever costs more than this test saves
    static func stripLiterals(_ line: String) -> String {
        line.replacingOccurrences(
            of: #""(\\.|[^"\\])*""#,
            with: "\"\"",
            options: .regularExpression
        )
    }

    static func hasUnsafeConstruct(_ line: String) -> Bool {
        let code = stripLiterals(line)
        if code.contains("try!") || code.contains("as!") || code.contains("@unchecked") {
            return true
        }
        return code.range(of: #"[A-Za-z0-9_)\]]!(?!=)"#, options: .regularExpression) != nil
    }

    static func matches(in source: String, pattern: String, group: Int) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(source.startIndex..., in: source)
        return regex.matches(in: source, range: range).compactMap {
            Range($0.range(at: group), in: source).map { String(source[$0]) }
        }
    }

    static func commentViolations(in source: String, file: URL) -> [String] {
        let lines = source.components(separatedBy: .newlines)
        let isEndpointFile = file.lastPathComponent.hasSuffix("Endpoint.swift")
        var endpointDocCount = 0
        var violations: [String] = []

        for (index, line) in lines.enumerated() {
            let code = stripLiterals(line)
            guard let markerRange = code.range(of: "//") ?? code.range(of: "/*") else { continue }

            let before = String(code[code.startIndex ..< markerRange.lowerBound])
            let comment = String(
                line[
                    line.index(
                        line.startIndex,
                        offsetBy: code.distance(from: code.startIndex, to: markerRange.lowerBound)
                    )...
                ]
            )
            .trimmingCharacters(in: .whitespaces)
            let location = "\(file.lastPathComponent):\(index + 1)"

            if comment.hasPrefix("// swiftlint:") || comment.hasPrefix("// MARK:")
                || comment.hasPrefix("// ponytail:")
            {
                continue
            }

            if isEndpointFile,
               comment.range(
                   of: #"^/// (GET|POST|PUT|PATCH|DELETE) /\S+$"#, options: .regularExpression
               )
               != nil
            {
                endpointDocCount += 1
                if endpointDocCount > 1 {
                    violations.append("\(location): more than one endpoint doc line")
                }
                continue
            }

            let nextLine = index + 1 < lines.count ? lines[index + 1] : ""
            if hasUnsafeConstruct(before) || hasUnsafeConstruct(nextLine) {
                continue
            }

            violations.append("\(location): disallowed comment -> \(comment)")
        }

        return violations
    }

    @Test("Each source file declares a type named after it")
    func filenamesMatchDeclaredTypes() throws {
        var violations: [String] = []

        for file in try Self.scannedSwiftFiles() {
            let name = file.deletingPathExtension().lastPathComponent
            let source = try String(contentsOf: file, encoding: .utf8)
            let pattern = "(enum|struct|class|actor|protocol|extension)\\s+\(name)"

            if source.range(of: pattern, options: .regularExpression) == nil {
                violations.append("\(file.lastPathComponent): declares no type named \(name)")
            }
        }

        #expect(violations.isEmpty, Comment(rawValue: violations.joined(separator: "\n")))
    }
}
