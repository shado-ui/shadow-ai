# Convert PNG to ICO for Windows app icon
Add-Type -AssemblyName System.Drawing

$sourcePng = "C:\Users\Shadow\Downloads\AppIcons\android\mipmap-xxxhdpi\krisha .png"
$destIco = "c:\Users\Shadow\Downloads\ai_hub\ai_hub\windows\runner\resources\app_icon.ico"

# Load the PNG
$img = [System.Drawing.Image]::FromFile($sourcePng)

# Create icon sizes (256, 128, 64, 48, 32, 16)
$sizes = @(256, 128, 64, 48, 32, 16)
$iconStream = New-Object System.IO.MemoryStream

# ICO header
$iconStream.WriteByte(0)
$iconStream.WriteByte(0)
$iconStream.WriteByte(1)
$iconStream.WriteByte(0)
$iconStream.WriteByte($sizes.Count)
$iconStream.WriteByte(0)

$offset = 6 + ($sizes.Count * 16)

foreach ($size in $sizes) {
    # Resize image
    $resized = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($resized)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($img, 0, 0, $size, $size)
    $graphics.Dispose()
    
    # Save to memory stream
    $pngStream = New-Object System.IO.MemoryStream
    $resized.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes = $pngStream.ToArray()
    
    # Write icon directory entry
    $iconStream.WriteByte($size)
    $iconStream.WriteByte($size)
    $iconStream.WriteByte(0)
    $iconStream.WriteByte(0)
    $iconStream.WriteByte(1)
    $iconStream.WriteByte(0)
    $iconStream.WriteByte(32)
    $iconStream.WriteByte(0)
    
    $length = $pngBytes.Length
    $iconStream.WriteByte($length -band 0xFF)
    $iconStream.WriteByte(($length -shr 8) -band 0xFF)
    $iconStream.WriteByte(($length -shr 16) -band 0xFF)
    $iconStream.WriteByte(($length -shr 24) -band 0xFF)
    
    $iconStream.WriteByte($offset -band 0xFF)
    $iconStream.WriteByte(($offset -shr 8) -band 0xFF)
    $iconStream.WriteByte(($offset -shr 16) -band 0xFF)
    $iconStream.WriteByte(($offset -shr 24) -band 0xFF)
    
    $offset += $length
    
    $pngStream.Dispose()
    $resized.Dispose()
}

# Write image data
foreach ($size in $sizes) {
    $resized = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($resized)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($img, 0, 0, $size, $size)
    $graphics.Dispose()
    
    $pngStream = New-Object System.IO.MemoryStream
    $resized.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes = $pngStream.ToArray()
    $iconStream.Write($pngBytes, 0, $pngBytes.Length)
    
    $pngStream.Dispose()
    $resized.Dispose()
}

# Save ICO file
[System.IO.File]::WriteAllBytes($destIco, $iconStream.ToArray())

$iconStream.Dispose()
$img.Dispose()

Write-Host "Windows icon created successfully at: $destIco"
