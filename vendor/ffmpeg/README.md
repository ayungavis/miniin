# FFmpeg

Miniin links FFmpeg for demuxing, decoding, remuxing, and filtering. H.264 and HEVC encoding never
goes through FFmpeg — it goes through VideoToolbox on both processing paths. See `docs/adr/0002`.

## Build

    make ffmpeg

Clones FFmpeg at the pinned tag into `build/`, configures and builds it for iOS, the iOS Simulator,
and macOS, and assembles `FFmpeg.xcframework` beside this file. Neither `build/` nor the framework is
committed.

## Licensing

FFmpeg is built LGPL-2.1+ with `--disable-gpl --disable-nonfree`. It is linked **dynamically**, so
the LGPL relinking obligation is satisfied by replacing `FFmpeg.framework` — no Miniin object files
are required.

`libx264` and `libx265` are prohibited permanently, not deferred. Adopting either converts the
product to GPL and makes App Store distribution impossible.

`CONFIGURE` records the exact configure line of the last build. It is generated; do not edit it.
