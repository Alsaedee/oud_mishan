$sourcePath = "C:\Users\j-t\Downloads\oud_app_1_artifacts\build\ios\archive\Runner.xcarchive\Products\Applications\Runner.app"
$destinationZip = "C:\Users\j-t\Downloads\luxury_perfume_pos.zip"
$destinationIpa = "C:\Users\j-t\Downloads\luxury_perfume_pos.ipa"
$tempPayload = "C:\Users\j-t\Downloads\Payload"

if (Test-Path $tempPayload) {
    Remove-Item -Path $tempPayload -Recurse -Force
}

New-Item -ItemType Directory -Path "$tempPayload" -Force
Copy-Item -Path $sourcePath -Destination "$tempPayload\Runner.app" -Recurse -Force

if (Test-Path $destinationZip) {
    Remove-Item -Path $destinationZip -Force
}
if (Test-Path $destinationIpa) {
    Remove-Item -Path $destinationIpa -Force
}

Compress-Archive -Path $tempPayload -DestinationPath $destinationZip -Force
Rename-Item -Path $destinationZip -NewName "luxury_perfume_pos.ipa" -Force
Remove-Item -Path $tempPayload -Recurse -Force

Write-Output "Successfully packaged IPA!"
