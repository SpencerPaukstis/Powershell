$DocID = "1FAIpQLSdHyq9JzhukW21UZelWsH90wKFfyhYNuxsStut6uSR57ygJfA"

$os = (Get-WmiObject -Class Win32_OperatingSystem).Caption
$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$totalStorage = $disk.Size / 1GB -as [int]
$freeStorage = $disk.FreeSpace / 1GB -as [int]
$usedStorage = $totalStorage - $freeStorage

$EntryID1 = "entry.909595856"  # Entry ID for Computer Name
$EntryID2 = "entry.1274887975" # Entry ID for Operating System
$EntryID3 = "entry.1743270688" # Entry ID for Total Storage
$EntryID4 = "entry.1538239808" # Entry ID for Free Storage
$EntryID5 = "entry.577997690"  # Entry ID for Used Storage
$EntryID6 = "entry.1603480600" # Unused programs

# Specify the number of days to consider a program as not used
$daysToConsider = 90

# Get the current date
$currentDate = Get-Date

# Get all programs installed on the machine
$programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object DisplayName, InstallDate

# Filter out the programs and calculate days since installation
$programsNotUsed = $programs | Where-Object {
    $_.InstallDate -and [datetime]::ParseExact($_.InstallDate, "yyyyMMdd", $null) -lt $currentDate
} | Where-Object { 
    $installDate = [datetime]::ParseExact($_.InstallDate, "yyyyMMdd", $null)
    $daysSince = ($currentDate - $installDate).Days
    $daysSince -ge $daysToConsider
}

$programsNotUsedToString = $programsNotUsed | ForEach-Object { 
    $installDate = [datetime]::ParseExact($_.InstallDate, "yyyyMMdd", $null)
    $daysSince = ($currentDate - $installDate).Days
    "$($_.DisplayName) - $daysSince" 
} | Out-String

# Build the form data to submit
$FormURL = "https://docs.google.com/forms/d/e/$DocID/formResponse"
$FormData = @{
    $EntryID1 = $computerName
    $EntryID2 = $os
    $EntryID3 = $totalStorage
    $EntryID4 = $freeStorage
    $EntryID5 = $usedStorage
    $EntryID6 = $programsNotUsedToString
}

# Post the list of programs not used to the Google form
Invoke-WebRequest -Uri $FormURL -Method POST -Body $FormData