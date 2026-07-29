[CmdletBinding()]
param(
	[string]$GodotPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
	$godotCommand = Get-Command godot -ErrorAction SilentlyContinue
	if ($null -eq $godotCommand) {
		throw "Godot was not found on PATH. Pass -GodotPath with a Godot 4.7 console executable."
	}
	$GodotPath = $godotCommand.Source
} elseif (Test-Path -LiteralPath $GodotPath) {
	$GodotPath = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
	$godotCommand = Get-Command $GodotPath -ErrorAction SilentlyContinue
	if ($null -eq $godotCommand) {
		throw "GodotPath does not reference an executable or command."
	}
	$GodotPath = $godotCommand.Source
}

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempRoot = [IO.Path]::GetFullPath((Join-Path $tempBase ("gamejam-template-verify-" + [guid]::NewGuid().ToString("N"))))
if (-not $tempRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) {
	throw "Verification temp directory escaped the system temp root."
}

New-Item -ItemType Directory -Force -Path (Join-Path $tempRoot "Roaming"), (Join-Path $tempRoot "Local") | Out-Null
$env:APPDATA = Join-Path $tempRoot "Roaming"
$env:LOCALAPPDATA = Join-Path $tempRoot "Local"

function Invoke-GodotCheck {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Name,
		[Parameter(Mandatory = $true)]
		[string[]]$Arguments
	)

	Write-Output "== $Name =="
	$output = @(& $GodotPath @Arguments 2>&1)
	$output | ForEach-Object { Write-Output $_ }
	if ($LASTEXITCODE -ne 0) {
		throw "$Name failed with exit code $LASTEXITCODE."
	}
	$runtimeErrors = @($output | Where-Object {
		$_ -match "SCRIPT ERROR:" -or
		$_ -match "ERROR: (Cannot open file|Failed loading resource|Failed to load script|Node not found)"
	})
	if ($runtimeErrors.Count -gt 0) {
		throw "$Name emitted script or resource errors."
	}
}

try {
	Invoke-GodotCheck -Name "Editor parse" -Arguments @("--headless", "--editor", "--path", $repoRoot, "--quit")
	Invoke-GodotCheck -Name "Regression tests" -Arguments @("--headless", "--path", $repoRoot, "--script", "res://tests/run_regressions.gd")
	Invoke-GodotCheck -Name "Menu smoke" -Arguments @("--headless", "--path", $repoRoot, "--scene", "res://Scenes/UI/Menu/menu.tscn", "--quit-after", "5")
	Write-Output "Template verification passed."
} finally {
	if (Test-Path -LiteralPath $tempRoot) {
		Remove-Item -LiteralPath $tempRoot -Recurse -Force
	}
}
