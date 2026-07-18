**### # Convert Images to WebP v1.1**

This tool was created to help with managing downloaded media for ES-DE Frontend. Version 1.1 adds interactive configuration, immediate cleanup, safer temporary output files, WebP validation, running storage-savings tracking, and additional protections against accidental data loss.

> [!IMPORTANT]
> Version 1.1 will permanently delete existing PNG, JPG, and JPEG files if a new valid smaller WEBP file is validated after conversion. Deleted files bypass the Recycle Bin. Back up important files before running the script.

**### ## Changes from v1.0**

### Interactive startup options

The script now prompts the user to configure each run.

#### Clean up existing WebP pairs

- `Y` processes valid source/WebP pairs that existed before the current run.
- `N` leaves all pre-existing source/WebP pairs untouched.
- WebPs created during the current run are still cleaned up immediately.
- Press Enter to accept the default value of `N`.

#### PNG compression level

- Select a compression level from `1` through `10`.
- Every level remains fully lossless.
- Pixel data and transparency are preserved.
- `1` is faster but may produce larger WebP files.
- `10` is slower and applies the maximum compression effort.
- Press Enter to accept the default value of `10`.

#### JPG/JPEG WebP quality

- Select a quality level from `0` through `100`.
- Higher values preserve more image detail but create larger files.
- Lower values create smaller files with greater additional quality loss.
- Press Enter to accept the default value of `90`.

## Immediate cleanup

Version 1.0 retained all original PNG, JPG, and JPEG files.

Version 1.1 performs cleanup immediately after each successful conversion.

### PNG behavior

1. The PNG is converted to a lossless WebP.
2. The generated WebP is validated.
3. The temporary output is renamed to its final `.webp` filename.
4. The original PNG is permanently deleted.

### JPG and JPEG behavior

1. The JPG or JPEG is converted to WebP using the selected quality setting.
2. The generated WebP is validated.
3. The original and WebP file sizes are compared.
4. The larger file is permanently deleted.

If the JPG/JPEG and WebP are exactly the same size, the original JPG/JPEG is retained and the redundant WebP is deleted.

## Temporary conversion files

New WebP files are initially written using a temporary filename:

`filename.webp.part`

After successful conversion and validation, the temporary file is renamed to:

`filename.webp`

This prevents an interrupted or failed conversion from leaving an incomplete file with the final `.webp` extension.

## Existing WebP protection

Version 1.1 distinguishes between:

- WebPs created during the current run
- WebPs that already existed before the script started

By default:

- Newly created WebPs are validated and cleaned up immediately.
- Pre-existing source/WebP pairs are left untouched.

Cleanup of pre-existing pairs must be explicitly enabled through the startup prompt.

## WebP validation

Before an original image is deleted, the script verifies that:

- `cwebp.exe` returned a successful exit code.
- The generated WebP exists.
- The generated file is large enough to contain a WebP header.
- The file contains valid `RIFF` and `WEBP` signatures.
- The file size declared in the RIFF header matches the actual file size.

If validation fails, the original source image is retained.

## Running storage-savings tally

The script now displays the actual net storage saved after every processed file.

Example:

`[1174/19218 | Net saved: 6.42 GB]`

Storage savings are calculated during processing, so the script no longer needs to perform a second full scan of the directory tree after conversion.

## Filename-collision protection

Files such as:

- `game.png`
- `game.jpg`

would both attempt to create:

- `game.webp`

Version 1.1 detects these filename collisions and skips the affected files instead of risking an overwrite or incorrect deletion.

## Junction and symbolic-link protection

The recursive scan now excludes:

- Directory junctions
- Symbolic-link directories
- Other reparse-point directories

This prevents the script from unintentionally scanning linked folders, another drive, or a recursive directory structure.

## Rollback protection

When a new WebP is created but the original source file cannot be deleted, the script attempts to remove the newly created WebP.

This prevents a failed cleanup from leaving an unnecessary duplicate beside the original source image.

## Improved error handling

Version 1.1 now:

- Uses red console output only for genuine errors.
- Retains original files after failed conversion or validation.
- Reports conversion and validation errors separately from deletion errors.
- Tracks filename-collision skips.
- Tracks excluded junction and symbolic-link directories.
- Displays detailed completion totals.
- Displays running net storage savings.

## Installation

Place these files together inside the folder tree you want to process:

- `Convert-Images-to-WEBP-v1.1.ps1`
- `cwebp.exe`

The script scans that folder and every normal subfolder beneath it.

Download Google’s official Windows WebP utilities here:

https://developers.google.com/speed/webp/download

Extract `cwebp.exe` from the downloaded package and place it beside the PowerShell script.

## Running the script

Open the target folder in File Explorer.

Click the File Explorer address bar, type:

`powershell`

Press Enter.

Run the following command in PowerShell:

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Convert-Images-to-WEBP-v1.1.ps1"`

> [!IMPORTANT]
> The script displays a permanent-deletion warning and requires the user to type `CONVERT AND DELETE` before processing begins.
