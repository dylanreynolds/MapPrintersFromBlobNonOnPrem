# Create a log of all results everytime this script runs
Start-Transcript -Path "C:\ProgramData\InTunePrinterMapping\PrinterMapping.log"

$printMappingConfig = @()
$folder = "C:\ProgramData\IntunePrintDrivers"

# Update below custom objects to create required printer mappings
$printMappingConfig += [PSCUSTOMOBJECT]@{
    printerName = "FX ApeosPort-VII C6673"
    printerPortName = "IP_xxx.xxx.xxx.xxx"
    printerPortIP = "xxx.xxx.xxx.xxx"
    driverName = "FX ApeosPort-VII C6673 PCL 6"
}

<# $printMappingConfig += [PSCUSTOMOBJECT]@{
    printerName = "Head Office - GF Canon MFP Printer"
    printerPortName = "IP_xxx.xxx.xxx.xxx"
    printerPortIP = "xxx.xxx.xxx.xxx"
    driverName = "Canon Generic UFR II V4"
} #>

# $printMappingConfig += [PSCUSTOMOBJECT]@{
#     printerName = "Head Office - Dispatch - OKI Printer"
#     printerPortName = "IP_xxx.xxx.xxx.xxx"
#     printerPortIP = "xxx.xxx.xxx.xxx"
#     driverName = "OKI B401"
# }

Write-Output "Starting script."

$printMappingConfig.GetEnumerator() | ForEach-Object {
    # Check printer already exists
    Write-Output "Checking for printer $($PSItem.printerName) on port $($PSItem.printerPortName)"
    $checkPrinterExists = Get-Printer -Name $($PSItem.printerName) -ErrorAction SilentlyContinue

    if ($checkPrinterExists -ne $null ) {
        Write-Output "Skipped. Printer $($PSItem.printerName) already exists."
    } else {
        # If path already exists
        if (Test-Path -path $folder) {
            Write-Output "Skipped. Path $folder and possibly driver already exists."
        } else{
            # Make the folder
            mkdir $folder
            if ($($PSItem.printerName) -match "Canon") {
                # Get Canon print drivers from blob
                Write-Output "Downloading Canon drivers."
                wget "https://yourtenancy.blob.core.windows.net/printerdrivers/cnnv4_cb3_amd64.cab" -outfile $folder'\cnnv4_cb3_amd64.cab'

            } elseif ($($PSItem.printerName) -match "OKI") {
                # Get OKI print drivers from blob
                Write-Output "Downloading OKI drivers."
                Write-Output "OKI Requires manual installation at this time."
            } else {
                Write-Output "No matching printer types, please update script and upload appropriate printer drivers to blob."
            }
        }

        if ($($PSItem.printerName) -match "Canon") {
            # Add print driver via pnputil
            pnputil -i -a "C:\ProgramData\IntunePrintDrivers\cnnv4_cb3_fgeneric.inf"
            # Add print driver via pnputil
            Add-PrinterPort -Name $($PSItem.printerPortName) -PrinterHostAddress $($PSItem.printerPortIP) -ErrorAction SilentlyContinue
            Add-PrinterDriver -Name $($PSItem.driverName)
            Add-Printer -Name $($PSItem.printerName) -DriverName $($PSItem.driverName) -PortName $($PSItem.printerPortName)
        } elseif ($($PSItem.printerName) -match "OKI") {
            Write-Output "OKI Requires manual installation at this time."
        }
    }
}


Stop-Transcript
