# Copyright (c) STÜBER SYSTEMS GmbH. All rights reserved.
# Licensed under the MIT License.

Import-LocalizedData -BindingVariable stringTable

<#
 .Synopsis
  Creates a new JSON configuration template for the 'Start-EnbreaImport' cmdlet

 .Description
  This cmdlet will copy a template josn file to the target destination. You must adapt 
  the configuration to your needs by opening the configuration file in a text editor.
  
 .Parameter ConfigFile
  The file name of the JSON configuration file. If this file exists already this cmdlet 
  will terminate with an error.

 .Example
  # Adds a configuration template for ENBREA imports
  Initialize-EnbreaImport -ConfigFile MyImportConfig.json

 .Example
  # Adds a configuration template for ENBREA imports (short form)
  Initialize-EnbreaImport MyImportConfig.json
#>
function Initialize-EnbreaImport {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigFile
    )
    process
    {
        try
        {
            $ConfigPath = GetFullConfigPath -ConfigFile $ConfigFile
            $ConfigTemplatePath = GetConfigTemplatePath -TemplateName "Import"

            if (-not (Test-Path -Path $ConfigPath))
            {
                Copy-Item $ConfigTemplatePath -Destination $ConfigPath
            }
            else 
            {
                throw ([string]::Format($stringTable.ErrorFileExists, $ConfigPath))
            }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
        }
    }
}

<#
 .Synopsis
  Creates a new JSON configuration template for the 'Start-EnbreaExport' cmdlet

 .Description
  This cmdlet will copy a template josn file to the target destination. You must adapt 
  the configuration to your needs by opening the configuration file in a text editor.
  
 .Parameter ConfigFile
  The file name of the JSON configuration file. If this file exists already this cmdlet 
  will terminate with an error.

 .Example
  # Adds a configuration template for ENBREA exports
  Initialize-EnbreaExport -ConfigFile MyExportConfig.json

 .Example
  # Adds a configuration template for ENBREA exports (short from)
  Initialize-EnbreaExport MyExportConfig.json
#>
function Initialize-EnbreaExport {
   param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigFile
    )
    process
    {
        try
        {
            $ConfigPath = GetFullConfigPath -ConfigFile $ConfigFile
            $ConfigTemplatePath = GetConfigTemplatePath -TemplateName "Export"

            if (-not (Test-Path -Path $ConfigPath))
            {
                Copy-Item $ConfigTemplatePath -Destination $ConfigPath
            }
            else 
            {
                throw ([string]::Format($stringTable.ErrorFileExists, $ConfigPath))
            }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
        }
    }
}

<#
 .Synopsis
  Starts a new import from a supported source to ENBREA.

 .Description
  This cmdlet will start a new import from a supported source to ENBREA. This is a two step
  process. First data is exported from a source (e.g. DAVINCI) to ECF. After that ECF is 
  imported to ENBREA. The target 'ecf' is an exception because only the second step is 
  executed. The configuration  for this import process will be read from a JSON configuration
  file.

 .Parameter Source
  The name of a supported import source. Currently supported are 'davinci', 'magellan',
  'untis', 'edoosys', 'schildnrw', 'bbsplanung', 'excel' and 'ecf'.

 .Parameter ConfigFile
  The file name of the JSON configuration file. 

 .Parameter SkipEcfExport
  If true do not export ECF from source. This flag is for testing purpose.

 .Parameter SkipEcfImport
  If true do not import ECF to ENBREA. This flag is for testing purpose.

 .Example
  # Starts an import from DAVINCI to ENBREA
  Start-EnbreaImport -Source davinci -ConfigFile MyImportConfig.json

 .Example
  # Starts an import from DAVINCI to ENBREA (short form)
  Start-EnbreaImport davinci MyImportConfig.json

 .Example
  # Starts an import from plain ECF to ENBREA
  Start-EnbreaImport -Source ecf -ConfigFile MyImportConfig.json
