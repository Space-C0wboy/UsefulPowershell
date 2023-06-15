<#
.SYNOPSIS
This PowerShell script is designed to execute a set of system health check commands and log their output in a verbose manner.

.DESCRIPTION
The script runs a series of commands for checking and repairing the system integrity:
- 'sfc /scannow': This command scans the integrity of all protected system files and replaces incorrect versions with correct Microsoft versions.
- 'Dism /Online /Cleanup-Image /CheckHealth': This command checks for component store corruption and records that corruption to the log file but does not fix any corruption.
- 'Dism /Online /Cleanup-Image /ScanHealth': This command checks for component store corruption, records the corruption to the log file, and also captures a record of the system state at the time.
- 'Dism /Online /Cleanup-Image /RestoreHealth': This command checks for component store corruption, records the corruption to the log file, and also fixes the corruption using Windows Update.
These commands are run twice in sequence for thorough system health check.

The script has a robust logging mechanism that writes output from these commands into a log file in the 'C:\Hosted\' directory.
Each new execution of the script generates a new log file named with a timestamp to avoid overwriting previous logs. 

The script should be run as an Administrator due to the elevated permissions required by the commands.

.NOTES
The script uses Write-Host to also display the log output in the console, in addition to writing it to the log file.
#>

# Define logging function
function LogWrite
{
    param ([string]$logstring)

    Add-content $LogFile -value $logstring
    Write-Host $logstring
}

# Define command execution function
function ExecuteCommand
{
    param ([string]$command)

    LogWrite "Running command: $command"
    
    try
    {
        $output = & cmd.exe /c $command
        LogWrite "Command Output:`n$output"
    }
    catch
    {
        LogWrite "Error encountered while executing command: $($_.Exception.Message)"
    }

    LogWrite "Command completed: $command"
}

# Initialize log file
$LogFile = "C:\logging\logs_$(get-date -f yyyy-MM-dd_hh-mm-ss).txt"
if(!(Test-Path -Path "C:\logging\" ))
{
    New-Item -ItemType directory -Path "C:\logging\"
}
if(!(Test-Path -Path $LogFile ))
{
    New-Item -ItemType file -Path $LogFile
}

# Define and execute commands
$commands = @("sfc /scannow", "Dism /Online /Cleanup-Image /CheckHealth", "Dism /Online /Cleanup-Image /ScanHealth", "Dism /Online /Cleanup-Image /restoreHealth", "sfc /scannow")
foreach($command in $commands)
{
    ExecuteCommand $command
}
