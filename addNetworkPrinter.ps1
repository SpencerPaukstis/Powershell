# The name that will be displayed for the printer
$printerName = "DEVICE NAME"
# The static IP address for the printer
$printerIP = "LOCAL IP ADDRESS"
# The Driver name - We've found this to be the best one, but may need updated in the future
$driverName = "HP Universal Printing PCL 6"
# Port name (No need to update this variable)
$printerPort = "IP_$printerIP"

# Create a new printer port if it doesn't exist
if (-not (Get-PrinterPort -Name $printerPort -ErrorAction SilentlyContinue)) {
    Add-PrinterPort -Name $printerPort -PrinterHostAddress $printerIP
}

# Check if the driver is installed
if (-not (Get-PrinterDriver -Name $driverName -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Printer Driver."
    Add-PrinterDriver -Name "HP Universal Printing PCL 6"
}

# Add the printer
try {
    Add-Printer -Name $printerName -PortName $printerPort -DriverName $driverName -ErrorAction Stop
    Write-Host "'$printerName' has been added"
} catch {
    Write-Host "Failed to add '$printerName'. Error: $_"
}
