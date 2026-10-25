param(
	[switch]$NoBump
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = "C:\Users\bikee\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
$iscc = "C:\Users\bikee\AppData\Local\Programs\Inno Setup 6\ISCC.exe"

$versionFile = Join-Path $projectRoot "version.txt"
$version = (Get-Content -LiteralPath $versionFile -Raw).Trim()
if ($version -notmatch '^(\d+)\.(\d+)$') {
	throw "Invalid version format in version.txt: '$version' (expected MAJOR.MINOR)"
}
$major = [int]$Matches[1]
$minor = [int]$Matches[2]

$issFile = Join-Path $PSScriptRoot "tycoon.iss"
$exePath = Join-Path $projectRoot "build\windows\Businessman.exe"

Write-Host "Building version $major.$minor"

$issContent = Get-Content -LiteralPath $issFile -Raw
$issContent = $issContent -replace '#define MyAppVersion "[^"]*"', "#define MyAppVersion `"$major.$minor`""
Set-Content -LiteralPath $issFile -Value $issContent -NoNewline

if (Test-Path -LiteralPath $exePath) {
	Remove-Item -LiteralPath $exePath -Force
}

& $godot --headless --path $projectRoot --import | Out-Null
& $godot --headless --path $projectRoot --export-release "Windows Desktop" $exePath 2>&1 | Out-Null
if (-not (Test-Path -LiteralPath $exePath)) {
	throw "Export failed: $exePath not found"
}
Write-Host "Exported: $exePath"

& $iscc $issFile

$setupPath = Join-Path $projectRoot "dist\Businessman-Setup-$major.$minor.exe"
if (-not (Test-Path -LiteralPath $setupPath)) {
	throw "Installer build failed: $setupPath not found"
}
Write-Host "Installer: $setupPath"

if (-not $NoBump) {
	$next = "$major.$($minor + 1)"
	Set-Content -LiteralPath $versionFile -Value $next
	Write-Host "Next build version: $next"
}
