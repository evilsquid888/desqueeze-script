#!/bin/bash

################################################################################
# Desqueeze Script for Anamorphic Media
################################################################################
# Purpose: Processes anamorphic images (DNG/RAW) and videos to restore correct
#          aspect ratio by applying horizontal desqueeze transformation
#
# Features:
#   - Automatically detects and processes only Sirui 20mm lens photos
#   - Processes DNG/RAW files by modifying EXIF DefaultScale metadata
#   - Processes JPEG files by scaling with ffmpeg
#   - Processes video files (MP4, MOV, AVI, MKV) with interactive confirmation
#   - Preserves original files (creates new files with _desqueezed suffix)
#
# Usage: ./desqueeze.sh [ASPECT_RATIO]
#   ASPECT_RATIO: Optional desqueeze factor (default: 1.33)
#
# Examples:
#   ./desqueeze.sh       # Uses default 1.33x aspect ratio
#   ./desqueeze.sh 1.5   # Uses 1.5x aspect ratio
#
# Dependencies:
#   - exiftool: Required for all operations
#   - ffmpeg: Required for JPEG and video processing
#
# Author: evilsquid888
# Repository: https://github.com/evilsquid888/desqueeze-script
################################################################################

# Parse aspect ratio argument (default: 1.33x for Sirui 20mm anamorphic lens)
ASPECT_RATIO="${1:-1.33}"

echo "Desqueezing files with aspect ratio: ${ASPECT_RATIO}x"
echo "Only processing images taken with Sirui 20mm lens..."
echo ""

################################################################################
# Process DNG/RAW Image Files
################################################################################
# Strategy: Modify EXIF DefaultScale metadata to signal correct aspect ratio
# to photo editing software (e.g., Lightroom, Capture One)
# This is non-destructive and preserves full RAW data
################################################################################
shopt -s nullglob
for ext in dng DNG; do
    for file in *."$ext"; do
        # Extract lens model from EXIF metadata
        lens=$(exiftool -LensModel -s3 "$file" 2>/dev/null)

        # Check if the lens is Sirui 20mm (case-insensitive pattern matching)
        if [[ "$lens" =~ [Ss][Ii][Rr][Uu][Ii].*20 ]] || [[ "$lens" =~ 20.*[Ss][Ii][Rr][Uu][Ii] ]]; then
            echo "Processing DNG: $file (Lens: $lens)"

            # Create output filename with _desqueezed suffix
            output="${file%.*}_desqueezed.${ext}"

            # Copy original file to preserve it
            cp "$file" "$output"

            # Modify DefaultScale EXIF tag to apply horizontal desqueeze
            # Format: "horizontal_scale vertical_scale" (e.g., "1.33 1.0")
            exiftool -DefaultScale="${ASPECT_RATIO} 1.0" -overwrite_original "$output"
        else
            echo "Skipping: $file (Lens: $lens)"
        fi
    done
done

################################################################################
# Process JPEG Files
################################################################################
# Strategy: Use ffmpeg to physically scale image width while preserving height
# This creates a new JPEG file with the correct aspect ratio
# Quality setting: -q:v 2 (high quality, scale 1-31, lower is better)
################################################################################
if command -v ffmpeg &> /dev/null; then
    for ext in jpg JPG jpeg JPEG; do
        for file in *."$ext"; do
            # Extract lens model from EXIF metadata
            lens=$(exiftool -LensModel -s3 "$file" 2>/dev/null)

            # Check if the lens is Sirui 20mm (case-insensitive pattern matching)
            if [[ "$lens" =~ [Ss][Ii][Rr][Uu][Ii].*20 ]] || [[ "$lens" =~ 20.*[Ss][Ii][Rr][Uu][Ii] ]]; then
                echo "Processing JPEG: $file (Lens: $lens)"
                output="${file%.*}_desqueezed.${ext}"

                # Scale image: multiply width by aspect ratio, keep height same
                # -q:v 2: high quality output
                # -y: overwrite output file if exists
                ffmpeg -i "$file" -vf "scale=iw*${ASPECT_RATIO}:ih" -q:v 2 "$output" -y 2>&1 | grep -E "(error|Error)" || true

                # Copy all metadata from original to desqueezed file
                if [ -f "$output" ]; then
                    exiftool -TagsFromFile "$file" -all:all "$output" -overwrite_original 2>/dev/null
                    echo "  Created: $output"
                fi
            else
                echo "Skipping: $file (Lens: $lens)"
            fi
        done
    done
else
    echo "Warning: ffmpeg not found. Skipping JPEG processing."
fi

################################################################################
# Process Video Files
################################################################################
# Strategy: Re-encode video with scaled dimensions using H.264 codec
# User confirmation required for each video (no lens metadata in video files)
# Settings:
#   - CRF 18: Near-lossless quality (0-51 scale, lower is better)
#   - Preset slow: Better compression (slower encoding)
#   - Audio: Copy without re-encoding
################################################################################
if command -v ffmpeg &> /dev/null; then
    for ext in mp4 MP4 mov MOV avi AVI mkv MKV; do
        for file in *."$ext"; do
            # For videos, ask user interactively (no lens metadata available)
            echo ""
            read -n 1 -p "Desqueeze video '$file'? (y/n): " answer
            echo ""

            if [[ "$answer" =~ ^[Yy]$ ]]; then
                echo "Processing video: $file - this may take a while..."
                output="${file%.*}_desqueezed.${file##*.}"

                # Calculate target width (keep height same)
                width=$(exiftool -ImageWidth -s3 "$file")
                height=$(exiftool -ImageHeight -s3 "$file")
                new_width=$(awk "BEGIN {printf \"%d\", $width * $ASPECT_RATIO}")

                # Round to even number (required for H.264 compatibility)
                if [ $((new_width % 2)) -ne 0 ]; then
                    new_width=$((new_width + 1))
                fi

                # Re-encode video with new dimensions
                # -c:v libx264: Use H.264 video codec
                # -crf 18: Constant Rate Factor (quality-based encoding)
                # -preset slow: Slower encoding for better compression
                # -c:a copy: Copy audio stream without re-encoding
                ffmpeg -i "$file" -vf "scale=${new_width}:${height}" -c:v libx264 -crf 18 -preset slow -c:a copy "$output" -y 2>&1 | grep -E "(Duration|frame=|time=|error)" || true

                if [ -f "$output" ]; then
                    echo "  Created: $output"
                fi
            else
                echo "Skipping video: $file"
            fi
        done
    done
else
    echo "Warning: ffmpeg not found. Skipping video processing."
    echo "Install ffmpeg to process videos: sudo apt install ffmpeg"
fi
shopt -u nullglob

################################################################################
# Completion Summary
################################################################################
echo ""
echo "Done! All desqueezed files have been saved with '_desqueezed' suffix."
echo "Original files remain unchanged."
echo ""
echo "Next steps:"
echo "  - For images: Import desqueezed DNGs to Lightroom or your RAW processor"
echo "  - For videos: Use the desqueezed video files in your video editor"
