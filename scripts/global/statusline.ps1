# SREDNOFF OS statusline: shows ACTIVE (green) / OFF (red) for the current project.
# Wired via settings.json "statusLine". Reads JSON on stdin, prints ONE colored line.
# ASCII-only (PS 5.1 safe). ANSI colors render in the status bar.
$ErrorActionPreference = "SilentlyContinue"

$raw = [Console]::In.ReadToEnd()
$cwd = $null; $model = ""
if ($raw) {
  try {
    $j = $raw | ConvertFrom-Json
    $cwd = $j.workspace.current_dir
    if (-not $cwd) { $cwd = $j.cwd }
    $model = $j.model.display_name
  } catch {}
}
if (-not $cwd) { $cwd = (Get-Location).Path }

$e = [char]27
$green = "$e[92m"; $red = "$e[91m"; $cyan = "$e[96m"; $dim = "$e[2m"; $bold = "$e[1m"; $reset = "$e[0m"

$name = Split-Path -Leaf $cwd
$rootGuard = if ($env:SREDNOFF_OS_ROOT) { $env:SREDNOFF_OS_ROOT } else { $HOME }
$inWorkspace = ($cwd -like "$rootGuard*") -and ($cwd.TrimEnd('\') -ine $rootGuard.TrimEnd('\'))
$hasOS = Test-Path (Join-Path $cwd ".claude\rules\00-operating-system.md")

$label = "${bold}${cyan}SREDNOFF OS${reset}"

if (-not $inWorkspace) {
  Write-Output "$label ${dim}(outside workspace)${reset}"
  exit 0
}

if ($hasOS) {
  $tags = ""
  $lock = Join-Path $cwd ".claude\PROFILE.lock.md"
  if (Test-Path $lock) {
    $m = Select-String -Path $lock -Pattern '^`([^`]+)`$' | Select-Object -First 1
    if ($m) { $tags = $m.Matches[0].Groups[1].Value }
  }
  $line = "$label ${green}* ACTIVE${reset} ${dim}|${reset} $name"
  if ($model) { $line += " ${dim}|${reset} $model" }
  if ($tags) { $line += " ${dim}| ${tags}${reset}" }
  Write-Output $line
} else {
  Write-Output "$label ${red}o OFF${reset} ${dim}|${reset} $name ${dim}(run init)${reset}"
}
exit 0