#>
function Start-EnbreaImport {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ImportSource]
        $Source,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigFile,
        [switch]
        $SkipEcfExport,
        [switch]
        $SkipEcfImport
    )
    process
    {
        try
        {
        
            $ConfigPath = GetFullConfigPath -ConfigFile $ConfigFile
            $Config = GetConfig -Config $ConfigPath
            $Provider = $Source.ToString().ToLower()
            $FolderPath = GetEcfSourceFolderPath -Source $Source -Config $Config
        
            if (-not ($SkipEcfExport))
            {
                switch ($Source)
                {
                    ([ImportSource]::davinci)    { RunDavConsole -Command "export" -Config $Config }
                    ([ImportSource]::magellan)   { RunEcfTool -Tool ([EcfTool]::magellan) -Command "export" -Config $Config -ConfigPath $ConfigPath }
                    ([ImportSource]::untis)      { RunEcfTool -Tool ([EcfTool]::untis) -Command "export" -Config $Config -ConfigPath $ConfigPath }
                    ([ImportSource]::edoosys)    { RunEcfTool -Tool ([EcfTool]::edoosys) -Command "export" -Config $Config -ConfigPath $ConfigPath }
                    ([ImportSource]::schildnrw)  { RunEcfTool -Tool ([EcfTool]::schildnrw) -Command "export" -Config $Config -ConfigPath $ConfigPath }
                    ([ImportSource]::bbsplanung) { RunEcfTool -Tool ([EcfTool]::bbsplanung) -Command "export" -Config $Config -ConfigPath $ConfigPath }
                    ([ImportSource]::excel)      { RunEcfTool -Tool ([EcfTool]::excel) -Command "export" -Config $Config -ConfigPath $ConfigPath }
                }
            }

            if (-not ($SkipEcfImport))
            {
                RunEcfTool -Tool ([EcfTool]::enbrea) -Command "import" -Config $Config -ConfigPath $ConfigPath -Provider $Provider -FolderPath $FolderPath
            }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
        }
    }
}

<#
 .Synopsis
  Starts a new export from ENBREA to a supported target.

 .Description
  This cmdlet will start a new export from ENBREA to a supported target. This is a two step
  process. First data is exported from ENBREA to ECF. After that ECF is imported to a target
  (e.g. MAGELLAN). The source 'ecf' is an exception because only the first step is executed.
  The configuration for this export process will be read from a JSON configuration 
  file.

 .Parameter Source
  The name of a supported export target. Currently supported are 'davinci', 'magellan' and 'ecf'.

 .Parameter ConfigFile
  The file name of the JSON configuration file. 

 .Parameter SkipEcfExport
  If true do not export ECF files from ENBREA. This flag is for testing purpose.

 .Parameter SkipEcfImport
  If true do not import ECF files to target. This flag is for testing purpose.

 .Example
  # Starts an export from ENBREA to DAVINCI
  Start-EnbreaExport -Target davinci -ConfigFile MyExportConfig.json

 .Example
  # Starts an export from ENBREA to DAVINCI (short form)
  Start-EnbreaExport davinci MyExportConfig.json

 .Example
  # Starts an export from ENBREA to plain ECF
  Start-EnbreaExport -Target ecf -ConfigFile MyExportConfig.json
#>
function Start-EnbreaExport {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ExportTarget]
        $Target,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigFile,
        [switch]
        $SkipEcfExport,
        [switch]
        $SkipEcfImport
    )
    process
    {
        try
        {
            $ConfigPath = GetFullConfigPath -ConfigFile $ConfigFile
            $Config = GetConfig -Config $ConfigPath
            $Provider = $Target.ToString().ToLower()
            $FolderPath = GetEcfTargetFolderPath -Target $Target -Config $Config

            if (-not ($SkipEcfExport))
            {
                RunEcfTool -Tool ([EcfTool]::enbrea) -Command "export" -Config $Config -ConfigPath $ConfigPath -Provider $Provider -FolderPath $FolderPath
            }

            if (-not ($SkipEcfImport))
            {
                switch ($Target)
                {
                    ([ImportSource]::davinci)  { RunDavConsole -Command "import" -Config $Config }
                    ([ImportSource]::magellan) { RunEcfTool -Tool ([EcfTool]::magellan) -Command "import" -Config $Config -ConfigPath $ConfigPath }
                }
            }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
        }
    }
}

<#
 .Synopsis
  Installs one or more ECF Tools 

 .Description
  An ECF Tool is an command line processor for consuming and/or generating ECF files. This 
  cmdlet will download and install the current versions from GitHub.

 .Parameter Tool
  An array of ECF Tool short names. Currently supported are 'enbrea', 'magellan', 'untis', 
  'edoosys', 'schildnrw', 'bbsplanung' and 'excel'.

 .Parameter Version
  Version number of the ECF tool if not the current one.

 .Example
  # Installing ECF Tool for MAGELLAN
  Install-EcfTools -Tools magellan

 .Example
  # Installing ECF Tool for MAGELLAN and Excel
  Install-EcfTools -Tools magellan, excel
