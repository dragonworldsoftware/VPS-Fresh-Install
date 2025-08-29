# Forex Fresh Installer

#region Window Size
# Set window size (wrapped in try-catch as it may fail in some environments)
try {
    $ws = $host.UI.RawUI.WindowSize
    $ws.Height = [Math]::Min(35, $host.UI.RawUI.MaxWindowSize.Height)
    $ws.Width = [Math]::Min(120, $host.UI.RawUI.MaxWindowSize.Width)
    $host.UI.RawUI.WindowSize = $ws
} catch {
    # Commend line below for: Silently continue if window sizing fails
    Write-Verbose "Could not set window size: $_" -Verbose:$false
}
#endregion

#region Show Broker Menu
function Show-BrokerMenu {
  Clear-Host
  Write-Host ""
  Write-Host " Welcome to the MetaTrader5 Installer" -ForegroundColor Green
  Write-Host " =====================================" -ForegroundColor Green
  Write-Host ""
  Write-Host " Select Broker:" -ForegroundColor Cyan
  Write-Host " 1. Forex.com MT5" -ForegroundColor White
  Write-Host " 2. Trading.com MT5" -ForegroundColor White
  Write-Host ""
  Write-Host " 0. Exit" -ForegroundColor Red
  Write-Host ""
}
#endregion

#region Load Config
function Load-Config {
    param(
        [string]$ConfigPath = "config.yaml"
    )
    
    # Ensure we're looking in the script's directory
    $scriptDir = Split-Path -Parent $PSCommandPath
    $fullPath = Join-Path $scriptDir $ConfigPath
    
    Write-Host "Looking for config at: $fullPath" -ForegroundColor Cyan
    
    if (-not (Test-Path $fullPath)) {
        Write-Host "Config file not found: $fullPath" -ForegroundColor Red
        return $null
    }
    
    $config = @{}
    Get-Content $fullPath | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') {
            return
        }
        
        if ($_ -match '^\s*(\w+)\s*[:=]\s*"([^"]+)"' -or 
            $_ -match "^\s*(\w+)\s*[:=]\s*'([^']+)'" -or
            $_ -match '^\s*(\w+)\s*[:=]\s*(.+)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim().Trim('"').Trim("'")
            $config[$key] = $value
            Write-Host "Loaded: $key = $value" -ForegroundColor Gray
        }
    }
    
    Write-Host "Config loaded with $($config.Count) values" -ForegroundColor Green
    return $config
}
#endregion

#region Downlaod Files
function Download-GoogleDriveFile {
  param(
      [string]$FileId,
      [string]$OutputPath
  )
  
  $downloadUrl = "https://drive.google.com/uc?export=download&id=$FileId"
  
  try {
      Invoke-WebRequest -Uri $downloadUrl -OutFile $OutputPath -UseBasicParsing
      Write-Host "Downloaded: $OutputPath" -ForegroundColor Green
      return $true
  }
  catch {
      Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
      return $false
  }
}
#endregion

#region MT5 Login Keys
function Perform-MT5Login {
    param(
        [string]$Login,
        [string]$Password, 
        [string]$Server
    )

    # Debug output
    Write-Host "Login value: '$Login'" -ForegroundColor Yellow
    Write-Host "Server value: '$Server'" -ForegroundColor Yellow
    
    if ([string]::IsNullOrWhiteSpace($Login)) {
        Write-Host "WARNING: Login is empty!" -ForegroundColor Red
    }
    if ([string]::IsNullOrWhiteSpace($Server)) {
        Write-Host "WARNING: Server is empty!" -ForegroundColor Red
    }

    
    Add-Type -AssemblyName System.Windows.Forms
    
    # Close account dialog
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Seconds 3
    
    # Open login dialog
    [System.Windows.Forms.SendKeys]::SendWait("%")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{DOWN}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("L")
    Start-Sleep -Seconds 2
    
    # Enter credentials
    [System.Windows.Forms.SendKeys]::SendWait($Login)
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait($Password)
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait($Server)
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep -Milliseconds 500
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    Write-Host "Login completed" -ForegroundColor Green
}
#endregion

#region Login to Forex.com
function Login-ToForexAccount {
    param([hashtable]$Config)
    
    Write-Host "Starting automated login for Forex.com..." -ForegroundColor Cyan
    
    $login = $Config.forex_com_login
    $password = $Config.forex_com_password
    $server = if ($Config.forex_com_server) { $Config.forex_com_server } else { "FOREX.com-Server" }
    
    Perform-MT5Login -Login $login -Password $password -Server $server
}
#endregion

#region Login to Trading
function Login-ToTradingAccount {
    param([hashtable]$Config)
    
    Write-Host "Starting automated login for Trading.com..." -ForegroundColor Cyan
    
    $login = $Config.trading_com_login
    $password = $Config.trading_com_password
    $server = if ($Config.trading_com_server) { $Config.trading_com_server } else { "Trading.comMarkets-MT5" }
    
    Perform-MT5Login -Login $login -Password $password -Server $server
}
#endregion

