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
$Global:ecErrorVar = $null
function Execute_Command($ecExecute, $ecCommand)
{
    $functionRc = $false
    $functionLEC = 0
    $functionError = $null
    if ($ecCommand -ne $null) {
	if($ecExecute -eq 0) {
	    Write-ColorOutput "Green" ">> EXECUTE: $ecCommand"
	    $Global:ecOutput = Invoke-Expression $ecCommand -ErrorVariable functionError 2>&1
	    $functionRc = $?
	    $functionLEC = $LASTEXITCODE
	    $Global:ecError = $Global:ecOutput | ?{$_.gettype().Name -eq "ErrorRecord"}
	    if ($functionError -ne $null) {
	        $Global:ecErrorVar = $functionError
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
# INITIALIZE
#

Set-PSDebug -trace 0 -strict
$Error.Clear()

Clear-Screen

Set-StrictMode -Version Latest

Set-PSDebug -trace 1 -strict
# For Testing here
Set-PSDebug -trace 0 -strict
# Exit

#
# END INITIALIZE
######################################################################################################


######################################################################################################
# INITIALIZE Variables
#
$ProjectPrefix = 'atlass'
$DataCenterPrefix = 'wu'

#-----------------------------------------------------------------------------------------------------
# Initialize Azure variables
$subscriptionName = 'Atlassian Subscription (NSEN)'
$subscriptionPROSsit = 'PROS SIT'
$vnetName = 'Atlassian-VNet'
$location = 'West US'
$userName = 'wagsadmin'
$password = 'Welcome!234'

#-----------------------------------------------------------------------------------------------------
# Initialize Server "Naming" variables
$theseTiers = @("WEB","APP","DB")
$thisEnv="P"
$theseOSTypes = @("WINDOWS","LINUX")
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
$newStdStorageTypes = @('web1', 'app1', 'img1')
$newHighPerfStorageNames = @()
$newHighPerfStorageTypes = @('db1')

#-----------------------------------------------------------------------------------------------------
# Initialize Cloud Services array
$newCloudServices = @()

#-----------------------------------------------------------------------------------------------------
# Initialize Container names
$srcContainer = 'vhds'
$destContainer = 'vhds'

#-----------------------------------------------------------------------------------------------------
# Initialize Image names and family
$imageWindowsNames = @('wagswin2012r2app1', 'wagswin2012r2app2', 'wagswin2012r2db1', 'wagswin2012r2as1')
$imageLinuxNames = @('wagslinuxweb1', 'wagslinuxapp2', 'wagslinuxdb1', 'wagslinuxdb2')
$imageFamily = 'Walgreens'

#-----------------------------------------------------------------------------------------------------
# Initialize VMLists
$VMList = @()
$windowsVMList = @()
$linuxVMList = @()

#-----------------------------------------------------------------------------------------------------
# Initialize Endpoints
$sshEndpointName = 'SSH'
$sshEndpointPort = '57101'
#---
$rdpEndpointName = 'RemoteDesktop'
$rdpEndpointPort = '57201'
#---
$domainJoin = 'devwalgreenco.net'
$domain = 'walgreenco'
#---
$ou = 'OU=Azure,OU=Servers,DC=devwalgreenco,DC=net'
#
Write-ColorOutput "Red" "BOBFIX-NEED-TO-FIX(???): [`$dns UNDEFINED]"
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
$thisCommand = "Add-AzureAccount"
Execute_Command 1 "$thisCommand"
$thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(A-AA): [$thisRc|$ecRc]"


# Set the current subscription
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionName`""
Execute_Command 0 "$thisCommand"
$thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(S-AS): [$thisRc|$ecRc]"

# Create the Standard storage accounts
foreach ($newStorageType in $newStdStorageTypes)
{

    $newStorageName = $ProjectPrefix + $DataCenterPrefix + $newStorageType
    $newStdStorageNames += "$newStorageName"
    if ( $newStorageType -ne 'img1') {
    	$newCloudServices += "$newStorageName"
    }
    $thisCommand = "New-AzureStorageAccount -StorageAccountName `"$newStorageName`" -Location `"$location`" -Type Standard_LRS"

    $testCommand = "Get-AzureStorageAccount -StorageAccountName `"$newStorageName`""
    Execute_Command 0 "$testCommand"
    $thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(G-ASA): [$thisRc|$ecRc]"

    if ($ecRc -eq $false) {
Write-ColorOutput "Red" "BOBFIX-ERROR(G-ASA): [$Global:ecErrorVar]"
	Execute_Command 0 "$thisCommand"
    }
    else {
	Write-ColorOutput "Yellow" "Storage Account `"$newStorageName`" already created!"
    }

}
$destStorageAccounts = $newStdStorageNames

# Create the High-Performance storage accounts
foreach ($newStorageType in $newHighPerfStorageTypes)
{

    $newStorageName = $ProjectPrefix + $DataCenterPrefix + $newStorageType
    $newHighPerfStorageNames += "$newStorageName"
    if ( $newStorageType -ne 'img1') {
    	$newCloudServices += "$newStorageName"
    }
    $thisCommand = "New-AzureStorageAccount -StorageAccountName `"$newStorageName`" -Location `"$location`" -Type Premium_LRS"

    $testCommand = "Get-AzureStorageAccount -StorageAccountName `"$newStorageName`""
    Execute_Command 0 "$testCommand"
    $thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(G-ASA): [$thisRc|$ecRc]"

    if ($ecRc -eq $false) {
Write-ColorOutput "Red" "BOBFIX-ERROR(G-ASA): [$Global:ecErrorVar]"
	Execute_Command 0 "$thisCommand"
    }
    else {
	Write-ColorOutput "Yellow" "Storage Account `"$newStorageName`" already created!"
    }

}
$destStorageAccounts += $newHighPerfStorageNames

# Set the current storage account (not required but a good practice)
$thisCommand = "Set-AzureSubscription -SubscriptionName `"$subscriptionName`" -CurrentStorageAccountName `"$($newStdStorageNames[0])`""
Execute_Command 0 "$thisCommand"

# Copy the Windows VM image VHDs to the storage accounts
$srcStorageAccount = 'ppsssitwuimg1'

# NOTE: STARTING (Need to change selected subscription to pull the key in the next step)
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionPROSsit`""
Execute_Command 0 "$thisCommand"
# NOTE: COMPLETE

$thisCommand = "Get-AzureStorageKey -StorageAccountName $srcStorageAccount"
Write-ColorOutput "Green" ">> EXECUTE: `$srcStorageKey = (Invoke-Expression $thisCommand).Primary"
$srcStorageKey = (Invoke-Expression $thisCommand).Primary
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT: $srcStorageKey"

# NOTE STARTING:  (Need to change selected subscription Back to this subscription after retrieving key)
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionName`""
Execute_Command 0 "$thisCommand"
# NOTE: COMPLETE


#$srcContext = New-AzureStorageContext –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey
$thisCommand = "New-AzureStorageContext –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey"
Write-ColorOutput "Green" ">> EXECUTE: `$srcContext = Invoke-Expression $thisCommand"
$srcContext = Invoke-Expression $thisCommand
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT: $srcContext"


Clear-Ten


foreach ($destStorageAccount in $destStorageAccounts)
{

#    $destStorageKey = (Get-AzureStorageKey -StorageAccountName $destStorageAccount).Primary
    $thisCommand = "Get-AzureStorageKey -StorageAccountName $destStorageAccount"
    Write-ColorOutput "Green" ">> EXECUTE: `$destStorageKey = (Invoke-Expression $thisCommand).Primary"
    $destStorageKey = (Invoke-Expression $thisCommand).Primary
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT(G-ASK): $destStorageKey"

#    $destContext = New-AzureStorageContext –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey
    $thisCommand = "New-AzureStorageContext –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey"
    Write-ColorOutput "Green" ">> EXECUTE: `$destContext = Invoke-Expression $thisCommand"
    $destContext = Invoke-Expression $thisCommand
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT(N-ASCx): $srcContext"

# Write-Output "	BOBFIX >>>> " `
#    New-AzureStorageContainer -Name vhds -Context $destContext
Write-ColorOutput "Red" "BOBFIX: Do a test with Get-AzureStorageContainer"
    $thisCommand = "New-AzureStorageContainer -Name vhds -Context $destContext"
    Execute_Command 1 "$thisCommand"
    $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(N-ASCr): [$thisRc|$ecRc]"

    $srcBlob = '2012R2Image.vhd'
    $destBlob = '2012R2Image.vhd'
    Write-Host Copying Windows VHD to $destStorageAccount

    $blob = $null
#    $blob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
#        -DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
#        -Force
    $thisCommand = "Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
        -DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
        -Force"
    Write-ColorOutput "Yellow" ">> TESTING: `$blob = Invoke-Expression $thisCommand"
Write-Output "	BOBFIX >>>> " `
    $blob = Invoke-Expression $thisCommand
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT(S-ASBC): $blob"

Write-Output "	BOBFIX >>>> `
    $blob | Get-AzureStorageBlobCopyState -WaitForComplete"

    $srcBlob = 'LinuxImage.vhd'
    $destBlob = 'LinuxImage.vhd'

    Write-Host Copying Linux VHD to $destStorageAccount

    $blob = $null
#    $blob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
#        -DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
#        -Force
    $thisCommand = "Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
        -DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
        -Force"
    Write-ColorOutput "Yellow" ">> TESTING: `$blob = Invoke-Expression $thisCommand"
Write-Output "	BOBFIX >>>> " `
    $blob = Invoke-Expression $thisCommand
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT(S-ASBC): $blob"

Write-Output "	BOBFIX >>>> `
    $blob | Get-AzureStorageBlobCopyState -WaitForComplete"

}


Clear-Ten


# Create the VM Image objects
$count = 0
foreach ($destStorageAccount in $destStorageAccounts)
{
#    $imageDisk = 'https://{0}.blob.core.windows.net/vhds/2012R2Image.vhd' -f $destStorageAccount
    $thisCommand = "`'https://{0}.blob.core.windows.net/vhds/2012R2Image.vhd`' -f `$destStorageAccount"
    Write-ColorOutput "Green" ">> EXECUTE: `$imageDisk = Invoke-Expression $thisCommand"
    $imageDisk = Invoke-Expression $thisCommand
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT(https): $imageDisk"
    $imageName = $imageWindowsNames[$count]
    $imageLabel = $imageWindowsNames[$count]
    $imageDescription = 'Walgreens Windows Server 2012 R2 in storage account {0}' -f $destStorageAccount

#    Add-AzureVMImage -ImageName $imageName -MediaLocation $imageDisk -OS Windows -Label $imageLabel -Description $imageDescription -ImageFamily $imageFamily -PublishedDate (Get-Date) -ShowInGui
    $thisCommand = "Add-AzureVMImage -ImageName $imageName -MediaLocation $imageDisk -OS Windows -Label $imageLabel -Description $imageDescription -ImageFamily $imageFamily -PublishedDate (Get-Date) -ShowInGui"
    Execute_Command 1 "$thisCommand"
    $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(A-AVMI): [$thisRc|$ecRc]"

#    $imageDisk = 'https://{0}.blob.core.windows.net/vhds/LinuxImage.vhd' -f $destStorageAccount
    $thisCommand = "`'https://{0}.blob.core.windows.net/vhds/LinuxImage.vhd`' -f `$destStorageAccount"
    Write-ColorOutput "Green" ">> EXECUTE: `$imageDisk = Invoke-Expression $thisCommand"
    $imageDisk = Invoke-Expression $thisCommand
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT(https): $imageDisk"
    $imageName = $imageLinuxNames[$count]
    $imageLabel = $imageLinuxNames[$count]
    $imageDescription = 'Walgreens Linux in storage account {0}' -f $destStorageAccount
#    Add-AzureVMImage -ImageName $imageName -MediaLocation $imageDisk -OS Linux -Label $imageLabel -Description $imageDescription -ImageFamily $imageFamily -PublishedDate (Get-Date) -ShowInGui
    $thisCommand = "Add-AzureVMImage -ImageName $imageName -MediaLocation $imageDisk -OS Linux -Label $imageLabel -Description $imageDescription -ImageFamily $imageFamily -PublishedDate (Get-Date) -ShowInGui"
    Execute_Command 1 "$thisCommand"
    $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(A-AVMI): [$thisRc|$ecRc]"

    $count++
}


Clear-Ten


Write-ColorOutput "Cyan" "BOBFIX-(Cloud-Services): [$newCloudServices]"

foreach ($newCloudService in $newCloudServices)
{
    # Create the cloud services
    # New-AzureService -ServiceName '$newCloudService' -Location $location
    $thisCommand = "New-AzureService -ServiceName `"$newCloudService`" -Location $location"
    Execute_Command 1 "$thisCommand"
    $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(A-AVMI): [$thisRc|$ecRc]"

    # New-AzureReservedIP -Location $location -ReservedIPName 'pccperfwuweb1vip'
    $thisCommand = "New-AzureReservedIP -Location $location -ReservedIPName `"${newCloudService}vip`""
    Execute_Command 1 "$thisCommand"
    $thisRc = $?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(A-AVMI): [$thisRc|$ecRc]"

}


# Set-PSDebug -trace 0 -strict
for ($typeCount=0;$typeCount -lt 3;$typeCount++)
{
    $thisTier = $theseTiers[${typeCount}]
    $thisType = $theseTypes[${typeCount}]
    $entryMax = 1
    if ($typeCount -eq 0 -or $typeCount -eq 2) { $entryMax = 1 }
    else {
	if ($typeCount -eq 1) { $entryMax = 4 }
    }

    for ($entryCount=0;$entryCount -lt $entryMax;$entryCount++)
    {
	$newAVSet = $newCloudServices[${typeCount}] -creplace '[0-9]*$',''
	$newAVSet = "${newAVSet}avset"
	$entryCountPrint = $($entryCount+1).ToString("00")
	if ($typeCount -eq 1 -and $entryCount -eq 0) {
	    $thisOS = $theseOSs[0]
	    $thisOSType = $theseOSTypes[0]
	    $thisImageName = $imageWindowsNames[${typeCount}]
	    $thisEndpointName = $rdpEndpointName
	    $thisEndpointPort = $rdpEndpointPort
	}
	else {
	    $thisOS = $theseOSs[1]
	    $thisOSType = $theseOSTypes[1]
	    $thisImageName = $imageLinuxNames[${typeCount}]
	    $thisEndpointName = $sshEndpointName
	    $thisEndpointPort = $sshEndpointPort
	}
	if ($typeCount -eq 2) {
	    $thisImageSize = $azureHighPerfVMSize
	}
	else {
	    $thisImageSize = $azureStdVMSize
	}
	$thisVMName = "$thisEnv$thisOS$thisType-$thisDataCenterLoc$thisApplication$entryCountPrint"

	$VMList += @(,($thisVMName, `
			$thisTier, `
			$newCloudServices[${typeCount}], `
			$thisOSType, `
			$thisImageName, `
			$thisImageSize, `
			$newAVSet, `
			$newStdStorageNames[${typeCount}], `
			$newSubnets[${typeCount}], `
			$newIPAddrs[${typeCount}][${entryCount}], `
			$thisEndpointName, $thisEndpointPort `
		))
    }
}


Set-PSDebug -trace 1 -strict
$VMList[0]
$VMList[1]
$VMList[2]
$VMList[3]
$VMList[4]
$VMList[5]

$VMList.count

Set-PSDebug -trace 1 -strict
for($entryCount = 0; $entryCount -lt $VMList.count; $entryCount++)
{
    $vmName = $VMList[${entryCount}][0]
    $tierType = $VMList[${entryCount}][1]
    $serviceName = $VMList[${entryCount}][2]
    $osType = $VMList[${entryCount}][3]
    $imageName = $VMList[${entryCount}][4]
    $vmSize = $VMList[${entryCount}][5]
    $avSetName = $VMList[${entryCount}][6]
    $storageAccount = $VMList[${entryCount}][7]
    $subnetName = $VMList[${entryCount}][8]
    $staticIPAddress = $VMList[${entryCount}][9]
    $thisEndpointName = $VMList[${entryCount}][10]
    $thisEndpointPort = $VMList[${entryCount}][11]
    $osDisk = 'https://{0}.blob.core.windows.net/vhds/{1}-os-1.vhd' -f $storageAccount, $vmName
    $dataDisk1 = 'https://{0}.blob.core.windows.net/vhds/{1}-data-1.vhd' -f $storageAccount, $vmName
    $dataDisk2 = 'https://{0}.blob.core.windows.net/vhds/{1}-data-2.vhd' -f $storageAccount, $vmName

    if ($osType -eq "LINUX")
    {
Write-ColorOutput "Red" "BOBFIX-NEED-TO-FIX(???): [How many disks???]"
Write-ColorOutput "Yellow" ">> BOBFIX TESTING >>>> " `

Set-PSDebug -trace 0 -strict
Exit
	New-AzureVMConfig -Name $vmName -InstanceSize $vmSize -ImageName $imageName -AvailabilitySetName $avSetName -MediaLocation $osDisk | `
		Add-AzureProvisioningConfig -Linux -LinuxUser $userName -Password $password | `
		Set-AzureEndpoint -Name $thisEndpointName -PublicPort $thisEndpointPort | `
		Set-AzureSubnet -SubnetNames $subnetName | `
		Set-AzureStaticVNetIP -IPAddress $staticIPAddress | `
		Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 1' -LUN 1 -MediaLocation $dataDisk1 | `
		Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 2' -LUN 2 -MediaLocation $dataDisk2 | `
		New-AzureVM -ServiceName $serviceName -VNetName $vnetName

    }
    else
    {
	if ($osType -eq "WINDOWS")
	{
Write-ColorOutput "Red" "BOBFIX-NEED-TO-FIX(???): [How many disks???]"
Write-ColorOutput "Red" "BOBFIX-NEED-TO-FIX(???): [`$dns UNDEFINED]"
Write-ColorOutput "Yellow" ">> BOBFIX TESTING >>>> " `
	New-AzureVMConfig -Name $vmName -InstanceSize $vmSize -ImageName $imageName -AvailabilitySetName $avSetName -MediaLocation $osDisk | `

Set-PSDebug -trace 0 -strict
Exit
		Add-AzureProvisioningConfig -WindowsDomain -JoinDomain $domainJoin -Domain $domain -AdminUsername $userName -Password $password -MachineObjectOU $ou -NoWinRMEndpoint | `
		Set-AzureEndpoint -Name $rdpEndpointName -PublicPort $rdpEndpointPort | `
		Set-AzureSubnet -SubnetNames $subnetName | `
		Set-AzureStaticVNetIP -IPAddress $staticIPAddress | `
		Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 1' -LUN 1 -MediaLocation $dataDisk1 | `
		Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 2' -LUN 2 -MediaLocation $dataDisk2 | `
		New-AzureVM -ServiceName $serviceName -VNetName $vnetName -DnsSettings $dns

	}
    }

Set-PSDebug -trace 0 -strict
Exit
}


# Create App VM #1
Set-PSDebug -trace 0 -strict
Exit

# Associate the Reserved VIPs with the cloud services
Write-Output "	BOBFIX >>>> " `
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwuweb1vip' -ServiceName 'pccperfwuweb1'
Write-Output "	BOBFIX >>>> " `
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwuapp1vip' -ServiceName 'pccperfwuapp1'
Write-Output "	BOBFIX >>>> " `
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwudb1vip' -ServiceName 'pccperfwudb1'


Set-PSDebug -trace 0 -strict
Exit
