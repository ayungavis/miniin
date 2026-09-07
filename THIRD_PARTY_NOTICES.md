# Third-party notices

Miniin is licensed under the Mozilla Public License 2.0. It links the following third-party software.

## FFmpeg

- Version: n7.1.1
- License: GNU Lesser General Public License, version 2.1 or later
- Source: https://git.ffmpeg.org/ffmpeg.git, tag `n7.1.1`
- Homepage: https://ffmpeg.org

FFmpeg is built with `--disable-gpl --disable-nonfree`, so the binary contains no GPL or non-free
components. The GPL encoders `libx264` and `libx265` are excluded permanently. H.264 and HEVC
encoding goes through Apple's VideoToolbox on both processing paths.

The exact configure line is published in [`vendor/ffmpeg/CONFIGURE`](vendor/ffmpeg/CONFIGURE) and the
build script in [`vendor/ffmpeg/build.sh`](vendor/ffmpeg/build.sh).

### Written offer

FFmpeg is linked **dynamically**, as `FFmpeg.framework` inside the application bundle. You may modify
FFmpeg and relink it with Miniin by replacing that framework with your own build; no Miniin object
files are required.

The corresponding source for the FFmpeg version distributed with Miniin is available at the tag above.
For any binary release, a copy of that source is also available on request for at least three years
from the date of that release, at the contact address in the repository.

The full text of the LGPL-2.1 is available at https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
