function Get-GradientColor {
    param (
        [int[]]$StartColor,
        [int[]]$EndColor,
        [int]$Steps
    )
    $colors = @()
    for ($i = 0; $i -lt $Steps; $i++) {
        $r = [math]::Round($StartColor[0] + ($EndColor[0] - $StartColor[0]) * $i / ($Steps - 1))
        $g = [math]::Round($StartColor[1] + ($EndColor[1] - $StartColor[1]) * $i / ($Steps - 1))
        $b = [math]::Round($StartColor[2] + ($EndColor[2] - $StartColor[2]) * $i / ($Steps - 1))
        $colors += "$r;$g;$b"
    }
    return $colors
}
$logos = @{
    "Windows 11" = @{
        logo = @"
__        __  ___   _   _      _   _ 
\ \      / / |_ _| | \ | |    / | / |
 \ \ /\ / /   | |  |  \| |    | | | |
  \ V  V /    | |  | |\  |    | | | |
   \_/\_/    |___| |_| \_|    |_| |_| 
"@
        startColor = @(0, 255, 255)  
        endColor = @(0, 0, 255)      
    }
    "Windows 10" = @{
        logo = @"
__        __  ___   _   _      _    ___  
\ \      / / |_ _| | \ | |    / |  / _ \ 
 \ \ /\ / /   | |  |  \| |    | | | | | |
  \ V  V /    | |  | |\  |    | | | |_| |
   \_/\_/    |___| |_| \_|    |_|  \___/ 
"@
        startColor = @(0, 0, 255)   
        endColor = @(0, 0, 255)     
    }
    "Windows 7" = @{
        logo = @"
__        __  ___   _   _      _____ 
\ \      / / |_ _| | \ | |    |___  |
 \ \ /\ / /   | |  |  \| |       / / 
  \ V  V /    | |  | |\  |      / /  
   \_/\_/    |___| |_| \_|     /_/   
"@
        startColor = @(0, 255, 255)  
        endColor = @(144, 238, 144)  
    }
    "Windows 8" = @{
        logo = @"
__        __  ___   _   _       ___  
\ \      / / |_ _| | \ | |     ( _ ) 
 \ \ /\ / /   | |  |  \| |     / _ \ 
  \ V  V /    | |  | |\  |    | (_) |
   \_/\_/    |___| |_| \_|     \___/ 
"@
        startColor = @(255, 165, 0) 
        endColor = @(255, 165, 0)    
    }
    "Windows 8.1" = @{
        logo = @"
__        __  ___   _   _       ___        _ 
\ \      / / |_ _| | \ | |     ( _ )      / |
 \ \ /\ / /   | |  |  \| |     / _ \      | |
  \ V  V /    | |  | |\  |    | (_) |  _  | |
   \_/\_/    |___| |_| \_|     \___/  (_) |_|
"@
        startColor = @(255, 165, 0) 
        endColor = @(255, 255, 0)     
    }
    "Windows Unknown" = @{
        logo = @"
__        __  ___   _   _      ___ 
\ \      / / |_ _| | \ | |    |__ \
 \ \ /\ / /   | |  |  \| |      / /
  \ V  V /    | |  | |\  |     |_| 
   \_/\_/    |___| |_| \_|     (_) 
"@
        startColor = @(255, 0, 0)    
        endColor = @(255, 0, 0)      
    }
}
function Print-Logo {
    param (
        [string]$osName
    )
    $logoInfo = $logos[$osName]
    $logo = $logoInfo.logo
    $startRGB = $logoInfo.startColor
    $endRGB = $logoInfo.endColor
    $lines = $logo -split "`n"
    $colors = Get-GradientColor -StartColor $startRGB -EndColor $endRGB -Steps $lines.Length
    foreach ($i in 0..($lines.Length - 1)) {
        $escCode = [char]0x1B + "[38;2;$($colors[$i])m"
        Write-Host "$escCode$($lines[$i])"
    }
}
$os = Get-WmiObject -Class Win32_OperatingSystem
$osVersion = $os.Version
$osCaption = $os.Caption
if ($osVersion -like "10.0*") {
    if ($osCaption -like "*Windows 11*") {
        Print-Logo "Windows 11"
    }
    else {
        Print-Logo "Windows 10"
    }
} elseif ($osVersion -like "6.1*") {
    Print-Logo "Windows 7"
} elseif ($osVersion -like "6.2*" -or $osVersion -like "6.3*") {
    if ($osVersion -like "6.3*") {
        Print-Logo "Windows 8.1"
    } else {
        Print-Logo "Windows 8"
    }
} else {
    Print-Logo "Windows Unknown"
}
function Print-WithDelay {
    param (
        [string]$Text,
        [int]$Delay = 15
    )
    foreach ($char in $Text.ToCharArray()) {
        Write-Host -NoNewline $char
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host
}
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$uptime = python "$scriptDirectory\uptime.py"
$osInfo = Get-WmiObject Win32_OperatingSystem
$os = $osInfo.Caption
$releaseId = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
$totalMemoryKB = $osInfo.TotalVisibleMemorySize
$freeMemoryKB = $osInfo.FreePhysicalMemory
$usedMemoryKB = $totalMemoryKB - $freeMemoryKB
$totalMemoryMB = [math]::Round($totalMemoryKB / 1024)
$usedMemoryMB = [math]::Round($usedMemoryKB / 1024)
$ram = "$usedMemoryMB/$totalMemoryMB MB"
$hostname = $env:COMPUTERNAME
$cpu = (Get-WmiObject Win32_Processor).Name -replace '\s+', ' '
$gpu = (Get-WmiObject Win32_VideoController).Name -replace '\s+', ' '
$network = Get-WmiObject Win32_NetworkAdapterConfiguration | 
           Where-Object { $_.IPEnabled -and $_.IPAddress -ne $null }
$ipv4 = $network.IPAddress | 
        Where-Object { $_ -notlike '*:*' } | 
        Select-Object -First 1
if (-not $ipv4) { $ipv4 = "Not Available" }
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
try {
    $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    $resolution = "$($primaryScreen.Bounds.Width)x$($primaryScreen.Bounds.Height)"
}
catch {
    $resolution = "Unknown"
}
$publicIP = try { 
    Invoke-RestMethod -Uri "https://api.ipify.org" -ErrorAction Stop 
} catch { 
    "Not Available" 
}

Print-WithDelay "Uptime:     $uptime"
Print-WithDelay "OS:         $os ($releaseId)"
Print-WithDelay "Hostname:   $hostname"
Print-WithDelay "User:       $env:USERNAME"
Print-WithDelay "PShell:     $($PSVersionTable.PSVersion)"
Print-WithDelay "IP:         $ipv4"
Print-WithDelay "Public IP:  $publicIP"
Print-WithDelay "CPU:        $cpu"
Print-WithDelay "GPU:        $gpu"
Print-WithDelay "RAM:        $ram"
Print-WithDelay "Resolution: $resolution"