#>
function Install-EcfTools {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [EcfTool[]]
        $Tools,
        [string]
        $Version
    )
    process
    {
        try
        {   
            foreach($tool in $Tools)
            {
                SetupEcfTool -Tool $tool -Version $Version
            }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Error $ErrorMessage
        }
    }
}

<#
 .Synopsis
  Updates one or more ECF Tools 

 .Description
  An ECF Tool is an command line processor for consuming and/or generating ECF files. This 
  cmdlet searches for newer versions of allready installed ECF Tools on GitHub. If found they 
  will be downloaded and installed.

 .Parameter Tool
  An array of ECF Tool short names. Currently supported are 'enbrea', 'magellan', 'untis', 
  'edoosys', 'schildnrw', 'bbsplanung' and 'excel'. Skipping this parameter means updating
  all ECF Tools.

 .Parameter Tool
  An array of ECF Tool short names. Currently supported are 'enbrea', 'magellan', 'untis', 
  'edoosys', 'schildnrw', 'bbsplanung' and 'excel'. Skipping this parameter means updating
  all ECF Tools.

 .Parameter Version
  Version number of the ECF tool if not the current one.

 .Example
  # Updating ECF Tool for MAGELLAN 
  Update-EcfTools -Tools magellan

 .Example
  # Updating ECF Tools for MAGELLAN and Excel
  Update-EcfTools -Tools magellan, excel

 .Example
  # Updating all supported ECF Tools
  Update-EcfTools
#>
function Update-EcfTools {
    param(
        [EcfTool[]]
        $Tools,
        [string]
        $Version
    )
    process
    {
        try
        {   
            if ($Tools.Count -gt 0)
            {
                foreach($tool in $Tools)
                {
                    UpdateEcfTool -Tool $tool -Version $Version
                }
            }
            else 
            {
                foreach($tool in [enum]::GetValues([EcfTool]))
                {
                    UpdateEcfTool -Tool $tool -Version $Version
                }
            }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            Write-Host $ErrorMessage
        }
    }
}

function SetupEcfTool {
    param(
        [EcfTool]
        $Tool,
        [string]
        $Version
    )
    process
    {
        $SetupFolder = GetEcfToolFolder -Tool $Tool
        $ShortName = GetEcfToolShortName -Tool $Tool
        $FriendlyName = GetEcfToolFriendlyName -Tool $Tool
        
        if ((-not ($SetupFolder)) -or (-not (Test-Path -Path $SetupFolder)))
        {
            Write-Verbose "Searching for latest version of $($FriendlyName)"

            if (-not (Test-Path -Path $SetupFolder -PathType Container))
            {
                $null = New-Item -Path $SetupFolder -ItemType Directory -Force
            }
            
            if ($Version)
            {
                $GitHubInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/stuebersystems/$($ShortName)/releases/tags/v-$($Version)"
            }
            else
            {
                $GitHubInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/stuebersystems/$($ShortName)/releases/latest"
            }
                
            if ($GitHubInfo.tag_name) 
            {
                $RemoteVersion = GetSemVersion $GitHubInfo.tag_name
                
                Write-Verbose "Remote version: $($RemoteVersion.ToString())"

                if ($GitHubInfo.assets.browser_download_url) 
                {
                    $TempZipArchive = "$($SetupFolder)\_download.zip"

                    $ProgressPreference = 'SilentlyContinue'    
                    try 
                    {
                        Invoke-WebRequest -Uri $GitHubInfo.assets.browser_download_url -OutFile $TempZipArchive 
                    }
                    finally 
                    {
                        $ProgressPreference = 'Continue'    
                    }

                    Expand-Archive $TempZipArchive -DestinationPath $SetupFolder -Force
                    
                    Remove-Item -Path $TempZipArchive -Force
                }

                Write-Host ([string]::Format($stringTable.EcfToolInstalled, $FriendlyName, $RemoteVersion.ToString()))
            }
        }
        else 
        {
            Write-Host ([string]::Format($stringTable.EcfToolAlreadyInstalled, $FriendlyName))
        }
    }
}