#region MT5 Auto Install
function Start-MT5AutoInstall {
    param([string]$InstallPath)

    # Add required assembly for SendKeys
    Add-Type -AssemblyName System.Windows.Forms

    # Wait for installer window
    Start-Sleep 3

    # Move backwards from Next to Settings button
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    # Wait for Settings dialog
    Start-Sleep 2

    # Clear installation path field and enter custom path
    [System.Windows.Forms.SendKeys]::SendWait("^a")
    Start-Sleep 1
    [System.Windows.Forms.SendKeys]::SendWait($InstallPath)
    Start-Sleep 1

    # TAB to Browse Button
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1

    # TAB to Program Group field (leave default)
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1

    # TAB to checkbox
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1

    # Press Space to "Uncheck"
    [System.Windows.Forms.SendKeys]::SendWait(" ")
    Start-Sleep 1

    # TAB to "< Back"
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1
    # TAB to "Next >"
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1
    # ENTER: Go to next window
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
   
    # Wait for Forex to Finish Installing
    Start-Sleep 20

    # TAB to "Website Button"
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1
    # TAB to "FINISH"
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
    Start-Sleep 1
    # ENTER: To Close Installer Window
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

}
#endregion

#region Install Forex MT5
function Install-ForexComMT5 {
    param(
        [hashtable]$Config
    )
    
    $fileId = "1AI1Xxn00eC_0aolL0V0ofed8N0wwMnwE"
    $zipPath = "$env:TEMP\ForexCom_MT5.zip"
    $extractPath = "$env:TEMP\ForexCom_MT5"
    $baseDir = "C:\MetaTrader"
    $installPath = "$baseDir\MetaTrader5_ForexCom"
    
    if (-not (Test-Path $baseDir)) {
        New-Item -Path $baseDir -ItemType Directory -Force
        Write-Host "Created directory: $baseDir" -ForegroundColor Green
    }
    
    Write-Host "Downloading Forex.com MT5..." -ForegroundColor Cyan
    
    if (Download-GoogleDriveFile -FileId $fileId -OutputPath $zipPath) {
        Write-Host "Extracting archive..." -ForegroundColor Cyan
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        $installer = Get-ChildItem -Path $extractPath -Filter "*.exe" -Recurse | Select-Object -First 1
        if ($installer) {
            Write-Host "Installing MT5 to $installPath..." -ForegroundColor Cyan
            Start-Process -FilePath $installer.FullName -NoNewWindow
            Start-MT5AutoInstall -InstallPath $installPath
            Write-Host "Forex.com MT5 installation completed" -ForegroundColor Green
            
            Start-Sleep 5
            Login-ToForexAccount -Config $Config
        }
        
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
#endregion

#region Install Trading MT5
function Install-TradingComMT5 {
    param(
        [hashtable]$Config
    )
    
    $fileId = "1I4zkc1lZw2t0UCJ_NRpwgRZGX5rtbM_l"
    $zipPath = "$env:TEMP\TradingCom_MT5.zip"
    $extractPath = "$env:TEMP\TradingCom_MT5"
    $baseDir = "C:\MetaTrader"
    $installPath = "$baseDir\MetaTrader5_TradingCom"
    
    # Create base directory if it doesn't exist
    if (-not (Test-Path $baseDir)) {
        New-Item -Path $baseDir -ItemType Directory -Force
        Write-Host "Created directory: $baseDir" -ForegroundColor Green
    }
    
    Write-Host "Downloading Trading.com MT5..." -ForegroundColor Cyan
    
    if (Download-GoogleDriveFile -FileId $fileId -OutputPath $zipPath) {
        Write-Host "Extracting archive..." -ForegroundColor Cyan
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        # Find and run installer
        $installer = Get-ChildItem -Path $extractPath -Filter "*.exe" -Recurse | Select-Object -First 1
        if ($installer) {
            Write-Host "Installing MT5 to $installPath..." -ForegroundColor Cyan
            Start-Process -FilePath $installer.FullName -NoNewWindow
            Start-MT5AutoInstall -InstallPath $installPath
            Write-Host "Trading.com MT5 installation completed" -ForegroundColor Green
            
            # Login instead of closing
            Start-Sleep 5
            Login-ToTradingAccount -Config $Config
        }
        
        # Cleanup
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
#endregion

#region Main Execution
$config = Load-Config -ConfigPath "config.yaml"
if (-not $config) {
    Write-Host "Config file required for automated login" -ForegroundColor Red
    exit
}

Show-BrokerMenu
$choice = Read-Host "Enter your choice"

switch ($choice) {
   "1" { Install-ForexComMT5 -Config $config }
   "2" { Install-TradingComMT5 -Config $config }
   "0" { 
       Write-Host "Exiting program..." -ForegroundColor Yellow
       exit 
   }
   default { 
       Write-Host "Invalid selection." -ForegroundColor Red
       exit
   }
}
#endregion