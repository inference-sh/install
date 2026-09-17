# belt installer for Windows.
#   irm https://cli.inference.sh/install.ps1 | iex
# Pin a version with:  $env:VERSION = "v1.18.35"
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$version = if ($env:VERSION) { $env:VERSION } else { "latest" }
$installDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { Join-Path $HOME ".local\bin" }

# No native windows-arm64 build yet; the amd64 build runs under emulation.
$key = "windows-amd64"

$manifestUrl = if ($version -eq "latest") {
  "https://dist.inference.sh/cli/manifest.json"
} else {
  "https://dist.inference.sh/cli/$version/manifest.json"
}

try {
  $manifest = Invoke-RestMethod -Uri $manifestUrl
} catch {
  throw "version $version not found ($manifestUrl): $($_.Exception.Message)"
}

$build = $manifest.builds.$key
if (-not $build) { throw "no build for $key in $manifestUrl" }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("belt-install-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
  $zip = Join-Path $tmp "belt.zip"
  Write-Host "downloading cli $($manifest.version) for $key..."
  Invoke-WebRequest -Uri $build.url -OutFile $zip -UseBasicParsing

  Write-Host "verifying checksum..."
  $actual = (Get-FileHash -Path $zip -Algorithm SHA256).Hash.ToLower()
  if ($build.sha256 -and $actual -ne $build.sha256.ToLower()) {
    throw "checksum mismatch: expected $($build.sha256), got $actual"
  }

  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  $exe = Get-ChildItem -Path $tmp -Filter *.exe | Select-Object -First 1
  if (-not $exe) { throw "no .exe found in $($build.url)" }

  New-Item -ItemType Directory -Path $installDir -Force | Out-Null
  $names = @("inferencesh") + @($manifest.aliases)
  if ($names.Count -eq 1) { $names += @("belt", "infsh") }
  foreach ($name in ($names | Select-Object -Unique)) {
    $dest = Join-Path $installDir "$name.exe"
    # A running exe cannot be overwritten but can be renamed aside.
    if (Test-Path $dest) {
      $old = "$dest.old"
      Remove-Item $old -Force -ErrorAction SilentlyContinue
      Rename-Item -Path $dest -NewName (Split-Path $old -Leaf) -Force
    }
    Copy-Item -Path $exe.FullName -Destination $dest -Force
    Remove-Item "$dest.old" -Force -ErrorAction SilentlyContinue
  }
} finally {
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

$userPath = "" + [Environment]::GetEnvironmentVariable("Path", "User")
if (-not (($userPath -split ";") -contains $installDir)) {
  [Environment]::SetEnvironmentVariable("Path", (($userPath.TrimEnd(";") + ";" + $installDir).TrimStart(";")), "User")
  $env:Path = "$env:Path;$installDir"
  Write-Host "added $installDir to your user PATH (new terminals pick it up)"
}

Write-Host "installed to $installDir"
Write-Host "run 'belt login' to get started"
