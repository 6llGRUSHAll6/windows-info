$logo = @"
__        __  ___   _   _ 
\ \      / / |_ _| | \ | |
 \ \ /\ / /   | |  |  \| |
  \ V  V /    | |  | |\  |
   \_/\_/    |___| |_| \_|                                                                                
"@

function Get-GradientColor {
    param(
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
$startRGB = @(0, 255, 255)
$endRGB = @(100, 130, 255)
$logo -split "`n" | ForEach-Object {
    $line = $_
    $colors = Get-GradientColor -StartColor $startRGB -EndColor $endRGB -Steps $line.Length
    $output = ""
    for ($i = 0; $i -lt $line.Length; $i++) {
        $escCode = [char]0x1B + "[38;2;$($colors[$i])m"
        $output += "$escCode$($line[$i])"
    }
    $output += [char]0x1B + "[0m"
    $output
}
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$uptime = python "$scriptDirectory\uptime.py"
$osInfo = Get-WmiObject Win32_OperatingSystem
$os = $osInfo.Caption
$version = $osInfo.Version
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

Write-Host "Uptime:     $uptime"
Write-Host "OS:         $os ($releaseId)"
Write-Host "Version:    $version"
Write-Host "Hostname:   $hostname"
Write-Host "User:       $env:USERNAME"
Write-Host "PShell:     $($PSVersionTable.PSVersion)"
Write-Host "IP:         $ipv4"
Write-Host "Public IP:  $publicIP"
Write-Host "CPU:        $cpu"
Write-Host "GPU:        $gpu"
Write-Host "RAM:        $ram"
Write-Host "Resolution: $resolution"
