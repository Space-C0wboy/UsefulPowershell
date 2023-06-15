<#
.SYNOPSIS
This PowerShell script uploads files from a local directory to a remote SFTP server using WinSCP. 

.DESCRIPTION
The script first loads the WinSCP .NET assembly, then sets up the session parameters, including protocol, hostname, 
username, password, and SSH host key fingerprint. It then initiates a connection to the SFTP server.

Once the connection is established, it begins uploading files from the local directory specified in the $localPath variable 
to the remote directory specified in the $remotePath variable.

If a file is successfully uploaded, the script moves that file to a backup directory specified in the $backupPath variable. 
If the upload fails, an error message is logged.

After all files are processed, the script disposes of the session and exits.

This version of the script also logs all activities, errors, and outputs to a file located at "C:\Hosted\winscp_script.log".

.PARAMETER localPath
Specifies the local path where the files to be uploaded are stored.

.PARAMETER remotePath
Specifies the path on the remote SFTP server where the files are to be uploaded.

.PARAMETER backupPath
Specifies the local backup path where files are moved after successful upload.

#>

param (
    $localPath = "C:\Example_Path_Here\*",
    $remotePath = "/Remote_Path_Here/",
    $backupPath = "D:\Example_Backup_Path_Here\"
)
 
try
{
    # Load WinSCP .NET assembly
    Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"
 
    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = "ftp.serverpath.here"
        UserName = "Username"
        Password = "Password"
        SshHostKeyFingerprint = "SSH Key"
    }
 
    $session = New-Object WinSCP.Session
    $session.SessionLogPath = "C:\logging\winscp_script.log"
    $session.DebugLogPath = "C:\logging\winscp_script.log"
    $session.DebugLogLevel = 2 # 0-Off, 1-Fatal, 2-Error, 3-Warning, 4-Info (normal), 5-Debug (verbose)
 
    try
    {
        # Connect
        $session.Open($sessionOptions)
 
        # Upload files, collect results
        $transferResult = $session.PutFiles($localPath, $remotePath)
 
        # Iterate over every transfer
        foreach ($transfer in $transferResult.Transfers)
        {
            # Success or error?
            if ($transfer.Error -eq $Null)
            {
                Write-Host "Upload of $($transfer.FileName) succeeded, moving to backup" -Verbose
                # Upload succeeded, move source file to backup
                $file = $transfer.filename -split '\\' | select -last 1
                $parentpath = $transfer.filename -replace "C:\\Example_Path_Here\\Upload\\(.+)$file",'$1'
                $destinationpath = Join-Path $backupPath $parentpath
                Move-Item $transfer.FileName $destinationpath -Verbose
            }
            else
            {
                Write-Host "Upload of $($transfer.FileName) failed: $($transfer.Error.Message)" -Verbose
            }
        }
    }
    finally
    {
        # Disconnect, clean up
