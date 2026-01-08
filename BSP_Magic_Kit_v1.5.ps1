$_creator = "Mike Lu (lu.mike@inventec.com)"
$_version = 1.5
$_changedate = 1/7/2026


# User-defined settings
$thumbdrive = "TEST"


# PATH settings
$BSP_driver = "ProdSigned"

# [Options]
# regrouped_driver_ATT_Signed
# regrouped_driver
# ProdSigned

$product = "glymur-wp-1-0_amss_standard_oem"
$product_id = "8480"
$new_driver = "Updated_driver"
$iso_folder = "ISO"
$fuse_folder = "FUSE"
$cva_file = "CVA_info_BSP.txt"
$enable_debugMode = $false
$rename_efi = $true

# BSP to ISO mapping
$bspToIsoMapping = @{
    'r03000' = '27902'
	'r03300' = '27902'
	'r03500' = '27924'
	'r03500_x2' = '27924'
	'r03900' = '27950'
	'r03900_x2' = '27965'
	'r04000' = '27965'
	'r04000_x1' = '27965'
    'r04100' = '28000' # release note: 27975
	'r04300' = '28000'
	'r04300_x1' = '28000'
	'r04400' = '28000'
	'r04400_x1' = '28000'
	'r04500' = '28000'
}

# Specific driver settings for Installer
$driverConfigs = @(
    @{
        name = "CashmereQ"
        remove_driver = @(
            "qcSensorsConfig$product_id"
            "Qccamtelesensor$product_id"
            "Qccamultrawidesensor$product_id"
            "qccamultrawidesensor_extension$product_id"
            "qccamtelesensor_extension$product_id"
            "qccamrearsensor_extension$product_id"
            "qccamrearsensor$product_id"
            "qcAlwaysOnSensing"
			"qccamjpege_ffu$product_id"
            "qcdxext_cdps$product_id"
            "qcdxext_idp$product_id"
            "qcdxext_idps$product_id"
            "qcdxext_qcb$product_id"
			"HalExtQCWdogTimer$product_id"
        )
        add_driver = @(
            "qccamflash_ext$product_id"  # Added to the later of qccamflash$product_id
        )
    },
    @{
        name = "Dolcelatte"
        remove_driver = @(
            "qcdxext_cdps$product_id"
            "qcdxext_idp$product_id"
            "qcdxext_idps$product_id"
            "qcdxext_qcb$product_id"
			"HalExtQCWdogTimer$product_id"
        )
        add_driver = @()
    }
)
$driverCheckList = @(
    @{ path = "qcdxext_crd$product_id/qcdxext_crd$product_id.inf"; label = "Gfx" }
	@{ path = "qcasd_apo$product_id/qcasd_apo$product_id.inf"; label = "Audio (APO)" }
	@{ path = "qcadx_ext$product_id/qcadx_ext$product_id.inf"; label = "Audio (SVA)" }
    @{ path = "qccamauxsensor_extension$product_id/qccamauxsensor_extension$product_id.inf"; label = "Camera (IR)" }
    @{ path = "qccamfrontsensor_extension$product_id/qccamfrontsensor_extension$product_id.inf"; label = "Camera (5MP)" }
    @{ path = "qccamisp_ext$product_id/qccamisp_ext$product_id.inf"; label = "Camera (ISP)" }
	@{ path = "CameraComponent/mep_camera_component.inf"; label = "MEP" }
	@{ path = "Camera_Optin_WOA/MEPOptInCameraExt.inf"; label = "MEP opt-in" }
	@{ path = "qcSensors$product_id/qcSensors$product_id.inf"; label = "Sensor" }
    @{ path = "qcSensorsConfigCrd$product_id/qcSensorsConfigCrd$product_id.inf"; label = "SensorConfig" }
    @{ path = "qcsubsys_ext_adsp$product_id/qcsubsys_ext_adsp$product_id.inf"; label = "aDSP" }
    @{ path = "QcTreeExtOem$product_id/QcTreeExtOem$product_id.inf"; label = "QcTreeExtOem" }
	@{ path = "QcTreeExtQcom$product_id/QcTreeExtQcom$product_id.inf"; label = "QcTreeExtQcom" }
	# @{ path = "qcnspmcdm$product_id/qcnspmcdm$product_id.inf"; label = "Hexagon NPU (cDSP)" }
	# @{ path = "QcXhciFilter$product_id/QcXhciFilter$product_id.inf"; label = "xHCI" }
	# @{ path = "QcUsb4Filter$product_id/QcUsb4Filter$product_id.inf"; label = "USB4" }
	# @{ path = "qcscm$product_id/qcscm$product_id.inf"; label = "QcSCM" }
	# @{ path = "qcbluetooth$product_id/qcbluetooth$product_id.inf"; label = "BT" }
	# @{ path = "qci2c$product_id/qci2c$product_id.inf"; label = "I2C bus" }
	# @{ path = "qcspi$product_id/qcspi$product_id.inf"; label = "SPI bus" }
	# @{ path = "qcppx$product_id/qcppx$product_id.inf"; label = "PCIe" }
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

function Set-RenameEfiInTotalUpdate {
    param(
        [string]$DesktopScriptsPath,
        [bool]$EnableRename,
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
		Write-Host ""
        Write-Host "Setting boot EFI in TotalUpdate.bat..." -ForegroundColor Cyan
    }

    $targetLine = 'move %THUMBDRIVE%:\efi\boot\bootaa64.efi %THUMBDRIVE%:\efi\boot\bootaa64_back.efi'
    $success = $false

    try {
        $lines = Get-Content -Path $totalUpdatePath -Encoding Default
        $modified = $false

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $trimmed = $line.TrimStart()
            $isCommented = $trimmed.StartsWith('::')

            # Remove leading comment markers and spaces for comparison
            $core = $trimmed
            if ($isCommented) {
                $core = $core.Substring(2).TrimStart()
            }
            
            # Trim both ends for comparison to handle trailing spaces
            $coreTrimmed = $core.Trim()
            $targetLineTrimmed = $targetLine.Trim()

            # Match the target line (case-insensitive, ignoring leading/trailing whitespace)
            if ($coreTrimmed -ieq $targetLineTrimmed) {
                # Get leading whitespace/indentation from original line
                $leadingWhitespace = ''
                if ($line -match '^(\s*)') {
                    $leadingWhitespace = $matches[1]
                }
                
                if ($EnableRename) {
                    # Ensure line is uncommented (remove :: and any space after it)
                    $lines[$i] = $leadingWhitespace + $targetLine
                } else {
                    # Ensure line is commented with ::
                    $lines[$i] = $leadingWhitespace + ':: ' + $targetLine
                }
                $modified = $true
                break
            }
        }

        if ($modified) {
            Set-Content -Path $totalUpdatePath -Value $lines -Encoding Default
        }

        $success = $true
    } catch {
        if (-not $SuppressMessages) {
            Write-Host "Failed to update boot EFI setting in TotalUpdate.bat: $_" -ForegroundColor Red
        }
    }

    if ($success -and -not $SkipCompletionMessage -and -not $SuppressMessages) {
        Write-Host "Completed!" -ForegroundColor Green
    }

    return $success
}

