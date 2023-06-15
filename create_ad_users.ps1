<#
.SYNOPSIS
    This script automates the process of creating Active Directory users from a CSV file.

.DESCRIPTION
    The script reads a CSV file and for each row, creates a user in Active Directory if one does not already exist with the specified username.
    It sets user attributes such as the name, description, UserPrincipalName, EmployeeID, etc., from the CSV data.
    The user is then added to various groups based on certain conditions.
    If the VPN column is 'Y', the user is added to the 'vpn-access' group.
    If the IQUser column is 'Y', the user is added to the 'SCAC_IQ' group and the script prompts for adding the user to the 'SCAC_FIN' group as well.

    The script writes to a log file under C:\logging, providing detailed information of all operations, successes, skips and errors.

.NOTES
    Make sure to change the CSV column names in the script if they change in the CSV file.
    Ensure that the Active Directory PowerShell module is installed and available for import.
#>

Set-StrictMode -Version latest

$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$newpath  = $directorypath + "\import_create_ad_users.csv"
$logPath  = "C:\logging"
$logFileName = "create_ad_users_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log"
$log      = Join-Path -Path $logPath -ChildPath $logFileName
$date     = Get-Date
$Description = 'Created on ' + $date
$vpnGroup = "vpn-access"
$addn     = (Get-ADDomain).DistinguishedName
$dnsroot  = (Get-ADDomain).DNSRoot
$i        = 1

function LogWrite {
    Param ([string]$logstring)

    Add-Content $log -value "$(Get-Date) - $logstring"
    Write-Output $logstring
}

try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    LogWrite "[ERROR] ActiveDirectory Module couldn't be loaded. Script will stop!"
    Exit 1
}

function Create-Users {
    LogWrite "Processing started on $date"
    LogWrite "--------------------------------------------"
    Import-CSV $newpath | ForEach-Object {
        try {
            if ($_.Username -eq "") {
                throw "Please provide valid Username. Processing skipped for line $($i)"
            }
            
            $sam = $_.Username.ToLower()
            $exists = $null

            try { $exists = Get-ADUser -LDAPFilter "(sAMAccountName=$sam)" } catch {}

            if (!$exists) {
                # Creating the user and adding to the groups
                $setpass = $_.Password
                $SCAC = $_.SCAC.toUpper()
                $IQGroup = $SCAC + "_IQ"
                $IQFinGroup = $SCAC + "_FIN"

                LogWrite "[INFO] Creating user: $sam"

                New-ADUser $sam -GivenName $sam -DisplayName $sam `
                -Description $Description -UserPrincipalName ($sam + "@" + $dnsroot) `
                -EmployeeID $sam -AccountPassword (ConvertTo-SecureString $setpass -AsPlainText -Force) -Enabled $True `
                -PasswordNeverExpires $True -CannotChangePassword $True

                LogWrite "[INFO] Created new user: $sam"
                $dn = (Get-ADUser $sam).DistinguishedName

                # This section adds the new user to their SCAC group in AD.
                Add-ADGroupMember -Identity $_.SCAC.ToUpper() -Member $sam

                # This section adds the user to the vpn vpn-access group if the VPN = 'Y' in the spreadsheet.
                if ($_.VPN -eq "Y") {
                    Add-ADGroupMember -Identity $vpnGroup -Member $sam
                    LogWrite "[INFO] User $sam added to $vpnGroup"
                }

                # This section adds the user to the to SCAC_IQ group if the IQUser = 'Y' in the spreadsheet.
                # It will also ask if the user should be added to the SCAC_FIN group if the IQUser = 'Y' in the spreadsheet.
                if ($_.IQUser -eq "Y") {
                    Add-ADGroupMember -Identity $IQGroup -Member $sam
                    LogWrite "[INFO] User $sam added to $IQGroup"

                    $iqFinancial = Read-Host -Prompt ('Does user ' + $sam + ' require ' + $SCAC + '_FIN access as well? (Y/N)')

                    if ($iqFinancial -eq "Y") {
                        Add-ADGroupMember -Identity $IQFinGroup -Member $sam
                        LogWrite "[INFO] User $sam added to $IQFinGroup"
                    } else {
                        LogWrite "[INFO] Only adding to $IQGroup"
                    }
                }
            } else {
                # Outputs error message if user already exists or otherwise returns another error.
                throw "User $sam already exists or returned an error!"
            }
        } catch {
            LogWrite "[ERROR] Oops, something went wrong: $($_.Exception.Message)"
        } finally {
            $i++
        }
    }
    LogWrite "--------------------------------------------"
}

LogWrite "STARTED SCRIPT"
Create-Users
LogWrite "STOPPED SCRIPT"
