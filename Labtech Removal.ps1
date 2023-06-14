<#
.SYNOPSIS
    This script is designed to uninstall all products whose name starts with 'labtech' or 'ScreenConnect Client',
    stop, disable and delete the 'ltservice', 'ltsvcmon', and 'labvnc' services, kill 'LTTray.exe' process,
    delete specific registry keys, and remove the 'C:\Windows\LTSvc' directory.

.DESCRIPTION
    The script first identifies and uninstalls all products with names beginning with 'labtech' or 'ScreenConnect Client'.
    It then stops, disables and deletes the 'ltservice', 'ltsvcmon', and 'labvnc' services.
    Next, it kills 'LTTray.exe' process if it is running.
    Afterward, it removes two specified registry keys and all their sub-keys and values.
    Lastly, it checks if the 'C:\Windows\LTSvc' directory exists and, if it does, removes it and all its contents.

    Please run this script with administrative privileges as it performs operations that require elevated permissions.
    Be sure to backup your system or at least create a system restore point before running this script.
    It's recommended to test this script in a controlled, non-production environment before deploying it in production.

.NOTES
    Author: Kierston Grantham
    Date Created: 14/06/2023
#>

# Uninstall products with 'labtech' or 'ScreenConnect Client' in the name
$products = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE (Name LIKE 'labtech%') OR (Name LIKE 'ScreenConnect Client%')"
foreach ($product in $products) {
    Write-Host "Uninstalling $($product.Name)"
    $product.Uninstall()
}

# Stop, disable and delete services
$services = "ltservice", "ltsvcmon", "labvnc"
foreach ($service in $services) {
    Write-Host "Stopping and disabling $service"
    try {
        Stop-Service $service -ErrorAction Stop
        Set-Service $service -StartupType Disabled
    } catch {
        Write-Host "$service not running or does not exist."
    }

    Write-Host "Deleting $service"
    try {
        sc.exe delete $service
    } catch {
        Write-Host "Failed to delete $service"
    }
}

# Kill LTTray.exe process
try {
    Get-Process LTTray -ErrorAction Stop | Stop-Process -Force
} catch {
    Write-Host "LTTray process not running or does not exist."
}

# Remove registry keys
$keys = "HKLM:\SOFTWARE\Labtech", "HKLM:\SOFTWARE\Wow6432Node\Labtech"
foreach ($key in $keys) {
    if (Test-Path $key) {
        Write-Host "Removing $key"
        Remove-Item -Path $key -Recurse -Force
    } else {
        Write-Host "$key does not exist"
    }
}

# Remove directory
$dir = "C:\Windows\LTSvc"
if (Test-Path $dir) {
    Write-Host "Removing $dir"
    Remove-Item -Path $dir -Recurse -Force
} else {
    Write-Host "$dir does not exist"
}
