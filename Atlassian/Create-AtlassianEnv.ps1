<#
.SYNOPSIS
	This script provisions the Atlassian environment.
	
.DESCRIPTION
	This script creates storage accounts, copies the VM image to each storage account and then provisions the VMs.

.PREREQUISITES
    This script copies the Walgreens Windows and Linux "golden" images from the 'ppsssitwuimg1' storage account.  The user
    running this script needs access to that account.
	
.NOTES
	Original Author: Ed Mondek
	New Author: Bob Seward
	Date: 7/28/2015
	Revision: 1.0

.CHANGELOG
    1.0  7/27/2015  Ed Mondek  Initial commit
    1.0  7/31/2015  Robert Seward  Initial commit
#>

function Clear-Ten()
{
    Write-Output " " " " " " " " " " " " " " " " " " " "
}

function Clear-Screen()
{
    Clear-Ten
    Clear-Ten
    Clear-Ten
    Clear-Ten
}

function New-Error {
    [CmdletBinding()]
    param()
    $MyErrorRecord = new-object System.Management.Automation.ErrorRecord `
	"", `
	"", `
	([System.Management.Automation.ErrorCategory]::NotSpecified), `
	""
    $PSCmdlet.WriteError($MyErrorRecord)
}

function Write-ColorOutput-SingleQ($ForegroundColor)
{
    # save the current color
    $fc = $host.UI.RawUI.ForegroundColor

    # set the new color
    $host.UI.RawUI.ForegroundColor = $ForegroundColor

    # output
    if ($args) {
	Invoke-Expression "Write-Output $args"
    }
    else {
	$input | Write-Output
#	for($wcoCount = 0; $wcoCount -le $args.Length; $wcoCount++) {
#	    Write-Output "$args[$wcoCount]"
#	}
    }

    # restore the original color
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-ColorOutput($ForegroundColor)
{
    # save the current color
    $fc = $host.UI.RawUI.ForegroundColor

    # set the new color
    $host.UI.RawUI.ForegroundColor = $ForegroundColor

    # output
    if ($args) {
	Write-Output $args
    }
    else {
	$input | Write-Output
#	for($wcoCount = 0; $wcoCount -le $args.Length; $wcoCount++) {
#	    Write-Output "$args[$wcoCount]"
#	}
    }

    # restore the original color
    $host.UI.RawUI.ForegroundColor = $fc
}

$Global:ecRc = $false
$Global:ecOutput = $null
$Global:ecError = $null
$Global:ecVariableError = $null
function Execute_Command($ecExecute, $ecCommand)
{
    $Global:ecRc = $true
    $functionRc = $false
    $functionLEC = 0
    $functionError = $null
    $Global:ecOutput = $null
    $Global:ecError = $null
    $Global:ecVariableError = $null
    if ($ecCommand -ne $null) {
	if($ecExecute -eq 0) {
	    Write-ColorOutput "Green" ">> EXECUTE: $ecCommand"
	    $Global:ecOutput = Invoke-Expression $ecCommand -ErrorVariable functionError 2>&1
	    $functionRc = $?
	    $functionLEC = $LASTEXITCODE
	    $Global:ecError = $Global:ecOutput | ?{$_.gettype().Name -eq "ErrorRecord"}
	    if ($functionError -ne $null) {
	        $Global:ecVariableError = $functionError
	        $functionRc = $false
	    }
	}
	else {
	    Write-ColorOutput "Yellow" ">> TESTING: $ecCommand"
	    $functionRc = $true
	}
    }

Write-ColorOutput "Magenta" ">> RETURN-CODES: [$functionRc|$functionLEC|$functionError]"
    $Global:ecRc = $functionRc

#--------------------------------------------------
# Other method?!?
#    if($functionRc -eq $false) {
#	New-Error
#    }
#--------------------------------------------------

}

######################################################################################################
# Create-Cloud-Services
#
function Create-Cloud-Services()
{
    foreach ($thisTier in $theseTiers)
    {
	$thisTierName = $thisTier.ToLower()
	$theseCSNames = $null
	for($count=1;$count -le $CloudServicesTotal.$thisTier;$count++)
	{
	    $thisCloudService = "$ProjectPrefix$DataCenterPrefix$CloudServicePrefix$thisTierName$count"
	    $theseCSNames += @($thisCloudService)

	    $thisCommand = "New-AzureService -ServiceName `"$thisCloudService`" -Location `"$location`""
	    $testCommand = "Get-AzureService -ServiceName $thisCloudService"
	    Execute_Command 0 "$testCommand"; $thisRc=$?
	    if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-AS]: [$thisRc|$Global:ecRc]"

	    if ($Global:ecRc -eq $false) {
Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-AS]: [$Global:ecVariableError]"
# Write-ColorOutput "Red" "BOBFIX-ENABLE[N-AS]"
		Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-AS]: [$thisRc|$Global:ecRc]"
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-AS]: $Global:ecOutput'
		if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
	    } else {
		Write-ColorOutput "Yellow" "Get-AzureService: -ServiceName `"$thisCloudService`" already created!"
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-AS]: $Global:ecOutput'
	    }

	    $newReservedName = "${thisCloudService}vip"
	    $thisCommand = "New-AzureReservedIP -Location `"$location`" -ReservedIPName `"$newReservedName`""
	    $testCommand = "Get-AzureReservedIP -ReservedIPName `"$newReservedName`""
	    Execute_Command 0 "$testCommand"; $thisRc=$?
	    if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ARIP]: [$thisRc|$Global:ecRc]"

	    if ($Global:ecRc -eq $false) {
Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-ARIP]: [$Global:ecVariableError]"
# Write-ColorOutput "Red" "BOBFIX-ENABLE[n-ARIP]"
		Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[A-ARIP]: [$thisRc|$Global:ecRc]"
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[A-ARIP]: $Global:ecOutput'
		if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
	    } else {
		Write-ColorOutput "Yellow" "Get-AzureReservedIP -ReservedIPName `"$newReservedName`" already created!"
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-ARIP]: $Global:ecOutput'
	    }

	}
