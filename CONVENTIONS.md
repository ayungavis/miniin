# Conventions

These rules are enforced mechanically wherever possible. `make ios-validate` must pass before a
change is considered done.

## Comments

Application source files carry no explanatory comments. Under `apps/**` and `packages/**` only five
forms are permitted, each because a tool or a safety rule already requires it:

1. `// swiftlint:` directives.
2. `// MARK:` navigation.
3. `// tradeoff:` markers on a deliberate shortcut, naming the ceiling it accepts and the upgrade
   path — for example `// tradeoff: global lock, per-account locks if throughput matters`.
4. A short rationale beside a force unwrap, `try!`, `as!`, or `@unchecked`. It must sit **adjacent**
   to the unsafe line, on it or immediately above it, because adjacency is the only form a machine
   can tell apart from prose.
5. Exactly one `///` line per `*Endpoint.swift` file naming the verb and path, bounded by the regex
   `^/// (GET|POST|PUT|PATCH|DELETE) /\S+$` — for example `/// POST /v1/sessions`.

`ConventionsTests` in `packages/MiniinKit/Tests/MiniinKitTests/ConventionsTests.swift` walks every
`.swift` file under `packages/MiniinKit/Sources/` and `apps/Miniin/Miniin/` and fails on any comment
line outside that list. `Tests/` is deliberately out of scope.

There is no "this one is genuinely non-obvious" exception. Everything you want to say about a
decision — why a line is ordered the way it is, which bug it prevents, what the alternative was —
belongs in the pull request, never in the file. If code needs explaining, rename it or extract it.

## Type safety

- No force unwrap, `try!`, or `as!` outside a documented last resort.
- No `Any` or untyped dictionaries in domain APIs.
- No `AnyView`. Use generics or `@ViewBuilder`.
- Prefer enums with associated values over parallel optionals, so illegal states cannot be written.
- Errors are typed `AppError` values, never strings.
- Every exception carries the short adjacent rationale described above.

SwiftLint treats the first three as errors, and additionally blocks `print()`, literal colours, and
`[String: Any]` in API signatures.

## Architecture

- MVVM with Swift Observation. Each feature lives under `Features/<Name>/` with `<Name>View.swift`
  and `<Name>ViewModel.swift`.
- Every ViewModel is `@MainActor @Observable`. Views own them with `@State private`.
- Dependencies are injected through initializers and assembled in `AppContainer`. A ViewModel
  receives only what it uses; the container itself is never injected.
- Feature code depends on protocols, never on concrete media, persistence, purchase, or file-system
  implementations.
- Media work never runs on the main actor, and every cancellable task propagates cancellation.

## Layout

```text
apps/Miniin/        Multiplatform app target (iOS 18.0, macOS 15.0), xcconfig, XcodeGen spec.
                    Miniin.xcodeproj is generated and never committed.
packages/MiniinKit/ Shared Swift package: Core/, DesignSystem/, Features/<Name>/, and tests.
                    Almost all code lives here.
services/           Future hosted services. Empty today.
```

Every UI file ends in `View.swift`, and a filename matches its primary type. Shared UI with no domain
dependency belongs in `DesignSystem/Components/`; shared UI that needs domain types belongs in
`Core/Components/`.

Views use the `AppColor`, `AppFont`, `Spacing`, and `.appShadow()` design tokens rather than literal
values, and every colour token is backed by asset-catalog Any and Dark variants. User-facing strings
live in `Localizable.xcstrings` in the module that owns the UI, with English as the base language and
Indonesian included.

## Validation

```sh
make ios-validate   # format, lint, test, build iOS and macOS
make test           # MiniinKit unit tests only, the fast loop
make lint           # SwiftLint, strict
make generate       # regenerate Miniin.xcodeproj after editing apps/Miniin/project.yml
```

`make ios-validate` must finish with zero lint violations, all tests passing, and `BUILD SUCCEEDED`
on both platforms.

New behaviour is covered by tests for success, failure, and cancellation where applicable, written
with Swift Testing rather than XCTest.