function UpdateEcfTool {
    param(
        [EcfTool]
        $Tool,
        [string]
        $Version
    )
    process
    {
        $ConsolePath = GetEcfToolBinaryPath -Tool $Tool
        $ShortName = GetEcfToolShortName -Tool $Tool
        $FriendlyName = GetEcfToolFriendlyName -Tool $Tool
        
        if (Test-Path -Path $ConsolePath -PathType Leaf)
        {
            Write-Verbose "Searching for update of $($FriendlyName)"

            if ($Version)
            {
                $GitHubInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/stuebersystems/$($ShortName)/releases/tags/v-$($Version)"
            }
            else
            {
                $GitHubInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/stuebersystems/$($ShortName)/releases/latest"
            }
                
            if ($GitHubInfo.tag_name) 
            {
                $RemoteVersion = GetSemVersion $GitHubInfo.tag_name
                $LocalVersion = GetSemVersion (GetFileVersion $ConsolePath)
                
                Write-Verbose "Remote version: $($RemoteVersion.ToString())"
                Write-Verbose "Local version: $($LocalVersion.ToString())"

                if ($Version) 
                {
                    if ($RemoteVersion -eq $LocalVersion)
                    {
                        Write-Host ([string]::Format($stringTable.EcfToolVersionAlreadyInstalled, $FriendlyName, $RemoteVersion.ToString()))
                        return
                    }
                }
                else
                {
                    if ($RemoteVersion -le $LocalVersion)
                    {
                        Write-Host ([string]::Format($stringTable.EcfToolUpToDate, $FriendlyName, $RemoteVersion.ToString()))
                        return
                    }
                }

                if ($GitHubInfo.assets.browser_download_url) 
                {
                    $ConsoleFolder = Split-Path -Path $ConsolePath
                    
                    $TempZipArchive = "$($ConsoleFolder)\_download.zip"

                    $ProgressPreference = 'SilentlyContinue'    
                    try 
                    {
                        Write-Verbose $GitHubInfo.assets.browser_download_url
                        Invoke-WebRequest -Uri $GitHubInfo.assets.browser_download_url -OutFile $TempZipArchive
                    }
                    finally 
                    {
                        $ProgressPreference = 'Continue'    
                    }

                    Expand-Archive $TempZipArchive -DestinationPath $ConsoleFolder -Force
                    
                    Remove-Item -Path $TempZipArchive -Force
                }

                Write-Host ([string]::Format($stringTable.EcfToolUpdated, $FriendlyName, $RemoteVersion.ToString()))
            }
        }
        else 
        {
            Write-Host ([string]::Format($stringTable.EcfToolNotInstalled, $FriendlyName))
        }
    }
}

function RunEcfTool{
    param(
        [EcfTool]
        $Tool,
        [string]
        $Command,
        [PSObject]
        $Config,
        [string]
        $ConfigPath,
        [string]
        $Provider,
        [string]
        $FolderPath
    )
    process
    {   
        Write-Host $stringTable.StartEcfTool -ForegroundColor $Host.PrivateData.VerboseForegroundColor

        $ConsolePath = GetEcfToolBinaryPath -Tool $Tool -Config $Config
        $FriendlyName = GetEcfToolFriendlyName -Tool $Tool
        
        if (($ConsolePath) -and (Test-Path -Path $ConsolePath -PathType Leaf))
        {
            $CurrentLocation = Get-Location
            Set-Location -Path (Split-Path -Path $ConfigPath)
            try 
            {
                if ($Tool -eq [EcfTool]::enbrea)
                {
                    dotnet ""$($ConsolePath)"" $($Command) -c ""$($ConfigPath)"" -p $($Provider) -f $($FolderPath)
                }
                else
                {
                    dotnet ""$($ConsolePath)"" $($Command) -c ""$($ConfigPath)""
                }
            }
            finally 
            {
                Set-Location -Path $CurrentLocation
            }

            if ($LASTEXITCODE -ne 0)
            {
                $ErrorMessage = ([string]::Format($stringTable.ErrorEcfToolFailed, $FriendlyName))
                throw $ErrorMessage
            }
        }
        else
        {
            $ErrorMessage = ([string]::Format($stringTable.ErrorEcfToolNotFound, $FriendlyName))
            throw $ErrorMessage
        }
    }
}