# BOBFIX
Write-ColorOutput "Red" "BOBFIX-DISABLE[CloudServiceName-OVERRIDE]"
# if($BOBTEST -eq $true -and $thisTier -ne "DB") { $theseCSNames = "$ProjectPrefix$DataCenterPrefix$thisTierName"+"1" }
if($BOBTEST -eq $true) { $theseCSNames = "$ProjectPrefix$DataCenterPrefix$thisTierName"+"1" }
	$Global:CloudServiceName += @{"$thisTier" = @($theseCSNames)}
    }
}


######################################################################################################
# Copy-VM-Image
# Copy the Windows VM Install VHD images to the storage accounts
#
function Copy-VM-Image($cvmiStoragePool, $cvmiTier, $cvmiTierCount, $cvmiStoragePoolExt)
{
    ###############################################################################################################
    # Set the current storage account (not required but a good practice)
    $thisCommand = "Set-AzureSubscription -SubscriptionName `"$subscriptionName`" -CurrentStorageAccountName `"$cvmiStoragePool`""
    Execute_Command 0 "$thisCommand"; $thisRc=$?
    if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
    #
    ###############################################################################################################


#    $thisCommand = "Get-AzureStorageKey -StorageAccountName "+'$cvmiStoragePool'
    $thisCommand = "Get-AzureStorageKey -StorageAccountName $cvmiStoragePool"
    Write-ColorOutput "Green" ">> EXECUTE: `$destStorageKey = (Invoke-Expression $thisCommand).Primary"
    $destStorageKey = (Invoke-Expression $thisCommand).Primary; $thisRc=$?
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT[G-ASK]: $destStorageKey"
    if ($thisRc -eq $false) { Exit }

    $thisCommand = "New-AzureStorageContext –StorageAccountName $cvmiStoragePool -StorageAccountKey $destStorageKey"
    Write-ColorOutput "Green" ">> EXECUTE: `$destContext = Invoke-Expression $thisCommand"

    $destContext = Invoke-Expression $thisCommand; $thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ASCr]: [$thisRc|$Global:ecRc]"
# Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[N-ASCx]: $destContext'
    if ($thisRc -eq $false) { Exit }

    $thisCommand = "New-AzureStorageContainer -Name $containerName -Context "+'$destContext'
    $testCommand = "Get-AzureStorageContainer -Name $containerName -Context "+'$destContext'
    Execute_Command 0 "$testCommand"; $thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ASCr]: [$thisRc|$Global:ecRc]"

    if ($Global:ecRc -eq $false) {
Write-ColorOutput "Red" "BOBFIX-ERROR[G-ASCr]: [$Global:ecVariableError]"
# Write-ColorOutput "Red" "BOBFIX-ENABLE[G-ASC]"
Set-PSDebug -trace 0 -strict;Exit
	Execute_Command 0 "$thisCommand"; $thisRc=$?
	if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ASCr]: [$thisRc|$Global:ecRc]"
    }
    else {
	Write-ColorOutput "Yellow" "Storage Container: `"$containerName`" Storage-Account: `"$cvmiStoragePool`" already created!"
    }

    $blob = $null
    $thisOSImageType = 0
    $theseImageNames = $null
    foreach ($baseImageName in $imageNames)
    {
	$srcBlob = $baseImageName
	$destBlob = $baseImageName

	$thisCommand = "Start-AzureStorageBlobCopy -Context "+'$srcContext'+" -SrcContainer $srcContainer -SrcBlob $srcBlob `
        	-DestContext "+'$destContext'+" -DestContainer $destContainer -DestBlob $destBlob `
        	-Force"
	$testCommand = "Get-AzureStorageBlob -Blob $destBlob -Container $containerName -Context "+'$destContext'
	Execute_Command 0 "$testCommand"; $thisRc=$?
	if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ASB]: [$thisRc|$Global:ecRc]"

	if ($Global:ecRc -eq $false) {
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[N-ASCx]: $destContext'
	    Write-Host Copying $baseImageName to $cvmiStoragePool
Write-ColorOutput "Red" "BOBFIX-ERROR[G-ASB]: [$Global:ecVariableError]"
	    Write-ColorOutput "Green" ">> EXECUTE: `$blob = $thisCommand"
	    $Global:ecRc = $true
# Set-PSDebug -trace 0 -strict;Exit
# Write-ColorOutput "Red" "BOBFIX-ENABLE[S-ASBC]"
if ( $cvmiStoragePool -match "$StoragePoolPrefix$HP_STORAGE") { Set-PSDebug -trace 1 -strict }
# if ( $cvmiStoragePool -match "$StoragePoolPrefix$HP_STORAGE") { Set-PSDebug -trace 0 -strict;Exit }
	    $blob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
        	-DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
        	-Force
	    $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[S-ASBC]: [$thisRc|$Global:ecRc]"

	    $thisCommand = "Get-AzureStorageBlobCopyState -WaitForComplete"
	    Write-ColorOutput "Green" ">> EXECUTE: `$blob = $thisCommand"
	    $Global:ecRc = $true
	    $blob | Get-AzureStorageBlobCopyState -WaitForComplete
	    $thisRc = $?
Set-PSDebug -trace 0 -strict
Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ASBCS]: [$thisRc|$Global:ecRc]"
	    if ($thisRc -eq $false) { Exit }
	} else {
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-ASCr]: $Global:ecOutput'
	    Write-ColorOutput "Yellow" "Storage Blob: -Blob `"$destBlob`" -Container `"$containerName`" -Context "'"$destContext" already created!'
	}

	$osTypePretty = $theseOSPrettyTypes[$thisOSImageType]
	$VMImageName = "$WAG_IMAGE_PREFIX"+$OS_PREFIX[$thisOSImageType]+"$cvmiStoragePoolExt"
	$VMImageLabel = $VMImageName
	$imageDescription = $BaseDescriptions[$thisOSImageType]+" in storage account {0}" -f $cvmiStoragePool
	$testCommand = "Get-AzureVMImage -ImageName $VMImageName"
	Execute_Command 0 "$testCommand"; $thisRc=$?
	if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ASB]: [$thisRc|$Global:ecRc]"

	if ($Global:ecRc -eq $false) {
Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-AVMI]: [$Global:ecVariableError]"
	    $imageDisk = 'https://{0}.blob.core.windows.net/vhds/{1}' -f $cvmiStoragePool, $baseImageName
	    $thisRc = $?

	    $imageDate = (Get-Date)
	    $thisCommand = "Add-AzureVMImage -ImageName $VMImageName -MediaLocation $imageDisk -OS $osTypePretty -Label $VMImageLabel -Description `"$imageDescription`" -ImageFamily $imageFamily -PublishedDate `"$imageDate`" -ShowInGui"
	    Execute_Command 0 "$thisCommand"; $thisRc = $?
	    Write-ColorOutput "Magenta" "BOBFIX-RETURN[A-AVMI]: [$thisRc|$Global:ecRc]"
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[A-AVMI]: $Global:ecOutput'
#Write-ColorOutput "Magenta" "BOBFIX-CREATED-OUTPUT-ERRORS[G-AVMI]: [$Global:ecVariableError]"
	    if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
	} else {
	    Write-ColorOutput "Yellow" "Get-AzureVMImage: -ImageName `"$VMImageName`" already created!"
# Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-AVMI]: $Global:ecOutput'
	}
	$theseImageNames += @($VMImageName)
	$thisOSImageType++
    }
    if ($cvmiTierCount -le 1) { $thisSPIType = "$cvmiTier" }
    else { $thisSPIType = "$cvmiTier$cvmiTierCount" }
    $Global:StoragePoolImages += @{"$thisSPIType" = @($theseImageNames)}

}


######################################################################################################
# Create-Storage-Pools
#
function Create-Storage-Pools()
{
    foreach ($thisTier in $theseTiers)
    {
	$thisTierName = $thisTier.ToLower()
	$theseSPNames = $null
	for($count=1;$count -le $StoragePoolsTotal.$thisTier;$count++)
	{
	    if($StoragePoolsTotal.$thisTier -le 1) {
		$thisStorageType = $StoragePoolTypes.$thisTier
	    }else {
		$thisStorageType = $StoragePoolTypes.$thisTier[$count-1]
	    }
	    $thisStoragePool = "$ProjectPrefix$DataCenterPrefix$StoragePoolPrefix$thisStorageType$thisTierName$count"
	    $theseSPNames += @($thisStoragePool)

	    $StorageTypeParameter = $StoragePoolParm.$thisStorageType
	    $thisCommand = "New-AzureStorageAccount -StorageAccountName `"$thisStoragePool`" -Location `"$location`" -Type $StorageTypeParameter"
	    $testCommand = "Get-AzureStorageAccount -StorageAccountName `"$thisStoragePool`""
	    Execute_Command 0 "$testCommand"; $thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ASA]: [$thisRc|$Global:ecRc]"

	    if ($Global:ecRc -eq $false) {
Write-ColorOutput "Red" "BOBFIX-ERROR[G-ASA]: [$Global:ecVariableError]"
# Write-ColorOutput "Red" "BOBFIX-ENABLE[N-ASA]"
		Execute_Command 0 "$thisCommand"; $thisRc=$?
		if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
	    }
	    else {
		Write-ColorOutput "Yellow" "Storage Account `"$thisStoragePool`" already created!"
	    }
