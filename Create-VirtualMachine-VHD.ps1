Set-ExecutionPolicy Unrestricted
<#
Funções de Suporte
#>
function local_Apply_Cab($cabName)
{
    Write-Output "-> Instalando pacote $cabName.cab"

    Invoke-Expression "$DismFolder\dism /Add-Package /PackagePath:'$mountVolumeDriveLetter\NanoServer\Packages\$cabName.cab' /Image:'$VHD_DirName'"
    Invoke-Expression "$DismFolder\dism /Add-Package /PackagePath:'$mountVolumeDriveLetter\NanoServer\Packages\en-us\$cabName.cab' /Image:'$VHD_DirName'"
}

function local_GetNextFileName()
{
    $indexNumber = 1;
    $newFileName = ""
    for (; $indexNumber -lt 2000; $indexNumber++) { 
        $newFileName =  $VHD_FileName -replace '.vhd', "_$indexNumber.vhd"
        If (-not (Test-Path $newFileName)){
            break
        }
    }
    return $newFileName    
}

function local_Apply_Unattend()
{
    Write-Output "-> Aplicando unattend.xml"
    Write-Output "$DismFolder\dism /image:$VHD_DirName /Apply-Unattend:.\unattend.xml"
    Invoke-Expression "$DismFolder\dism /image:$VHD_DirName /Apply-Unattend:.\unattend.xml"
    If (-not (Test-Path "$VHD_DirName\windows\panther")){
        New-Item -itemtype directory -path "$VHD_DirName\windows\panther"
    }
    Copy-Item -Path ".\unattend.xml" -Destination "$VHD_DirName\windows\panther" -Force 
}




<#
Configuração
#>



$isoShortFileName = (Get-ChildItem -Filter *.iso)
$WindowsISO = join-path -path (Resolve-Path  -path '.\') $isoShortFileName.Name
$VHD_DirName = join-path -path (Resolve-Path  -path '.\') 'NanoServer_vhd' 
$VHD_FileName = join-path -path (Resolve-Path  -path '.\') 'NanoServer.vhd'
$DismFolder = join-path -path (Resolve-Path  -path '.\') 'dism'

Write-Output "-> Montando imagem $WindowsISO"
$mountResult = Mount-DiskImage -ImagePath $WindowsISO -StorageType ISO -PassThru 
$mountVolume = $mountResult | Get-Volume
$mountVolumeDriveLetter = ($mountVolume | Get-Volume).DriveLetter
Write-Output "-> A imagem foi montada na unidade $mountVolumeDriveLetter"
$mountVolumeDriveLetter = $mountVolumeDriveLetter + ':'

Write-Output "-> Criando pasta DISM"
New-Item -itemtype directory -path $DismFolder | Out-Null

Write-Output "-> Copiando artefatos da pasta DISM da ISO para a pasta local"
Copy-Item -Path $mountVolumeDriveLetter\sources\api*downlevel*.dll -Destination $DismFolder -Force
Copy-Item -Path $mountVolumeDriveLetter\sources\*dism*.dll -Destination $DismFolder -Force 
Copy-Item -Path $mountVolumeDriveLetter\sources\*provider*.dll -Destination $DismFolder -Force 
Copy-Item -Path $mountVolumeDriveLetter\sources\*dism*.* -Destination $DismFolder -Force 


Write-Output "-> Convertendo WIM em VHD"
Invoke-Expression ".\Convert-WindowsImage.ps1 -WIM '$mountVolumeDriveLetter\NanoServer\NanoServer.wim' -VHD '$VHD_FileName' -VHDFormat VHD -DiskType Dynamic -SizeBytes 5GB -Edition 1"

Write-Output "-> Montando $VHD_FileName em $VHD_DirName"
New-Item -itemtype directory -path $VHD_DirName | Out-Null
Mount-WindowsImage -ImagePath $VHD_FileName -Path $VHD_DirName -Index 1 | Out-Null


local_Apply_Cab -cabName 'Microsoft-NanoServer-Compute-Package'
local_Apply_Cab -cabName 'Microsoft-NanoServer-FailoverCluster-Package'
local_Apply_Cab -cabName 'Microsoft-NanoServer-Guest-Package'
local_Apply_Cab -cabName 'Microsoft-NanoServer-OEM-Drivers-Package'
local_Apply_Cab -cabName 'Microsoft-NanoServer-Storage-Package'
local_Apply_Cab -cabName 'Microsoft-OneCore-ReverseForwarders-Package'

local_Apply_Unattend

New-Item -Type Directory $VHD_DirName\Windows\Setup | Out-Null
New-Item -Type Directory $VHD_DirName\Windows\Setup\Scripts | Out-Null
Copy-Item -Path ".\SetupComplete.cmd" -Destination "$VHD_DirName\Windows\Setup\Scripts" -Force | Out-Null

#pause

Write-Output "-> Desmontando $VHD_DirName e aplicando alterações em $VHD_FileName"
Dismount-WindowsImage -Path $VHD_DirName -Save | Out-Null
remove-item $VHD_DirName


Write-Output "-> Renomeando VHD"
$newFileName = local_GetNextFileName
Move-Item $VHD_FileName $newFileName
remove-item $DismFolder -Force -Recurse 

Write-Output "-> Desmontando ISO $WindowsISO da unidade $mountVolumeDriveLetter"
Dismount-DiskImage -ImagePath $WindowsISO -StorageType ISO

Write-Output "-> O novo disco está pronto com nome de $newFileName"
