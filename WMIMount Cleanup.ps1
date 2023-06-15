<#
    .SYNOPSIS
        This script scans the registry for mounted Windows Imaging Format (WIM) files, identifying any that may be orphaned. If found, it attempts to dismount and discard these orphaned files.
        
    .DESCRIPTION
        The script first identifies potential orphaned WIM files by examining the registry keys under 'HKLM\SOFTWARE\Microsoft\WIMMount\mounted images'. Any paths matching the 'Mount Path' criteria are deemed to be potentially orphaned.

        It then counts the number of potential orphaned WIMs found. If any are identified, it issues a warning and attempts to dismount each one in turn, logging success or failure for each attempt.

        If no potential orphaned WIMs are found, it confirms this with an output message.

        All output, including error messages, is logged to a file in 'C:\Hosted'.
#>

# Initialize log file
$logFile = "C:\logging\ScriptLog.txt"

# Specify matching sub-key
$subKeyMatch = "Mount Path"

# Initialize array to hold potential orphaned WIMs
$orphMountedWims = @()

# Specify registry key to search
$regMounted = "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WIMMount\mounted images"

# Gather registry keys
$mountedKey = [array](Get-ChildItem "$($regMounted)\" -Recurse -Depth 0)

foreach ($key in $mountedKey) {
    $keyProps = ((Get-Item -path "REGISTRY::$key").property)
    foreach ($subKey in $keyProps) {
        if ($subKey -like "$($subKeyMatch)") {
            $regSubPropValue = Get-ItemProperty -path "REGISTRY::$Key" | Select-Object -ExpandProperty $subKey 
            $orphMountedWims += $regSubPropValue
        }
    }
}

if (($orphMountedWims | Measure-Object).Count -ge 1) {
    $message = "Orphaned WIM(s) have been found."
    Write-Warning $message
    Add-Content -Path $logFile -Value "$(Get-Date) - WARNING: $message"
    
    foreach ($oMWim in $orphMountedWims) { 
        try {
            $message = "Attempting to dismount and discard changes for Orphaned [Path: $($oMWim)]"
            Write-Verbose $message
            Add-Content -Path $logFile -Value "$(Get-Date) - VERBOSE: $message"
            
            Dismount-WindowsImage -Path "$($oMWim)" -Discard
            
            $message = "Success discarding changes."
            Write-Output $message
            Add-Content -Path $logFile -Value "$(Get-Date) - OUTPUT: $message"
        }
        catch [System.exception] {           
            $message = "Error - Failed to dismount and discard changes from Orphaned wim [Mount Path: $($oMWim)]. Error: $($_.exception.message)"
            Write-Error $message
            Add-Content -Path $logFile -Value "$(Get-Date) - ERROR: $message"
            
            continue
        }
    }
}
else {
    $message = "No Orphaned WIM files found, module clear to run."
    Write-Output $message
    Add-Content -Path $log