# if ( $thisTier -eq "DB" -and $thisStorageType -eq "hp") { Set-PSDebug -trace 0 -strict;Exit }
	    Copy-VM-Image "$thisStoragePool" "$thisTier" "$count" "$thisStorageType$thisTierName$count"

	}
	$Global:StoragePoolName += @{"$thisTier" = @($theseSPNames)}
    }
}


######################################################################################################
# INITIALIZE
#

Write-ColorOutput "Red" "BOBTEST-NEED-TO-Turn off BOBTEST"
Set-PSDebug -trace 1 -strict
$BOBTEST = $true

Set-PSDebug -trace 0 -strict
$Error.Clear()
$LASTEXITCODE = $null

Clear-Screen

Set-StrictMode -Version Latest

# Set-PSDebug -trace 1 -strict
# For Testing here
# Set-PSDebug -trace 0 -strict
# Exit

#
# END INITIALIZE
######################################################################################################


######################################################################################################
# INITIALIZE Variables
#
$Global:CloudServiceName = @{}
$Global:StoragePoolName = @{}
$Global:StoragePoolImages = @{}
$ProjectPrefix = 'atlass'
$DataCenterPrefix = 'wu'
$CloudServicePrefix = 'cs'
$StoragePoolPrefix = 'sp'
$STD_STORAGE = 'st'
$HP_STORAGE = 'hp'

$STANDARD_STORAGE = 'Standard_LRS'
$HIGHPERF_STORAGE = 'Premium_LRS'

$StoragePoolParm = @{"$STD_STORAGE" = "$STANDARD_STORAGE"; "$HP_STORAGE" = "$HIGHPERF_STORAGE"}

#-----------------------------------------------------------------------------------------------------
# Initialize Azure variables
$subscriptionName = 'Atlassian Subscription (NSEN)'
$subscriptionPROSsit = 'PROS SIT'
$vnetName = 'WBA Atlassian Azure'
$location = 'West US'
$userName = 'wagsadmin'
$password = 'Welcome!234'

#-----------------------------------------------------------------------------------------------------
# Initialize Server "Naming" variables
    $theseTiers = @("WEB","APP","DB")
# Number of WEB, APP, and DB VMs to be created
Write-ColorOutput "Red" "BOBFIX-TESTING second DB server in High Perf Storage"
Set-PSDebug -trace 1 -strict
#    $tierCounts = @(1,4,1)
    $tierCounts = @(1,4,2)
Set-PSDebug -trace 0 -strict
# Number of WINDOWS servers for WEB, APP, and DB
    $tierWindowsCounts = @(0,1,0)
# Number of Cloud services for WEB, APP, and DB
    $CloudServicesTotal = @{"WEB" = 1; "APP" = 1; "DB" = 1}
# Number of Storage Pools for WEB, APP, and DB
    $StoragePoolsTotal = @{"WEB" = 1; "APP" = 1; "DB" = 2}
# Storage Pool Types for WEB, APP, and DB
    $StoragePoolTypes = @{"WEB" = "$STD_STORAGE"; "APP" = "$STD_STORAGE"; "DB" = @("$STD_STORAGE", "$HP_STORAGE")}
# Storage Pool For each Server
    $StoragePoolNumber = @{}
    $StoragePoolNumber.WEB = @(0)
    $StoragePoolNumber.APP = @(0,0,0,0)
    $StoragePoolNumber.DB = @(0,1)

$thisEnv="P"
$theseOSTypes = @("WINDOWS","LINUX")
$theseOSPrettyTypes = @("Windows","Linux")
$theseOSs = @("W","L")
$theseTypes = @("WB","AP","DB")
$thisDataCenterLoc="AZ"
$thisApplication="ATL"

#-----------------------------------------------------------------------------------------------------
# Initialize "Image-Types" variables
$azureStdVMSize = "Standard_DS3"
$azureHighPerfVMSize = "Standard_DS12"

