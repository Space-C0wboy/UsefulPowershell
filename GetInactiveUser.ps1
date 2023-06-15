<#
.SYNOPSIS
   This script identifies all users in a specified Active Directory domain who have been inactive for a certain period of time. 
   It then exports these users' names and the timestamp of their last login to a CSV file.

.DESCRIPTION
   The script imports the Active Directory module and defines a domain and inactivity period in days.
   It then calculates a date that is the specified number of days in the past. 
   It filters all Active Directory users based on the last login timestamp being less than this date and the user being enabled. 
   It selects these users' names and converts the last login timestamp to a readable DateTime format.
   This information is then exported to a CSV file on the current user's desktop.
   It also creates a unique log file in C:\logging, recording when the script has started and ended, along with the total number of users exported.

.PARAMETER domain
   The domain in which to look for inactive users. 
   
.PARAMETER DaysInactive
   The number of days of inactivity after which users should be considered inactive.
#>

# Import the Active Directory module
import-module activedirectory 

# Define the domain and number of days of inactivity
$domain = "exampledomain.com" 
$DaysInactive = 365 

# Calculate a date the specified number of days in the past
$time = (Get-Date).Adddays(-($DaysInactive))

# Define the path to the current user's desktop
$userDesktop = [Environment]::GetFolderPath("Desktop")

# Define the log file path and name with current timestamp
$logFileName = "log_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date)
$logFilePath = "C:\logging\$logFileName"

# Start logging
"Script started at: $(Get-Date)" | Out-File -FilePath $logFilePath -Append

# Get all AD User with lastLogonTimestamp less than our time and set to enable
$users = Get-ADUser -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true} -Properties LastLogonTimeStamp | select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}

# Export to CSV
$users | export-csv "$userDesktop\OLD_User.csv" -notypeinformation

# Finish logging
"$($users.Count) user(s) have been exported to the CSV file. Script ended at: $(Get-Date)" | Out-File -FilePath $logFilePath -Append
