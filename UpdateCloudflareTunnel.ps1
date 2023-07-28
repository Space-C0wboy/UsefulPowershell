# Script starts here

# Define the path to the log file
# This is where all output and errors from this script will be recorded
$logFile = 'C:\Program Files (x86)\cloudflared\UpdateCloudflareTunnel.log'

# Check the log file size, and if it's larger than a threshold (e.g., 100MB), archive it
if ((Get-Item $logFile).Length -gt 100MB) {
    # Create an archive filename with a timestamp
    $archiveFile = '{0}\{1}_{2}.log' -f (Split-Path $logFile), (Split-Path $logFile -Leaf), (Get-Date -Format FileDateTimeUniversal)
    # Move the current log file to the archive file
    Move-Item $logFile $archiveFile
}

# Add a timestamp and some space to the log file to separate instances
# If the file doesn't exist yet, this will create it
Add-Content -Path $logFile -Value "`n`n--- Logging started at $(Get-Date) ---`n"

# Start-Transcript begins a transcript of all command-line input and output in the current session
# It will append to the existing log file rather than overwriting it
Start-Transcript -Path $logFile -Append

# Execute the command sequence in a try block, so that errors can be caught and handled
try {
    # The Write-Verbose cmdlet writes text to the verbose message stream 
    # Here we're logging a message about updating cloudflared
    Write-Verbose "Updating cloudflared"
    
    # Run the command 'cloudflared update' 
    # The '2>&1' part is redirecting standard error (2) to the same location as standard output (1)
    cloudflared update 2>&1

    # Logging a message about starting the cloudflared service
    Write-Verbose "Starting cloudflared service"
    
    # The Start-Service cmdlet sends a start message to the Windows Service Controller for each of the specified services
    Start-Service -Name cloudflared 2>&1
}
# The catch block is where you specify the action to take if an error occurs in the try block
catch {
    # Write-Error writes an object to the error pipeline 
    # The $_ automatic variable refers to the current object; in this case, the error object
    Write-Error $_
}
# The finally block statements run regardless of whether an error occurred in the try block
finally {
    # Use Stop-Transcript to stop logging
    Stop-Transcript
}

# Script ends here
