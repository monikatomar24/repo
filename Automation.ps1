Write-Host "Import JSON File"

$jsonFile = ".\localsetupconfig.json"
$json = Get-Content $jsonFile | ConvertFrom-Json

Write-Host "Check if git is already installed"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Install git"
    $url = "https://github.com/git-for-windows/git/releases/download/v2.32.0.windows.2/Git-2.32.0.2-64-bit.exe"
    $output = "git.exe"
    Invoke-WebRequest -Uri $url -OutFile $output
    Start-Process -FilePath $output -ArgumentList "/VERYSILENT", "/NORESTART"
    $env:PATH += ";C:\Program Files\Git\bin"
}

Write-Host "Clone repository"
if (-not (Test-Path "Simplifyi3_R2")) {
    git clone --branch dev --single-branch https://epicdevops.epicgroupllc.net/EPIC_Projects/Simplify%20i3%20V2/_git/Simplifyi3_R2
}

Write-Host "Copy the file"
 if (Test-Path -Path ".\Simplifyi3_R2\Build.ps1") {
     Write-Host "File already exists in the destination folder. Skipping copy."
 } else {
 
     Move-Item -Path ".\Build.ps1" -Destination ".\Simplifyi3_R2"
     Write-Host "File copied successfully to the destination folder."
 }

#Load configuration from JSON file
 $config = Get-Content .\localsetupconfig.json -Raw | ConvertFrom-Json
# Check if InvokeBuild module is installed
if (-not (Get-Module -Name InvokeBuild -ListAvailable)) {
    # Install the module
    Install-Module -Name InvokeBuild -Scope CurrentUser -Force
}


Write-Host "Build ASP.NET Core web application"
 Write-Host "Running Build file..."
 #Start-Process localsetup.bat
 #Start-Sleep -Seconds 2000

 # Copy artifacts to the Web folder
$webArtifactsPath = ".\Simplifyi3_R2\angular\dist"
$webDestinationPath = "C:\inetpub\wwwroot\Web"
Copy-Item -Path $webArtifactsPath -Destination $webDestinationPath -Recurse -Force

# Copy artifacts to the WebAPI folder
$webApiArtifactsPath = ".\Simplifyi3_R2\aspnet-core\src\EPIC.Simplifyi3.Web.Host\bin\Release\net5.0"
$webApiDestinationPath = "C:\inetpub\wwwroot\WebAPI"
Copy-Item -Path $webApiArtifactsPath -Destination $webApiDestinationPath -Recurse -Force


# Fetch the IP address of the system
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq "Wi-Fi" }).IPAddress

# Specify the file paths
$jsonFilePath = "C:\inetpub\wwwroot\Web\dist\assets\appconfig.json"
$prodFilePath = "C:\inetpub\wwwroot\Web\dist\assets\appconfig.production.json"
$appsettingFilePath = "C:\inetpub\wwwroot\WebAPI\net5.0\appsettings.json"
$productionFilePath = "C:\inetpub\wwwroot\WebAPI\net5.0\appsettings.Production.json"
$stagingFilePath = "C:\inetpub\wwwroot\WebAPI\net5.0\appsettings.Staging.json"

# Update the appconfig.json file
Write-Host "Updating the appconfig.json file..."
if (Test-Path $jsonFilePath) {
    $jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json
    $jsonContent.remoteServiceBaseUrl = "https://$ipAddress`:8081"
    $jsonContent.reportServiceBaseUrl = "https://$ipAddress`:8081"
    $jsonContent.appBaseUrl = "https://$ipAddress`:8082"
    $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonFilePath
} else {
    Write-Host "File '$jsonFilePath' not found. Skipping update."
}

# Update the appconfig.production.json file
Write-Host "Updating the appconfig.production.json file..."
if (Test-Path $prodFilePath) {
    $prodContent = Get-Content -Path $prodFilePath | ConvertFrom-Json
    $prodContent.remoteServiceBaseUrl = "https://$ipAddress`:8081"
    $prodContent.reportServiceBaseUrl = "https://$ipAddress`:8081"
    $prodContent.appBaseUrl = "https://$ipAddress`:8082"
    $prodContent | ConvertTo-Json -Depth 10 | Set-Content -Path $prodFilePath
} else {
    Write-Host "File '$prodFilePath' not found. Skipping update."
}

