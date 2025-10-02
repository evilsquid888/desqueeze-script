# Desqueeze Script

A bash script for processing anamorphic images and videos captured with the Sirui 20mm anamorphic lens. Automatically detects and desqueezes media files to restore correct aspect ratio.

## Overview

The Sirui 20mm anamorphic lens captures images with a squeezed horizontal aspect ratio. This script automatically identifies photos taken with this lens and applies the correct desqueeze transformation to restore the intended cinematic look.

### Features

- **Automatic Lens Detection**: Uses EXIF metadata to identify Sirui 20mm lens photos
- **Multiple Format Support**: Handles DNG/RAW, JPEG, and video files (MP4, MOV, AVI, MKV)
- **Non-Destructive Processing**: Creates new files with `_desqueezed` suffix, preserving originals
- **Smart Processing**:
  - DNG/RAW: Modifies EXIF DefaultScale metadata (non-destructive, preserves full RAW data)
  - JPEG: Physically scales image using high-quality ffmpeg processing
  - Video: Re-encodes with H.264 codec at near-lossless quality (CRF 18)
- **Customizable Aspect Ratio**: Default 1.33x (standard for Sirui 20mm), configurable via command-line

## Prerequisites

### Required

- **exiftool**: Image metadata manipulation
  ```bash
  # Ubuntu/Debian
  sudo apt install libimage-exiftool-perl

  # macOS
  brew install exiftool

  # Windows (WSL)
  sudo apt install libimage-exiftool-perl
  ```

### Optional (for JPEG and video processing)

- **ffmpeg**: Video and image processing
  ```bash
  # Ubuntu/Debian
  sudo apt install ffmpeg

  # macOS
  brew install ffmpeg

  # Windows (WSL)
  sudo apt install ffmpeg
  ```

**Note**: Script will run without ffmpeg but will skip JPEG and video processing.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/evilsquid888/desqueeze-script.git
   cd desqueeze-script
   ```

2. Make the script executable:
   ```bash
   chmod +x desqueeze.sh
   ```

3. Verify prerequisites are installed:
   ```bash
   exiftool -ver
   ffmpeg -version
   ```

## Usage

### Basic Usage

Run the script in a directory containing your anamorphic media files:

```bash
./desqueeze.sh
```

This uses the default 1.33x aspect ratio suitable for Sirui 20mm lens.

### Custom Aspect Ratio

Specify a different desqueeze factor:

```bash
./desqueeze.sh 1.5
```

### Examples

```bash
# Default 1.33x desqueeze
./desqueeze.sh

# Stronger 1.5x desqueeze
./desqueeze.sh 1.5

# Lighter 1.25x desqueeze
./desqueeze.sh 1.25
```

## How It Works

### Image Processing (DNG/RAW)

1. Scans directory for DNG files
2. Reads EXIF metadata to identify lens model
3. Filters for Sirui 20mm lens photos only
4. Creates copy of RAW file with `_desqueezed` suffix
5. Modifies EXIF `DefaultScale` tag to signal correct aspect ratio to photo editing software
6. Result: Non-destructive desqueeze preserving full RAW data

### Image Processing (JPEG)

1. Scans directory for JPEG files
2. Identifies Sirui 20mm lens photos via EXIF
3. Uses ffmpeg to physically scale image width (height remains constant)
4. Applies high-quality encoding (`-q:v 2`)
5. Copies all metadata from original to output
6. Result: Desqueezed JPEG ready to use

### Video Processing

1. Scans directory for video files (MP4, MOV, AVI, MKV)
2. Prompts user for confirmation (videos don't contain lens metadata)
3. Extracts current dimensions
4. Calculates new width (multiplied by aspect ratio, rounded to even number)
5. Re-encodes using H.264 codec with near-lossless quality (CRF 18)
6. Copies audio stream without re-encoding
7. Result: Desqueezed video file

## Supported Formats

| Format | Extensions | Processing Method |
|--------|-----------|------------------|
| RAW | `.dng`, `.DNG` | EXIF metadata modification |
| JPEG | `.jpg`, `.JPG`, `.jpeg`, `.JPEG` | Image scaling with ffmpeg |
| Video | `.mp4`, `.MP4`, `.mov`, `.MOV`, `.avi`, `.AVI`, `.mkv`, `.MKV` | Video re-encoding with H.264 |

## Output

All processed files are saved with the `_desqueezed` suffix:

```
Original files:
  IMG_0001.dng
  IMG_0002.jpg
  VID_0001.mp4

Output files:
  IMG_0001_desqueezed.dng
  IMG_0002_desqueezed.jpg
  VID_0001_desqueezed.mp4
```

**Original files are never modified or deleted.**

## Post-Processing Workflow

### For Images (DNG/RAW)

1. Import desqueezed DNG files into your RAW processor (Lightroom, Capture One, etc.)
2. The correct aspect ratio is automatically applied via EXIF metadata
3. Continue with normal photo editing workflow

### For Images (JPEG)

1. Use desqueezed JPEG files directly in any image editor or viewer
2. Aspect ratio correction already applied

### For Videos

1. Import desqueezed video files into your video editor
2. Aspect ratio correction already applied to video frames
3. Continue with normal video editing workflow

## Technical Details

### EXIF DefaultScale Tag

For DNG/RAW files, the script modifies the `DefaultScale` EXIF tag:

```bash
exiftool -DefaultScale="1.33 1.0" file.dng
```

This signals to photo editing software to apply a 1.33x horizontal scale when rendering the image.

### FFmpeg Video Encoding Settings

```bash
ffmpeg -i input.mp4 \
  -vf "scale=${new_width}:${height}" \
  -c:v libx264 \
  -crf 18 \
  -preset slow \
  -c:a copy \
  output.mp4
```

- **CRF 18**: Constant Rate Factor for near-lossless quality (0-51 scale)
- **Preset slow**: Better compression ratio with slower encoding
- **Audio copy**: Preserves original audio without re-encoding

## Troubleshooting

### Script doesn't find any files to process

- Ensure you're running the script in the directory containing your media files
- Verify files are in supported formats (DNG, JPEG, MP4, etc.)
- Check that EXIF data contains "Sirui 20mm" or "20 Sirui" in the lens model field

### "exiftool: command not found"

Install exiftool (see Prerequisites section above)

### "ffmpeg not found" warning

Install ffmpeg for JPEG and video processing (see Prerequisites section above). Script will still process DNG files without ffmpeg.

### Video processing is very slow

This is normal. H.264 encoding with CRF 18 and slow preset prioritizes quality over speed. Processing time depends on:
- Video resolution
- Video length
- CPU performance

Expect several minutes for 4K videos.

### Aspect ratio still looks wrong

Double-check the aspect ratio value. Sirui 20mm typically uses 1.33x, but try adjusting:

```bash
# Try slightly different values
./desqueeze.sh 1.25
./desqueeze.sh 1.35
./desqueeze.sh 1.5
```

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please open an issue or submit a pull request on GitHub.

## Repository

https://github.com/evilsquid888/desqueeze-script

## Author

evilsquid888

## Acknowledgments

- Designed for the Sirui 20mm anamorphic lens
- Uses ExifTool by Phil Harvey
- Uses FFmpeg for video/image processing
