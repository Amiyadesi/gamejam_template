[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$GodotSource,
	[string]$Scons = "scons",
	[int]$Jobs = [Environment]::ProcessorCount
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = (Resolve-Path -LiteralPath $GodotSource).Path
$sconstructPath = Join-Path $sourceRoot "SConstruct"
$versionPath = Join-Path $sourceRoot "version.py"
$profilePath = Join-Path $repoRoot "build_profiles/windows_small.gdbuild"

if (-not (Test-Path -LiteralPath $sconstructPath)) {
	throw "GodotSource must point to a Godot source checkout containing SConstruct."
}

$versionText = Get-Content -Raw -LiteralPath $versionPath
$isGodot47Stable = (
	$versionText -match "(?m)^major = 4$" -and
	$versionText -match "(?m)^minor = 7$" -and
	$versionText -match '(?m)^status = "stable"$'
)
if (-not $isGodot47Stable) {
	throw "The small template profile is validated only against Godot 4.7-stable."
}

if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) {
	$vswherePath = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio/Installer/vswhere.exe"
	if (-not (Test-Path -LiteralPath $vswherePath)) {
		throw "Visual Studio Build Tools with the C++ workload are required."
	}
	$visualStudioPath = & $vswherePath -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
	if ([string]::IsNullOrWhiteSpace($visualStudioPath)) {
		throw "Visual Studio Build Tools with the C++ workload are required."
	}
	$devShellPath = Join-Path $visualStudioPath "Common7/Tools/Launch-VsDevShell.ps1"
	& $devShellPath -Arch amd64 -HostArch amd64 -SkipAutomaticLocation
}

$sconsCommand = Get-Command $Scons -ErrorAction Stop
$arguments = @(
	"-C", $sourceRoot,
	"-j$([Math]::Max(1, $Jobs))",
	"platform=windows",
	"target=template_release",
	"arch=x86_64",
	"production=yes",
	"optimize=size_extra",
	"lto=full",
	"debug_symbols=no",
	"build_profile=$profilePath"
)

& $sconsCommand.Source @arguments
if ($LASTEXITCODE -ne 0) {
	throw "Godot export template build failed with exit code $LASTEXITCODE."
}

$builtTemplate = Join-Path $sourceRoot "bin/godot.windows.template_release.x86_64.exe"
if (-not (Test-Path -LiteralPath $builtTemplate)) {
	throw "SCons completed without producing the expected Windows release template."
}

$templateDirectory = Join-Path $repoRoot "custom_templates"
$templatePath = Join-Path $templateDirectory "windows_release.exe"
New-Item -ItemType Directory -Force -Path $templateDirectory | Out-Null
Copy-Item -LiteralPath $builtTemplate -Destination $templatePath -Force

$templateSize = (Get-Item -LiteralPath $templatePath).Length
Write-Output "Small Windows template: $templatePath ($templateSize bytes)"
