[CmdletBinding()]
param(
    [Parameter(mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$BasePath
)

################
# Global settings
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
Set-StrictMode -Version 2

################
# Global variables
$LogFile = [System.IO.Path]::Combine($BasePath, "Noveris.ForwardDiscovery.log")
$ConfigFile = [System.IO.Path]::Combine($BasePath, "config.json")

# Check for base path
New-Item -ItemType Directory $BasePath -EA Ignore | Out-Null
if (!(Test-Path -PathType Container $BasePath))
{
    Write-Error "Base path exists and is not a directory ($BasePath)"
}

# Check for the log file
New-Item -ItemType File $LogFile -EA Ignore | Out-Null
if (!(Test-Path -PathType Leaf $LogFile))
{
    Write-Error "Log file does not exist and could not be created ($LogFile)"
}

# Preserve the last x number of lines of the log file
$content = Get-Content -Encoding UTF8 -Tail 1000 $LogFile
$content | Out-File -Encoding UTF8 $LogFile

# Check for the existance of the config file
if (!(Test-Path -PathType Leaf $ConfigFile))
{
    Write-Error "Config file does not exist ($ConfigFile)"
}

# Import Module
$Env:PSModulePath = $BasePath + [System.IO.Path]::PathSeparator + $Env:PSModulePath
Import-Module Noveris.ForwardDiscovery

$configObj = Get-Content $ConfigFile | ConvertFrom-Json -Depth 3
$configArgs = @{}
foreach ($member in $configObj.PSObject.Properties)
{
    $configArgs[$member.Name] = $member.Value
}

# Generate report and log to log file
Update-ConditionalForwarders @configArgs *>&1 | Out-String -Stream | Out-File -Append -Encoding UTF8 $LogFile