#-----------------------------------------------------------------------------------------------------
# Initialize Nework and IP-Pools variables
$newSubnets = @("WBA-ATL-WEB","WBA-ATL-APP","WBA-ATL-DB")
$newWebIPAddrs = @("10.217.0.4","10.217.0.5","10.217.0.6","10.217.0.7","10.217.0.8","10.217.0.9","10.217.0.10")
$newAppIPAddrs = @("10.217.0.68","10.217.0.69","10.217.0.70","10.217.0.71","10.217.0.72","10.217.0.73","10.217.0.74")
$newDBIPAddrs = @("10.217.0.132","10.217.0.133","10.217.0.134","10.217.0.135","10.217.0.136","10.217.0.137","10.217.0.138")
$newIPAddrs = $newWebIPAddrs, $newAppIPAddrs, $newDBIPAddrs

#-----------------------------------------------------------------------------------------------------
# Initialize Storage Type name extensions
$newStdStorageNames = @()
# BOBFIX 2015/08/09: Removed img1 storage account, as it was not required for what we are doing
# $newStdStorageTypes = @('web1', 'app1', 'img1')
$newStdStorageTypes = @('web1', 'app1')
$newHighPerfStorageNames = @()
$newHighPerfStorageTypes = @('db1')
$standardLUNType = "Standard"
$standardLUNSize = 100
$standardLUNTotal = 2
$databaseLUNType = "P20"
$databaseLUNSize = 512
$databaseLUNTotal = 3
#
$WAG_IMAGE_PREFIX = 'wags'
$WINDOWS_PREFIX = 'win2012r2'
$LINUX_PREFIX = 'linux'
$OS_PREFIX = @($WINDOWS_PREFIX, $LINUX_PREFIX)

#
$WindowsBaseDescription = 'Walgreens Windows Server 2012 R2'
$LinuxBaseDescription = 'Walgreens Linux'
$BaseDescriptions = @($WindowsBaseDescription, $LinuxBaseDescription)
#-----------------------------------------------------------------------------------------------------
# Initialize Cloud Services array
$newCloudServices = @()

#-----------------------------------------------------------------------------------------------------
# Initialize Container names
$containerName = 'vhds'
$srcContainer = 'vhds'
$destContainer = 'vhds'

#-----------------------------------------------------------------------------------------------------
# Initialize Image names and family
$srcStorageAccount = 'ppsssitwuimg1'

$windowsImageName = '2012R2Image.vhd'
$linuxImageName = 'LinuxImage.vhd'
$imageNames = $windowsImageName, $linuxImageName

# BOBFIX 2015/08/09: Updated Images Names per where they are going, changed due to removing img1 storage account
# $imageWindowsNames = @('wagswin2012r2app1', 'wagswin2012r2app2', 'wagswin2012r2db1', 'wagswin2012r2as1')
# $imageLinuxNames = @('wagslinuxweb1', 'wagslinuxapp2', 'wagslinuxdb1', 'wagslinuxdb2')
$imageWindowsNames = @('wagswin2012r2app1', 'wagswin2012r2app2', 'wagswin2012r2db1')
$imageLinuxNames = @('wagslinuxweb1', 'wagslinuxapp2', 'wagslinuxdb1')
$imageFamily = 'Walgreens'

#-----------------------------------------------------------------------------------------------------
# Initialize VMLists
$VMList = @()
$windowsVMList = @()
$linuxVMList = @()

#-----------------------------------------------------------------------------------------------------
# Initialize Endpoints
$sshEndpointName = 'SSH'
$sshEndpointPort = 57101
#---
$rdpEndpointName = 'RemoteDesktop'
$rdpEndpointPort = 57201
#---
$EndpointNames = $rdpEndpointName, $sshEndpointName
$EndpointPorts = $rdpEndpointPort, $sshEndpointPort
#---
$domainJoin = 'devwalgreenco.net'
$domain = 'walgreenco'
#---
$ou = 'OU=Azure,OU=Servers,DC=devwalgreenco,DC=net'
#
Write-ColorOutput "Red" "BOBFIX-NEED-TO-FIX[???]: [`$dns UNDEFINED]"
$dns = $null
#
######################################################################################################


######################################################################################################
# DEPRECATED Information
#
#-----------------------------------------------------------------------------------------------------
# $newCloudServices = @('pccperfwuweb1', 'pccperfwuapp1', 'pccperfwudb1')
#-----------------------------------------------------------------------------------------------------
#
######################################################################################################


######################################################################################################
# Begin Azure work
######################################################################################################
# Sign in to your Azure account
#
Write-ColorOutput "Red" "BOBFIX-ENABLE[A-AA]"
$thisCommand = "Add-AzureAccount"
Execute_Command 1 "$thisCommand"; $thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[A-AA]: [$thisRc|$Global:ecRc]"
if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
#
######################################################################################################



