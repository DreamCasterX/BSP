
$_creator = "Mike Lu"
$_version = 1.0
$_changedate = 7/22/2025

$product = "glymur-wp-1-0_amss_standard_oem"
$product_id = "8480"


# User-defined settings
$BSP_driver = "regrouped_driver_ATT_Signed"    
$thumbdrive = "USB_Installer"
$new_driver = "IEC_driver"
$iso_folder = "ISO"
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
    "qccamflash_ext$product_id"
)

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
Write-Host "3) Update drivers"
Write-Host "4) Display driver info"    
Write-Host "5) Copy thumbdrive to USB" 
Write-Host "=========================="

do {
    $mainSelection = Read-Host "Select a function"
} until ($mainSelection -eq '1' -or $mainSelection -eq '2' -or $mainSelection -eq '3' -or $mainSelection -eq '4' -or $mainSelection -eq '5')

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
        $currentScript = $MyInvocation.MyCommand.Name
        # Ignore folders: WP/$thumbdrive/regrouped_driver
        $folders = Get-ChildItem -Directory | Where-Object { $_.Name -ne $currentScript -and $_.Name -ne 'WP' -and $_.Name -ne $thumbdrive -and $_.Name -ne $new_driver -and $_.Name -ne $iso_folder -and $_.Name -ne 'USB_Installer' -and $_.Name -ne 'IEC_driver' -and $_.Name -ne 'ISO' }
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
            $valid = $selection -match '^\d+$' -and $selection -ge 1 -and $selection -le $folders.Count
        } until ($valid)
        $srcRoot = $folders[$selection - 1].FullName

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
        if (Test-Path $dstFolder) {
            do {
                $overwrite = Read-Host "WP folder already exists, overwrite? (y/n)"
            } until ($overwrite -eq 'y' -or $overwrite -eq 'Y' -or $overwrite -eq 'n' -or $overwrite -eq 'N')
            if ($overwrite -eq 'n' -or $overwrite -eq 'N') {
                Write-Host "Skip copying BSP package files" -ForegroundColor Yellow
                Write-Host ""
            } else {
                Remove-Item -Path $dstFolder -Recurse -Force
                New-Item -Path $dstFolder -ItemType Directory -Force | Out-Null
                Copy-Item -Path $srcThumbdrive -Destination $dstFolder -Recurse -Force
                Write-Host "Completed!" -ForegroundColor Green
                Write-Host ""
                # Copy DesktopScripts
                $srcDesktopScripts = Join-Path (Join-Path $prebuiltPath $numFolder) 'DesktopScripts'
                $dstDesktopScripts = Join-Path $dstPrebuilt 'DesktopScripts'
                if (Test-Path $srcDesktopScripts) {
                    if (Test-Path $dstDesktopScripts) { Remove-Item -Path $dstDesktopScripts -Recurse -Force }
                    Copy-Item -Path $srcDesktopScripts -Destination $dstPrebuilt -Recurse -Force
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
            Write-Host "Completed!" -ForegroundColor Green
            Write-Host ""
            # Copy DesktopScripts
            $srcDesktopScripts = Join-Path (Join-Path $prebuiltPath $numFolder) 'DesktopScripts'
            $dstDesktopScripts = Join-Path $dstPrebuilt 'DesktopScripts'
            if (Test-Path $srcDesktopScripts) {
                if (Test-Path $dstDesktopScripts) { Remove-Item -Path $dstDesktopScripts -Recurse -Force }
                Copy-Item -Path $srcDesktopScripts -Destination $dstPrebuilt -Recurse -Force
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

        # Copy ADK files (DISM & BCDBoot)
        Write-Host "Copying ADK files to Thumbdrive..." -ForegroundColor Cyan
        $adkDism = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Dism\Dism.exe"
        $adkDismFolder = Split-Path $adkDism -Parent
        $adkBcdBootFolder = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\BCDBoot"
        $adkVersion = $null
        if (Test-Path $adkDism) {
            $adkVersion = (Get-Item $adkDism).VersionInfo.ProductVersion
            Write-Host "ADK version: " -NoNewline
            Write-Host $adkVersion -ForegroundColor Blue
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
        Write-Host "List of ISO files:"
        for ($i = 0; $i -lt $isoFiles.Count; $i++) {
            Write-Host ("{0}) {1}" -f ($i+1), $isoFiles[$i].Name)
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
        $winpeVersion = (Get-WmiObject -Class Win32_product | Where-Object {$_.Name -like "Windows PE Boot Files (DesktopEditions)*"} | Select-Object -ExpandProperty Version).ToString()
        if ($winpeVersion) {
            Write-Host "WinPE version: " -NoNewline
            Write-Host $winpeVersion -ForegroundColor Blue
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

        # Copy IEC customized drivers
        Write-Host "Copying IEC customized drivers..." -ForegroundColor Cyan

        $iecDriverFolder = Join-Path $PWD $new_driver
        if (!(Test-Path $iecDriverFolder)) {
            Write-Host "IEC driver folder not found" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }

        # Get all the folders in IEC_driver
        $iecSubFolders = Get-ChildItem -Path $iecDriverFolder -Directory
        if ($iecSubFolders.Count -eq 0) {
            Write-Host "No subfolders found in IEC_driver." -ForegroundColor Yellow
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

            # Compare the folder name between IEC_driver vs. BSP driver
            $iecNames = $iecSubFolders.Name
            $dstNames = $dstSubFolders.Name
            $sameNames = $iecNames | Where-Object { $dstNames -contains $_ }
            $diffNames = $iecNames | Where-Object { $dstNames -notcontains $_ }

            Write-Host "IEC_driver folders with the same name in BSP driver folder:"
            if ($sameNames.Count -eq 0) {
                Write-Host "  N/A"
            } else {
                $sameNames | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor Blue }
            }
            Write-Host "IEC_driver folders with different name:"
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
        }
        
        # Modify pre-loaded driver in DesktopScripts\drivers
        Write-Host ""
        Write-Host "Modifying preloaded drivers...." -ForegroundColor Cyan
        $desktopScriptsDir = Join-Path $dstPrebuilt 'DesktopScripts'
        $driversTxtPath = Join-Path $desktopScriptsDir 'drivers.txt'
        if (Test-Path $driversTxtPath) {
            Write-Host "Add list:"
            $add_driver | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
            Write-Host "Remove list:"
            $remove_driver | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
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
                        if ($remove_driver -contains $trimmedLine) {
                            continue # Skip this line
                        }
                        $newLines += $line # Add the current line
                        if ($trimmedLine -eq "qccamflash8480") {
                            $newLines += $add_driver # Add new drivers after the anchor
                        }
                    }
                    Set-Content -Path $driversTxtPath -Value $newLines -Encoding Default
                    Write-Host "Completed!" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to modify preloaded drivers: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "Skip modifying preloaded drivers" -ForegroundColor Yellow
            }
        }


        # Mount winpe.wim 
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
        # Update drivers
        Write-Host "Copying IEC customized drivers..." -ForegroundColor Cyan
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
            Write-Host "IEC driver folder not found" -ForegroundColor Red
            Write-Host ""
            Read-Host "Press Enter to exit..."
            return
        }
        $iecSubFolders = Get-ChildItem -Path $iecDriverFolder -Directory
        if ($iecSubFolders.Count -eq 0) {
            Write-Host "No subfolders found in IEC_driver." -ForegroundColor Yellow
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
            Write-Host "IEC_driver folders with the same name in BSP driver folder:"
            if ($sameNames.Count -eq 0) {
                Write-Host "  N/A"
            } else {
                $sameNames | ForEach-Object { Write-Host ("  " + $_) -ForegroundColor Blue }
            }
            Write-Host "IEC_driver folders with different name:"
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
        }

        # Modify pre-loaded driver in DesktopScripts\drivers
        $dstPrebuilt = Join-Path $prebuiltDir $numFolder
        Write-Host ""
        Write-Host "Modifying preloaded drivers...." -ForegroundColor Cyan
        $desktopScriptsDir = Join-Path $dstPrebuilt 'DesktopScripts'
        $driversTxtPath = Join-Path $desktopScriptsDir 'drivers.txt'
        if (Test-Path $driversTxtPath) {
            Write-Host "Add list:" 
            $add_driver | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
            Write-Host "Remove list:"
            $remove_driver | ForEach-Object { Write-Host ("  $_") -ForegroundColor Blue }
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
                        if ($remove_driver -contains $trimmedLine) {
                            continue # Skip this line
                        }
                        $newLines += $line # Add the current line
                        if ($trimmedLine -eq "qccamflash8480") {
                            $newLines += $add_driver # Add new drivers after the anchor
                        }
                    }
                    Set-Content -Path $driversTxtPath -Value $newLines -Encoding Default
                    Write-Host "Completed!" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to modify preloaded drivers: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "Skip modifying preloaded drivers" -ForegroundColor Yellow
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
        # Display driver info (GFX/Sensor/Camera/Audio/aDSP/QcTreeExtOem)
        Write-Host ""
        Write-Host "Check driver versions..." -ForegroundColor Cyan
        # Check if $new_driver folder exists
        $driverDir = Join-Path $PWD $new_driver
        if (!(Test-Path $driverDir)) {
            Write-Host "No driver folder found!" -ForegroundColor Red
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
        $driverList = @(
            @{ path = "qcdxext_crd$product_id/qcdxext_crd$product_id.inf"; label = "Gfx" },
            @{ path = "qcSensorsConfigCrd$product_id/qcSensorsConfigCrd$product_id.inf"; label = "SensorConfig" },
            @{ path = "qccamauxsensor$product_id/qccamauxsensor$product_id.inf"; label = "Camera (auxsensor)" },
            @{ path = "qccamavs$product_id/qccamavs$product_id.inf"; label = "Camera (avs)" },
            @{ path = "qccamfrontsensor$product_id/qccamfrontsensor$product_id.inf"; label = "Camera (frontsensor)" },
            @{ path = "qccamplatform$product_id/qccamplatform$product_id.inf"; label = "Camera (platform)" },
            @{ path = "qcaxu$product_id/qcaxu$product_id.inf"; label = "Audio" },
            @{ path = "qcsubsys_ext_adsp$product_id/qcsubsys_ext_adsp$product_id.inf"; label = "aDSP" },
            @{ path = "QcTreeExtOem$product_id/QcTreeExtOem$product_id.inf"; label = "QcTreeExtOem" }
        )
        foreach ($drv in $driverList) {
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
        foreach ($drv in $driverList) {
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
                            $signResult = "Test-signed"
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
            if ($signResult -eq "Test-signed") {
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
        $targetDrive = $usbArray[$selection - 1].DeviceID + '\'
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
}