function RunDavConsole{
    param(
        [string]
        $Command,
        [PSObject]
        $Config
    )
    process
    {
        Write-Host $stringTable.StartDaVinciConsole -ForegroundColor $Host.PrivateData.VerboseForegroundColor

        $ConsolePath = GetDavConsolePath -Config $Config

        if (($ConsolePath) -and (Test-Path -Path $ConsolePath -PathType Leaf))
        {
            $CurrentLocation = Get-Location
            Set-Location -Path (Split-Path -Path $ConfigPath)
            try
            {   
                Invoke-Expression "& ""$($consolePath)"" $($Command) -c ""$($ConfigPath)"""
            }
            finally 
            {
                Set-Location -Path $CurrentLocation
            }

            if ($LASTEXITCODE -ne 0)
            {
                $ErrorMessage = $stringTable.ErrorDaVinciConsoleFailed
                throw $ErrorMessage
            }
        }
        else
        {
            $ErrorMessage = ([string]::Format($stringTable.ErrorDaVinciConsoleNotFound, $ConsolePath)) 
            throw $ErrorMessage
        }
    }
}

function GetConfig {
    param(
        [string]
        $ConfigPath
    )
    process
    {
        if (($ConfigPath) -and (Test-Path -Path $ConfigPath -PathType leaf))
        {
            return Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        }
        else
        {
            return "{}" | ConvertFrom-Json
        }
    }
}

function GetConfigTemplatePath {
    param(
        [string]
        $TemplateName
    )
    process
    {
        return Join-Path -Path $PSScriptRoot -ChildPath "PsEnbrea.Template.$($TemplateName).json"
    }
}

function GetFullConfigPath {
    param(
        [string]
        $ConfigFile
    )
    process
    {
        $ConfigPath = $ConfigFile
        
        if ((Split-Path -Path $ConfigPath -Leaf) -eq $ConfigPath)
        {
            $ConfigPath = Join-Path -Path (Get-Location) -ChildPath $ConfigPath
        }

        if (-not (Test-Path -Path $ConfigPath -PathType Leaf))
        {
            if (-not ([IO.Path]::HasExtension($ConfigPath)))
            {
                $ConfigPath = [IO.Path]::ChangeExtension($ConfigPath, "json")
            }
        }

        return $ConfigPath
    }
}

function GetDavConsolePath {
    param(
        [PSObject]
        $Config
    )
    process
    {
        if ($Config)
        {
            if ($Config.PSEnbrea.Tools.DaVinciConsole)
            {
                return $config.PSEnbrea.Tools.DaVinciConsole
            }
        }
        
        $RegKey64 = "HKLM:\SOFTWARE\WOW6432Node\Stueber Systems\daVinci 6\Main"
        $RegKey32 = "HKLM:\SOFTWARE\Stueber Systems\daVinci 6\Main"

        if ([Environment]::Is64BitProcess)
        {
            if (Test-Path -Path $RegKey64)
            {
                $RegKey = Get-ItemProperty -Path $RegKey64 -Name BinFolder
                return Join-Path -Path $RegKey.BinFolder -ChildPath "daVinciConsole.exe"
            }
            else
            {
                return $null
            }
        }
        else
        {
            if (Test-Path -Path $RegKey32)
            {
                $RegKey = Get-ItemProperty -Path $RegKey32 -Name BinFolder
                return Join-Path -Path $RegKey.BinFolder -ChildPath "daVinciConsole.exe"
            }
            else
            {
                return $null
            }
        }
    
    }
}

function GetEcfSourceFolderPath {
    param(
        [ImportSource]
        $Source,
        [PsObject]
        $Config
    )
    process
    {
        $Provider = $Source.ToString()
        $ProviderConfig = $Config | Select-Object -ExpandProperty $Provider
        return $ProviderConfig.EcfExport.TargetFolderName
    }
}

function GetEcfTargetFolderPath {
    param(
        [ExportTarget]
        $Target,
        [PsObject]
        $Config
    )
    process
    {
        $Provider = $Target.ToString()
        $ProviderConfig = $Config | Select-Object -ExpandProperty $Provider
        return $ProviderConfig.EcfExport.SourceFolderName
    }
}

function GetEcfToolBinaryName {
    param(
        [EcfTool]
        $Tool
    )
    process
    {
        switch ($Tool)
        {
            ([EcfTool]::enbrea)     { return "ecf.enbrea.dll" }
            ([EcfTool]::magellan)   { return "ecf.magellan.dll" }
            ([EcfTool]::untis)      { return "ecf.untis.dll" }
            ([EcfTool]::bbsplanung) { return "ecf.bbsplanung.dll" }
            ([EcfTool]::edoosys)    { return "ecf.edoosys.dll" }
            ([EcfTool]::schildnrw)  { return "ecf.schildnrw.dll" }
            ([EcfTool]::excel)      { return "ecf.excel.dll" }
        }
    }
}

