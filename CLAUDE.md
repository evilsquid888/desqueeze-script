# CLAUDE.md

## Project Overview

**desqueeze-script** is a single-file Bash utility that restores correct aspect ratios on anamorphic media (photos and videos) captured with the Sirui 20mm anamorphic lens. It automatically detects the lens via EXIF metadata and applies a configurable horizontal desqueeze (default 1.33x).

## Repository Structure

```
desqueeze.sh   — The entire script (single file, ~170 lines)
README.md      — Full documentation with usage, prerequisites, and troubleshooting
```

There is no build step, test suite, or package manager. The project is a standalone shell script.

## Running the Script

```bash
# Make executable (first time only)
chmod +x desqueeze.sh

# Run in a directory containing anamorphic media files
./desqueeze.sh          # default 1.33x desqueeze
./desqueeze.sh 1.5      # custom aspect ratio
```

The script operates on files in the **current working directory**. It never modifies originals; output files get a `_desqueezed` suffix.

## Dependencies

| Tool | Required for | Install (Debian/Ubuntu) |
|------|-------------|------------------------|
| `exiftool` | All operations (lens detection, metadata) | `sudo apt install libimage-exiftool-perl` |
| `ffmpeg` | JPEG scaling and video re-encoding | `sudo apt install ffmpeg` |

The script gracefully degrades: without ffmpeg it still processes DNG/RAW files.

## How It Works (Architecture)

The script has three sequential processing sections:

1. **DNG/RAW** -- Copies the file then writes `DefaultScale` EXIF tag via exiftool (non-destructive; preserves full RAW data).
2. **JPEG** -- Uses `ffmpeg -vf "scale=iw*RATIO:ih"` to physically resize the image, then copies metadata back with exiftool.
3. **Video** (MP4/MOV/AVI/MKV) -- Prompts the user interactively (`read -n 1`), then re-encodes with H.264 (CRF 18, preset slow, audio stream copied).

Lens detection uses case-insensitive regex matching for "Sirui" + "20" in the `LensModel` EXIF field. Videos skip lens detection and prompt the user instead.

## Coding Conventions

- **Language**: Bash (shebang `#!/bin/bash`).
- **Style**: Heavy use of block comments with `####` section headers. Each processing section is visually separated and documented inline.
- **Globbing**: Uses `shopt -s nullglob` to avoid errors on empty globs; iterates over explicit extension variants (e.g., `dng DNG`).
- **Output naming**: `${file%.*}_desqueezed.${ext}` pattern throughout.
- **Error handling**: Minimal -- ffmpeg errors are filtered with `grep -E "(error|Error)"`, exiftool stderr is sent to `/dev/null`. No `set -e` or `set -o pipefail`.
- **No tests**: There is no test suite or CI configuration.

## Key Things to Know When Modifying

- Adding support for a new lens: modify the regex in the two `if [[ "$lens" =~ ... ]]` blocks (DNG section and JPEG section).
- Adding a new image format: add another extension to the `for ext in ...` loop in the relevant section.
- The video section uses interactive `read` -- this means piped/automated usage will need adjustment.
- Width values for H.264 video must be even numbers; the script rounds up odd values.