###############################################################################################################
# Get the source storage key to copy the VM Install VHD image from
#
# NOTE: STARTING (Need to change selected subscription to pull the key in the next step)
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionPROSsit`""
Execute_Command 0 "$thisCommand"; $thisRc=$?
if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
# NOTE: COMPLETE
#--------------------------------------------------------------------------------------------------------------
$thisCommand = "Get-AzureStorageKey -StorageAccountName $srcStorageAccount"
Write-ColorOutput "Green" ">> EXECUTE: `$srcStorageKey = (Invoke-Expression $thisCommand).Primary"
$srcStorageKey = (Invoke-Expression $thisCommand).Primary; $thisRc=$?
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT: $srcStorageKey"
#--------------------------------------------------------------------------------------------------------------
# NOTE STARTING:  (Need to change selected subscription Back to this subscription after retrieving key)
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionName`""
Execute_Command 0 "$thisCommand"; $thisRc=$?
if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
# NOTE: COMPLETE
#--------------------------------------------------------------------------------------------------------------
# Create the source storage Context to copy the VM Install VHD image from
$thisCommand = "New-AzureStorageContext –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey"
Write-ColorOutput "Green" ">> EXECUTE: `$srcContext = Invoke-Expression $thisCommand"
$srcContext = Invoke-Expression $thisCommand; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ASCr]: [$thisRc|$Global:ecRc]"
if ($thisRc -eq $false) { Exit }
#
###############################################################################################################