# Function to safely write file content
function Add-ContentSafely {
    param($FilePath, $Content, $Description = "")
    
    try {
        $Content | Add-Content -Path $FilePath -Encoding UTF8
    } catch {
        if ($Description) {
            Write-Host "Write fail $Description : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to check specific title in the file content
function Test-SectionExists {
    param($FilePath, $SectionTitle)
    
    if (-not (Test-Path $FilePath)) {
        return $false
    }
    
    try {
        $result = Select-String -Path $FilePath -Pattern [regex]::Escape($SectionTitle) -SimpleMatch
        return $null -ne $result
    } catch {
        $content = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
        if ($content) {
            return $content -like "*$SectionTitle*"
        }
        return $false
    }
}

function Get-DriverSignType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        return @{ Type = "N/A"; Color = "Red" }
    }

    try {
        $sig = Get-AuthenticodeSignature -FilePath $FilePath
        if (-not $sig) {
            return @{ Type = "N/A"; Color = "Red" }
        }

        $status = $sig.Status
        $signer = $sig.SignerCertificate.Subject

        # Test-signed (first priority)
        if ($signer -match 'CN=Qualcomm OEM Test Cert 2021 \(TEST ONLY\)') {
            return @{ Type = "Test signed"; Color = "Red" }
        }

        # MS WHCP: further distinguish ATT / WHQL via EKU
        if ($signer -match 'CN=Microsoft Windows Hardware Compatibility Publisher') {
            $eku = $sig.SignerCertificate.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Enhanced Key Usage" } | Select-Object -First 1
            $ekuText = ""
            if ($eku) {
                $ekuText = ($eku.Format($true) -split "`n" | Select-String -Pattern '\([0-9\.]+\)' | ForEach-Object {
                    $_.ToString().Trim() -replace '\s*\([0-9\.]+\)\s*$',''
                }) -join ", "
            }

            if ($ekuText -like "*Windows Hardware Driver Attested Verification*") {
                return @{ Type = "ATT-signed"; Color = "Yellow" }
            }
            if ($ekuText -like "*Windows Hardware Driver Extended Verification*") {
                return @{ Type = "WHQL signed"; Color = "Blue" }
            }
            if ($ekuText -like "*Lifetime Signing*") {   # EKU = Lifetime Signing, Preview Build Signing, Windows Hardware Driver Verification
                return @{ Type = "Non-WHQL signed"; Color = "DarkMagenta" }
            }
            # Default for WHCP signer but unknown EKU
            return @{ Type = "Microsoft WHCP (unknown EKU)"; Color = "Yellow" }
        }

        # Other valid signature
        if ($status -eq 'Valid' -or $status -eq 'ValidNotTrusted') {
            return @{ Type = $signer; Color = "Yellow" }
        }

        # Not valid
        return @{ Type = $status; Color = "Red" }
    } catch {
        return @{ Type = "Error"; Color = "Red" }
    }
}

# Function to modify preloaded drivers
function Update-PreloadedDrivers {
    param(
        [string]$DriversTxtPath,
        [string]$ThumbdriveDst,
        [string]$TargetBspDriver,
        [array]$RemoveDrivers,
        [array]$AddDrivers,
        [string]$ProductId
    )
    
    if (-not (Test-Path $DriversTxtPath)) {
        return $false
    }
    
    $hasAddDrivers = $AddDrivers.Count -gt 0
    $hasRemoveDrivers = $RemoveDrivers.Count -gt 0
    
    if (-not $hasAddDrivers -and -not $hasRemoveDrivers) {
        Write-Host "No drivers to add or remove. Skipping driver modification." -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "Add list:"
    if ($hasAddDrivers) {
        $AddDrivers | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
    } else {
        Write-Host "  N/A" -ForegroundColor Gray
    }
    Write-Host "Remove list:"
    if ($hasRemoveDrivers) {
        $RemoveDrivers | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
    } else {
        Write-Host "  N/A" -ForegroundColor Gray
    }
    
    do {
        $removeAns = Read-Host "Modify the above drivers from drivers.txt? (y/n)"
        $removeAnsLow = $removeAns.ToLower()
    } until ($removeAnsLow -eq 'y' -or $removeAnsLow -eq 'n')
    
    if ($removeAnsLow -eq 'n') {
        Write-Host "Skip modifying preloaded drivers" -ForegroundColor Yellow
        return $false
    }
    
    try {
        $driversLines = Get-Content $DriversTxtPath -Encoding Default
        $newLines = @()
        foreach ($line in $driversLines) {
            $trimmedLine = $line.Trim()
            if ($hasRemoveDrivers -and $RemoveDrivers -contains $trimmedLine) {
                continue # Skip this line
            }
            $newLines += $line # Add the current line
            if ($trimmedLine -eq "qccamflash$ProductId" -and $hasAddDrivers) {
                $newLines += $AddDrivers # Add new drivers after the anchor
            }
        }
        Set-Content -Path $DriversTxtPath -Value $newLines -Encoding Default
        
        # 同步到 Thumbdrive\drivers.txt（若存在）
        if ($ThumbdriveDst) {
            try {
                $thumbTxt = Join-Path $ThumbdriveDst 'drivers.txt'
                if (Test-Path $thumbTxt) {
                    Set-Content -Path $thumbTxt -Value $newLines -Encoding Default
                }
            } catch {}
        }
        
        # 同步刪除 $RemoveDrivers 中指定的 driver 目錄（從複製過來的資料夾中）
        if ($hasRemoveDrivers -and $TargetBspDriver) {
            if (Test-Path $TargetBspDriver) {
                foreach ($driverName in $RemoveDrivers) {
                    $driverDir = Join-Path $TargetBspDriver $driverName
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
        return $true
    } catch {
        Write-Host "Failed to modify preloaded drivers: $_" -ForegroundColor Red
        return $false
    }
}

        
# Check if run as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script with administrator privileges " -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit
}

# Main menu
Write-Host ""
Write-Host "** BSP Magic Kit " -NoNewline
Write-Host "v$_version" -ForegroundColor 'DarkYellow' -NoNewline
Write-Host " **"
Write-Host "=========================="
Write-Host "1) Download BSP package"
Write-Host "2) Create USB installer"
Write-Host "3) Update drivers (non-WinPE)"
Write-Host "4) Display driver info"    
Write-Host "5) Copy thumbdrive to USB" 
Write-Host "6) Make version.exe"
Write-Host "7) Get BSP CVA info"
Write-Host "8) Inspect secure sign"
Write-Host "=========================="

do {
    $mainSelection = Read-Host "Select a function"
} until ($mainSelection -eq '1' -or $mainSelection -eq '2' -or $mainSelection -eq '3' -or $mainSelection -eq '4' -or $mainSelection -eq '5' -or $mainSelection -eq '6' -or $mainSelection -eq '7' -or $mainSelection -eq '8')

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
            Write-Host "'$BSP_driver' source folder not found" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        $dstFolder = Join-Path -Path (Join-Path -Path (Join-Path -Path (Join-Path -Path $toUsbFolder 'WP') 'prebuilt') $numFolder) 'ISOGEN/emmcdl_method'
        $dstPrebuilt = Join-Path -Path (Join-Path -Path (Join-Path -Path $toUsbFolder 'WP') 'prebuilt') $numFolder
        $debugTargets = @()
        if (Test-Path $dstFolder) {
            do {
				Write-Host "Thumbdrive folder already exists, overwrite? (y/n)" -ForegroundColor Red -NoNewline
                $overwrite = Read-Host " "
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
                $usedAltDriver = $false
                $isProdSigned = $false
                if ($BSP_driver -eq 'ProdSigned') {
                    # For ProdSigned, check if ProdSigned folder exists
                    if (-not (Test-Path $srcDriver)) {
                        Write-Host "'$BSP_driver' source folder not found" -ForegroundColor Red
                        Write-Host ""
                        Read-Host "Press Enter to exit..."
                        return
                    }
                    # Check if ProdSigned\Driver exists
                    $srcDriverPath = Join-Path $srcDriver 'Driver'
                    if (-not (Test-Path $srcDriverPath)) {
                        Write-Host "'$BSP_driver\Driver' source folder not found" -ForegroundColor Red
                        Write-Host ""
                        Read-Host "Press Enter to exit..."
                        return
                    }
                    $srcDriver = $srcDriverPath
                    $isProdSigned = $true
                } elseif (-not (Test-Path $srcDriver)) {
                    if ($BSP_driver -eq 'regrouped_driver_ATT_Signed') {
                        Write-Host "'$BSP_driver' source folder not found" -ForegroundColor Red
                        $altSrcDriver = Join-Path (Join-Path $prebuiltPath $numFolder) 'regrouped_driver'
                        if (Test-Path $altSrcDriver) {
                            do {
								Write-Host "Use 'regrouped_driver' instead? (y/n)" -NoNewline
                                $useAlt = Read-Host " "
                            } until ($useAlt -eq 'y' -or $useAlt -eq 'Y' -or $useAlt -eq 'n' -or $useAlt -eq 'N')
                            if ($useAlt -eq 'y' -or $useAlt -eq 'Y') {
                                $srcDriver = $altSrcDriver
                                $usedAltDriver = $true
                            } else {
                                Write-Host "Copy cancelled" -ForegroundColor Yellow
                                Write-Host ""
                                Read-Host "Press Enter to exit..."
                                return
                            }
                        } else {
                            Write-Host "Alternative source folder 'regrouped_driver' also not found: $altSrcDriver" -ForegroundColor Red
                            Write-Host ""
                            Read-Host "Press Enter to exit..."
                            return
                        }
                    } else {
                        Write-Host "'$BSP_driver' source folder not found" -ForegroundColor Red
                        Write-Host ""
                        Read-Host "Press Enter to exit..."
                        return
                    }
                }
                if (Test-Path $srcDriver) {
                    $dstDriver = Join-Path $dstPrebuilt 'regrouped_driver'
                    if ($BSP_driver -eq 'regrouped_driver_ATT_Signed' -or $isProdSigned) {
                        if (Test-Path $dstDriver) { Remove-Item -Path $dstDriver -Recurse -Force }
                        New-Item -Path $dstDriver -ItemType Directory -Force | Out-Null
                        Copy-Item -Path (Join-Path $srcDriver '*') -Destination $dstDriver -Recurse -Force
                    } else {
                        $dstOtherDriver = Join-Path $dstPrebuilt $BSP_driver
                        if (Test-Path $dstOtherDriver) { Remove-Item -Path $dstOtherDriver -Recurse -Force }
                        Copy-Item -Path $srcDriver -Destination $dstPrebuilt -Recurse -Force
                    }
                    if ($usedAltDriver) {
                        Write-Host "Completed!" -ForegroundColor Green
                        Write-Host ""
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
            $usedAltDriver = $false
            $isProdSigned = $false
            if ($BSP_driver -eq 'ProdSigned') {
                # For ProdSigned, check if ProdSigned folder exists
                if (-not (Test-Path $srcDriver)) {
                    Write-Host "'$BSP_driver' source folder not found" -ForegroundColor Red
                    Write-Host ""
                    Read-Host "Press Enter to exit..."
                    return
                }
                # Check if ProdSigned\Driver exists
                $srcDriverPath = Join-Path $srcDriver 'Driver'
                if (-not (Test-Path $srcDriverPath)) {
                    Write-Host "'$BSP_driver\Driver' source folder not found" -ForegroundColor Red
                    Write-Host ""
                    Read-Host "Press Enter to exit..."
                    return
                }
                $srcDriver = $srcDriverPath
                $isProdSigned = $true
            } elseif (-not (Test-Path $srcDriver)) {
                if ($BSP_driver -eq 'regrouped_driver_ATT_Signed') {
                    Write-Host "'$BSP_driver' source folder not found" -ForegroundColor Red
                    $altSrcDriver = Join-Path (Join-Path $prebuiltPath $numFolder) 'regrouped_driver'
                    if (Test-Path $altSrcDriver) {
                        do {
                            Write-Host "Use 'regrouped_driver' instead? (y/n)" -NoNewline
                            $useAlt = Read-Host " "
                        } until ($useAlt -eq 'y' -or $useAlt -eq 'Y' -or $useAlt -eq 'n' -or $useAlt -eq 'N')
                        if ($useAlt -eq 'y' -or $useAlt -eq 'Y') {
                            $srcDriver = $altSrcDriver
                            $usedAltDriver = $true
                        } else {
                            Write-Host "Copy cancelled" -ForegroundColor Yellow
                            Write-Host ""
                            Read-Host "Press Enter to exit..."
                            return
                        }
                    } else {
                        Write-Host "Alternative source folder 'regrouped_driver' also not found: $altSrcDriver" -ForegroundColor Red
                        Write-Host ""
                        Read-Host "Press Enter to exit..."
                        return
                    }
                } else {
                    Write-Host "'$BSP_driver' source folder not found" -ForegroundColor Red
                    Write-Host ""
                    Read-Host "Press Enter to exit..."
                    return
                }
            }
            if (Test-Path $srcDriver) {
                $dstDriver = Join-Path $dstPrebuilt 'regrouped_driver'
                if ($BSP_driver -eq 'regrouped_driver_ATT_Signed' -or $isProdSigned) {
                    if (Test-Path $dstDriver) { Remove-Item -Path $dstDriver -Recurse -Force }
                    New-Item -Path $dstDriver -ItemType Directory -Force | Out-Null
                    Copy-Item -Path (Join-Path $srcDriver '*') -Destination $dstDriver -Recurse -Force
                } else {
                    $dstOtherDriver = Join-Path $dstPrebuilt $BSP_driver
                    if (Test-Path $dstOtherDriver) { Remove-Item -Path $dstOtherDriver -Recurse -Force }
                    Copy-Item -Path $srcDriver -Destination $dstPrebuilt -Recurse -Force
                }
                if ($usedAltDriver) {
                    Write-Host "Completed!" -ForegroundColor Green
                    Write-Host ""
                }
            }
        }

        if ($debugTargets.Count -gt 0) {
            # Update debug mode line
            $printedDebug = $false
            $updatedDebug = $false
            foreach ($targetPath in $debugTargets) {
                $params = @{
                    DesktopScriptsPath    = $targetPath
                    EnableDebug           = $enable_debugMode
                    SkipCompletionMessage = $true
                }
                if ($printedDebug) { $params.SuppressMessages = $true }
                if (Set-DebugModeInTotalUpdate @params) {
                    $updatedDebug = $true
                    if (-not $printedDebug) { $printedDebug = $true }
                }
            }
            if ($updatedDebug) {
                Write-Host "Completed!" -ForegroundColor Green
            }

            # Update boot EFI rename line
            $printedRename = $false
            $updatedRename = $false
            foreach ($targetPath in $debugTargets) {
                $params = @{
                    DesktopScriptsPath    = $targetPath
                    EnableRename          = $rename_efi
                    SkipCompletionMessage = $true
                }
                if ($printedRename) { $params.SuppressMessages = $true }
                if (Set-RenameEfiInTotalUpdate @params) {
                    $updatedRename = $true
                    if (-not $printedRename) { $printedRename = $true }
                }
            }
            if ($updatedRename) {
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
            if ($BSP_driver -eq 'regrouped_driver_ATT_Signed' -or $BSP_driver -eq 'ProdSigned') {
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
            # Ask if user wants to modify pre-loaded drivers
            do {
                $modifyPreloaded = Read-Host "Modify pre-loaded driver? (y/n)"
                $modifyPreloadedLow = $modifyPreloaded.ToLower()
            } until ($modifyPreloadedLow -eq 'y' -or $modifyPreloadedLow -eq 'n')
            
            if ($modifyPreloadedLow -eq 'n') {
                Write-Host "Skip modifying preloaded drivers" -ForegroundColor Yellow
            } else {
                # Display available driver configuration groups
                Write-Host ""
                Write-Host "Available driver config groups:"
                $maxIndexLen = ($driverConfigs.Count).ToString().Length
                for ($i = 0; $i -lt $driverConfigs.Count; $i++) {
                    $num = ($i+1).ToString().PadLeft($maxIndexLen)
                    Write-Host ("{0}) {1}" -f $num, $driverConfigs[$i].name)
                }
                
                # Let user select a configuration group
				do {
					$configSelection = Read-Host "Enter the number"
					$valid = $configSelection -match '^\d+$' -and [int]$configSelection -ge 1 -and [int]$configSelection -le $driverConfigs.Count
				} until ($valid)
                
                $selectedConfig = $driverConfigs[$configSelection - 1]
                Write-Host "Selected configuration: " -NoNewline
                Write-Host "$($selectedConfig.name)" -ForegroundColor Yellow
                Write-Host ""
                
                # Get target BSP driver folder path
                $targetBspDriver = Join-Path $dstPrebuilt $BSP_driver
                if ($BSP_driver -eq 'regrouped_driver_ATT_Signed') {
                    $targetBspDriver = Join-Path $dstPrebuilt 'regrouped_driver'
                }
                
                # Call the function to modify drivers
                Update-PreloadedDrivers -DriversTxtPath $driversTxtPath -ThumbdriveDst $thumbdriveDst -TargetBspDriver $dstBspDriver -RemoveDrivers $selectedConfig.remove_driver -AddDrivers $selectedConfig.add_driver -ProductId $product_id | Out-Null
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
                "bcdedit /store `"$bcdFullPath`" /ENUM ALL",
                "bcdedit /store `"$bcdFullPath`" /set {default} osdevice ramdisk=[boot]\sources\winpe.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}",
                "bcdedit /store `"$bcdFullPath`" /set {default} device ramdisk=[boot]\sources\winpe.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}",
                "bcdedit /store `"$bcdFullPath`" /ENUM ALL"
            )
            $success = $true
            for ($i = 0; $i -lt $bcdCmds.Count; $i++) {
                $bcdCmd = $bcdCmds[$i]
                $output = cmd /c $bcdCmd 2>&1 | Out-String
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "Failed: $bcdCmd" -ForegroundColor Red
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
            # Function to modify installwoa.cmd
            function Update-InstallwoaCmd {
                param([string]$InstallwoaPath, [string]$LocationName)
                
                if (!(Test-Path $InstallwoaPath)) {
                    Write-Host "  installwoa.cmd not found in $LocationName" -ForegroundColor Yellow
                    return $false
                }
                
                try {
                    $content = Get-Content $InstallwoaPath -Raw -Encoding Default
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
                        Set-Content -Path $InstallwoaPath -Value ($newLines -join "`r`n") -Encoding Default
                        # Reload installwoa.cmd and confirm
                        $verifyContent = Get-Content $InstallwoaPath -Raw -Encoding Default
                        if ($verifyContent -match "set deviceModel=CRD") {
                            return $true
                        } else {
                            Write-Host "  Modification failed or not verified in $LocationName" -ForegroundColor Red
                            return $false
                        }
                    } else {
                        Write-Host "  Target block not found in installwoa.cmd ($LocationName)" -ForegroundColor Yellow
                        return $false
                    }
                } catch {
                    Write-Host "  Failed to modify installwoa.cmd in $LocationName : $PSItem" -ForegroundColor Red
                    return $false
                }
            }
            
            # Modify installwoa.cmd in Thumbdrive
            $thumbdriveInstallwoaPath = Join-Path $thumbdriveDst 'installwoa.cmd'
            $thumbdriveModified = Update-InstallwoaCmd -InstallwoaPath $thumbdriveInstallwoaPath -LocationName "Thumbdrive"
            
            # Modify installwoa.cmd in DesktopScripts
            $desktopScriptsInstallwoaPath = Join-Path $dstPrebuilt 'DesktopScripts\installwoa.cmd'
            $desktopScriptsModified = Update-InstallwoaCmd -InstallwoaPath $desktopScriptsInstallwoaPath -LocationName "DesktopScripts"
            
            # Check if both files were modified successfully
            $thumbdriveExists = Test-Path $thumbdriveInstallwoaPath
            $desktopScriptsExists = Test-Path $desktopScriptsInstallwoaPath
            
            if (-not $thumbdriveExists -and -not $desktopScriptsExists) {
                Write-Host "installwoa.cmd not found in both Thumbdrive and DesktopScripts" -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
            } elseif ($thumbdriveModified -and $desktopScriptsModified) {
                Write-Host "Completed!" -ForegroundColor Green
            } else {
                # At least one file failed to modify
                $errorMsg = "Failed to modify installwoa.cmd:"
                if ($thumbdriveExists -and -not $thumbdriveModified) {
                    $errorMsg += " Thumbdrive"
                }
                if ($desktopScriptsExists -and -not $desktopScriptsModified) {
                    if ($errorMsg -ne "Failed to modify installwoa.cmd:") { $errorMsg += "," }
                    $errorMsg += " DesktopScripts"
                }
                if (-not $thumbdriveExists) {
                    $errorMsg += " (Thumbdrive file not found)"
                }
                if (-not $desktopScriptsExists) {
                    $errorMsg += " (DesktopScripts file not found)"
                }
                Write-Host $errorMsg -ForegroundColor Red
                Write-Host ""
                Read-Host "Press Enter to exit..."
                return
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
            # Ask if user wants to modify pre-loaded drivers
            do {
                $modifyPreloaded = Read-Host "Modify pre-loaded driver? (y/n)"
                $modifyPreloadedLow = $modifyPreloaded.ToLower()
            } until ($modifyPreloadedLow -eq 'y' -or $modifyPreloadedLow -eq 'n')
            
            if ($modifyPreloadedLow -eq 'n') {
                Write-Host "Skip modifying preloaded drivers" -ForegroundColor Yellow
            } else {
                # Display available driver configuration groups
                Write-Host ""
                Write-Host "Available driver config groups:"
                $maxIndexLen = ($driverConfigs.Count).ToString().Length
                for ($i = 0; $i -lt $driverConfigs.Count; $i++) {
                    $num = ($i+1).ToString().PadLeft($maxIndexLen)
                    Write-Host ("{0}) {1}" -f $num, $driverConfigs[$i].name)
                }
                
                # Let user select a configuration group
				do {
					$configSelection = Read-Host "Enter the number"
					$valid = $configSelection -match '^\d+$' -and [int]$configSelection -ge 1 -and [int]$configSelection -le $driverConfigs.Count
				} until ($valid)
				
                $selectedConfig = $driverConfigs[$configSelection - 1]
                Write-Host "Selected configuration: " -NoNewline
                Write-Host "$($selectedConfig.name)" -ForegroundColor Yellow
                Write-Host ""
                
                # Get thumbdrive destination path
                $thumbdriveDst = Join-Path (Join-Path $dstPrebuilt 'ISOGEN/emmcdl_method') 'Thumbdrive'
                
                # Call the function to modify drivers
                Update-PreloadedDrivers -DriversTxtPath $driversTxtPath -ThumbdriveDst $thumbdriveDst -TargetBspDriver $dstBspDriver -RemoveDrivers $selectedConfig.remove_driver -AddDrivers $selectedConfig.add_driver -ProductId $product_id | Out-Null
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
			Write-Host ""
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
        # if (-not $product_id) {    # 此段先comment, 因為MEP driver不會有ID
        #     Write-Host "Cannot detect product id from driver folder!" -ForegroundColor Red
        #     return
        # }

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
            $signInfo = Get-DriverSignType -FilePath $catPath
            Write-Host -NoNewline ("  {0}: " -f $label)
            Write-Host $signInfo.Type -ForegroundColor $signInfo.Color
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
        # Get CVA info
        Write-Host ""
        Write-Host "Getting BSP detail CVA info..." -ForegroundColor Cyan
        
        # Common settings
        $CVA_OS = "W11A"
        $CVA_filePath = Join-Path -Path $PWD -ChildPath "$cva_file"
        $exeFilePath = ".\Version.exe"
        
        # Create CVA_info file if not exists
        if (-not (Test-Path $CVA_filePath)) {
            New-Item -Path $CVA_filePath -ItemType File -Force | Out-Null
        }
        
        # Check Version.exe info
        if (Test-Path $exeFilePath) {
            try {
                $exeItem = Get-Item $exeFilePath
                # More robust version retrieval
                $exeVersionString = $null
                try {
                    $exeVersionString = $exeItem.VersionInfo.FileVersion
                } catch {}
                if (-not $exeVersionString) {
                    try {
                        $verInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo((Resolve-Path $exeFilePath))
                        $exeVersionString = $verInfo.FileVersion
                    } catch {}
                }

                # Convert version to hex: extract numeric parts, pad to 4 with zeros
                $exeHexVersion = "N/A"
                if ($exeVersionString) {
                    $exeVersionParts = @([regex]::Matches($exeVersionString, '\d+')) | ForEach-Object { $_.Value }
                    while ($exeVersionParts.Count -lt 4) { $exeVersionParts += '0' }
                    $exeVersionParts = $exeVersionParts[0..3]
                    $exeHexVersion = "0x{0:X4},0x{1:X4},0x{2:X4},0x{3:X4}" -f [int]$exeVersionParts[0], [int]$exeVersionParts[1], [int]$exeVersionParts[2], [int]$exeVersionParts[3]
                }

                # Display the captured information header (BSP)
                $BSP_sub = "`n==== BSP CVA Information ===="
                Write-Host $BSP_sub
                Write-Host "File Version: " -NoNewline
                Write-Host "$exeVersionString" -ForegroundColor 'Blue'

                # Signature info (can be slow on some systems due to revocation checks)
                try {
                    $sig = Get-AuthenticodeSignature -FilePath $exeFilePath
                    if ($sig) {
                        $signer = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { "Unknown signer" }
                        $status = $sig.Status
                        $color = if ($status -eq 'Valid') { 'Blue' } else { 'Red' }
                        Write-Host "Signature: " -NoNewline
                        Write-Host "$status - $signer" -ForegroundColor $color
                    } else {
                        Write-Host "Signature: Not available" -ForegroundColor 'Yellow'
                    }
                } catch {
                    Write-Host "Signature: Skipped (error during signature check)" -ForegroundColor Yellow
                }

                # Display and persist the formatted line
                $exe_info = "Version.exe=<DRIVERS>,$exeHexVersion,$CVA_OS"
                Write-Host "Detail info: " -NoNewline
				Write-Host $exe_info -BackgroundColor 'Blue'

                # Check if CVA_info.txt has specific string
                $hasBSPInfo = Test-SectionExists $CVA_filePath "BSP CVA Information"
                if (-not $hasBSPInfo) {
                    Add-ContentSafely $CVA_filePath $BSP_sub "BSP Header"
                    Add-ContentSafely $CVA_filePath $exe_info "Version.exe Info"
                }

            } catch {
                Write-Host "Failed to read Version.exe details." -ForegroundColor 'Red'
            }
        } else {
            Write-Host "Version.exe not found in the current directory!" -ForegroundColor 'Red'
			Write-Host ""
			return
        }
        Write-Host ""
        Write-Host "Completed!" -ForegroundColor Green
        Write-Host ""
    }
	'8' {
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

