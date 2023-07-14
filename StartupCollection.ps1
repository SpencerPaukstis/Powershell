$DocID = "1FAIpQLScDTp3OcEiaJ9p5X-FwKhwTgzyaVBipyktRQIP9QOvLN9gduw"

$computerName = (Get-WmiObject -Class Win32_ComputerSystem).Name

# Get the list of all startup applications
$programNames = Get-CimInstance -ClassName Win32_StartupCommand |
                Select-Object -ExpandProperty Name 

$EntryID1 = "entry.207912345"  # Entry ID for Computer Name
$EntryID2 = "entry.1685495196" # Entry ID for Programs that run on startup

# Build the form data to submit
$FormURL = "https://docs.google.com/forms/d/e/$DocID/formResponse"
$FormData = @{
    $EntryID1 = $computerName
    $EntryID2 = $programNames -join "`r`n"  # Replaced ', ' with "`r`n"
}

# Post the list of programs not used to the Google form
Invoke-WebRequest -Uri $FormURL -Method POST -Body $FormData

# Exit PowerShell when finished
exit