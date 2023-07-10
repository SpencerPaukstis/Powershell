$SageSetKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\"
$CleanupItems = "Update Cleanup"

$CleanupItems | ForEach-Object { 
  $cleanupKeyPath = Join-Path -Path $SageSetKey -ChildPath $_
  Set-ItemProperty -Path $cleanupKeyPath -Name StateFlags0001 -Value 2 -ErrorAction SilentlyContinue 
}

# Add this function to call Disk Cleanup silently. It will perform the cleanup of various system files
function Start-DiskCleanup {
    $CleanmgrScriptPath = "C:\Windows\System32\cleanmgr.exe"

    # Start the cleanup process
    Invoke-Expression -Command "$CleanmgrScriptPath /sagerun:1"
}

Start-DiskCleanup

# Remove files from the Windows Temp folder and the current user's Temp folder
Get-ChildItem -Path "C:\Windows\Temp\*" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Get-ChildItem -Path "$env:TEMP\*" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# Remove temporary files from all User profiles
Get-ChildItem "C:\Users" -Directory | ForEach-Object {
    $UserTemp = $_.FullName + "\AppData\Local\Temp\*"
    Get-ChildItem -Path $UserTemp -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}

# Remove Windows Update temporary files
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Force -Recurse -ErrorAction SilentlyContinue

# Delete System Error Memory Dump Files and minidump files – suppress errors if files are in use
Remove-Item -Path "C:\Windows\Minidump\*" -Force -Recurse -ErrorAction  SilentlyContinue
Remove-Item -Path "C:\Windows\MEMORY.DMP" -Force -ErrorAction  SilentlyContinue

# Delete System Error reports and feedback diagnostics – suppress errors if files are in use
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\*" -Force -Recurse -ErrorAction  SilentlyContinue

# Empty the Recycle Bin - suppress errors if files are in use
$Shell = New-Object -ComObject Shell.Application
$Shell.Namespace(10).Items() | ForEach-Object {Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue -Confirm:$False}