###############################################################################################################
# Set the current subscription
#
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionName`""
Execute_Command 0 "$thisCommand"; $thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[S-AS]: [$thisRc|$Global:ecRc]"
if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }
#
###############################################################################################################


Clear-Ten


###############################################################################################################
# Create the Cloud Services
#
# Write-ColorOutput "Red" "BOBFIX-ENABLE[Create-Cloud-Services]!!!!!!!!!"
# if ($true -eq $false) {
Create-Cloud-Services
# }
$Global:CloudServiceName
# $Global:CloudServiceName.WEB
# $Global:CloudServiceName.APP
# $Global:CloudServiceName.DB
#
###############################################################################################################


###############################################################################################################
# Create the Storage Pools
#
# Write-ColorOutput "Red" "BOBFIX-ENABLE[Create-Storage-Pools]!!!!!!!!!"
# if ($true -eq $false) {
Create-Storage-Pools
# }
$Global:StoragePoolName
# $Global:StoragePoolName.WEB
# $Global:StoragePoolName.APP
# $Global:StoragePoolName.DB
#
###############################################################################################################


Clear-Ten


$stdCount = 0
$highPerfCount = 0
# $thisRDPPort = $rdpEndpointPort
# $thisSSHPort = $sshEndpointPort
for ($typeCount=0;$typeCount -lt 3;$typeCount++)
{
    # BOBFIX: 2015/08/09: Ports are specific to Cloud Services, which we have a separate one per type
#    $thisRDPPort = $rdpEndpointPort
#    $thisSSHPort = $sshEndpointPort
    $EndpointPortCount = @()
    $EndpointPortCount += $rdpEndpointPort
    $EndpointPortCount += $sshEndpointPort

    $thisTierType = $theseTiers[${typeCount}]
    $thisTierPrefixType = $theseTypes[${typeCount}]
    $entryMax = $tierCounts[${typeCount}]
    $windowsMax = $tierWindowsCounts[${typeCount}]

    $newAVSet = $CloudServiceName.$thisTierType -creplace '[0-9]*$',''
    $newAVSet = "${newAVSet}avset"

    for ($entryCount=0;$entryCount -lt $entryMax;$entryCount++)
    {
	$entryCountPrint = $($entryCount+1).ToString("00")

	#----------------------------------------------------------------------------------------
	# Provision any WINDOWS Servers first, rest of the servers are LINUX
	if ($entryCount -lt $windowsMax) { $thisOSTypeEntry=0 }
	#----------------------------------------------------------------------------------------
	# Rest of the servers are LINUX
	else { $thisOSTypeEntry=1 }
	#----------------------------------------------------------------------------------------
	$thisOS = $theseOSs[${thisOSTypeEntry}]
	$thisOSType = $theseOSTypes[${thisOSTypeEntry}]
	$thisEndpointName = $EndpointNames[${thisOSTypeEntry}]
	$thisImageName = $StoragePoolImages.$thisTierType[${thisOSTypeEntry}]
	$thisEndpointPort = $EndpointPortCount[${thisOSTypeEntry}]
	$EndpointPortCount[${thisOSTypeEntry}]++
	#----------------------------------------------------------------------------------------
# Set-PSDebug -trace 1 -strict
# $thisOS
# $thisOSType
# $thisEndpointName
# $thisImageName
# $thisEndpointPort
# Set-PSDebug -trace 0 -strict

# Set-PSDebug -trace 1 -strict
# $StoragePoolName.$thisTierType.Count
# $StoragePoolName.$thisTierType
	if ( $StoragePoolName.$thisTierType.Count -le 1) {
	    $thisStorageAccount = $StoragePoolName.$thisTierType
	} else {
	    # BOBFIX at some point fix to specify which pool for each server.
# Write-ColorOutput "Red" "BOBFIX-FIX-FUTURE to at some point fix to specify which pool for each server."
	    $thisStoragePoolEntry = $StoragePoolNumber.$thisTierType[$entryCount]
	    $thisStorageAccount = $StoragePoolName.$thisTierType[$thisStoragePoolEntry]
# $thisStorageAccount
	}
# Set-PSDebug -trace 0 -strict

	#----------------------------------------------------------------------------------------
	# Test for DATABASE server, which is HIGH-PERFORMANCE Storage
	if ($typeCount -eq 2) {
	    $thisImageSize = $azureHighPerfVMSize
	    $thisDiskType = $databaseLUNType
	    $thisDiskSize = $databaseLUNSize
	    $thisDiskTotal = $databaseLUNTotal
	}
	#----------------------------------------------------------------------------------------
	# Rest of the servers are STANDARD-PERFORMANCE Storage
	else {
	    $thisImageSize = $azureStdVMSize
	    $thisDiskType = $standardLUNType
	    $thisDiskSize = $standardLUNSize
	    $thisDiskTotal = $standardLUNTotal
	}
	#----------------------------------------------------------------------------------------

	$thisVMName = "$thisEnv$thisOS$thisTierPrefixType-$thisDataCenterLoc$thisApplication$entryCountPrint"

	$VMList += @(,($thisVMName, `
			$thisTierType, `
			$CloudServiceName.$thisTierType, `
			$thisOSType, `
			$thisImageName, `
			$thisImageSize, `
			$newAVSet, `
			$thisStorageAccount, `
			$thisDiskType, $thisDiskSize, $thisDiskTotal, `
			$newSubnets[${typeCount}], `
			$newIPAddrs[${typeCount}][${entryCount}], `
			$thisEndpointName, $thisEndpointPort `
		))
    }
    #----------------------------------------------------------------------------------------
    # Test for DATABASE server, which is HIGH-PERFORMANCE Storage
    if ($typeCount -eq 2) {
	$highPerfCount++
    }
    #----------------------------------------------------------------------------------------
    # Rest of the servers are STANDARD-PERFORMANCE Storage
    else {
	$stdCount++
    }
}

# Set-PSDebug -trace 1 -strict
$VMList.count
    for($thisVMCount=0;$thisVMCount -lt $VMList.count;$thisVMCount++) { "Entry:[$thisVMCount] ==>"; $VMList[$thisVMCount] }
# $VMList[0]
# $VMList[1]
# $VMList[2]
# $VMList[3]
# $VMList[4]
# $VMList[5]
Set-PSDebug -trace 0 -strict
# Exit 1


# Create VMs
for($entryCount = 0; $entryCount -lt $VMList.count; $entryCount++)
{
#Write-ColorOutput "Red" "BOBFIX-SKIPPING VM-Creation till ready"; if($entryCount -lt 5) { continue }
    $vmName = $VMList[${entryCount}][0]
    $tierType = $VMList[${entryCount}][1]
    $serviceName = $VMList[${entryCount}][2]
    $osType = $VMList[${entryCount}][3]
    $imageName = $VMList[${entryCount}][4]
    $vmSize = $VMList[${entryCount}][5]
    $avSetName = $VMList[${entryCount}][6]
    $storageAccount = $VMList[${entryCount}][7]
    $thisDiskType = $VMList[${entryCount}][8]
    $thisDiskSize = $VMList[${entryCount}][9]
    $thisDiskTotal = $VMList[${entryCount}][10]
    $subnetName = $VMList[${entryCount}][11]
    $staticIPAddress = $VMList[${entryCount}][12]
    $thisEndpointName = $VMList[${entryCount}][13]
    $thisEndpointPort = $VMList[${entryCount}][14]
    $osDisk = 'https://{0}.blob.core.windows.net/vhds/{1}-os-1.vhd' -f $storageAccount, $vmName

    $testCommand = "Get-AzureVM -Name $vmName -ServiceName $serviceName"
    Execute_Command 0 "$testCommand"; $thisRc=$?
    if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-AVM]: [$thisRc|$Global:ecRc]"

#if ( $newHighPerfStorageNames -contains $storageAccount) { Write-ColorOutput "RED" ">> SKIPPING: $vmname DUE to different execution steps"; continue }
    if ($Global:ecRc -eq $false) {
Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-AVM]: [$Global:ecVariableError]"

	$thisCommand = "New-AzureVMConfig -Name $vmName -InstanceSize $vmSize -ImageName $imageName -AvailabilitySetName $avSetName -MediaLocation $osDisk"
	Write-ColorOutput "Green" ">> EXECUTE: `$vm1 = Invoke-Expression $thisCommand"
	$vm1 = Invoke-Expression $thisCommand; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-VMC]: [$thisRc|$Global:ecRc]"
	if ($thisRc -eq $false) { Exit }

	if ($osType -eq "LINUX")
	{
	    $thisCommand = "Add-AzureProvisioningConfig -vm "+'$vm1'+" -Linux -LinuxUser $userName -Password $password"
	} elseif ($osType -eq "WINDOWS")
	{
	    $thisCommand = "Add-AzureProvisioningConfig -vm "+'$vm1'+" -Windows -AdminUsername $userName -Password $password -NoWinRMEndpoint"
	}
	Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[A-APC]: [$thisRc|$Global:ecRc]"
	if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }

	$thisCommand = "Set-AzureEndpoint -Name $thisEndpointName -vm "+'$vm1'+" -PublicPort $thisEndpointPort"
	Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[S-AE]: [$thisRc|$Global:ecRc]"
	if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }

	$thisCommand = "Set-AzureSubnet -SubnetNames $subnetName -VM "+'$vm1'
	Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[A-AS]: [$thisRc|$Global:ecRc]"
	if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }

	$thisCommand = "Set-AzureStaticVNetIP -IPAddress $staticIPAddress -VM "+'$vm1'
	Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[A-ASVNIP]: [$thisRc|$Global:ecRc]"
	if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }

	for($thisDiskCount = 1; $thisDiskCount -le $thisDiskTotal; $thisDiskCount++)
	{
	    $dataDisk = 'https://{0}.blob.core.windows.net/vhds/{1}-data-{2}.vhd' -f $storageAccount, $vmName, $thisDiskCount
	    $thisDiskLabel = "Data_$thisDiskCount"
	    $thisCommand = "Add-AzureDataDisk -CreateNew -DiskSizeInGB $thisDiskSize -DiskLabel $thisDiskLabel -LUN $thisDiskCount -VM "+'$vm1'+" -MediaLocation $dataDisk"
	    Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[A-ADD]: [$thisRc|$Global:ecRc]"
	    if ($thisRc -eq $false -or $Global:ecRc -eq $false) { Exit }

	}

	$thisCommand = "New-AzureVM -ServiceName $serviceName -vm "+'$vm1'+" -VNetName `"$vnetName`""
#	if ($osType -eq "WINDOWS") { $thisCommand = "$thisCommand -DnsSettings $dns" }
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[N-AVM]: $vm1'
# Write-ColorOutput "Red" "BOBFIX-ENABLE[N-AVM]"
	Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-AVM]: [$thisRc|$Global:ecRc]"
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[N-AVM]: $Global:ecOutput'
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-VM1[N-AVM]: $vm1'
	if ($thisRc -eq $false -or $Global:ecRc -eq $false) {
	    Write-ColorOutput "Red" "BOBFIX-ERROR[N-AVM]: [$Global:ecVariableError]"
	    Exit
	}

    } else {
	Write-ColorOutput "Yellow" "Get-AzureVM: -Name `"$vmName`" -ServiceName `"$serviceName`" already created!"
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-AVM]: $Global:ecOutput'
    }

