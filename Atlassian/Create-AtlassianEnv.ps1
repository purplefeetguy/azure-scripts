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

function Clear-Screen()
{
    Write-Output " " " " " " " " " " " " " " " " " " " "
    Write-Output " " " " " " " " " " " " " " " " " " " "
    Write-Output " " " " " " " " " " " " " " " " " " " "
    Write-Output " " " " " " " " " " " " " " " " " " " "
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


function Execute_Command($ecExecute)
{
    if ($args) {
	if($ecExecute -eq 0) {
	    Write-ColorOutput "Green" ">> EXECUTE: $args"
#Write-Output "	BOBFIX >>>> " `
	    Invoke-Expression $thisCommand
	}
	else {
	    Write-ColorOutput "Yellow" ">> TESTING: $args"
	}
    }

}

Clear-Screen

Set-StrictMode -Version Latest

Set-PSDebug -trace 0 -strict

# Detailed Debugging:
# $DebugPreference = 'Continue'
# $VerbosePreference = 'Continue'
#
# Default Debugging:
# $DebugPreference = 'SilentlyContinue'
# $VerbosePreference = 'SilentlyContinue'


$ProjectPrefix = 'atlass'
$DataCenterPrefix = 'wu'

# Sign in to your Azure account
$thisCommand = "Add-AzureAccount"
Execute_Command 1 "$thisCommand"

# Initialize variables
$subscriptionName = 'Atlassian Subscription (NSEN)'
$subscriptionPROSsit = 'PROS SIT'
$vnetName = 'Atlassian-VNet'
$location = 'West US'
$userName = 'wagsadmin'
$password = 'Welcome!234'

# Set the current subscription
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionName`""
Execute_Command 0 "$thisCommand"

# Create the Standard storage accounts
$newStdStorageNames = @()
$newStdStorageTypes = @('web1', 'app1', 'img1')

foreach ($newStorageType in $newStdStorageTypes)
{

$newStorageName = $ProjectPrefix + $DataCenterPrefix + $newStorageType
$newStdStorageNames += "$newStorageName"
$thisCommand = "New-AzureStorageAccount -StorageAccountName `"$newStorageName`" -Location `"$location`" -Type Standard_LRS"
Execute_Command 1 "$thisCommand"

}

# Create the Standard storage accounts
$newHighPerfStorageNames = @()
$newHighPerfStorageTypes = @('db1')

foreach ($newStorageType in $newHighPerfStorageTypes)
{

$newStorageName = $ProjectPrefix + $DataCenterPrefix + $newStorageType
$newHighPerfStorageNames += "$newStorageName"
$thisCommand = "New-AzureStorageAccount -StorageAccountName `"$newStorageName`" -Location `"$location`" -Type Premium_LRS"
Execute_Command 1 "$thisCommand"

}

# Set the current storage account (not required but a good practice)
$thisCommand = "Set-AzureSubscription -SubscriptionName `"$subscriptionName`" -CurrentStorageAccountName `"$($newStdStorageNames[0])`""
Execute_Command 0 "$thisCommand"

# Copy the Windows VM image VHDs to the storage accounts
$srcStorageAccount = 'ppsssitwuimg1'

# Write-ColorOutput "Red" "BOBFIX: OVERRIDE Storage device[ppsssitwuimg1]"
# $srcStorageAccount = 'atlasswudb1'

# BOBFIX STARTING (DELETE TILL COMPLETE WHEN FIXED By Azure)
Write-ColorOutput "Red" "BOBFIX: OVERRIDE Select-AzureSubscription [Atlassian Subscription (NSEN)]"
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionPROSsit`""
Execute_Command 0 "$thisCommand"
# BOBFIX COMPLETE (DELETE Back to STARTING WHEN FIXED By Azure)

$thisCommand = "Get-AzureStorageKey -StorageAccountName $srcStorageAccount"
Write-ColorOutput "Green" ">> EXECUTE: `$srcStorageKey = (Invoke-Expression $thisCommand).Primary"
$srcStorageKey = (Invoke-Expression $thisCommand).Primary
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT: $srcStorageKey"

