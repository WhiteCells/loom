param(
    [ValidateSet('Debug', 'Release', 'RelWithDebInfo', 'MinSizeRel')]
    [string]$Config = 'Release',
    [string]$BuildDir,
    [string]$DistDir,
    [string]$Generator,
    [string]$QtPrefix,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir '..')
$AppTarget = 'LoomDesktop'

if (-not $BuildDir) {
    $BuildDir = Join-Path $ProjectRoot 'build/package-windows'
}

if (-not $DistDir) {
    $DistDir = Join-Path $ProjectRoot 'dist'
}

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name is required."
    }
}

function Get-ProjectVersion {
    $cmakeFile = Join-Path $ProjectRoot 'CMakeLists.txt'
    $match = Select-String -Path $cmakeFile -Pattern 'project\(LoomDesktop VERSION ([^\s\)]+)' | Select-Object -First 1
    if (-not $match) {
        throw 'Unable to read project version from CMakeLists.txt.'
    }
    return $match.Matches[0].Groups[1].Value
}

Require-Command cmake

if (-not $Generator -and (Get-Command ninja -ErrorAction SilentlyContinue)) {
    $Generator = 'Ninja'
}

$Version = Get-ProjectVersion
$Arch = if ($env:PROCESSOR_ARCHITECTURE) { $env:PROCESSOR_ARCHITECTURE.ToLowerInvariant() } else { 'unknown' }
$PackageName = "$AppTarget-$Version-windows-$Arch"
$StageParent = Join-Path $DistDir 'stage'
$StageDir = Join-Path $StageParent $PackageName
$ArchivePath = Join-Path $DistDir "$PackageName.zip"

if ($Clean -and (Test-Path $BuildDir)) {
    Remove-Item $BuildDir -Recurse -Force
}

$ConfigureArgs = @(
    '-S', $ProjectRoot,
    '-B', $BuildDir,
    "-DCMAKE_BUILD_TYPE=$Config"
)

if ($Generator) {
    $ConfigureArgs += @('-G', $Generator)
}

if ($QtPrefix) {
    $ConfigureArgs += "-DCMAKE_PREFIX_PATH=$QtPrefix"
}

& cmake @ConfigureArgs
& cmake --build $BuildDir --config $Config --parallel

if (Test-Path $StageDir) {
    Remove-Item $StageDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $StageDir | Out-Null
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

& cmake --install $BuildDir --config $Config --prefix $StageDir

if (Test-Path $ArchivePath) {
    Remove-Item $ArchivePath -Force
}

Compress-Archive -Path $StageDir -DestinationPath $ArchivePath -Force

Write-Host 'Package created:'
Write-Host "  $ArchivePath"
