#Requires -Version 5.1
param(
	[switch]$KeepBuild
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = "C:\Users\bikee\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
$webBuildDir = Join-Path $projectRoot "build\web"
$indexHtml = Join-Path $webBuildDir "index.html"
$finalZipPath = Join-Path $webBuildDir "Businessman-web.zip"
$tempZipPath = Join-Path $env:TEMP "Businessman-web.zip"

if (-not (Test-Path -LiteralPath $godot)) {
	throw "Godot executable not found: $godot"
}

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

$godotExeName = [System.IO.Path]::GetFileName($godot)
# Expected filename: Godot_v4.7.2-stable_win64.exe -> template folder 4.7.2.stable
if ($godotExeName -notmatch 'Godot_v(\d+\.\d+\.\d+)-stable') {
	throw "Cannot determine Godot version from executable name: $godotExeName"
}
$godotVersion = "$($Matches[1]).stable"
$templatesDir = Join-Path $env:APPDATA "Godot\export_templates\$godotVersion"
$webTemplates = @(Get-ChildItem -Path (Join-Path $templatesDir "web_release*.zip") -ErrorAction SilentlyContinue)
if ($webTemplates.Count -eq 0) {
	throw "Web export templates not found in '$templatesDir'. Please install Web export templates for Godot $godotVersion."
}

Write-Host "Importing project..."
$global:LASTEXITCODE = Invoke-External $godot @("--headless", "--path", $projectRoot, "--import")
if ($LASTEXITCODE -ne 0) {
	throw "Godot project import failed with exit code $LASTEXITCODE"
}

if (-not $KeepBuild) {
	if (Test-Path -LiteralPath $webBuildDir) {
		Remove-Item -LiteralPath $webBuildDir -Recurse -Force
	}
}
New-Item -ItemType Directory -Path $webBuildDir -Force | Out-Null

Write-Host "Exporting Web build..."
$global:LASTEXITCODE = Invoke-External $godot @("--headless", "--path", $projectRoot, "--export-release", "Web", $indexHtml)
if ($LASTEXITCODE -ne 0) {
	throw "Web export failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $indexHtml)) {
	throw "Web export failed: $indexHtml not found"
}

$files = @(Get-ChildItem -Path $webBuildDir -File)
if ($files.Count -eq 0) {
	throw "Web export produced no files in $webBuildDir"
}

# Remove any previous archive so it is not packed into the new archive
if (Test-Path -LiteralPath $finalZipPath) {
	Remove-Item -LiteralPath $finalZipPath -Force
}
if (Test-Path -LiteralPath $tempZipPath) {
	Remove-Item -LiteralPath $tempZipPath -Force
}

Compress-Archive -Path (Join-Path $webBuildDir "*") -DestinationPath $tempZipPath -CompressionLevel Optimal

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($tempZipPath)
try {
	$hasIndexAtRoot = $false
	$hasNestedZip = $false
	foreach ($entry in $zip.Entries) {
		if ($entry.FullName -eq "index.html") {
			$hasIndexAtRoot = $true
		}
		if ($entry.FullName -like "*.zip") {
			$hasNestedZip = $true
		}
	}
	if (-not $hasIndexAtRoot) {
		throw "Archive validation failed: index.html is not at the root of the zip"
	}
	if ($hasNestedZip) {
		throw "Archive validation failed: zip contains nested archive(s)"
	}
} finally {
	$zip.Dispose()
}

Move-Item -LiteralPath $tempZipPath -Destination $finalZipPath -Force

$zipSize = (Get-Item -LiteralPath $finalZipPath).Length
Write-Host "Exported Web build to: $webBuildDir"
Write-Host "Created archive: $finalZipPath ($([math]::Round($zipSize / 1MB, 2)) MB)"

Write-Host ""
Write-Host "=== itch.io upload instructions ==="
Write-Host "1. Upload '$finalZipPath' to your itch.io project."
Write-Host "2. Mark the uploaded file as 'This file will be played in the browser'."
Write-Host "3. Set viewport / canvas size to 1280x720 if prompted."
Write-Host "4. This build has thread_support=false, so SharedArrayBuffer / COOP-COEP headers are NOT required."
Write-Host "==================================="
