param(
	[switch]$NoBump
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = "C:\Users\bikee\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
$iscc = "C:\Users\bikee\AppData\Local\Programs\Inno Setup 6\ISCC.exe"

function Invoke-External($FilePath, $Arguments) {
	$quoted = $Arguments | ForEach-Object {
		$a = [string]$_
		# Escape trailing backslashes and internal quotes for CommandLineToArgvW.
		$a = $a -replace '(\\+)$', '$1$1'
		$a = $a -replace '(\\*)"', '$1$1\"'
		'"' + $a + '"'
	}
	$argString = $quoted -join ' '
	$proc = Start-Process -FilePath $FilePath -ArgumentList $argString -Wait -PassThru -NoNewWindow
	return $proc.ExitCode
}

$versionFile = Join-Path $projectRoot "version.txt"
$version = ([System.IO.File]::ReadAllText($versionFile, [System.Text.Encoding]::ASCII)).Trim()
if ($version -notmatch '^(\d+)\.(\d+)$') {
	throw "Invalid version format in version.txt: '$version' (expected MAJOR.MINOR)"
}
$major = [int]$Matches[1]
$minor = [int]$Matches[2]

$issFile = Join-Path $PSScriptRoot "tycoon.iss"
$exePath = Join-Path $projectRoot "build\windows\Businessman.exe"

Write-Host "Building version $major.$minor"

$issContent = [System.IO.File]::ReadAllText($issFile, [System.Text.Encoding]::UTF8)
$issContent = $issContent -replace '#define MyAppVersion "[^"]*"', "#define MyAppVersion `"$major.$minor`""
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($issFile, $issContent, $utf8Bom)

if (Test-Path -LiteralPath $exePath) {
	Remove-Item -LiteralPath $exePath -Force
}

$global:LASTEXITCODE = Invoke-External $godot @("--headless", "--path", $projectRoot, "--import")
if ($LASTEXITCODE -ne 0) {
	throw "Godot project import failed with exit code $LASTEXITCODE"
}

$global:LASTEXITCODE = Invoke-External $godot @("--headless", "--path", $projectRoot, "--export-release", "Windows Desktop", $exePath)
if ($LASTEXITCODE -ne 0) {
	throw "Windows export failed with exit code $LASTEXITCODE"
}
if (-not (Test-Path -LiteralPath $exePath)) {
	throw "Export failed: $exePath not found"
}
Write-Host "Exported: $exePath"

$global:LASTEXITCODE = Invoke-External $iscc @($issFile)
if ($LASTEXITCODE -ne 0) {
	throw "Inno Setup build failed with exit code $LASTEXITCODE"
}

$setupPath = Join-Path $projectRoot "dist\Businessman-Setup-$major.$minor.exe"
if (-not (Test-Path -LiteralPath $setupPath)) {
	throw "Installer build failed: $setupPath not found"
}
Write-Host "Installer: $setupPath"

if (-not $NoBump) {
	$next = "$major.$($minor + 1)"
	[System.IO.File]::WriteAllText($versionFile, $next, [System.Text.Encoding]::ASCII)
	Write-Host "Next build version: $next"
}
