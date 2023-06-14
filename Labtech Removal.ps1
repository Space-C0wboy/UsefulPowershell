<#
.SYNOPSIS
    This script is designed to uninstall all products whose name starts with 'labtech',
    stop and delete the 'ltservice' and 'ltsvcmon' services, delete specific registry keys,
    and remove the 'C:\Windows\LTSvc' directory.

.DESCRIPTION
    The script first identifies and uninstalls all products with names beginning with 'labtech'.
    It then stops and deletes the 'ltservice' and 'ltsvcmon' services.
    Next, it removes two specified registry keys and all their sub-keys and values.
    Lastly, it checks if the 'C:\Windows\LTSvc' directory exists and, if it does, removes it and all its contents.

    Please run this script with administrative privileges as it performs operations that require elevated permissions.
    Be sure to backup your system or at least create a system restore point before running this script.
    It's recommended to test this script in a controlled, non-production environment before deploying it in production.

.NOTES
    Author: Kierston Grantham
    Date Created: 06/14/2023
#>

# Uninstall products with 'labtech' in the name
$products = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE (Name LIKE 'labtech%')"
foreach ($product in $products) {
    Write-Host "Uninstalling $($product.Name)"
    $product.Uninstall()
}

# Stop and delete services
$services = "ltservice", "ltsvcmon"
foreach ($service in $services) {
    Write-Host "Stopping $service"
    try {
        Stop-Service $service -ErrorAction Stop
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
