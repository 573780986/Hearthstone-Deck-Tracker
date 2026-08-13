[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (Test-Path "nuget.exe") {
	Invoke-Expression "./nuget restore"
}
elseif((Get-Command "nuget" -ErrorAction SilentlyContinue) -ne $null) {
	nuget restore
}
else {
	"Nuget was not found and is required to run bootstrap.ps. Download and retry now?"
	choice /c yn
	if ($LASTEXITCODE -eq 1) {
		"Downloading nuget..."
		$nugetLocation = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
		(New-Object Net.WebClient).DownloadFile($nugetLocation, "$PSScriptRoot\nuget.exe")
		Invoke-Expression "./nuget restore"
	}
}

try {
	git --version
}
catch {
	"Git was not found and is required to run bootstrap.bat. Download git from https://git-scm.com/download and during installation choose `"Use Git from the Windows Command Prompt`"."
}

# ============ Locate MSBuild.exe ============
$msbuild = $null
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
	try {
		$msbuild = & $vswhere -latest -products '*' -prerelease -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' 2>$null
	} catch { }
}
if (-not $msbuild -or -not (Test-Path $msbuild)) {
	$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
}
if (-not $msbuild -or -not (Test-Path $msbuild)) {
	$cmdMsbuild = Get-Command msbuild -ErrorAction SilentlyContinue
	if ($cmdMsbuild) {
		$msbuild = $cmdMsbuild.Source
	}
}
if (-not $msbuild -or -not (Test-Path $msbuild)) {
	throw "MSBuild.exe not found. Tried: (1) vswhere, (2) hardcoded VS18 path, (3) system PATH. Please install Visual Studio Build Tools or set up VS Developer Environment."
}
"Using MSBuild: $msbuild"

# Build Bootstrap.csproj first (used by Hearthstone Deck Tracker build)
& $msbuild Bootstrap/Bootstrap.csproj /p:Configuration=Debug
if ($LASTEXITCODE -ne 0) { throw "Bootstrap.csproj build failed (exit $LASTEXITCODE)" }

# Build main Hearthstone Deck Tracker project
& $msbuild 'Hearthstone Deck Tracker/Hearthstone Deck Tracker.csproj' /p:Configuration=Debug
if ($LASTEXITCODE -ne 0) { throw "Hearthstone Deck Tracker.csproj build failed (exit $LASTEXITCODE)" }
