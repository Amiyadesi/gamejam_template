[CmdletBinding()]
param(
	[string]$GodotPath = "",
	[switch]$ReleaseReadiness
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

function Invoke-ReleaseReadiness {
	$failures = [System.Collections.Generic.List[string]]::new()
	$warnings = [System.Collections.Generic.List[string]]::new()
	$projectText = Get-Content -LiteralPath (Join-Path $repoRoot "project.godot") -Raw
	$menuText = Get-Content -LiteralPath (Join-Path $repoRoot "Scenes/UI/Menu/menu.tscn") -Raw

	if ($projectText -match 'config/name="Game Jam Template"') {
		$failures.Add("project.godot still uses the default project name.")
	}

	$entryMatch = [regex]::Match($menuText, '(?m)^start_scene_path\s*=\s*"([^"]*)"')
	if (-not $entryMatch.Success -or [string]::IsNullOrWhiteSpace($entryMatch.Groups[1].Value)) {
		$failures.Add("Menu.start_scene_path does not define a game entry scene.")
	} else {
		$entryPath = $entryMatch.Groups[1].Value -replace '^res://', ''
		if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $entryPath))) {
			$failures.Add("Menu.start_scene_path points to a missing scene: $($entryMatch.Groups[1].Value)")
		}
	}

	$textExtensions = @('.gd', '.tscn', '.tres', '.godot', '.cfg', '.md', '.json', '.ps1')
	$textFiles = Get-ChildItem -LiteralPath $repoRoot -Recurse -File | Where-Object {
		$_.FullName -notmatch '[\\/]\.godot[\\/]' -and
		$_.FullName -notmatch '[\\/]tools[\\/]verify_template\.ps1$' -and
		$textExtensions -contains $_.Extension.ToLowerInvariant()
	}
	$godotReferences = @($textFiles | Select-String -Pattern 'res://\.godot/' -SimpleMatch:$false)
	if ($godotReferences.Count -gt 0) {
		$failures.Add("Project files still reference res://.godot/.")
	}

	$projectCodeFiles = Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Filter '*.gd' | Where-Object {
		$_.FullName -notmatch '[\\/]addons[\\/]' -and
		$_.FullName -notmatch '[\\/]tests[\\/]' -and
		$_.FullName -notmatch '[\\/]demo[\\/]' -and
		$_.FullName -notmatch '[\\/]Scenes[\\/]Autoload[\\/]game_audio\.gd$'
	}
	$directSoundManagerCalls = @($projectCodeFiles | Select-String -Pattern '(?m)^(?!\s*#).*SoundManager\.')
	if ($directSoundManagerCalls.Count -gt 0) {
		$failures.Add("Project code calls SoundManager outside Scenes/Autoload/game_audio.gd.")
	}

	$runtimeFiles = Get-ChildItem -LiteralPath (Join-Path $repoRoot "Dialogue/Runtime") -Recurse -File -ErrorAction SilentlyContinue
	$runtimeDemoReferences = @($runtimeFiles | Select-String -Pattern 'Dialogue/Examples|res://demo/')
	if ($runtimeDemoReferences.Count -gt 0) {
		$failures.Add("Dialogue/Runtime still references demo paths.")
	}

	if (Test-Path -LiteralPath (Join-Path $repoRoot "addons/limboai")) {
		$warnings.Add("LimboAI is present; remove addons/limboai and demo from copied projects when unused.")
	}
	if (Test-Path -LiteralPath (Join-Path $repoRoot "Dialogue/Examples/demo")) {
		$warnings.Add("Dialogue demo content is present and should stay excluded from release exports.")
	}
	if (Test-Path -LiteralPath (Join-Path $repoRoot "addons/project-time-tracker")) {
		$warnings.Add("Project Time Tracker is retained but disabled; confirm whether the copied project needs it.")
	}

	foreach ($warning in $warnings) {
		Write-Warning $warning
	}
	if ($failures.Count -gt 0) {
		foreach ($failure in $failures) {
			Write-Error $failure -ErrorAction Continue
		}
		throw "Release readiness failed with $($failures.Count) error(s)."
	}
	Write-Output "Release readiness checks passed."
}

try {
	if ($ReleaseReadiness) {
		Invoke-ReleaseReadiness
	}
	Invoke-GodotCheck -Name "Editor parse" -Arguments @("--headless", "--editor", "--path", $repoRoot, "--quit")
	Invoke-GodotCheck -Name "Regression tests" -Arguments @("--headless", "--path", $repoRoot, "--script", "res://tests/run_regressions.gd")
	Invoke-GodotCheck -Name "Menu smoke" -Arguments @("--headless", "--path", $repoRoot, "--scene", "res://Scenes/UI/Menu/menu.tscn", "--quit-after", "5")
	Write-Output "Template verification passed."
} finally {
	if (Test-Path -LiteralPath $tempRoot) {
		Remove-Item -LiteralPath $tempRoot -Recurse -Force
	}
}
