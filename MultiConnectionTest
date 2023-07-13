<#
.SYNOPSIS
   This script pings multiple hosts concurrently.
.DESCRIPTION
   This script uses a custom function to ping a list of hosts in parallel using PowerShell jobs. 
   It collects the results from all jobs, appends a timestamp to each result, and writes the output to a text file. 
   The script runs in an infinite loop, allowing for continuous monitoring of the hosts. 
#>

# Define a custom ping function
function Ping-Host ($TargetHost) {
    # Get the current timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Perform the ping
    $ping = Test-Connection -ComputerName $TargetHost -Count 1 -Quiet -ErrorAction SilentlyContinue

    # Create an output string with the timestamp and the result of the ping
    # If the ping was successful, output a success message
    # If the ping failed, output a failure message
    if($ping){
        "$timestamp - Ping to $TargetHost successful"
    } else {
        "$timestamp - Ping to $TargetHost failed"
    }
}

# Define a list of hosts to ping
$hosts = "google.com", "8.8.8.8"

# Start an infinite loop
while($true){
    # Ping all hosts and write the output to a file
    # Create an empty array to hold all the PowerShell job objects
    $jobs = @()
    foreach ($HostName in $hosts) {
        # For each host in the list, start a new PowerShell job
        # The job will execute the Ping-Host function with the host as the argument
        # The job object is then added to the jobs array
        $jobs += Start-Job -ScriptBlock ${function:Ping-Host} -ArgumentList $HostName
    }

    # Collect results
    foreach ($job in $jobs) {
        # For each job in the jobs array, wait for the job to complete and collect the results
        # The results are then appended to the output file
        # After collecting the results, the job is removed
        Receive-Job $job -Wait | Tee-Object -Append "PingResults.txt"
        Remove-Job $job
    }

    # Wait for a short period of time before the next round of pings
    Start-Sleep -Seconds 5
}
