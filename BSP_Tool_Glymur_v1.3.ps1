$_creator = "Mike Lu (lu.mike@inventec.com)"
$_version = 1.3
$_changedate = 11/12/2025


# User-defined settings
$thumbdrive = "TEST"


# PATH settings
$BSP_driver = "regrouped_driver_ATT_Signed"
$product = "glymur-wp-1-0_amss_standard_oem"
$product_id = "8480"
$enable_debugMode = $false
$new_driver = "Updated_driver"
$iso_folder = "ISO"
$fuse_folder = "FUSE"

# BSP to ISO mapping
$bspToIsoMapping = @{
	'r01900' = '26394'
	'r02100' = '27842'
    'r02300' = '27863'
    'r02500' = '27863'
    'r02900' = '27871'
    'r03000' = '27902'
	'r03300' = '27902'
	'r03500' = '27924'
	'r03500_x2' = '27924'
	'r03900' = '27950'
	'r03900_x2' = '27965'
	'r04000' = '27965'
	'r04000_x1' = '27965'
    'r04100' = ''
	'r04300' = ''
	'r04500' = ''
}

# Specific driver settings for Installer (CashmereQ only)
$remove_driver = @(
    "qcSensorsConfig$product_id",
    "Qccamtelesensor$product_id",
    "Qccamultrawidesensor$product_id",
    "qccamultrawidesensor_extension$product_id",
    "qccamtelesensor_extension$product_id",
    "qccamrearsensor_extension$product_id",
    "qccamrearsensor$product_id",
    "qcAlwaysOnSensing"
)
$add_driver = @(
    "qccamflash_ext$product_id"  # Added to the later of qccamflash$product_id
)
$driverCheckList = @(
    @{ path = "qcdxext_crd$product_id/qcdxext_crd$product_id.inf"; label = "Gfx" },
	@{ path = "qcasd_apo$product_id/qcasd_apo$product_id.inf"; label = "Audio" },
	@{ path = "qcadx_ext$product_id/qcadx_ext$product_id.inf"; label = "SVA" },
    @{ path = "qccamauxsensor_extension$product_id/qccamauxsensor_extension$product_id.inf"; label = "Camera (IR)" },
    @{ path = "qccamfrontsensor_extension$product_id/qccamfrontsensor_extension$product_id.inf"; label = "Camera (5MP)" },
    @{ path = "qccamisp_ext$product_id/qccamisp_ext$product_id.inf"; label = "Camera (ISP)" },
	@{ path = "qcSensors$product_id/qcSensors$product_id.inf"; label = "Sensor" },
    @{ path = "qcSensorsConfigCrd$product_id/qcSensorsConfigCrd$product_id.inf"; label = "SensorConfig" },
    @{ path = "qcsubsys_ext_adsp$product_id/qcsubsys_ext_adsp$product_id.inf"; label = "aDSP" },
    @{ path = "QcTreeExtOem$product_id/QcTreeExtOem$product_id.inf"; label = "QcTreeExtOem" },
	@{ path = "QcTreeExtQcom$product_id/QcTreeExtQcom$product_id.inf"; label = "QcTreeExtQcom" }
	# @{ path = "qcnspmcdm$product_id/qcnspmcdm$product_id.inf"; label = "Hexagon NPU (cDSP)" },
	# @{ path = "QcXhciFilter$product_id/QcXhciFilter$product_id.inf"; label = "xHCI" },
	# @{ path = "QcUsb4Filter$product_id/QcUsb4Filter$product_id.inf"; label = "USB4" }
	# @{ path = "qcscm$product_id/qcscm$product_id.inf"; label = "QcSCM" },
	# @{ path = "qcbluetooth$product_id/qcbluetooth$product_id.inf"; label = "BT" },
	# @{ path = "qci2c$product_id/qci2c$product_id.inf"; label = "I2C bus" },
	# @{ path = "qcspi$product_id/qcspi$product_id.inf"; label = "SPI bus" }
)

function Set-DebugModeInTotalUpdate {
    param(
        [string]$DesktopScriptsPath,
        [bool]$EnableDebug,
        [switch]$SuppressMessages,
        [switch]$SkipCompletionMessage
    )

    if (-not $DesktopScriptsPath) { return $false }
    $totalUpdatePath = Join-Path $DesktopScriptsPath 'TotalUpdate.bat'
    if (!(Test-Path $totalUpdatePath)) {
        if (-not $SuppressMessages) {
            Write-Host "TotalUpdate.bat not found under $DesktopScriptsPath" -ForegroundColor Yellow
        }
        return $false
    }

    if (-not $SuppressMessages) {
        if ($EnableDebug) {
            Write-Host "Enabling debug mode in TotalUpdate.bat..." -ForegroundColor Cyan
        } else {
            Write-Host "Disabling debug mode in TotalUpdate.bat..." -ForegroundColor Cyan
        }
    }

    $replacement = if ($EnableDebug) { 'bcdedit /set {default} debug on' } else { 'bcdedit /set {default} debug off' }
    $pattern = 'bcdedit\s*/set\s*\{default\}\s*debug\s*(on|off)'
    $success = $false

    try {
        $content = Get-Content -Path $totalUpdatePath -Raw -Encoding Default
        $newContent = [System.Text.RegularExpressions.Regex]::Replace(
            $content,
            $pattern,
            $replacement,
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
        if ($content -ne $newContent) {
            Set-Content -Path $totalUpdatePath -Value $newContent -Encoding Default
        }
        $success = $true
    } catch {
        Write-Host "Failed to update debug mode in TotalUpdate.bat: $_" -ForegroundColor Red
    }

    if ($success -and -not $SkipCompletionMessage -and -not $SuppressMessages) {
        Write-Host "Completed!" -ForegroundColor Green
    }

    return $success
}

        
# Check if run as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script with administrator privileges " -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit
}

# Main menu
Write-Host "=========================="
Write-Host "1) Download BSP package"
Write-Host "2) Create USB installer"
Write-Host "3) Update drivers (non-WinPE)"
Write-Host "4) Display driver info"    
Write-Host "5) Copy thumbdrive to USB" 
Write-Host "6) Make version.exe"
Write-Host "7) Inspect secure sign"
Write-Host "=========================="

do {
    $mainSelection = Read-Host "Select a function"
} until ($mainSelection -eq '1' -or $mainSelection -eq '2' -or $mainSelection -eq '3' -or $mainSelection -eq '4' -or $mainSelection -eq '5' -or $mainSelection -eq '6' -or $mainSelection -eq '7')

