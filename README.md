# Miniin

Make every video lighter. / Bikin videomu lebih ringan.

Miniin is an offline-first video compressor for iOS and macOS. Videos are inspected, configured, and
encoded entirely on device — nothing is uploaded, and no account is required for local features.

**Status: pre-Phase 0.** The project skeleton and validation pipeline are in place. Media processing
is not implemented yet.

## Requirements

| Tool                                                       | Version used                   |
| ---------------------------------------------------------- | ------------------------------ |
| Xcode                                                      | 26.6                           |
| Swift                                                      | 6.3                            |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen)          | 2.46                           |
| [SwiftLint](https://github.com/realm/SwiftLint)            | 0.65                           |
| [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) | 0.62                           |
| [xcbeautify](https://github.com/cpisciotta/xcbeautify)     | 3.2                            |
| FFmpeg                                                     | n7.1.1, built by `make ffmpeg` |

```sh
brew install xcodegen swiftlint swiftformat xcbeautify
```

Deployment targets: iOS 18.0, macOS 15.0.

## Getting started

```sh
make generate       # create apps/Miniin/Miniin.xcodeproj from project.yml
make ios-validate   # format, lint, test, build iOS and macOS
make ios-run        # build, install, and launch on the iOS Simulator
```

`Miniin.xcodeproj` is generated and not committed. Run `make generate` after pulling changes to
`apps/Miniin/project.yml`, then open the project in Xcode.

### FFmpeg

`make ios-validate` links `vendor/ffmpeg/FFmpeg.xcframework`, which is **not committed**. Build it
once per clone:

```sh
make ffmpeg         # clones FFmpeg at the pinned tag and builds three arm64 slices
```

It takes a while. `vendor/ffmpeg/CONFIGURE` records the exact configure line of the last build.

On CI, cache `vendor/ffmpeg/FFmpeg.xcframework` keyed on a hash of `vendor/ffmpeg/build.sh` plus the
pinned tag, or publish the framework as a release asset. Committing it is the worse option: LFS
bandwidth is metered per clone, and storage is permanent per version.

## Layout

```text
apps/Miniin/        Multiplatform app target, xcconfig, XcodeGen spec
packages/MiniinKit/ Shared Swift package: Core, DesignSystem, Features, tests
services/           Future hosted services
CONVENTIONS.md      Enforceable project conventions
```

## Conventions

Project rules live in [`CONVENTIONS.md`](CONVENTIONS.md) and are enforced mechanically where possible:
SwiftLint blocks force unwraps, `AnyView`, `print()`, literal colors, and untyped dictionary APIs;
`ConventionsTests` rejects explanatory comments in application sources and colour tokens without a
dark variant. `make ios-validate` must pass with zero lint violations, all tests green, and
`BUILD SUCCEEDED` on both platforms.

## Licensing

Miniin is licensed under the [Mozilla Public License 2.0](LICENSE).

FFmpeg is built LGPL-2.1+ with GPL and non-free components disabled, and is dynamically linked, so
the relinking obligation is met by the shipped dynamic library plus the published build scripts. The
GPL encoders `libx264` and `libx265` are permanently excluded: H.264 and HEVC encoding always goes
through VideoToolbox, on either processing path. FFmpeg is responsible for demuxing, decoding,
remuxing, filtering, and BSD-licensed codecs.

A self-built copy does not receive official signing, production credentials, hosted service access,
or trademark rights.
