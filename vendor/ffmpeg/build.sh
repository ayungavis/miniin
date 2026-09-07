#!/usr/bin/env bash
set -euo pipefail

FFMPEG_TAG="n7.1.1"
FRAMEWORK="FFmpeg"
IOS_MIN="18.0"
MACOS_MIN="15.0"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$ROOT/build"
SRC="$BUILD/ffmpeg"
XCFRAMEWORK="$ROOT/$FRAMEWORK.xcframework"

LIBS=(avfilter avformat avcodec swresample swscale avutil)

FLAGS=(
  --disable-gpl
  --disable-nonfree
  --disable-programs
  --disable-doc
  --disable-everything
  --disable-network
  --disable-autodetect
  --disable-avdevice
  --disable-shared
  --enable-static
  --enable-pic
  --enable-cross-compile
  --enable-videotoolbox
  --enable-protocol=file
  --enable-demuxer=mov,matroska,avi
  --enable-muxer=mp4,mov
  --enable-decoder=h264,hevc,prores,mpeg4,vp9,av1,aac,alac,mp3,vorbis,opus
  --enable-decoder=pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le
  --enable-encoder=h264_videotoolbox,hevc_videotoolbox,aac
  --enable-parser=h264,hevc,mpeg4video,vp9,av1,aac,mpegaudio,vorbis,opus
  --enable-bsf=h264_mp4toannexb,hevc_mp4toannexb,extract_extradata,aac_adtstoasc
  --enable-filter=scale,format,aformat,aresample,copy,fps,null,anull,setpts,asetpts
  --enable-filter=transpose,hflip,vflip
)

fetch() {
  if [ -d "$SRC/.git" ]; then
    echo "==> source present at $SRC"
    return
  fi

  echo "==> cloning FFmpeg $FFMPEG_TAG"
  mkdir -p "$BUILD"
  git clone --depth 1 --branch "$FFMPEG_TAG" https://git.ffmpeg.org/ffmpeg.git "$SRC"
}

# $1 sdk  $2 clang target triple  $3 prefix
build_slice() {
  local sdk="$1" target="$2" prefix="$3"
  local sysroot cc flags

  sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
  cc="$(xcrun --sdk "$sdk" -f clang)"
  flags="-arch arm64 -target $target -isysroot $sysroot"

  echo "==> configuring $target"
  rm -rf "$BUILD/$sdk"
  mkdir -p "$BUILD/$sdk"

  (
    cd "$BUILD/$sdk"
    "$SRC/configure" \
      --prefix="$prefix" \
      --target-os=darwin \
      --arch=arm64 \
      --cc="$cc" \
      --sysroot="$sysroot" \
      --extra-cflags="$flags" \
      --extra-ldflags="$flags" \
      "${FLAGS[@]}" > configure.log 2>&1 || {
        echo "!! configure failed, tail of $BUILD/$sdk/configure.log:"
        tail -30 "$BUILD/$sdk/configure.log"
        tail -30 "$BUILD/$sdk/ffbuild/config.log" 2>/dev/null || true
        exit 1
      }

    echo "==> building $target"
    make -j"$(sysctl -n hw.ncpu)" > make.log 2>&1 || {
      echo "!! make failed, tail of $BUILD/$sdk/make.log:"
      tail -30 "$BUILD/$sdk/make.log"
      exit 1
    }
    make install > /dev/null
  )
}