function GetEcfToolBinaryPath {
    param(
        [EcfTool]
        $Tool,
        [PSObject]
        $Config
    )
    process
    {
        if ($Config)
        {
            $ShortName = GetEcfToolShortName -Tool $Tool

            if (($Config.PSEnbrea.Tools) -and ($ShortName -in $Config.PSEnbrea.Tools.PSObject.Properties.Name))
            {
                return $Config.PSEnbrea.Tools | Select-Object -ExpandProperty $ShortName
            }
        }

        return Join-Path -Path (GetEcfToolFolder -Tool $Tool) -ChildPath (GetEcfToolBinaryName -Tool $Tool)
    }
}

function GetEcfToolFolder {
    param(
        [EcfTool]
        $Tool
    )
    process
    {
        $EcfToolInstallVariableName = "EcfToolsInstall"
        $EcfToolInstallPath = [Environment]::GetEnvironmentVariable($EcfToolInstallVariableName)
        
        if (($EcfToolInstallPath) -and (Test-Path -Path $EcfToolInstallPath))
        {
            return $EcfToolInstallPath  
        }
            
        return Join-Path -Path $Env:PROGRAMDATA -ChildPath (Join-Path -Path "Stueber Systems\Ecf-Tools" -ChildPath (GetEcfToolShortName -Tool $Tool))   
    }
}

function GetEcfToolFriendlyName {
    param(
        [EcfTool]
        $Tool
    )
    process
    {
        switch ($Tool)
        {
            ([EcfTool]::enbrea)     { return "ECF Tool for ENBREA" }
            ([EcfTool]::magellan)   { return "ECF Tool for MAGELLAN" }
            ([EcfTool]::untis)      { return "ECF Tool for Untis" }
            ([EcfTool]::bbsplanung) { return "ECF Tool for BBS-Planung" }
            ([EcfTool]::edoosys)    { return "ECF Tool for edoo.sys" }
            ([EcfTool]::schildnrw)  { return "ECF Tool for Schild-NRW" }
            ([EcfTool]::excel)      { return "ECF Tool for Excel" }
        }
    }
}

function GetEcfToolShortName {
    param(
        [EcfTool]
        $Tool
    )
    process
    {
        switch ($Tool)
        {
            ([EcfTool]::enbrea)     { return "ecf.enbrea" }
            ([EcfTool]::magellan)   { return "ecf.magellan" }
            ([EcfTool]::untis)      { return "ecf.untis" }
            ([EcfTool]::bbsplanung) { return "ecf.bbsplanung" }
            ([EcfTool]::edoosys)    { return "ecf.edoosys" }
            ([EcfTool]::schildnrw)  { return "ecf.schildnrw" }
            ([EcfTool]::excel)      { return "ecf.excel" }
        }
    }
}

function GetFileVersion {
    param(
        [string]
        $Path
    )
    process
    {
        return (Get-Command $Path).FileVersionInfo.ProductVersion
    }
}

function GetSemVersion {
    param(
        [string]
        $TagName
    )
    process
    {
        $Version = $null
        $TagName = $TagName -replace "v-", ""

        if ([NuGet.Versioning.SemanticVersion]::TryParse($TagName, [ref]$Version))
        {
            return $Version
        }
        else
        {
            $ErrorMessage = ([string]::Format($stringTable.ErrorTagNameParsing, $TagName))
            throw $ErrorMessage
        }
    }
}

# List of supported ecf tools
Enum EcfTool {
    enbrea
    magellan
    untis
    bbsplanung
    edoosys
    schildnrw
    excel
}

# List of supported import sources
Enum ImportSource {
    davinci
    magellan
    untis
    bbsplanung
    edoosys
    schildnrw
    excel
    ecf
}

# List of supported export targets
Enum ExportTarget {
    davinci
    magellan
    ecf
}

Export-ModuleMember -Function Initialize-EnbreaImport
Export-ModuleMember -Function Initialize-EnbreaExport
Export-ModuleMember -Function Install-EcfTools
Export-ModuleMember -Function Start-EnbreaImport
Export-ModuleMember -Function Start-EnbreaExport
Export-ModuleMember -Function Update-EcfTools