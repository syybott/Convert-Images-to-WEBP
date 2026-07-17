# Convert-Images-to-WEBP
Simple script to convert png (lossless) and jpg (lossy) files to WEBP

1. Download Convert-Images-to-WEBP-System-Folder-Portable.ps1
2. Download Google’s official Windows WebP utilities from: https://developers.google.com/speed/webp/download, select 'Download for Windows'
3. Extract the downloaded archive, open its bin folder, and locate cwebp.exe
4. Copy both cwebp.exe & Convert-Images-to-WEBP-System-Folder-Portable.ps1 into your ES-DE downloaded_media folder
5. In File Explorer, with the downloaded_media folder open, click the address bar, and type: powershell
Then press Enter
In the PowerShell window, run: powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Convert-Images-to-WEBP-System-Folder-Portable.ps1"

The script will recursively scan every folder inside downloaded_media, convert PNG files to lossless WebP, convert JPG/JPEG files to quality-90 WebP, skip existing same-named WebP files, and leave the original images untouched.