# Update the appsettings.json file
Write-Host "Updating the appsettings.json file..."
if (Test-Path $appsettingFilePath) {
    $appsettingContent = Get-Content -Path $appsettingFilePath | ConvertFrom-Json
    $appsettingContent.ConnectionStrings.Default = "User ID=postgres;Password=123;Host=localhost;Port=5432;Database=qa0505;Pooling=true;"
    $appsettingContent.App.ServerRootAddress = "https://$ipAddress`:8081"
    $appsettingContent.App.ClientRootAddress = "https://$ipAddress`:8082"
    $appsettingContent.App.CorsOrigins = "http:"
    $appsettingContent.IdentityServer.Authority = "https://$ipAddress`:8081"
    $appsettingContent.HealthChecks.HealthChecksUI.HealthChecks[0].Uri = "https://$ipAddress`:8082/health"
    $appsettingContent.Elsa.Http.BaseUrl = "https://$ipAddress`:8081"
    $appsettingContent | ConvertTo-Json -Depth 10 | Set-Content -Path $appsettingFilePath
} else {
    Write-Host "File '$appsettingFilePath' not found. Skipping update."
}

# Update the appsettings.Production.json file
Write-Host "Updating the appsettings.Production.json file..."
if (Test-Path $productionFilePath) {
    $productionContent = Get-Content -Path $productionFilePath | ConvertFrom-Json
    $productionContent.ConnectionStrings.Default = "User ID=postgres;Password=123;Host=localhost;Port=5432;Database=qa0505;Pooling=true;"
    $productionContent.App.ServerRootAddress = "https://$ipAddress`:8081"
    $productionContent.App.ClientRootAddress = "https://$ipAddress`:8082"
    $productionContent.App.CorsOrigins = "https://$ipAddress`:8081/,https://$ipAddress`:8082/"
    $productionContent | ConvertTo-Json -Depth 10 | Set-Content -Path $productionFilePath
} else {
    Write-Host "File '$productionFilePath' not found. Skipping update."
}

# Update the appsettings.Staging.json file
Write-Host "Updating the appsettings.Staging.json file..."
if (Test-Path $stagingFilePath) {
    $stagingContent = Get-Content -Path $stagingFilePath | ConvertFrom-Json
    $stagingContent.ConnectionStrings.Default = "User ID=postgres;Password=123;Host=localhost;Port=5432;Database=qa0505;Pooling=true;"
    $stagingContent.App.ServerRootAddress = "https://$ipAddress`:8081"
    $stagingContent.App.ClientRootAddress = "https://$ipAddress`:8082"
    $stagingContent.App.CorsOrigins = "https://$ipAddress`:8081/,https://$ipAddress`:8082/"
    $stagingContent | ConvertTo-Json -Depth 10 | Set-Content -Path $stagingFilePath
} else {
    Write-Host "File '$stagingFilePath' not found. Skipping update."
}

Write-Host "Update completed successfully."

$configurationFile = ".\localsetupconfig.json"

# Check if IIS is already installed
$checkIIS = dism /Online /Get-FeatureInfo /FeatureName:IIS-WebServerRole

if ($checkIIS -match "State : Disabled") {
    # Install IIS
    dism /Online /Enable-Feature /FeatureName:IIS-WebServerRole /All

    # Verify the installation
    $checkIIS = dism /Online /Get-FeatureInfo /FeatureName:IIS-WebServerRole
    if ($checkIIS -match "State : Enabled") {
        Write-Host "IIS installation completed successfully."
    } else {
        Write-Host "IIS installation failed."
    }
} else {
    Write-Host "IIS is already installed."
}




# Create the application pools if they don't exist
foreach ($appPool in $json.AppPools) {
    if (Get-Item "IIS:\AppPools\$($appPool.Name)" -ErrorAction SilentlyContinue) {
        Write-Warning "Application pool '$($appPool.Name)' already exists."
    } else {
        New-Item "IIS:\AppPools\$($appPool.Name)" -Value @{
            "managedRuntimeVersion" = $appPool.ManagedRuntimeVersion
            "managedPipelineMode" = $appPool.ManagedPipelineMode
        }
        Write-Host "Application pool '$($appPool.Name)' created successfully."
    }
}

# Set the same app pool for both sites
$appPoolName = $json.AppPools[0].Name

# Create the app pool if it doesn't exist
if (-not (Get-Item "IIS:\AppPools\$appPoolName" -ErrorAction SilentlyContinue)) {
    New-Item "IIS:\AppPools\$appPoolName" -ManagedRuntimeVersion $json.AppPools[0].ManagedRuntimeVersion -ManagedPipelineMode $json.AppPools[0].ManagedPipelineMode
    Write-Host "Application pool '$appPoolName' created successfully."
}