switch ($mainSelection) {
    '1' {
        # Download BSP
        # Get versions from ChipCode
        $tags = git ls-remote --tags https://chipmaster2.qti.qualcomm.com/home/git/inventec-corp/$product.git |
            ForEach-Object {
                if ($_ -match "refs/tags/([^{}]+)\^\{\}") {
                    $tag = $matches[1].Trim()
                    $tag
                }
            }

        # Display the list
        Write-Host ""
        Write-Host "List of the releases:"
        $maxIndexLen = ($tags.Count).ToString().Length
        foreach ($idx in 0..($tags.Count-1)) {
            $num = ($idx+1).ToString().PadLeft($maxIndexLen)
            Write-Host ("{0}) {1}" -f $num, $tags[$idx])
        }

        # User input
        do {
            $selection = Read-Host "Enter the number"
            $valid = $selection -match '^\d+$' -and $selection -ge 1 -and $selection -le $tags.Count
            if (-not $valid) {
            }
        } until ($valid)

        $version = $tags[$selection - 1]
        Write-Host "Selected version: " -NoNewline
        Write-Host $version -ForegroundColor Cyan
        Write-Host ""

        # Config git parameters
        git config --global http.'https://chipmaster2.qti.qualcomm.com'.followRedirects "true"
        git config --global core.autocrlf true
        git config --global http.postBuffer 524288000   # 500MB
        git config --global core.longpaths true

        # Run git clone
        $targetFolder = "${product}_$version"
        # git clone -b $version --depth 1 https://qpm-git.qualcomm.com/home2/git/inventec-corp/$product.git ./$targetFolder
        git clone -b $version --depth 1 https://chipmaster2.qti.qualcomm.com/home/git/inventec-corp/$product.git ./$targetFolder
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nCompleted!" -ForegroundColor Green
        } else {
            Write-Host "`nDownload failed!" -ForegroundColor Red
        }
        Write-Host ""
        Read-Host "Press Enter to exit..."
    }
    '2' {
        # Create USB installer
        # Only list folders starting with product name
        $folders = Get-ChildItem -Directory | Where-Object { $_.Name -like ("$product*") }
        if ($folders.Count -eq 0) {
            Write-Host "No folders found" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        Write-Host ""
        # Display the downloaded BSP list
        Write-Host "List of the BSP source packages:"
        $maxIndexLen = ($folders.Count).ToString().Length
        for ($i = 0; $i -lt $folders.Count; $i++) {
            $num = ($i+1).ToString().PadLeft($maxIndexLen)
            Write-Host ("{0}) {1}" -f $num, $folders[$i].Name)
        }
        do {
            $selection = Read-Host "Enter the number"
            $valid = $selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $folders.Count
        } until ($valid)
        $srcRoot = $folders[$selection - 1].FullName
		Write-Host "Selected: " -NoNewline
		Write-Host "$($folders[$selection -1].Name)" -ForegroundColor Yellow
		Write-Host ""

        # Create $thumbdrive folder if not exists
        $toUsbFolder = Join-Path $PWD $thumbdrive
        if (!(Test-Path $toUsbFolder)) {
            New-Item -Path $toUsbFolder -ItemType Directory | Out-Null
        }

        # Copy required BSP package files (Thumbdrive/Firmware/DesktopScripts/regrouped_driver)
        Write-Host "Copying BSP source package to Thumbdrive..." -ForegroundColor Cyan
        $prebuiltPath = Join-Path $srcRoot 'WP/prebuilt'
        $numFolder = $product_id
        $srcThumbdrive = Join-Path (Join-Path $prebuiltPath $numFolder) 'ISOGEN_QCReference/Thumbdrive'
        if (!(Test-Path $srcThumbdrive)) {
            Write-Host "Source package not found: $srcThumbdrive" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        $dstFolder = Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $toUsbFolder 'WP') 'prebuilt') $numFolder) 'ISOGEN/emmcdl_method'
        $dstPrebuilt = Join-Path -Path (Join-Path -Path (Join-Path -Path $toUsbFolder 'WP') 'prebuilt') $numFolder
        $debugTargets = @()
        if (Test-Path $dstFolder) {
            do {
                $overwrite = Read-Host "Thumbdrive folder already exists, overwrite? (y/n)"
            } until ($overwrite -eq 'y' -or $overwrite -eq 'Y' -or $overwrite -eq 'n' -or $overwrite -eq 'N')
            if ($overwrite -eq 'n' -or $overwrite -eq 'N') {
                Write-Host "Skip copying BSP package files" -ForegroundColor Yellow
                Write-Host ""
            } else {
                Remove-Item -Path $dstFolder -Recurse -Force
                New-Item -Path $dstFolder -ItemType Directory -Force | Out-Null
                Copy-Item -Path $srcThumbdrive -Destination $dstFolder -Recurse -Force
                $thumbdriveRoot = Join-Path $dstFolder 'Thumbdrive'
                if (Test-Path $thumbdriveRoot) {
                    $debugTargets += $thumbdriveRoot
                }
                Write-Host "Completed!" -ForegroundColor Green
                Write-Host ""
                # Copy DesktopScripts
                $srcDesktopScripts = Join-Path (Join-Path $prebuiltPath $numFolder) 'DesktopScripts'
                $dstDesktopScripts = Join-Path $dstPrebuilt 'DesktopScripts'
                if (Test-Path $srcDesktopScripts) {
                    if (Test-Path $dstDesktopScripts) { Remove-Item -Path $dstDesktopScripts -Recurse -Force }
                    Copy-Item -Path $srcDesktopScripts -Destination $dstPrebuilt -Recurse -Force
                    if (Test-Path $dstDesktopScripts) { $debugTargets += $dstDesktopScripts }
                }
                # Copy firmware
                $srcFirmware = Join-Path (Join-Path $prebuiltPath $numFolder) 'firmware'
                $dstFirmware = Join-Path $dstPrebuilt 'firmware'
                if (Test-Path $srcFirmware) {
                    if (Test-Path $dstFirmware) { Remove-Item -Path $dstFirmware -Recurse -Force }
                    Copy-Item -Path $srcFirmware -Destination $dstPrebuilt -Recurse -Force
                }
                # Copy $BSP_driver
                $srcDriver = Join-Path (Join-Path $prebuiltPath $numFolder) $BSP_driver
                if (Test-Path $srcDriver) {
                    $dstDriver = Join-Path $dstPrebuilt 'regrouped_driver'
                    if ($BSP_driver -eq 'regrouped_driver_ATT_Signed') {
                        if (Test-Path $dstDriver) { Remove-Item -Path $dstDriver -Recurse -Force }
                        New-Item -Path $dstDriver -ItemType Directory -Force | Out-Null
                        Copy-Item -Path (Join-Path $srcDriver '*') -Destination $dstDriver -Recurse -Force
                    } else {
                        $dstOtherDriver = Join-Path $dstPrebuilt $BSP_driver
                        if (Test-Path $dstOtherDriver) { Remove-Item -Path $dstOtherDriver -Recurse -Force }
                        Copy-Item -Path $srcDriver -Destination $dstPrebuilt -Recurse -Force
                    }
                }
            }
        } else {
            New-Item -Path $dstFolder -ItemType Directory -Force | Out-Null
            Copy-Item -Path $srcThumbdrive -Destination $dstFolder -Recurse -Force
            $thumbdriveRoot = Join-Path $dstFolder 'Thumbdrive'
            if (Test-Path $thumbdriveRoot) {
                $debugTargets += $thumbdriveRoot
            }
            Write-Host "Completed!" -ForegroundColor Green
            Write-Host ""
            # Copy DesktopScripts
            $srcDesktopScripts = Join-Path (Join-Path $prebuiltPath $numFolder) 'DesktopScripts'
            $dstDesktopScripts = Join-Path $dstPrebuilt 'DesktopScripts'
            if (Test-Path $srcDesktopScripts) {
                if (Test-Path $dstDesktopScripts) { Remove-Item -Path $dstDesktopScripts -Recurse -Force }
                Copy-Item -Path $srcDesktopScripts -Destination $dstPrebuilt -Recurse -Force
                if (Test-Path $dstDesktopScripts) { $debugTargets += $dstDesktopScripts }
            }
            # Copy firmware
            $srcFirmware = Join-Path (Join-Path $prebuiltPath $numFolder) 'firmware'
            $dstFirmware = Join-Path $dstPrebuilt 'firmware'
            if (Test-Path $srcFirmware) {
                if (Test-Path $dstFirmware) { Remove-Item -Path $dstFirmware -Recurse -Force }
                Copy-Item -Path $srcFirmware -Destination $dstPrebuilt -Recurse -Force
            }
            # Copy $BSP_driver
            $srcDriver = Join-Path (Join-Path $prebuiltPath $numFolder) $BSP_driver
            if (Test-Path $srcDriver) {
                $dstDriver = Join-Path $dstPrebuilt 'regrouped_driver'
                if ($BSP_driver -eq 'regrouped_driver_ATT_Signed') {
                    if (Test-Path $dstDriver) { Remove-Item -Path $dstDriver -Recurse -Force }
                    New-Item -Path $dstDriver -ItemType Directory -Force | Out-Null
                    Copy-Item -Path (Join-Path $srcDriver '*') -Destination $dstDriver -Recurse -Force
                } else {
                    $dstOtherDriver = Join-Path $dstPrebuilt $BSP_driver
                    if (Test-Path $dstOtherDriver) { Remove-Item -Path $dstOtherDriver -Recurse -Force }
                    Copy-Item -Path $srcDriver -Destination $dstPrebuilt -Recurse -Force
                }
            }
        }

        if ($debugTargets.Count -gt 0) {
            $printed = $false
            $updated = $false
            foreach ($targetPath in $debugTargets) {
                $params = @{
                    DesktopScriptsPath    = $targetPath
                    EnableDebug           = $enable_debugMode
                    SkipCompletionMessage = $true
                }
                if ($printed) { $params.SuppressMessages = $true }
                if (Set-DebugModeInTotalUpdate @params) {
                    $updated = $true
                    if (-not $printed) { $printed = $true }
                }
            }
            if ($updated) {
                Write-Host "Completed!" -ForegroundColor Green
            }
        }

        # Copy ADK files (DISM & BCDBoot)
		Write-Host ""
        Write-Host "Copying ADK files to Thumbdrive..." -ForegroundColor Cyan
        $adkDism = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Dism\Dism.exe"
        $adkDismFolder = Split-Path $adkDism -Parent
        $adkBcdBootFolder = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\BCDBoot"
        $adkVersion = $null
        if (Test-Path $adkDism) {
            $adkVersion = (Get-Item $adkDism).VersionInfo.ProductVersion.ToString().Trim()
			# $adkVersion = (Get-Package | Where-Object { $_.Name -like "Windows Deployment Tools" }).Version.ToString().Trim()
            Write-Host "ADK version: " -NoNewline
            
            # Get selected BSP version from folder name for ADK version check
            $selectedBspName = $folders[$selection - 1].Name
            $bspVersion = $null
            # Try to match r03900_x2 format first
            if ($selectedBspName -match 'r\d{5}\.\d+_x(\d+)') {
                $bspVersion = "r" + ($selectedBspName -replace '.*r(\d{5})\.\d+_x(\d+).*', '$1') + "_x" + ($selectedBspName -replace '.*r(\d{5})\.\d+_x(\d+).*', '$2')
            } elseif ($selectedBspName -match 'r\d{5}(_x\d+)?') {
                $bspVersion = $selectedBspName -replace '.*(r\d{5}(_x\d+)?).*', '$1'
            } else {
                # Fallback: try to extract just the version number
                if ($selectedBspName -match 'r(\d{5})') {
                    $bspVersion = "r" + $matches[1]
                }
            }
            
            # Get expected ISO version for selected BSP
            $expectedIsoVersionForAdk = $null
            if ($bspVersion -and $bspToIsoMapping.ContainsKey($bspVersion)) {
                $expectedIsoVersionForAdk = $bspToIsoMapping[$bspVersion]
            }
            

            
            # Check if ADK version matches expected ISO version
            $adkVersionColor = "White"
            if ($expectedIsoVersionForAdk -and $adkVersion -match "^.*$expectedIsoVersionForAdk.*$") {
                $adkVersionColor = "Blue"
            } elseif ($expectedIsoVersionForAdk) {
                $adkVersionColor = "Red"
            }
            
            Write-Host $adkVersion -ForegroundColor $adkVersionColor
        } else {
            Write-Host "ADK not found. Please install Windows ADK first!" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        do {
            $adkContinue = Read-Host "Continue to copy ADK files? (y/n)"
        } until ($adkContinue -eq 'y' -or $adkContinue -eq 'Y' -or $adkContinue -eq 'n' -or $adkContinue -eq 'N')
        if ($adkContinue -eq 'n' -or $adkContinue -eq 'N') {
            Write-Host "Copy cancelled" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        $thumbdriveDst = Join-Path $dstFolder 'Thumbdrive'
        try {
            Copy-Item -Path $adkDismFolder -Destination $thumbdriveDst -Recurse -Force
            Copy-Item -Path $adkBcdBootFolder -Destination $thumbdriveDst -Recurse -Force
            Write-Host "Completed!" -ForegroundColor Green
        } catch {
            Write-Host "Failed to copy ADK files: $_" -ForegroundColor Red
        }
        Write-Host ""

        # Copy OS ISO folders (boot/efi/sources/support)
        Write-Host "Copying OS ISO folders to Thumbdrive..." -ForegroundColor Cyan
        $isoDir = Join-Path $PWD $iso_folder
        $isoFiles = Get-ChildItem -Path $isoDir -Filter *.iso
        if ($isoFiles.Count -eq 0) {
            Write-Host "No ISO files found in ISO directory. Please put the OS ISO file in the ISO folder." -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        # List ISO files, excluding "ADK"
        $isoFiles = $isoFiles | Where-Object { $_.Name -notmatch 'ADK' }
        
        # Get selected BSP version from folder name
        $selectedBspName = $folders[$selection - 1].Name
        $bspVersion = $null
        # Try to match r03900_x2 format first
        if ($selectedBspName -match 'r\d{5}\.\d+_x(\d+)') {
            $bspVersion = "r" + ($selectedBspName -replace '.*r(\d{5})\.\d+_x(\d+).*', '$1') + "_x" + ($selectedBspName -replace '.*r(\d{5})\.\d+_x(\d+).*', '$2')
        } elseif ($selectedBspName -match 'r\d{5}(_x\d+)?') {
            $bspVersion = $selectedBspName -replace '.*(r\d{5}(_x\d+)?).*', '$1'
        } else {
            # Fallback: try to extract just the version number
            if ($selectedBspName -match 'r(\d{5})') {
                $bspVersion = "r" + $matches[1]
            }
        }

        # Get expected ISO version for selected BSP
        $expectedIsoVersion = $null
        if ($bspVersion -and $bspToIsoMapping.ContainsKey($bspVersion)) {
            $expectedIsoVersion = $bspToIsoMapping[$bspVersion]
        }
        
        Write-Host "List of ISO files:"
        for ($i = 0; $i -lt $isoFiles.Count; $i++) {
            $isoFileName = $isoFiles[$i].Name
            $isMatched = $false
            
            # Check if this ISO matches the expected version for selected BSP
            if ($expectedIsoVersion -and $isoFileName -match "^.*$expectedIsoVersion.*$") {
                $isMatched = $true
            }
            
            if ($isMatched) {
                Write-Host ("{0}) " -f ($i+1)) -NoNewline
                Write-Host $isoFileName -ForegroundColor Blue
            } else {
                Write-Host ("{0}) " -f ($i+1)) -NoNewline
                Write-Host $isoFileName
            }
        }
        do {
            $isoSelection = Read-Host "Enter the number"
            $valid = $isoSelection -match '^\d+$' -and $isoSelection -ge 1 -and $isoSelection -le $isoFiles.Count
        } until ($valid)
        $isoPath = $isoFiles[$isoSelection - 1].FullName
        try {
            Write-Host "Mounting ISO..." 
            Mount-DiskImage -ImagePath $isoPath -PassThru | Out-Null
            $driveLetter = (Get-DiskImage -ImagePath $isoPath | Get-Volume).DriveLetter + ":"
            $isoFolders = @("boot", "efi", "sources", "support")
            $allExist = $true
            foreach ($folder in $isoFolders) {
                if (!(Test-Path (Join-Path $driveLetter $folder))) {
                    $allExist = $false
                    break
                }
            }
            if (-not $allExist) {
                Write-Host "One or more required folders (boot, efi, sources, support) not found in ISO." -ForegroundColor Red
                Write-Host "Unmounting ISO..." 
                Dismount-DiskImage -ImagePath $isoPath | Out-Null
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            }
            foreach ($folder in $isoFolders) {
                Copy-Item -Path (Join-Path $driveLetter $folder) -Destination $thumbdriveDst -Recurse -Force
            }
            Write-Host "Unmounting ISO..." 
            Dismount-DiskImage -ImagePath $isoPath | Out-Null
            $installWim = Join-Path $thumbdriveDst "sources\install.wim"
            if (Test-Path $installWim) {
                Move-Item -Path $installWim -Destination $thumbdriveDst -Force
            }
            Write-Host "Completed!" -ForegroundColor Green
            
            # Check if the copied OS ISO is ARM based
            $bootaa64Path = Join-Path $thumbdriveDst "efi\boot\bootaa64.efi"
            $bootx64Path = Join-Path $thumbdriveDst "efi\boot\bootx64.efi"
            if (Test-Path $bootx64Path) {
                Write-Host "The copied OS ISO is not arm based" -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            } elseif (!(Test-Path $bootaa64Path)) {
                Write-Host "bootaa64.efi not found in efi\boot\" -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            }
        } catch {
            Write-Host "Failed to copy ISO folders: $_" -ForegroundColor Red
        }
        Write-Host ""

        # Copy WinPE Add-ons file (winpe.win) and delete boot.wim
        Write-Host "Copying WinPE file to Thumbdrive..." -ForegroundColor Cyan
        $winpeWim = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\arm64\en-us\winpe.wim"
		try {
			$winpeVersion = (Get-Package | Where-Object { $_.Name -like "Windows PE Boot Files (DesktopEditions)*" }).Version.ToString().Trim()
		} catch {
			$winpeVersion = $null
		}
	
        if ($winpeVersion) {
            Write-Host "WinPE version: " -NoNewline
            
            # Get selected BSP version from folder name for WinPE version check
            $selectedBspName = $folders[$selection - 1].Name
            $bspVersion = $null
            # Try to match r03900_x2 format first
            if ($selectedBspName -match 'r\d{5}\.\d+_x(\d+)') {
                $bspVersion = "r" + ($selectedBspName -replace '.*r(\d{5})\.\d+_x(\d+).*', '$1') + "_x" + ($selectedBspName -replace '.*r(\d{5})\.\d+_x(\d+).*', '$2')
            } elseif ($selectedBspName -match 'r\d{5}(_x\d+)?') {
                $bspVersion = $selectedBspName -replace '.*(r\d{5}(_x\d+)?).*', '$1'
            } else {
                # Fallback: try to extract just the version number
                if ($selectedBspName -match 'r(\d{5})') {
                    $bspVersion = "r" + $matches[1]
                }
            }
            
            # Get expected ISO version for selected BSP
            $expectedIsoVersionForWinPE = $null
            if ($bspVersion -and $bspToIsoMapping.ContainsKey($bspVersion)) {
                $expectedIsoVersionForWinPE = $bspToIsoMapping[$bspVersion]
            }
            
            # Check if WinPE version matches expected ISO version
            $winpeVersionColor = "White"
            if ($expectedIsoVersionForWinPE -and $winpeVersion -match "^.*$expectedIsoVersionForWinPE.*$") {
                $winpeVersionColor = "Blue"
            } elseif ($expectedIsoVersionForWinPE) {
                $winpeVersionColor = "Red"
            }
            
            Write-Host $winpeVersion -ForegroundColor $winpeVersionColor
        } else {
            Write-Host "WinPE Add-ons not found. Please install WinPE Add-ons first!" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        do {
            $winpeContinue = Read-Host "Continue to copy WinPE file? (y/n)"
        } until ($winpeContinue -eq 'y' -or $winpeContinue -eq 'Y' -or $winpeContinue -eq 'n' -or $winpeContinue -eq 'N')
        if ($winpeContinue -eq 'n' -or $winpeContinue -eq 'N') {
            Write-Host "Copy cancelled" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        $destSources = Join-Path $thumbdriveDst "sources"
        try {
            Copy-Item -Path $winpeWim -Destination $destSources -Force
            $bootWim = Join-Path $destSources "boot.wim"
            if (Test-Path $bootWim) {
                Remove-Item -Path $bootWim -Force
            }
            Write-Host "Completed!" -ForegroundColor Green
        } catch {
            Write-Host "Failed to copy WinPE file: $_" -ForegroundColor Red
        }
        Write-Host ""

        # Copy customized drivers
        Write-Host "Copying customized drivers..." -ForegroundColor Cyan

        $iecDriverFolder = Join-Path $PWD $new_driver
        if (!(Test-Path $iecDriverFolder)) {
            Write-Host "Updated_driver folder not found" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }

        # Get all the folders in Updated_driver
        $iecSubFolders = Get-ChildItem -Path $iecDriverFolder -Directory
        if ($iecSubFolders.Count -eq 0) {
            Write-Host "No subfolders found in Updated_driver." -ForegroundColor Yellow
            Write-Host ""
        } else {
            # Check if there's any sub-directory (Only ADSP/CDSP/HTP/qcdeviceinfo and ARM64 (qcdpps.exe/qdcmlib.dll) folders are allowed)
            foreach ($sub in $iecSubFolders) {
                $subSubFolders = Get-ChildItem -Path $sub.FullName -Directory
                foreach ($subSub in $subSubFolders) {
                    $isADSP = ($subSub.Name -eq 'ADSP')
                    $isCDSP = ($subSub.Name -eq 'CDSP')
                    $isHTP = ($subSub.Name -eq 'HTP')
                    $isQCDeviceInfo = ($subSub.Name -eq 'qcdeviceinfo')
                    $isARM64WithQcdpps = ($subSub.Name -eq 'ARM64' -and (Test-Path (Join-Path $subSub.FullName 'qcdpps.exe')))
                    $isARM64WithQdcmlib = ($subSub.Name -eq 'ARM64' -and (Test-Path (Join-Path $subSub.FullName 'qdcmlib.dll')))
                    if (-not ($isADSP -or $isCDSP -or $isHTP -or $isQCDeviceInfo -or $isARM64WithQcdpps -or $isARM64WithQdcmlib)) {
                        Write-Host "Found sub-directory in $($sub.Name) folder!" -ForegroundColor Red
                        Write-Host ""
                        Read-Host "Press Enter to exit..."
                        return
                    }
                }
            }

            # Fetch the BSP driver list
            $dstBspDriver = Join-Path $dstPrebuilt $BSP_driver
            if ($BSP_driver -eq 'regrouped_driver_ATT_Signed') {
                $dstBspDriver = Join-Path $dstPrebuilt 'regrouped_driver'
            }
            if (!(Test-Path $dstBspDriver)) {
                Write-Host "Target BSP driver folder not found: $dstBspDriver" -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            }
            $dstSubFolders = Get-ChildItem -Path $dstBspDriver -Directory

            # Compare the folder name between Updated_driver vs. BSP driver
            $iecNames = $iecSubFolders.Name
            $dstNames = $dstSubFolders.Name
            $sameNames = $iecNames | Where-Object { $dstNames -contains $_ }
            $diffNames = $iecNames | Where-Object { $dstNames -notcontains $_ }

            Write-Host "Updated_driver folders with the same name in BSP driver folder:"
            if ($sameNames.Count -eq 0) {
                Write-Host "  N/A"
            } else {
                $sameNames | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor Blue }
            }
            Write-Host "Updated_driver folders with different name:"
            if ($diffNames.Count -eq 0) {
                Write-Host "  N/A"
            } else {
                $diffNames | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor Red }
            }

            # Ask to replace the same name folder
            if ($sameNames.Count -gt 0) {
                do {
                    $replace = Read-Host "Replace same name folders in BSP driver folder? (y/n)"
                } until ($replace -eq 'y' -or $replace -eq 'Y' -or $replace -eq 'n' -or $replace -eq 'N')
                if ($replace -eq 'y' -or $replace -eq 'Y') {
                    foreach ($name in $sameNames) {
                        $dstPath = Join-Path $dstBspDriver $name
                        $srcPath = Join-Path $iecDriverFolder $name
                        try {
                            Remove-Item -Path $dstPath -Recurse -Force
                            Copy-Item -Path $srcPath -Destination $dstBspDriver -Recurse -Force
                        } catch {
                            Write-Host "Failed to replace folder: $name" -ForegroundColor Red
                        }
                    }
                    Write-Host "Completed!" -ForegroundColor Green
                } else {
                    Write-Host "Skip replacing base drivers" -ForegroundColor Yellow
                }
            } else {
                Write-Host "No same name folders to replace."
            }
            Write-Host ""

            # Ask to add different-name folders
            if ($diffNames.Count -gt 0) {
                do {
                    $addDiff = Read-Host "Add different name folders to BSP driver folder? (y/n)"
                } until ($addDiff -eq 'y' -or $addDiff -eq 'Y' -or $addDiff -eq 'n' -or $addDiff -eq 'N')
                if ($addDiff -eq 'y' -or $addDiff -eq 'Y') {
                    # 1) Copy different-name folders into regrouped_driver
                    foreach ($name in $diffNames) {
                        $srcPath = Join-Path $iecDriverFolder $name
                        try {
                            Copy-Item -Path $srcPath -Destination $dstBspDriver -Recurse -Force
                        } catch {
                            Write-Host "Failed to copy folder: $name" -ForegroundColor Red
                        }
                    }

                    # 2) Show category menu and read selection
                    Write-Host ""
                    Write-Host "1) drivers"
                    Write-Host "2) DriversForCDPS"
                    Write-Host "3) DriversForCRD"
                    Write-Host "4) DriversForQCB"
                    Write-Host "5) DriversForWinPE"
					do {
						$catSel = Read-Host "Select driver category number(s) (e.g. 1 or 1,3)"
						$catSel = $catSel -replace '\\s',''
						$valid = $catSel -match '^[1-5](,[1-5])*$'
					} until ($valid)
					$catMap = @{ '1'='drivers'; '2'='DriversForCDPS'; '3'='DriversForCRD'; '4'='DriversForQCB'; '5'='DriversForWinPE' }
					$selectedCategories = ($catSel -split ',') | Select-Object -Unique | ForEach-Object { $catMap[$_] }

					# 3) Append different-name folders into drivers.txt under the selected category section
					foreach ($category in $selectedCategories) {
                    $desktopScriptsDir = Join-Path $dstPrebuilt 'DesktopScripts'
                    $driversTxtPath = Join-Path $desktopScriptsDir 'drivers.txt'
                    if (Test-Path $driversTxtPath) {
                        try {
                            $lines = Get-Content $driversTxtPath -Encoding Default
                            function Normalize([string]$s) { return ($s -replace "[\u200B\uFEFF]", "").Trim() }
                            $headerIndex = -1
                            $rx = [regex]::new('^\s*[\\\/]\s*' + [regex]::Escape($category) + '\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                            for ($i = 0; $i -lt $lines.Count; $i++) {
                                $t = Normalize $lines[$i]
                                if ($rx.IsMatch($t)) { $headerIndex = $i; break }
                            }
                            if ($headerIndex -ge 0) {
                                # 找到本區塊結束位置（下一個標頭或檔尾）
                                $endOfSection = $headerIndex + 1
                                for ($j = $endOfSection; $j -lt $lines.Count; $j++) {
                                    $trimJ = Normalize $lines[$j]
                                    if ($trimJ -match '^\s*[\\/]') { break }
                                    $endOfSection = $j + 1
                                }
                                # 插入點放在區塊尾端的第一個非空白行之後（去掉尾端多餘空白行）
                                $insertIndex = $endOfSection
                                while ($insertIndex -gt ($headerIndex + 1) -and (($lines[$insertIndex-1].Trim()).Length -eq 0)) {
                                    $insertIndex--
                                }
                                foreach ($name in $diffNames) {
                                    if ($insertIndex -ge $lines.Count) {
                                        $lines = $lines + @($name)
                                    } else {
                                        $lines = $lines[0..($insertIndex-1)] + @($name) + $lines[$insertIndex..($lines.Count-1)]
                                    }
                                    $insertIndex++
                                }
                                Set-Content -Path $driversTxtPath -Value $lines -Encoding Default
								# 同步到 Thumbdrive 根目錄的 drivers.txt（若存在）
								try {
									$thumbTxt = Join-Path $thumbdriveDst 'drivers.txt'
									if (Test-Path $thumbTxt) {
										Set-Content -Path $thumbTxt -Value $lines -Encoding Default
									}
								} catch {}
								Write-Host "drivers.txt updated for category: " -NoNewline
								Write-Host "$category" -ForegroundColor Yellow
                            } else {
                                Write-Host "Category header not found in drivers.txt: $category" -ForegroundColor Yellow
                                # 列出偵測到的區塊，協助除錯
                                $found = @()
                                for ($k = 0; $k -lt $lines.Count; $k++) {
                                    $t2 = Normalize $lines[$k]
                                    if ($t2.StartsWith("/") -or $t2.StartsWith("\\")) {
                                        $found += ($t2.TrimStart('/', '\\')).Trim()
                                    }
                                }
                                if ($found.Count -gt 0) {
                                    Write-Host ("Detected sections: " + ($found -join ', ')) -ForegroundColor Yellow
                                }
                            }
                        } catch {
                            Write-Host "Failed to update drivers.txt: $_" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "drivers.txt not found at $driversTxtPath" -ForegroundColor Yellow
                    }
					}
                } else {
                    Write-Host "Skip adding different name folders" -ForegroundColor Yellow
                }
            }
        }
        
        # Modify pre-loaded driver in DesktopScripts\drivers
        Write-Host ""
        Write-Host "Modifying preloaded drivers...." -ForegroundColor Cyan
        $desktopScriptsDir = Join-Path $dstPrebuilt 'DesktopScripts'
        $driversTxtPath = Join-Path $desktopScriptsDir 'drivers.txt'
        if (Test-Path $driversTxtPath) {
            # Check if there are any drivers to add or remove
            $hasAddDrivers = $add_driver.Count -gt 0
            $hasRemoveDrivers = $remove_driver.Count -gt 0
            
            if (-not $hasAddDrivers -and -not $hasRemoveDrivers) {
                Write-Host "No drivers to add or remove. Skipping driver modification." -ForegroundColor Yellow
            } else {
                Write-Host "Add list:"
                if ($hasAddDrivers) {
                    $add_driver | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
                } else {
                    Write-Host "  N/A" -ForegroundColor Gray
                }
                Write-Host "Remove list:"
                if ($hasRemoveDrivers) {
                    $remove_driver | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
                } else {
                    Write-Host "  N/A" -ForegroundColor Gray
                }
                do {
                    $removeAns = Read-Host "Modify the above drivers from drivers.txt? (y/n)"
                    $removeAnsLow = $removeAns.ToLower()
                } until ($removeAnsLow -eq 'y' -or $removeAnsLow -eq 'n')
                if ($removeAnsLow -eq 'y') {
                    try {
                        $driversLines = Get-Content $driversTxtPath -Encoding Default
                        $newLines = @()
                        foreach ($line in $driversLines) {
                            $trimmedLine = $line.Trim()
                            if ($hasRemoveDrivers -and $remove_driver -contains $trimmedLine) {
                                continue # Skip this line
                            }
                            $newLines += $line # Add the current line
                            if ($trimmedLine -eq "qccamflash$product_id" -and $hasAddDrivers) {
                                $newLines += $add_driver # Add new drivers after the anchor
                            }
                        }
                        Set-Content -Path $driversTxtPath -Value $newLines -Encoding Default
                        # 同步到 Thumbdrive\drivers.txt（若存在）
                        try {
                            $thumbTxt2 = Join-Path $thumbdriveDst 'drivers.txt'
                            if (Test-Path $thumbTxt2) {
                                Set-Content -Path $thumbTxt2 -Value $newLines -Encoding Default
                            }
                        } catch {}
                        
                        # 同步刪除 $remove_driver 中指定的 driver 目錄（從複製過來的資料夾中）
                        if ($hasRemoveDrivers) {
                            # 取得目標 BSP driver 資料夾路徑
                            $targetBspDriver = Join-Path $dstPrebuilt $BSP_driver
                            if ($BSP_driver -eq 'regrouped_driver_ATT_Signed') {
                                $targetBspDriver = Join-Path $dstPrebuilt 'regrouped_driver'
                            }
                            if (Test-Path $targetBspDriver) {
                                foreach ($driverName in $remove_driver) {
                                    $driverDir = Join-Path $targetBspDriver $driverName
                                    if (Test-Path $driverDir) {
                                        try {
                                            Remove-Item -Path $driverDir -Recurse -Force
                                            Write-Host "Removed driver directory: " -NoNewline
											Write-Host "$driverName" -ForegroundColor Yellow
                                        } catch {
                                            Write-Host "Failed to remove driver directory: $driverName - $_" -ForegroundColor Red
                                        }
                                    }
                                }
                            }
                        }
                        
                        Write-Host "Completed!" -ForegroundColor Green
                    } catch {
                        Write-Host "Failed to modify preloaded drivers: $_" -ForegroundColor Red
                    }
                } else {
                    Write-Host "Skip modifying preloaded drivers" -ForegroundColor Yellow
                }
            }
        }


        # Mount winpe.wim 
		Write-Host ""
        Write-Host "Mounting WinPE...." -ForegroundColor Cyan
        # Get the absolute path of winpe.wim 
        $thumbdriveSources = Join-Path $dstFolder 'Thumbdrive/sources'
        $winpeWimPath = Join-Path $thumbdriveSources 'winpe.wim'
        if (!(Test-Path $winpeWimPath)) {
            Write-Host "winpe.wim not found: $winpeWimPath" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
        } else {
            $winpeWimFullPath = (Resolve-Path $winpeWimPath).Path
            # Create C:\Mount
            $mountDir = 'C:\Mount'
            if (Test-Path $mountDir) {
                try {
					dism /unmount-wim /mountdir:$mountDir /discard
                    Remove-Item -Path $mountDir -Recurse -Force
                } catch {
                    Write-Host "Failed to remove C:\Mount. Please close any open files or folders in C:\Mount and try again." -ForegroundColor Red
                    return
                }
            }
            New-Item -Path $mountDir -ItemType Directory -Force | Out-Null
            # 直接在 PowerShell 執行 Dism
            $dismArgs = @("/mount-wim", "/Wimfile:$winpeWimFullPath", "/index:1", "/mountdir:C:\Mount")
            & dism $dismArgs
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Failed to mount winpe.wim." -ForegroundColor Red
                Write-Host "Unmounting WinPE...." -ForegroundColor Cyan
                & dism /Unmount-Image /MountDir:C:\Mount /Discard
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            }

            # Add ADK WinPE cab files
            Write-Host ""
            Write-Host "Adding ADK WinPE cab files..." -ForegroundColor Cyan
            $cabList = @(
                'WinPE-WMI.cab', 'en-us\WinPE-WMI_en-us.cab',
                'WinPE-NetFx.cab', 'en-us\WinPE-NetFx_en-us.cab',
                'WinPE-Scripting.cab', 'en-us\WinPE-Scripting_en-us.cab',
                'WinPE-PowerShell.cab', 'en-us\WinPE-PowerShell_en-us.cab',
                'WinPE-StorageWMI.cab', 'en-us\WinPE-StorageWMI_en-us.cab',
                'WinPE-DismCmdlets.cab', 'en-us\WinPE-DismCmdlets_en-us.cab'
				'WinPE-x64-Support.cab', 'en-us\WinPE-x64-Support_en-us.cab',  # 0731 added for WinPE BCU func
				'WinPE-Dot3Svc.cab', 'en-us\WinPE-Dot3Svc_en-us.cab', # 0731 added for WinPE BCU func
				'WinPE-MDAC.cab', 'en-us\WinPE-MDAC_en-us.cab', # 0731 added for WinPE BCU func
				'WinPE-WDS-Tools.cab', 'en-us\WinPE-WDS-Tools_en-us.cab', # 0731 added for WinPE BCU func
				'WinPE-SecureStartup.cab', 'en-us\WinPE-SecureStartup_en-us.cab' # 0731 added for WinPE BCU func
				'WinPE-SecureBootCmdlets.cab', 'WinPE-PlatformId.cab' # 0731 added for WinPE BCU func
            )
            $baseCabPath = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\arm64\WinPE_OCs'
            $success = $true
            foreach ($cab in $cabList) {
                $cabPath = Join-Path $baseCabPath $cab
                & dism /Add-Package /Image:C:\Mount /PackagePath:$cabPath
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Failed to add package: $cab" -ForegroundColor Red
                    $success = $false
                    break
                }
            }
            if ($success) {
                Write-Host ""
                Write-Host "Unmounting WinPE...." -ForegroundColor Cyan
                & dism /Unmount-Image /MountDir:C:\Mount /Commit
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Completed!" -ForegroundColor Green
                    # Delete C:\Mount 
                    if (Test-Path 'C:\Mount') {
                        try {
                            Remove-Item 'C:\Mount' -Recurse -Force
                        } catch {
                            Write-Host "Failed to delete C:\Mount, please check manually" -ForegroundColor Red
                        }
                    }
                } else {
                    Write-Host "Failed to unmount WinPE." -ForegroundColor Red
                }
            }

            # Modify BCD settings
            Write-Host ""
            Write-Host "Modifying BCD settings..." -ForegroundColor Cyan
            $bcdPath = Join-Path $dstFolder 'Thumbdrive/efi/microsoft/boot/bcd'
            $bcdFullPath = (Resolve-Path $bcdPath).Path
            $bcdCmds = @(
                @("/store", $bcdFullPath, "/ENUM", "ALL"),
                @("/store", $bcdFullPath, "/set", "{default}", "osdevice", "ramdisk=[boot]\sources\winpe.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}"),
                @("/store", $bcdFullPath, "/set", "{default}", "device", "ramdisk=[boot]\sources\winpe.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}"),
                @("/store", $bcdFullPath, "/ENUM", "ALL")
            )
            $success = $true
            for ($i = 0; $i -lt $bcdCmds.Count; $i++) {
                $bcdargs = $bcdCmds[$i]
                $output = & bcdedit @bcdargs | Out-String
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Failed: bcdedit $($bcdargs -join ' ')" -ForegroundColor Red
                    $success = $false
                    break
                }
                # 1st time check boot.wim
                if ($i -eq 0) {
                    if ($output -notmatch "device\s*ramdisk=\[boot\]\\sources\\boot\.wim") {
                        Write-Host "BCD check failed: device does not contain 'ramdisk=[boot]\\sources\\boot.wim'" -ForegroundColor Red
                        $success = $false
                        break
                    }
                }
                # 2nd time check boot.wim
                if ($i -eq 3) {
                    if ($output -notmatch "device\s*ramdisk=\[boot\]\\sources\\winpe\.wim") {
                        Write-Host "BCD check failed: device does not contain 'ramdisk=[boot]\\sources\\winpe.wim'" -ForegroundColor Red
                        $success = $false
                        break
                    }
                }
            }
            if ($success) {
                Write-Host "Completed!" -ForegroundColor Green
            } else {
                Write-Host "BCD settings failed, script will exit." -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            }

            # Split install.wim
            Write-Host ""
            Write-Host "Spliting install.wim file..." -ForegroundColor Cyan
            $installWim = Join-Path $dstFolder 'Thumbdrive/install.wim'
            $installWimFull = (Resolve-Path $installWim).Path
            $installSwmFull = (Join-Path ((Resolve-Path $dstFolder).Path) 'Thumbdrive\install.swm')
            & dism /split-image /imagefile:$installWimFull /swmfile:$installSwmFull /filesize:3000
            if ($LASTEXITCODE -eq 0) {
                # Delete the original install.wim after successfully spliting install.swm
                if (Test-Path $installWimFull) {
                    Remove-Item -Path $installWimFull -Force
                }
                Write-Host "Completed!" -ForegroundColor Green
            } else {
                Write-Host "Failed to split install.wim." -ForegroundColor Red
            }

            # Set environment variables
            Write-Host ""
            Write-Host "Setting environment variable..." -ForegroundColor Cyan
            $qcplatform = $numFolder
            $BSPRoot = (Resolve-Path $thumbdrive).Path
            $THUMBDRIVE = Join-Path $BSPRoot "WP\prebuilt\$qcplatform\ISOGEN\emmcdl_method\Thumbdrive"
            $env:qcplatform = $qcplatform
            $env:BSPRoot = $BSPRoot
            $env:THUMBDRIVE = $THUMBDRIVE
            $env:DISM_PATH = Join-Path $THUMBDRIVE 'DISM'
            $env:BCDBOOT_PATH = Join-Path $THUMBDRIVE 'BCDBoot'
            Write-Host "Completed!" -ForegroundColor Green

            # Delete old driver folders and install WinPE drivers
            Write-Host ""
            Write-Host "Running WinPEDriverInstall.cmd..." -ForegroundColor Cyan
            # Delete 5 driver folders first if exist 
            $driverFoldersToRemove = @(
                "drivers",
                "DriversForCDPS",
                "DriversForCRD",
                "DriversForQCB",
                "DriversForWinPE"
            )
            foreach ($folder in $driverFoldersToRemove) {
                $targetFolder = Join-Path $THUMBDRIVE $folder
                if (Test-Path $targetFolder) {
                    try {
                        Remove-Item -Path $targetFolder -Recurse -Force
                    } catch {
                        Write-Host ("Failed to remove " + $targetFolder + ": " + $PSItem) -ForegroundColor Red
                    }
                }
            }
            # Run WinPEDriverInstall.cmd
            $driverCmds = @(
                "WinPEDriverInstall.cmd -Source %BSPRoot%\WP\prebuilt\%qcplatform%\ -Destination %THUMBDRIVE% -Option 'DriverCopy'",
                "WinPEDriverInstall.cmd -Source %BSPRoot%\WP\prebuilt\%qcplatform%\ -Destination %THUMBDRIVE% -Option 'WINPE'",
                "WinPEDriverInstall.cmd -Source %BSPRoot%\WP\prebuilt\%qcplatform%\firmware\BOOTCHAIN -Destination %THUMBDRIVE%\nvmefirmware -Option 'robocopy'"
            )
            $success = $true
            foreach ($cmd in $driverCmds) {
                Push-Location $THUMBDRIVE
                cmd /c $cmd
                Pop-Location
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Failed: $cmd" -ForegroundColor Red
                    $success = $false
                    break
                }
            }
            if ($success) {
                Write-Host "Completed!" -ForegroundColor Green
            }

            # Modifying installwoa.cmd
            Write-Host ""
            Write-Host "Modifying installwoa.cmd..." -ForegroundColor Cyan
            $installwoaPath = Join-Path $thumbdriveDst 'installwoa.cmd'
            if (!(Test-Path $installwoaPath)) {
                Write-Host "installwoa.cmd not found in $thumbdriveDst" -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            } else {
                try {
                    $content = Get-Content $installwoaPath -Raw -Encoding Default
                    $lines = $content -split "`r`n"
                    $newLines = @()
                    $found = $false

                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if (
                            $lines[$i]   -eq 'setlocal enabledelayedexpansion' -and
                            $i+1 -lt $lines.Count -and $lines[$i+1] -like 'for /f*Select Model*' -and
                            $i+2 -lt $lines.Count -and $lines[$i+2] -eq 'if not defined deviceModel (' -and
                            $i+3 -lt $lines.Count -and $lines[$i+3] -eq '  %LogError% Unable to retrieve device model.' -and
                            $i+4 -lt $lines.Count -and $lines[$i+4] -eq '  exit /b 1' -and
                            $i+5 -lt $lines.Count -and $lines[$i+5] -eq ')' -and
                            $i+6 -lt $lines.Count -and $lines[$i+6] -eq 'set deviceModel=%deviceModel%'
                        ) {
                            $newLines += 'setlocal enabledelayedexpansion'
                            $newLines += $lines[$i+1]
                            $newLines += 'if not defined deviceModel ('
                            $newLines += '  REM %LogError% Unable to retrieve device model.'
                            $newLines += '  REM exit /b 1'
                            $newLines += ')'
                            $newLines += 'set deviceModel=CRD'
                            $i += 6
                            $found = $true
                        } else {
                            $newLines += $lines[$i]
                        }
                    }

                    if ($found) {
                        Set-Content -Path $installwoaPath -Value ($newLines -join "`r`n") -Encoding Default
                         # Reload installwoa.cmd and confirm
                        $verifyContent = Get-Content $installwoaPath -Raw -Encoding Default
                        if ($verifyContent -match "set deviceModel=CRD") {
                            Write-Host "Completed!" -ForegroundColor Green
                        } else {
                            Write-Host "Modification failed or not verified!" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "Target block not found in installwoa.cmd" -ForegroundColor Red
                    }
                } catch {
                    Write-Host ("Failed to modify installwoa.cmd: " + $PSItem) -ForegroundColor Red
                }
            }

            # All done
            Write-Host ""
			Write-Host ""
            Write-Host "** Congratulations! Everything is set :) **" -ForegroundColor Green
            Write-Host ""
        }
    }
    '3' {
        # Update drivers  注意只能是BSP driver, 如果是WinPE driver(ADSP/qcscm/QcTreeExtOem)要重頭build避免沒替換
		Write-Host ""
        Write-Host "Copying customized drivers..." -ForegroundColor Cyan
		Write-Host "Targeted folder: " -NoNewline
		Write-Host "$thumbdrive" -ForegroundColor Yellow
		Write-Host ""
        # Check if $thumbdrive exists in the current directory
        $toUsbFolder = Join-Path $PWD $thumbdrive
        if (!(Test-Path $toUsbFolder)) {
            Write-Host "No Thumbdrive found!" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        # Get prebuilt\(number folder name)
        $prebuiltDir = Join-Path $toUsbFolder 'WP\prebuilt'
        $numFolder = $product_id
        $dstBspDriver = Join-Path $prebuiltDir "$numFolder\regrouped_driver"
        $iecDriverFolder = Join-Path $PWD $new_driver
        if (!(Test-Path $iecDriverFolder)) {
            Write-Host "Updated_driver folder not found" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        $iecSubFolders = Get-ChildItem -Path $iecDriverFolder -Directory
        if ($iecSubFolders.Count -eq 0) {
            Write-Host "No subfolders found in Updated_driver." -ForegroundColor Yellow
            Write-Host ""
        } else {
             # Check if there's any sub-directory (Only ADSP/CDSP/HTP/qcdeviceinfo and ARM64 (qcdpps.exe/qdcmlib.dll) folders are allowed)
             foreach ($sub in $iecSubFolders) {
                $subSubFolders = Get-ChildItem -Path $sub.FullName -Directory
                foreach ($subSub in $subSubFolders) {
                    $isADSP = ($subSub.Name -eq 'ADSP')
                    $isCDSP = ($subSub.Name -eq 'CDSP')
                    $isHTP = ($subSub.Name -eq 'HTP')
                    $isQCDeviceInfo = ($subSub.Name -eq 'qcdeviceinfo')
                    $isARM64WithQcdpps = ($subSub.Name -eq 'ARM64' -and (Test-Path (Join-Path $subSub.FullName 'qcdpps.exe')))
                    $isARM64WithQdcmlib = ($subSub.Name -eq 'ARM64' -and (Test-Path (Join-Path $subSub.FullName 'qdcmlib.dll')))
                    if (-not ($isADSP -or $isCDSP -or $isHTP -or $isQCDeviceInfo -or $isARM64WithQcdpps -or $isARM64WithQdcmlib)) {
                        Write-Host "Found sub-directory in $($sub.Name) folder!" -ForegroundColor Red
                        Write-Host ""
                        Read-Host "Press Enter to exit..."
                        return
                    }
                }
            }
            if (!(Test-Path $dstBspDriver)) {
                Write-Host "Target BSP driver folder not found: $dstBspDriver" -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            }
            $dstSubFolders = Get-ChildItem -Path $dstBspDriver -Directory
            $iecNames = $iecSubFolders.Name
            $dstNames = $dstSubFolders.Name
            $sameNames = $iecNames | Where-Object { $dstNames -contains $_ }
            $diffNames = $iecNames | Where-Object { $dstNames -notcontains $_ }
            Write-Host "Updated_driver folders with the same name in BSP driver folder:"
            if ($sameNames.Count -eq 0) {
                Write-Host "  N/A"
            } else {
                $sameNames | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor Blue }
            }
            Write-Host "Updated_driver folders with different name:"
            if ($diffNames.Count -eq 0) {
                Write-Host "  N/A"
            } else {
                $diffNames | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor Red }
            }
            # Ask to replace the same name folder
            if ($sameNames.Count -gt 0) {
                do {
                    $replace = Read-Host "Replace same name folders in BSP driver folder? (y/n)"
                } until ($replace -eq 'y' -or $replace -eq 'Y' -or $replace -eq 'n' -or $replace -eq 'N')
                if ($replace -eq 'y' -or $replace -eq 'Y') {
                    foreach ($name in $sameNames) {
                        $dstPath = Join-Path $dstBspDriver $name
                        $srcPath = Join-Path $iecDriverFolder $name
                        try {
                            Remove-Item -Path $dstPath -Recurse -Force
                            Copy-Item -Path $srcPath -Destination $dstBspDriver -Recurse -Force
                        } catch {
                            Write-Host "Failed to replace folder: $name" -ForegroundColor Red
                        }
                    }
                    Write-Host "Completed!" -ForegroundColor Green
                } else {
                    Write-Host "Skip replacing base drivers" -ForegroundColor Yellow
                }
            } else {
                Write-Host "No same name folders to replace."
            }
            Write-Host ""

            # Ask to add different-name folders
            if ($diffNames.Count -gt 0) {
                do {
                    $addDiff = Read-Host "Add different name folders to BSP driver folder? (y/n)"
                } until ($addDiff -eq 'y' -or $addDiff -eq 'Y' -or $addDiff -eq 'n' -or $addDiff -eq 'N')
                if ($addDiff -eq 'y' -or $addDiff -eq 'Y') {
                    # 1) Copy different-name folders into regrouped_driver
                    foreach ($name in $diffNames) {
                        $srcPath = Join-Path $iecDriverFolder $name
                        try {
                            Copy-Item -Path $srcPath -Destination $dstBspDriver -Recurse -Force
                        } catch {
                            Write-Host "Failed to copy folder: $name" -ForegroundColor Red
                        }
                    }

                    # 2) Show category menu and read selection
                    Write-Host ""
                    Write-Host "1) drivers"
                    Write-Host "2) DriversForCDPS"
                    Write-Host "3) DriversForCRD"
                    Write-Host "4) DriversForQCB"
                    Write-Host "5) DriversForWinPE"
					do {
						$catSel = Read-Host "Select driver category number(s) (e.g. 1 or 1,3)"
						$catSel = $catSel -replace '\\s',''
						$valid = $catSel -match '^[1-5](,[1-5])*$'
					} until ($valid)
					$catMap = @{ '1'='drivers'; '2'='DriversForCDPS'; '3'='DriversForCRD'; '4'='DriversForQCB'; '5'='DriversForWinPE' }
					$selectedCategories = ($catSel -split ',') | Select-Object -Unique | ForEach-Object { $catMap[$_] }

					# 3) Append different-name folders into drivers.txt under the selected category section
					foreach ($category in $selectedCategories) {
                    $dstPrebuilt = Join-Path $prebuiltDir $numFolder
                    $desktopScriptsDir = Join-Path $dstPrebuilt 'DesktopScripts'
                    $driversTxtPath = Join-Path $desktopScriptsDir 'drivers.txt'
                    if (Test-Path $driversTxtPath) {
                        try {
                            $lines = Get-Content $driversTxtPath -Encoding Default
                            function Normalize([string]$s) { return ($s -replace "[\u200B\uFEFF]", "").Trim() }
                            $headerIndex = -1
                            $rx = [regex]::new('^\s*[\\\/]\s*' + [regex]::Escape($category) + '\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                            for ($i = 0; $i -lt $lines.Count; $i++) {
                                $t = Normalize $lines[$i]
                                if ($rx.IsMatch($t)) { $headerIndex = $i; break }
                            }
                            if ($headerIndex -ge 0) {
                                # 找到本區塊結束位置（下一個標頭或檔尾）
                                $endOfSection = $headerIndex + 1
                                for ($j = $endOfSection; $j -lt $lines.Count; $j++) {
                                    $trimJ = Normalize $lines[$j]
                                    if ($trimJ -match '^\s*[\\/]') { break }
                                    $endOfSection = $j + 1
                                }
                                # 插入點放在區塊尾端的第一個非空白行之後（去掉尾端多餘空白行）
                                $insertIndex = $endOfSection
                                while ($insertIndex -gt ($headerIndex + 1) -and (($lines[$insertIndex-1].Trim()).Length -eq 0)) {
                                    $insertIndex--
                                }
                                foreach ($name in $diffNames) {
                                    if ($insertIndex -ge $lines.Count) {
                                        $lines = $lines + @($name)
                                    } else {
                                        $lines = $lines[0..($insertIndex-1)] + @($name) + $lines[$insertIndex..($lines.Count-1)]
                                    }
                                    $insertIndex++
                                }
                                Set-Content -Path $driversTxtPath -Value $lines -Encoding Default
								# 同步到 Thumbdrive 根目錄的 drivers.txt（若存在）
								try {
									$thumbdriveDst = Join-Path (Join-Path $prebuiltDir $numFolder) 'ISOGEN/emmcdl_method/Thumbdrive'
									$thumbTxt = Join-Path $thumbdriveDst 'drivers.txt'
									if (Test-Path $thumbTxt) {
										Set-Content -Path $thumbTxt -Value $lines -Encoding Default
									}
								} catch {}
								Write-Host "drivers.txt updated for category: $category" -ForegroundColor Green
                            } else {
                                Write-Host "Category header not found in drivers.txt: $category" -ForegroundColor Yellow
                                # 列出偵測到的區塊，協助除錯
                                $found = @()
                                for ($k = 0; $k -lt $lines.Count; $k++) {
                                    $t2 = Normalize $lines[$k]
                                    if ($t2.StartsWith("/") -or $t2.StartsWith("\\")) {
                                        $found += ($t2.TrimStart('/', '\\')).Trim()
                                    }
                                }
                                if ($found.Count -gt 0) {
                                    Write-Host ("Detected sections: " + ($found -join ', ')) -ForegroundColor Yellow
                                }
                            }
                        } catch {
                            Write-Host "Failed to update drivers.txt: $_" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "drivers.txt not found at $driversTxtPath" -ForegroundColor Yellow
                    }
					}
                } else {
                    Write-Host "Skip adding different name folders" -ForegroundColor Yellow
                }
            }
        }

        # Modify pre-loaded driver in DesktopScripts\drivers
        $dstPrebuilt = Join-Path $prebuiltDir $numFolder
        Write-Host ""
        Write-Host "Modifying preloaded drivers...." -ForegroundColor Cyan
        $desktopScriptsDir = Join-Path $dstPrebuilt 'DesktopScripts'
        $driversTxtPath = Join-Path $desktopScriptsDir 'drivers.txt'
        if (Test-Path $driversTxtPath) {
            # Check if there are any drivers to add or remove
            $hasAddDrivers = $add_driver.Count -gt 0
            $hasRemoveDrivers = $remove_driver.Count -gt 0
            
            if (-not $hasAddDrivers -and -not $hasRemoveDrivers) {
                Write-Host "No drivers to add or remove. Skipping driver modification." -ForegroundColor Yellow
            } else {
                Write-Host "Add list:" 
                if ($hasAddDrivers) {
                    $add_driver | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
                } else {
                    Write-Host "  N/A" -ForegroundColor Gray
                }
                Write-Host "Remove list:"
                if ($hasRemoveDrivers) {
                    $remove_driver | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
                } else {
                    Write-Host "  N/A" -ForegroundColor Gray
                }
                do {
                    $removeAns = Read-Host "Modify the above drivers from drivers.txt? (y/n)"
                    $removeAnsLow = $removeAns.ToLower()
                } until ($removeAnsLow -eq 'y' -or $removeAnsLow -eq 'n')
                if ($removeAnsLow -eq 'y') {
                    try {
                        $driversLines = Get-Content $driversTxtPath -Encoding Default
                        $newLines = @()
                        foreach ($line in $driversLines) {
                            $trimmedLine = $line.Trim()
                            if ($hasRemoveDrivers -and $remove_driver -contains $trimmedLine) {
                                continue # Skip this line
                            }
                            $newLines += $line # Add the current line
                            if ($trimmedLine -eq "qccamflash$product_id" -and $hasAddDrivers) {
                                $newLines += $add_driver # Add new drivers after the anchor
                            }
                        }
                        Set-Content -Path $driversTxtPath -Value $newLines -Encoding Default
                        # 同步到 Thumbdrive\drivers.txt（若存在）
                        try {
                            $thumbdriveDst = Join-Path (Join-Path $dstPrebuilt 'ISOGEN/emmcdl_method') 'Thumbdrive'
                            $thumbTxt3 = Join-Path $thumbdriveDst 'drivers.txt'
                            if (Test-Path $thumbTxt3) {
                                Set-Content -Path $thumbTxt3 -Value $newLines -Encoding Default
                            }
                        } catch {}
                        
                        # 同步刪除 $remove_driver 中指定的 driver 目錄（從複製過來的資料夾中）
                        if ($hasRemoveDrivers) {
                            # 使用功能 3 中已定義的 $dstBspDriver 路徑
                            if (Test-Path $dstBspDriver) {
                                foreach ($driverName in $remove_driver) {
                                    $driverDir = Join-Path $dstBspDriver $driverName
                                    if (Test-Path $driverDir) {
                                        try {
                                            Remove-Item -Path $driverDir -Recurse -Force
                                            Write-Host "Removed driver directory: " -NoNewline
											Write-Host "$driverName" -ForegroundColor Yellow
                                        } catch {
                                            Write-Host "Failed to remove driver directory: $driverName - $_" -ForegroundColor Red
                                        }
                                    }
                                }
                            }
                        }
                        
                        Write-Host "Completed!" -ForegroundColor Green
                    } catch {
                        Write-Host "Failed to modify preloaded drivers: $_" -ForegroundColor Red
                    }
                } else {
                    Write-Host "Skip modifying preloaded drivers" -ForegroundColor Yellow
                }
            }
        }

        # Set environment variables
        Write-Host ""
        Write-Host "Setting environment variable..." -ForegroundColor Cyan
        $qcplatform = $numFolder
        $BSPRoot = (Resolve-Path $thumbdrive).Path
        $THUMBDRIVE = Join-Path $BSPRoot "WP\prebuilt\$qcplatform\ISOGEN\emmcdl_method\Thumbdrive"
        $env:qcplatform = $qcplatform
        $env:BSPRoot = $BSPRoot
        $env:THUMBDRIVE = $THUMBDRIVE
        $env:DISM_PATH = Join-Path $THUMBDRIVE 'DISM'
        $env:BCDBOOT_PATH = Join-Path $THUMBDRIVE 'BCDBoot'
        Write-Host "Completed!" -ForegroundColor Green
        
        # Delete old driver folders and install WinPE drivers
        Write-Host ""
        Write-Host "Running WinPEDriverInstall.cmd..." -ForegroundColor Cyan
        $driverFoldersToRemove = @(
            "drivers",
            "DriversForCDPS",
            "DriversForCRD",
            "DriversForQCB",
            "DriversForWinPE"
        )
        foreach ($folder in $driverFoldersToRemove) {
            $targetFolder = Join-Path $THUMBDRIVE $folder
            if (Test-Path $targetFolder) {
                try {
                    Remove-Item -Path $targetFolder -Recurse -Force
                } catch {
                    Write-Host ("Failed to remove " + $targetFolder + ": " + $PSItem) -ForegroundColor Red
                }
            }
        }
        $driverCmds = @(
            "WinPEDriverInstall.cmd -Source %BSPRoot%\WP\prebuilt\%qcplatform%\ -Destination %THUMBDRIVE% -Option 'DriverCopy'",
            "WinPEDriverInstall.cmd -Source %BSPRoot%\WP\prebuilt\%qcplatform%\ -Destination %THUMBDRIVE% -Option 'WINPE'",
            "WinPEDriverInstall.cmd -Source %BSPRoot%\WP\prebuilt\%qcplatform%\firmware\BOOTCHAIN -Destination %THUMBDRIVE%\nvmefirmware -Option 'robocopy'"
        )
        $success = $true
        foreach ($cmd in $driverCmds) {
            Push-Location $THUMBDRIVE
            cmd /c $cmd
            Pop-Location
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Failed: $cmd" -ForegroundColor Red
                $success = $false
                break
            }
        }
        if ($success) {
            Write-Host "Completed!" -ForegroundColor Green
        }
    }
    '4' {
        # Display driver info
        Write-Host ""
        Write-Host "Check driver versions..." -ForegroundColor Cyan
        # Check if $new_driver folder exists
        $driverDir = Join-Path $PWD $new_driver
        if (!(Test-Path $driverDir)) {
            Write-Host "No driver folder found!" -ForegroundColor Red
            Write-Host ""
            return
        }
        # Check if $new_driver is not empty
        $driverItems = Get-ChildItem -Path $driverDir
        if ($driverItems.Count -eq 0) {
            Write-Host "No driver found in $new_driver!" -ForegroundColor Red
            return
        }
        # Check INF files
        # Auto detect product id
        $subFolders = Get-ChildItem -Path $driverDir -Directory
        $product_id = $null
        foreach ($folder in $subFolders) {
            if ($folder.Name -match '\d{4,}') {
                $product_id = $matches[0]
                break
            }
        }
        if (-not $product_id) {
            Write-Host "Cannot detect product id from driver folder!" -ForegroundColor Red
            return
        }

        foreach ($drv in $driverCheckList) {
            $infPath = Join-Path $driverDir $drv.path
            $label = $drv.label
            $ver = "N/A"
            if (Test-Path $infPath) {
                try {
                    $lines = Get-Content $infPath -Encoding Default
                    foreach ($line in $lines) {
                        if ($line -match '^\s*DriverVer\s*=\s*(.+)$') {
                            $ver = $matches[1].Trim()
                            break
                        }
                    }
                } catch {
                    $ver = "N/A"
                }
            }
            if ($ver -ne "N/A") {
                Write-Host -NoNewline ("  {0}: " -f $label)
                Write-Host $ver -ForegroundColor Blue
            } else {
                Write-Host -NoNewline ("  {0}: " -f $label)
                Write-Host "N/A" -ForegroundColor Red
            }
        }
        Write-Host "Completed!" -ForegroundColor Green

        # Display check driver signing...
        Write-Host ""
        Write-Host "Check driver signing..." -ForegroundColor Cyan
        foreach ($drv in $driverCheckList) {
            $catPath = (Join-Path $driverDir $drv.path) -replace '\.inf$', '.cat'
            $label = $drv.label
            $signResult = "N/A"
            if (Test-Path $catPath) {
                try {
                    # Get driver signature
                    $sigInfo = Get-AuthenticodeSignature $catPath
                    if ($sigInfo -and $sigInfo.SignerCertificate) {
                        $signer = $sigInfo.SignerCertificate.Subject
                        if ($signer -match 'CN=Microsoft Windows Hardware Compatibility Publisher') {
                            $signResult = "ATT-signed"
                        } elseif ($signer -match 'CN=Qualcomm OEM Test Cert 2021 \(TEST ONLY\)') {
                            $signResult = "Unsigned"
                        } else {
                            $signResult = $sigInfo.SignerCertificate.Subject
                        }
                    } else {
                        $signResult = "N/A"
                    }
                } catch {
                    $signResult = "N/A"
                }
            }
            if ($signResult -eq "ATT-signed") {
                Write-Host -NoNewline ("  {0}: " -f $label)
                Write-Host $signResult -ForegroundColor Blue
            } elseif ($signResult -eq "Unsigned") {
                Write-Host -NoNewline ("  {0}: " -f $label)
                Write-Host $signResult -ForegroundColor Yellow
            } else {
                Write-Host -NoNewline ("  {0}: " -f $label)
                Write-Host "N/A" -ForegroundColor Red
            }
        }
        Write-Host "Completed!" -ForegroundColor Green
        Write-Host ""
    }
    '5' {
        # Copy thumbdrive to USB
        Write-Host ""
        Write-Host "Copying Thumbdrive to FAT32 USB ..." -ForegroundColor Cyan
		Write-Host "Targeted folder: " -NoNewline
		Write-Host "$thumbdrive" -ForegroundColor Yellow
		Write-Host ""
        # Find $thumbdrive/WP/prebuilt/{number}/ISOGEN/emmcdl_method/Thumbdrive
        $prebuiltPath = Join-Path $PWD "$thumbdrive/WP/prebuilt"
        $numFolder = $product_id
        $thumbdriveDst = Join-Path $prebuiltPath "$numFolder/ISOGEN/emmcdl_method/Thumbdrive"
        if (!(Test-Path $thumbdriveDst) -or ($null -eq (Get-ChildItem -Path $thumbdriveDst))) {
            Write-Host "Thumbdrive does not exist or is empty" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        # Find FAT32 USB drive (DriveType 2 or 3)
        $usbList = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { ($_.DriveType -eq 2 -or $_.DriveType -eq 3) -and $_.FileSystem -eq "FAT32" }
        if (!$usbList -or $usbList.Count -eq 0) {
            Write-Host "No FAT32 USB drive found!" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        Write-Host "List of FAT32 USB drives:"
        $idx = 1
        $usbArray = @()
        foreach ($usb in $usbList) {
            $sizeGB = "{0:N2}" -f ($usb.Size / 1GB)
            Write-Host ("{0}) {1}  {2}  {3} GB" -f $idx, $usb.DeviceID, $usb.VolumeName, $sizeGB)
            $usbArray += $usb
            $idx++
        }
        do {
            $selection = Read-Host "Enter the number to copy files"
            $valid = $selection -match '^[1-9][0-9]*$' -and $selection -ge 1 -and $selection -le $usbArray.Count
        } until ($valid)
        $targetDrive = $usbArray[$selection - 1].DeviceID + '\\'
        # Clean USB drive
        try {
            Get-ChildItem -Path $targetDrive -Force | Remove-Item -Recurse -Force
        } catch {
            Write-Host "Failed to clear USB drive: $_" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        # Copy Thumbdrive to USB drive with progress
        try {
            $items = Get-ChildItem -Path $thumbdriveDst -Force
            $total = $items.Count
            $idx = 1
            foreach ($item in $items) {
                $src = $item.FullName
                $dst = Join-Path $targetDrive $item.Name
                Write-Host ("[{0}/{1}] Copying: {2}" -f $idx, $total, $item.Name) -ForegroundColor Yellow
                if ($item.PSIsContainer) {
                    Copy-Item -Path $src -Destination $dst -Recurse -Force
                } else {
                    Copy-Item -Path $src -Destination $targetDrive -Force
                }
                $idx++
            }
            Write-Host "Completed!" -ForegroundColor Green
        } catch {
            Write-Host "Failed to copy files: $_" -ForegroundColor Red
        }
        Write-Host ""
        Read-Host "Press Enter to exit..."
    }
    '6' {
        # Check .NET 2.0 csc.exe
        $cscPath = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v2.0.50727\csc.exe'
        if (!(Test-Path $cscPath)) {
            Write-Host "Please install .Net Framnework v2.0.50727 first" -ForegroundColor Yellow
            Write-Host "Download URL: https://www.microsoft.com/zh-tw/download/details.aspx?id=6041" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }

        # List BSP source packages
        $folders = Get-ChildItem -Directory | Where-Object { $_.Name -like ("$product*") }
        if ($folders.Count -eq 0) {
            Write-Host "No folders found" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        Write-Host ""
        Write-Host "List of the BSP source packages:"
        $maxIndexLen = ($folders.Count).ToString().Length
        for ($i = 0; $i -lt $folders.Count; $i++) {
            $num = ($i+1).ToString().PadLeft($maxIndexLen)
            Write-Host ("{0}) {1}" -f $num, $folders[$i].Name)
        }
        do {
            $selection = Read-Host "Enter the number"
            $valid = $selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $folders.Count
        } until ($valid)
        $selectedName = $folders[$selection - 1].Name
		Write-Host "Selected: " -NoNewline
		Write-Host "$selectedName" -ForegroundColor Yellow
		Write-Host ""

        # Parse r0xxxx.x to ver1 (xxxx) and ver2 (x)
        $ver1 = $null
        $ver2 = $null
        if ($selectedName -match 'r(\d{5})\.(\d+)') {
            $rnum = $matches[1]
            $ver2 = $matches[2]
            try {
                $ver1 = [int]$rnum  # casting drops leading zero (e.g., 03000 -> 3000)
            } catch {
                $ver1 = $rnum.TrimStart('0')
                if ([string]::IsNullOrEmpty($ver1)) { $ver1 = '0' }
            }
        } else {
            Write-Host "Selected folder name does not contain r0xxxx.x pattern" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }

        # Create Version.cs content
        $csContent = @"
using System.Reflection;
// General Information about an assembly is controlled through the following 
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
[assembly: AssemblyTitle("Version")]
[assembly: AssemblyDescription("Something that Ron wanted")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("HP Company")]
[assembly: AssemblyProduct("Version")]
[assembly: AssemblyCopyright("Copyright © 2025 HP Development Company, L.P")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyVersion("$ver1.$ver2")]
[assembly: AssemblyFileVersion("$ver1.$ver2")]
namespace SigFile
{
class Program
{
static void Main(string[] args)
{
}
}
}
"@

        $import_file = "Version.cs"
        $export_file = "Version.exe"
        $destination = (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v2.0.50727\')

        try {
            Set-Content -Path .\$import_file -Value $csContent -Encoding Default
        } catch {
            Write-Host "Failed to write Version.cs: $_" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }

        # Compile using csc.exe
		Write-Host "Building Version.exe..." -ForegroundColor Cyan
		Write-Host "Version: " -NoNewline
		Write-Host "$ver1.$ver2" -ForegroundColor Blue
        if (Test-Path .\$import_file) {
            try {
                Copy-Item -Path .\$import_file -Destination ($destination + $import_file) -Force
                Push-Location $destination
                .\csc.exe $import_file
                Remove-Item -Path .\$import_file -Force
                Pop-Location
                Move-Item -Path ($destination + $export_file) -Destination .\ -Force
				if (Test-Path .\$import_file) { Remove-Item -Path .\$import_file -Force }
                Write-Host "Completed!" -ForegroundColor Green
                Write-Host ""
            } catch {
                Write-Host "Failed to build or move Version.exe: $_" -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            }
        } else {
            Write-Host "Version.cs file not found" -ForegroundColor Red
        }
    }
    '7' {
        # Validate secure sign
        Write-Host "" 
        Write-Host "Inspecting secure sign..." -ForegroundColor Cyan
        # Resolve FUSE directory
        $fuseDir = Join-Path $PWD $fuse_folder
        if (!(Test-Path $fuseDir)) {
            Write-Host "FUSE folder not found" -ForegroundColor Red
            Write-Host ""

            return
        }
        $fuseItems = Get-ChildItem -Path $fuseDir -Force -ErrorAction SilentlyContinue
        if (-not $fuseItems -or $fuseItems.Count -eq 0) {
            Write-Host "FUSE folder is empty" -ForegroundColor Red
            Write-Host ""
            return
        }

        # Check sectools.exe exists
        $sectoolsPath = Join-Path $fuseDir 'sectools.exe'
        if (!(Test-Path $sectoolsPath)) {
            Write-Host "sectools.exe not found in FUSE folder" -ForegroundColor Red
			Write-Host "Please copy it from BSP source \common\sectoolsv2\ext\Windows\sectools.exe" -ForegroundColor Red
            Write-Host ""
            return
        }

        # Collect target images (*.elf, *.mbn)
        $elfs = Get-ChildItem -Path $fuseDir -Filter *.elf -File -ErrorAction SilentlyContinue
        $mbns = Get-ChildItem -Path $fuseDir -Filter *.mbn -File -ErrorAction SilentlyContinue
        $images = @()
        if ($elfs) { $images += $elfs }
        if ($mbns) { $images += $mbns }
        if (-not $images -or $images.Count -eq 0) {
            Write-Host "No .elf or .mbn files found in FUSE folder." -ForegroundColor Red
            Write-Host ""
            return
        }

        # Iterate and inspect OEM ID
        Write-Host "Found $($images.Count) image file(s)"
        foreach ($img in $images) {
            try {
                Push-Location $fuseDir
                $output = & $sectoolsPath secure-image "$($img.FullName)" --inspect 2>&1
                Pop-Location

                $oemId = $null
                $prodId = $null
                foreach ($line in $output) {
                    if ($null -eq $line -or $line.Trim().Length -eq 0) { continue }
                    if (-not $oemId -and ($line -match '^\s*\|\s*OEM\s*ID:\s*\|\s*([^|]+)')) { $oemId = ($matches[1]).Trim() }
                    if (-not $prodId -and ($line -match '^\s*\|\s*OEM\s*Product\s*ID:\s*\|\s*([^|]+)')) { $prodId = ($matches[1]).Trim() }
                }
                # Fallback: relaxed search without the second pipe pattern
                if (-not $oemId) {
                    $relaxed = $output | Where-Object { $_ -match 'OEM\s*ID:' } | Select-Object -First 1
                    if ($relaxed -and ($relaxed -match 'OEM\s*ID:\s*\|?\s*([^|]+)')) { $oemId = ($matches[1]).Trim() }
                }
                if (-not $prodId) {
                    $relaxed2 = $output | Where-Object { $_ -match 'OEM\s*Product\s*ID:' } | Select-Object -First 1
                    if ($relaxed2 -and ($relaxed2 -match 'OEM\s*Product\s*ID:\s*\|?\s*([^|]+)')) { $prodId = ($matches[1]).Trim() }
                }

                Write-Host ("  {0} " -f $img.Name) -ForegroundColor Yellow
                # OEM ID line: label default color, value colored only
                Write-Host "      OEM ID: " -NoNewline  
                $oemVal = if ($oemId) { $oemId.Trim() } else { 'N/A' }
                if ($oemVal -eq 'N/A' -or $oemVal -match '^(?i)0x0$') { Write-Host $oemVal -ForegroundColor Red } else { Write-Host $oemVal -ForegroundColor Blue }
                # OEM Product ID line: label default color, value colored only
                Write-Host "      OEM Product ID: " -NoNewline
                $prodVal = if ($prodId) { $prodId.Trim() } else { 'N/A' }
                if ($prodVal -eq 'N/A' -or $prodVal -match '^(?i)0x0$') { Write-Host $prodVal -ForegroundColor Red } else { Write-Host $prodVal -ForegroundColor Blue }
            } catch {
                try { Pop-Location } catch {}
                Write-Host -NoNewline ("  {0} " -f $img.Name) -ForegroundColor Yellow
                Write-Host ("Failed to inspect: {0}" -f $_) -ForegroundColor Red
            }
        }
        Write-Host "Completed!" -ForegroundColor Green
        Write-Host ""
    }
}

