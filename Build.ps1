
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]$Stages
)

################
# Global settings
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2

################
# Modules
Remove-Module Noveris.Build -EA SilentlyContinue
Import-Module .\noveris.build\source\Noveris.Build

################
# Project settings
$projectName = "noveris.forwarddiscovery"
#$organisation = "Noveris"

################
# Capture version information
Set-BuildVersionInfo -Sources @(
    $Env:BUILD_SOURCEBRANCH,
    $Env:CI_COMMIT_TAG,
    $Env:BUILD_VERSION,
    "v0.1.0"
)

Use-BuildDirectories @(
	"stage",
    "package"
)

################
# Build stage
Set-BuildStage -Stage "Build" -Script {
    $version = [PSCustomObject]$_["Version"]

    # Clear build directories
    Clear-BuildDirectories

    # Output Build version for later use
	Write-Information ("Setting BUILD_VERSION: " + $version.Full)
	Write-Information ("##vso[task.setvariable variable=BUILD_VERSION;]" + $version.Full)

    # Template module definition
    Write-Information "Templating Noveris.ForwardDiscovery.psd1"
    Format-TemplateFile -Template source/Noveris.ForwardDiscovery.psd1.tpl -Target source/Noveris.ForwardDiscovery/Noveris.ForwardDiscovery.psd1 -Content @{
        __FULLVERSION__ = $version.Full
    }

    # Copy source files to outputs
    @("./stage/", $Env:BUILD_ARTIFACTSTAGINGDIRECTORY) | Where-Object { ![string]::IsNullOrEmpty($_) } | ForEach-Object {
        Write-Information "Copying source to $_"
        Copy-Item ./source/* $_ -Force -Recurse -Exclude ".git*"
    }

    # Compress files in to archive
    Write-Information "Packaging artifacts"
    $artifactName = ("package/{0}-{1}.zip" -f $projectName, $version.Full)
    Write-Information "Target file: ${artifactName}"
    Compress-Archive -Destination $artifactName -Path "./stage/*" -Force
}

################
# Run stages requested
Invoke-BuildStages -Stages $Stages