# Create the websites if they don't exist
foreach ($site in $json.Sites) {
    if (Get-Item "IIS:\Sites\$($site.Name)" -ErrorAction SilentlyContinue) {
        Write-Warning "Website '$($site.Name)' already exists."
    } else {
        New-Item "IIS:\Sites\$($site.Name)" -Bindings @{
            "protocol" = $site.Bindings.Protocol
            "bindingInformation" = "$($site.Bindings.IPAddress):$($site.Bindings.Port):$($site.Bindings.Hostname)"
        } -PhysicalPath $site.PhysicalPath -ApplicationPool $appPoolName
        Write-Host "Website '$($site.Name)' created successfully."
    }
}


# Update IP address in the JSON file
$ipAddress = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1).IPv4Address.IPAddressToString

$json.Sites | ForEach-Object {
    $_.Bindings | ForEach-Object {
        $_.IPAddress = $ipAddress
    }
}

# Save the updated JSON content back to the file
$json | ConvertTo-Json -Depth 4 | Set-Content -Path $configurationFile

# Create self-signed certificate if it doesn't exist
$certProps = @{
    DnsName = $json.DnsName
    CertStoreLocation = "Cert:\$certStoreLocation"
    KeyUsage = "DigitalSignature", "KeyEncipherment"
    KeyLength = 2048
    NotAfter = [datetime]::Parse($json.NotAfter)
}

$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.FriendlyName -eq "Simplify1" }

if ($cert -eq $null) {
    $cert = New-SelfSignedCertificate @certProps
    $cert.FriendlyName = "Simplify1"
    $cert.Thumbprint | Out-File -FilePath "certthumbprint.txt"
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -eq "Wi-Fi"}).IPAddress

    $jsonContent = Get-Content -Path $jsonFile | ConvertFrom-Json

    # Update the IP address in the JSON file
    $jsonContent.Sites | ForEach-Object {
        $_.Bindings | ForEach-Object {
            $_.IPAddress = $ipAddress
        }
    }

    # Convert the updated JSON content back to string
    $jsonString = $jsonContent | ConvertTo-Json -Depth 10

    # Save the updated JSON content back to the file
    $jsonString | Set-Content -Path $jsonFile
} else {
    $certThumbprint = $cert.Thumbprint
}

# Read the JSON file
$jsonContent = Get-Content -Path $jsonFile -Raw

# Convert the JSON content to PowerShell objects
$jsonData = $jsonContent | ConvertFrom-Json

# Iterate over the sites in the JSON data
foreach ($site in $jsonData.Sites) {
    $siteName = $site.Name
    $bindings = $site.Bindings

    # Get the site object from IIS Manager
    $iisSite = Get-Website -Name $siteName

    if ($iisSite -eq $null) {
        Write-Warning "Website with name '$siteName' not found."
        continue
    }

    # Remove existing bindings for the site
    $iisSite | Remove-WebBinding -Protocol *

    # Add the updated bindings from the JSON data
    foreach ($binding in $bindings) {
        $protocol = $binding.Protocol
        $ipAddress = $binding.IPAddress
        $port = $binding.Port
        $hostname = $binding.Hostname

        # Create the binding information
        $bindingInformation = "$($ipAddress):$($port):$($hostname)"

        
        Write-Host "Binding added for website '$siteName': $protocol $bindingInformation"
    }
}

# Import the WebAdministration module
Import-Module WebAdministration

# Specify the website name and binding information
$websiteName = $site.Name
$bindingProtocol = "https"
$bindingIPAddress = $binding.IPAddress
$bindingPort = $binding.Port
$bindingHostname = $binding.Hostname
$certFriendlyName = $cert.FriendlyName
$certThumbprint = "5C6ECBFDC489C18FEE4570E8561CB3B21E539BC7"

# Get the website object from the server manager
$website = $serverManager.Sites | Where-Object { $_.Name -eq $websiteName }

if ($website -eq $null) {
    Write-Warning "Website with name '$websiteName' not found."
    exit
}

# Find the certificate in the local machine store based on the thumbprint
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $certThumbprint } | Select-Object -First 1

if ($cert -eq $null) {
    Write-Warning "SSL certificate with thumbprint '$certThumbprint' not found in the certificate store."
    exit
}

# Configure the SSL binding for the website
$binding = $website.Bindings.CreateElement("binding")
$binding.Protocol = $bindingProtocol
$binding.BindingInformation = "$($bindingIPAddress):$($bindingPort):$($bindingHostname)"
$binding.CertificateHash = $cert.GetCertHashString()
$binding.CertificateStoreName = "my"
$website.Bindings.Add($binding)

# Save the changes to the server manager
$serverManager.CommitChanges()

# Restart the website
$website.Stop()
$website.Start()

Write-Host "SSL certificate selected for website '$websiteName'."
# Restart the website
$website.Stop()
$website.Start()

Write-Host "Website restarted."