# $1 sdk  $2 clang target triple  $3 prefix  $4 output dir  $5 "versioned"|"flat"
make_framework() {
  local sdk="$1" target="$2" prefix="$3" out="$4" layout="$5"
  local sysroot cc bundle binary headers archives=()

  sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
  cc="$(xcrun --sdk "$sdk" -f clang)"

  rm -rf "$out"
  bundle="$out/$FRAMEWORK.framework"

  if [ "$layout" = "versioned" ]; then
    mkdir -p "$bundle/Versions/A/Headers" "$bundle/Versions/A/Resources"
    binary="$bundle/Versions/A/$FRAMEWORK"
    headers="$bundle/Versions/A/Headers"
  else
    mkdir -p "$bundle/Headers"
    binary="$bundle/$FRAMEWORK"
    headers="$bundle/Headers"
  fi

  for lib in "${LIBS[@]}"; do
    archives+=("$prefix/lib/lib$lib.a")
  done

  echo "==> linking $FRAMEWORK.framework for $target"
  "$cc" -dynamiclib \
    -isysroot "$sysroot" \
    -target "$target" \
    -install_name "@rpath/$FRAMEWORK.framework/$FRAMEWORK" \
    -Wl,-all_load "${archives[@]}" \
    -framework CoreFoundation \
    -framework CoreMedia \
    -framework CoreVideo \
    -framework VideoToolbox \
    -framework AudioToolbox \
    -framework CoreAudio \
    -framework Metal \
    -o "$binary"

  cp -R "$prefix/include/"* "$headers/"

  if [ "$layout" = "versioned" ]; then
    write_plist "$sdk" "$bundle/Versions/A/Resources/Info.plist"
    ln -s A "$bundle/Versions/Current"
    ln -s "Versions/Current/$FRAMEWORK" "$bundle/$FRAMEWORK"
    ln -s Versions/Current/Headers "$bundle/Headers"
    ln -s Versions/Current/Resources "$bundle/Resources"
  else
    write_plist "$sdk" "$bundle/Info.plist"
  fi
}

write_plist() {
  local sdk="$1" path="$2" platform min

  case "$sdk" in
    iphoneos) platform="iPhoneOS"; min="$IOS_MIN" ;;
    iphonesimulator) platform="iPhoneSimulator"; min="$IOS_MIN" ;;
    *) platform="MacOSX"; min="$MACOS_MIN" ;;
  esac

  cat > "$path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleExecutable</key><string>$FRAMEWORK</string>
	<key>CFBundleIdentifier</key><string>org.ffmpeg.FFmpeg</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>$FRAMEWORK</string>
	<key>CFBundlePackageType</key><string>FMWK</string>
	<key>CFBundleShortVersionString</key><string>${FFMPEG_TAG#n}</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>
	<key>MinimumOSVersion</key><string>$min</string>
</dict>
</plist>
PLIST
}

record_configure_line() {
  {
    printf '# Written by vendor/ffmpeg/build.sh. Do not edit.\n'
    printf '# FFmpeg %s\n\n' "$FFMPEG_TAG"
    printf './configure'
    printf ' \\\n  %s' "${FLAGS[@]}"
    printf '\n'
  } > "$ROOT/CONFIGURE"
}

main() {
  fetch

  build_slice iphoneos "arm64-apple-ios$IOS_MIN" "$BUILD/prefix/iphoneos"
  build_slice iphonesimulator "arm64-apple-ios$IOS_MIN-simulator" "$BUILD/prefix/iphonesimulator"
  build_slice macosx "arm64-apple-macos$MACOS_MIN" "$BUILD/prefix/macosx"

  make_framework iphoneos "arm64-apple-ios$IOS_MIN" \
    "$BUILD/prefix/iphoneos" "$BUILD/framework/iphoneos" flat
  make_framework iphonesimulator "arm64-apple-ios$IOS_MIN-simulator" \
    "$BUILD/prefix/iphonesimulator" "$BUILD/framework/iphonesimulator" flat
  make_framework macosx "arm64-apple-macos$MACOS_MIN" \
    "$BUILD/prefix/macosx" "$BUILD/framework/macosx" versioned

  echo "==> assembling $XCFRAMEWORK"
  rm -rf "$XCFRAMEWORK"
  xcodebuild -create-xcframework \
    -framework "$BUILD/framework/iphoneos/$FRAMEWORK.framework" \
    -framework "$BUILD/framework/iphonesimulator/$FRAMEWORK.framework" \
    -framework "$BUILD/framework/macosx/$FRAMEWORK.framework" \
    -output "$XCFRAMEWORK"

  record_configure_line

  echo
  echo "==> done"
  du -sh "$XCFRAMEWORK"/*/ 2>/dev/null || true
}

main "$@"