# Associate the Reserved VIPs with the cloud services
    $newReservedName = "${serviceName}vip"
    $thisCommand = "Set-AzureReservedIPAssociation -ReservedIPName $newReservedName -ServiceName $serviceName"
#    $testCommand = "Get-AzureReservedIP -ReservedIPName `"$newReservedName`""
#    Execute_Command 0 "$testCommand"; $thisRc=$?
#    if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
#Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-AVM]: [$thisRc|$Global:ecRc]"

#    if ($Global:ecRc -eq $false) {
#Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-AVM]: [$Global:ecVariableError]"
# Write-ColorOutput "Red" "BOBFIX-SKIPPING ReservedIPAssociation [$entryCount] till ready"; if($entryCount -lt 5) { continue }
Write-ColorOutput "Red" "BOBFIX-SKIPPING ReservedIPAssociation [$entryCount] till ready"; if($entryCount -lt 6) { continue }
	Execute_Command 0 "$thisCommand"; $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN[S-ARIPA]: [$thisRc|$Global:ecRc]"
Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[S-ARIPA]: $Global:ecOutput'
	if ($thisRc -eq $false -or $Global:ecRc -eq $false) {
	    Write-ColorOutput "Red" "BOBFIX-ERROR[S-ARIPA]: [$Global:ecVariableError]"
	    Exit
	}
#    } else {
#	Write-ColorOutput "Yellow" "Get-AzureReservedIP: -ReservedIPName `"$newReservedName`" -ServiceName `"$serviceName`""
#Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-ARIP]: $Global:ecOutput'
#    }

}

Set-PSDebug -trace 0 -strict
Exit