# BOBFIX STARTING (DELETE TILL COMPLETE WHEN FIXED By Azure)
Write-ColorOutput "Red" "BOBFIX: RESET-OVERRIDE Select-AzureSubscription [Atlassian Subscription (NSEN)]"
$thisCommand = "Select-AzureSubscription -SubscriptionName `"$subscriptionName`""
Execute_Command 0 "$thisCommand"
# BOBFIX COMPLETE (DELETE Back to STARTING WHEN FIXED By Azure)

Set-PSDebug -trace 0 -strict

#$srcContext = New-AzureStorageContext –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey
$thisCommand = "New-AzureStorageContext –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey"
Write-ColorOutput "Green" ">> EXECUTE: `$srcContext = Invoke-Expression $thisCommand"
$srcContext = Invoke-Expression $thisCommand
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT: $srcContext"
$srcContainer = 'vhds'
$srcBlob = '2012R2Image.vhd'

$destStorageAccounts = $newStdStorageNames
$destStorageAccounts += $newHighPerfStorageNames
$destContainer = 'vhds'
$destBlob = '2012R2Image.vhd'

Set-PSDebug -trace 1 -strict

foreach ($destStorageAccount in $destStorageAccounts)
{

#    $destStorageKey = (Get-AzureStorageKey -StorageAccountName $destStorageAccount).Primary
    $thisCommand = "Get-AzureStorageKey -StorageAccountName $destStorageAccount"
    Write-ColorOutput "Green" ">> EXECUTE: `$destStorageKey = (Invoke-Expression $thisCommand).Primary"
    $destStorageKey = (Invoke-Expression $thisCommand).Primary
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT: $destStorageKey"

#    $destContext = New-AzureStorageContext –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey
    $thisCommand = "New-AzureStorageContext –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey"
    Write-ColorOutput "Green" ">> EXECUTE: `$destContext = Invoke-Expression $thisCommand"
    $destContext = Invoke-Expression $thisCommand
Write-ColorOutput "Cyan" "BOBFIX-OUTPUT: $srcContext"

Write-Output "	BOBFIX >>>> " `
    New-AzureStorageContainer -Name vhds -Context $destContext
    $thisCommand = "New-AzureStorageContainer -Name vhds -Context $destContext"
    Execute_Command 1 "$thisCommand"

    Write-Host Copying Windows VHD to $destStorageAccount


Set-PSDebug -trace 0 -strict
Exit

Write-Output "	BOBFIX >>>> " `
    $blob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
        -DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
        -Force

Set-PSDebug -trace 0 -strict
Exit

Write-Output "	BOBFIX >>>> " `
    $blob | Get-AzureStorageBlobCopyState -WaitForComplete
}

Set-PSDebug -trace 0 -strict
Exit

# Create the Windows VM Image objects
$imageNames = @('wagswin2012r2app1', 'wagswin2012r2app2', 'wagswin2012r2db1', 'wagswin2012r2as1')
$imageFamily = 'Walgreens'
$count = 0

foreach ($destStorageAccount in $destStorageAccounts)
{
Write-Output "	BOBFIX >>>> " `
    $imageDisk = 'https://{0}.blob.core.windows.net/vhds/2012R2Image.vhd' -f $destStorageAccount
    $imageName = $imageNames[$count]
    $imageLabel = $imageNames[$count]
    $imageDescription = 'Walgreens Windows Server 2012 R2 in storage account {0}' -f $destStorageAccount
Write-Output "	BOBFIX >>>> " `
    Add-AzureVMImage -ImageName $imageName -MediaLocation $imageDisk -OS Windows -Label $imageLabel -Description $imageDescription -ImageFamily $imageFamily -PublishedDate (Get-Date) -ShowInGui
    $count++
}

Set-PSDebug -trace 0 -strict
Exit

# Copy the Linux VM image VHDs to the storage accounts
$srcStorageAccount = 'ppsssitwuimg1'
Write-Output "	BOBFIX >>>> " `
$srcStorageKey = (Get-AzureStorageKey -StorageAccountName $srcStorageAccount).Primary
Write-Output "	BOBFIX >>>> " `
$srcContext = New-AzureStorageContext –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey
$srcContainer = 'vhds'
$srcBlob = 'LinuxImage.vhd'

$destStorageAccounts = @('pccperfwuweb1', 'pccperfwuapp1', 'pccperfwudb1', 'pccperfwudb2')
$destContainer = 'vhds'
$destBlob = 'LinuxImage.vhd'

foreach ($destStorageAccount in $destStorageAccounts)
{
Write-Output "	BOBFIX >>>> " `
    $destStorageKey = (Get-AzureStorageKey -StorageAccountName $destStorageAccount).Primary
Write-Output "	BOBFIX >>>> " `
    $destContext = New-AzureStorageContext –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey

Write-Output "	BOBFIX >>>> " `
    New-AzureStorageContainer -Name vhds -Context $destContext

Write-Output "	BOBFIX >>>> " `
    Write-Host Copying Linux VHD to $destStorageAccount

Write-Output "	BOBFIX >>>> " `
    $blob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
        -DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
        -Force

Write-Output "	BOBFIX >>>> " `
    $blob | Get-AzureStorageBlobCopyState -WaitForComplete
}

Set-PSDebug -trace 1 -strict

# Create the Linux VM Image objects
$imageNames = @('wagslinuxweb1', 'wagslinuxapp2', 'wagslinuxdb1', 'wagslinuxdb2')
$imageFamily = 'Walgreens'
$count = 0

foreach ($destStorageAccount in $destStorageAccounts)
{
Write-Output "	BOBFIX >>>> " `
    $imageDisk = 'https://{0}.blob.core.windows.net/vhds/LinuxImage.vhd' -f $destStorageAccount
    $imageName = $imageNames[$count]
    $imageLabel = $imageNames[$count]
    $imageDescription = 'Walgreens Linux in storage account {0}' -f $destStorageAccount
Write-Output "	BOBFIX >>>> " `
    Add-AzureVMImage -ImageName $imageName -MediaLocation $imageDisk -OS Linux -Label $imageLabel -Description $imageDescription -ImageFamily $imageFamily -PublishedDate (Get-Date) -ShowInGui
    $count++
}

Set-PSDebug -trace 0 -strict
Exit

# Create the cloud services
Write-Output "	BOBFIX >>>> " `
New-AzureService -ServiceName 'pccperfwuweb1' -Location $location
Write-Output "	BOBFIX >>>> " `
New-AzureService -ServiceName 'pccperfwuapp1' -Location $location
Write-Output "	BOBFIX >>>> " `
New-AzureService -ServiceName 'pccperfwudb1' -Location $location

# Reserve the VIPs associated with the cloud services
Write-Output "	BOBFIX >>>> " `
New-AzureReservedIP -Location $location -ReservedIPName 'pccperfwuweb1vip'
Write-Output "	BOBFIX >>>> " `
New-AzureReservedIP -Location $location -ReservedIPName 'pccperfwuapp1vip'
Write-Output "	BOBFIX >>>> " `
New-AzureReservedIP -Location $location -ReservedIPName 'pccperfwudb1vip'

Set-PSDebug -trace 0 -strict
Exit

# Create Web VM #1
$serviceName = 'pccperfwuweb1'
$vmName = 'ULWB-AZPCC01'
$imageName = 'wagslinuxweb1'
$vmSize = 'Standard_D11'
$avSetName = 'pccperfwuwebavset'
$storageAccount = 'pccperfwuweb1'
Write-Output "	BOBFIX >>>> " `
$osDisk = 'https://{0}.blob.core.windows.net/vhds/{1}-os-1.vhd' -f $storageAccount, $vmName
Write-Output "	BOBFIX >>>> " `
$dataDisk1 = 'https://{0}.blob.core.windows.net/vhds/{1}-data-1.vhd' -f $storageAccount, $vmName
$sshEndpointName = 'SSH'
$sshEndpointPort = '57101'
$subnetName = 'WEB'
$staticIPAddress = '172.17.38.4'

Set-PSDebug -trace 0 -strict
Exit

Write-Output "	BOBFIX >>>> " `
New-AzureVMConfig -Name $vmName -InstanceSize $vmSize -ImageName $imageName -AvailabilitySetName $avSetName -MediaLocation $osDisk | `
    Add-AzureProvisioningConfig -Linux -LinuxUser $userName -Password $password | `
    Set-AzureEndpoint -Name $sshEndpointName -PublicPort $sshEndpointPort | `
    Set-AzureSubnet -SubnetNames $subnetName | `
    Set-AzureStaticVNetIP -IPAddress $staticIPAddress | `
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 1' -LUN 1 -MediaLocation $dataDisk1 | `
    New-AzureVM -ServiceName $serviceName -VNetName $vnetName

# Create App VM #1
$serviceName = 'ppssuatptwuapp'
$vmName = 'ppssuatptwuapp1'
$imageName = 'wagswin2012r2app1'
$vmSize = 'Standard_DS14'
$avSetName = 'ppssuatptwuappavset'
$storageAccount = 'ppssuatptwuapp1'
Write-Output "	BOBFIX >>>> " `
$osDisk = 'https://{0}.blob.core.windows.net/vhds/{1}-os-1.vhd' -f $storageAccount, $vmName
Write-Output "	BOBFIX >>>> " `
$dataDisk1 = 'https://{0}.blob.core.windows.net/vhds/{1}-data-1.vhd' -f $storageAccount, $vmName
Write-Output "	BOBFIX >>>> " `
$dataDisk2 = 'https://{0}.blob.core.windows.net/vhds/{1}-data-2.vhd' -f $storageAccount, $vmName
$rdpEndpointName = 'RemoteDesktop'
$rdpEndpointPort = '57201'
$subnetName = 'App'
$staticIPAddress = '172.17.34.69'
$domainJoin = 'devwalgreenco.net'
$domain = 'walgreenco'
$ou = 'OU=Azure,OU=Servers,DC=devwalgreenco,DC=net'

Set-PSDebug -trace 0 -strict
Exit

Write-Output "	BOBFIX >>>> " `
New-AzureVMConfig -Name $vmName -InstanceSize $vmSize -ImageName $imageName -AvailabilitySetName $avSetName -MediaLocation $osDisk | `
	Add-AzureProvisioningConfig -WindowsDomain -JoinDomain $domainJoin -Domain $domain -AdminUsername $userName -Password $password -MachineObjectOU $ou -NoWinRMEndpoint | `	
    Set-AzureEndpoint -Name $rdpEndpointName -PublicPort $rdpEndpointPort | `
    Set-AzureSubnet -SubnetNames $subnetName | `
    Set-AzureStaticVNetIP -IPAddress $staticIPAddress | `
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 1' -LUN 1 -MediaLocation $dataDisk1 | `
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 2' -LUN 2 -MediaLocation $dataDisk2 | `
    New-AzureVM -ServiceName $serviceName -VNetName $vnetName -DnsSettings $dns

# Associate the Reserved VIPs with the cloud services
Write-Output "	BOBFIX >>>> " `
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwuweb1vip' -ServiceName 'pccperfwuweb1'
Write-Output "	BOBFIX >>>> " `
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwuapp1vip' -ServiceName 'pccperfwuapp1'
Write-Output "	BOBFIX >>>> " `
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwudb1vip' -ServiceName 'pccperfwudb1'


Set-PSDebug -trace 0 -strict
Exit
