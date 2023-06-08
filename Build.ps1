Write-Host "Install InvokeBuild module if not already installed"  
if (-not(Get-Module InvokeBuild -ListAvailable)) {
    Install-Module InvokeBuild -Scope CurrentUser
}

# Build header
Write-Host "=============================================================================="
Write-Host "                           Building Web Application                             "
Write-Host "=============================================================================="
Write-Host ""

# Set working directory to aspnet-core folder
Set-Location .\aspnet-core	

Write-Host "Check if SDK 5.0 is installed"
if (Get-Command dotnet.exe -ErrorAction SilentlyContinue) {
    Write-Host "SDK 5.0 is already installed" -ForegroundColor Green
}
else {
    Write-Host "Step 1: Installing SDK 5.0" -ForegroundColor Yellow
    $dotnetInstallerUrl = "https://dot.net/v1/dotnet-install.ps1"
    $installerScriptPath = Join-Path $env:TEMP "dotnet-install.ps1"
    Invoke-WebRequest -Uri $dotnetInstallerUrl -OutFile $installerScriptPath
    & $installerScriptPath -Channel 5.0 -InstallDir $env:ProgramFiles\dotnet
    [Environment]::SetEnvironmentVariable("DOTNET_ROOT", "$env:ProgramFiles\dotnet", "Machine")
    $env:PATH += ";$env:ProgramFiles\dotnet"
    Write-Host "SDK 5.0 has been installed and environment variables set" -ForegroundColor Green
}


Write-Host "Check if MSBuild is installed"
if (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe") {
    Write-Host "MSBuild is already installed" -ForegroundColor Green
}
else {
    Write-Host "Step 2: Installing MSBuild" -ForegroundColor Yellow
    $msbuildInstallerUrl = "https://aka.ms/vs/16/release/vs_buildtools.exe"
    $msbuildInstallerPath = ".\vs_buildtools.exe"
    Invoke-WebRequest -Uri $msbuildInstallerUrl -OutFile $msbuildInstallerPath
    Start-Process -FilePath ".\vs_buildtools.exe" -ArgumentList 
}

Write-Host "Check if NuGet is installed"
$nugetExeUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$nugetExePath = Join-Path $env:TEMP "nuget.exe"
$packages = @(
    'Abp.AspNetCore:6.3.0',
    'Abp.AspNetZeroCore.Web:3.0.0',
    'Microsoft.AspNetCore.Http:2.2.2',
    'Microsoft.Extensions.Configuration:5.0.0',
    'Microsoft.Extensions.Configuration.Json:5.0.0',
    'TimeZoneConverter:6.0.1'
)

# Configure NuGet package sources
$nugetSourceUrl = "https://api.nuget.org/v3/index.json"
$packageSources = @(
    "https://api.nuget.org/v3/index.json",
    "https://www.nuget.org/api/v2/"
)

# Download nuget.exe
Invoke-WebRequest -Uri $nugetExeUrl -OutFile $nugetExePath

# Set NuGet package sources
& $nugetExePath sources Add -Name "NuGet" -Source $nugetSourceUrl | Out-Null
& $nugetExePath config -Set globalPackagesFolder=.\packages

# Install NuGet packages
$packages | ForEach-Object {
    $packageParts = $_ -split ':'
    $packageName = $packageParts[0]
    $packageVersion = $packageParts[1]
    
    Write-Host "Installing package: $packageName ($packageVersion)"
    
    & $nugetExePath install $packageName -Version $packageVersion -Source $packageSources -OutputDirectory "packages"
}

Write-Host "NuGet packages have been installed."



# Restore NuGet packages
Write-Host "Step 4: Restoring NuGet Packages" -ForegroundColor Yellow
nuget restore EPIC.Simplifyi3.Web.sln

# Set working directory to parent folder
Set-Location ..

# Set working directory to angular folder
Set-Location .\angular

# Check if Node.js is installed
if (!(Get-Command node)) {
    Write-Host "Step 5: Installing Node.js" -ForegroundColor Yellow
    Invoke-WebRequest -Uri https://nodejs.org/dist/v14.16.0/node-v14.16.0-x64.msi -OutFile node-v14.16.0-x64.msi
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "node-v14.16.0-x64.msi", "/quiet", "/qn", "/norestart" -Wait
}
Set-Location ..
Set-Location .\Libs
# Copy Pre npm files
Write-Host "Step 6: Copying Files" -ForegroundColor Yellow
.\CopyFiles_Pre_npm_install.ps1

Set-Location ..
# Set working directory to angular folder
Set-Location .\angular

Write-Host "Step 7: Installing Angular CLI" -ForegroundColor Yellow

# Check if the 'ng' command is recognized
if (!(Test-Path "$env:APPDATA\npm\ng.cmd")) {
    # Install the latest version of Angular CLI globally
    npm install -g @angular/cli
}

# Add the npm global package path to the system's PATH environment variable
$npmGlobalPath = Join-Path $env:APPDATA "npm"
$env:PATH += ";$npmGlobalPath"

# Check if the 'ng' command is now recognized
if (Test-Path "$env:APPDATA\npm\ng.cmd") {
    Write-Host "Angular CLI has been installed successfully" -ForegroundColor Green
} else {
    Write-Host "Failed to install Angular CLI" -ForegroundColor Red
}


Write-Host "Step 8: npm install " -ForegroundColor Yellow
npm install
Set-Location ..
Set-Location .\Libs
#Copy Post npm files
Write-Host "Step 9: Copying Files" -ForegroundColor Yellow
.\CopyFiles_Post_npm_install.ps1
Set-Location ..
Set-Location .\angular

# Publish npm
Write-Host "Step 10: Publishing npm" -ForegroundColor Yellow
npm run publish --aot=true --optimization=true

# Set working directory to parent folder
Set-Location ..
Write-Host "=============================================================================="
Write-Host "                           Building API                           "
Write-Host "=============================================================================="
Write-Host ""	
Write-Host "Install SDK5.0" -ForegroundColor Green
winget install Microsoft.DotNet.SDK.5
Write-Host "Dotnet Restore" -ForegroundColor Green
Set-Location .\aspnet-core\src\EPIC.Simplifyi3.Web.Host
dotnet restore EPIC.Simplifyi3.Web.Host.csproj
Write-Host "Dotnet Publish" -ForegroundColor Green
dotnet publish EPIC.Simplifyi3.Web.Host.csproj
Set-Location ..
Write-Host "=============================================================================="
Write-Host "                           Building Scheduler                           "
Write-Host "=============================================================================="
Write-Host ""		
Write-Host "Dotnet Restore" -ForegroundColor Green
Set-Location .\EPIC.Simplifyi3.SchedulerService
dotnet restore EPIC.Simplifyi3.SchedulerService.csproj
Write-Host "Dotnet Publish" -ForegroundColor Green
dotnet publish EPIC.Simplifyi3.SchedulerService.csproj
