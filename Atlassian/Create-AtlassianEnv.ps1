<#
.SYNOPSIS
	This script provisions the Atlassian environment.
	
.DESCRIPTION
	This script creates storage accounts, copies the VM image to each storage account and then provisions the VMs.

.PREREQUISITES
    This script copies the Walgreens Windows and Linux "golden" images from the 'ppsssitwuimg1' storage account.  The user
    running this script needs access to that account.
	
.NOTES
	Author: Ed Mondek
	Date: 7/28/2015
	Revision: 1.0

.CHANGELOG
    1.0  7/27/2015  Ed Mondek  Initial commit
#>

# Sign in to your Azure account
Add-AzureAccount

# Initialize variables
$subscriptionName = 'Atlassian'
$vnetName = 'Atlassian-VNet'
$location = 'West US'
$userName = 'wagsadmin'
$password = 'Welcome!234'

# Set the current subscription
Select-AzureSubscription -SubscriptionName $subscriptionName

# Create the storage accounts
New-AzureStorageAccount -StorageAccountName 'pccperfwuweb1' -Location $location -Type Standard_LRS
New-AzureStorageAccount -StorageAccountName 'pccperfwuapp1' -Location $location -Type Standard_LRS
New-AzureStorageAccount -StorageAccountName 'pccperfwudb1' -Location $location -Type Standard_LRS
New-AzureStorageAccount -StorageAccountName 'pccperfwudb2' -Location $location -Type Standard_LRS
New-AzureStorageAccount -StorageAccountName 'pccperfwuimg1' -Location $location -Type Standard_LRS

# Set the current storage account (not required but a good practice)
Set-AzureSubscription -SubscriptionName $subscriptionName -CurrentStorageAccountName 'pccperfwuweb1'

# Copy the Windows VM image VHDs to the storage accounts
$srcStorageAccount = 'ppsssitwuimg1'
$srcStorageKey = (Get-AzureStorageKey -StorageAccountName $srcStorageAccount).Primary
$srcContext = New-AzureStorageContext –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey
$srcContainer = 'vhds'
$srcBlob = '2012R2Image.vhd'

$destStorageAccounts = @('ppssuatptwuapp1', 'ppssuatptwuapp2', 'ppssuatptwudb1', 'ppssuatptwuas1')
$destContainer = 'vhds'
$destBlob = '2012R2Image.vhd'

foreach ($destStorageAccount in $destStorageAccounts)
{

    $destStorageKey = (Get-AzureStorageKey -StorageAccountName $destStorageAccount).Primary
    $destContext = New-AzureStorageContext –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey

    New-AzureStorageContainer -Name vhds -Context $destContext

    Write-Host Copying Windows VHD to $destStorageAccount

    $blob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
        -DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
        -Force

    $blob | Get-AzureStorageBlobCopyState -WaitForComplete
}

# Create the Windows VM Image objects
$imageNames = @('wagswin2012r2app1', 'wagswin2012r2app2', 'wagswin2012r2db1', 'wagswin2012r2as1')
$imageFamily = 'Walgreens'
$count = 0

foreach ($destStorageAccount in $destStorageAccounts)
{
    $imageDisk = 'https://{0}.blob.core.windows.net/vhds/2012R2Image.vhd' -f $destStorageAccount
    $imageName = $imageNames[$count]
    $imageLabel = $imageNames[$count]
    $imageDescription = 'Walgreens Windows Server 2012 R2 in storage account {0}' -f $destStorageAccount
    Add-AzureVMImage -ImageName $imageName -MediaLocation $imageDisk -OS Windows -Label $imageLabel -Description $imageDescription -ImageFamily $imageFamily -PublishedDate (Get-Date) -ShowInGui
    $count++
}

# Copy the Linux VM image VHDs to the storage accounts
$srcStorageAccount = 'ppsssitwuimg1'
$srcStorageKey = (Get-AzureStorageKey -StorageAccountName $srcStorageAccount).Primary
$srcContext = New-AzureStorageContext –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey
$srcContainer = 'vhds'
$srcBlob = 'LinuxImage.vhd'

$destStorageAccounts = @('pccperfwuweb1', 'pccperfwuapp1', 'pccperfwudb1', 'pccperfwudb2')
$destContainer = 'vhds'
$destBlob = 'LinuxImage.vhd'

foreach ($destStorageAccount in $destStorageAccounts)
{
    $destStorageKey = (Get-AzureStorageKey -StorageAccountName $destStorageAccount).Primary
    $destContext = New-AzureStorageContext –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey

    New-AzureStorageContainer -Name vhds -Context $destContext

    Write-Host Copying Linux VHD to $destStorageAccount

    $blob = Start-AzureStorageBlobCopy -Context $srcContext -SrcContainer $srcContainer -SrcBlob $srcBlob `
        -DestContext $destContext -DestContainer $destContainer -DestBlob $destBlob `
        -Force

    $blob | Get-AzureStorageBlobCopyState -WaitForComplete
}

# Create the Linux VM Image objects
$imageNames = @('wagslinuxweb1', 'wagslinuxapp2', 'wagslinuxdb1', 'wagslinuxdb2')
$imageFamily = 'Walgreens'
$count = 0

foreach ($destStorageAccount in $destStorageAccounts)
{
    $imageDisk = 'https://{0}.blob.core.windows.net/vhds/LinuxImage.vhd' -f $destStorageAccount
    $imageName = $imageNames[$count]
    $imageLabel = $imageNames[$count]
    $imageDescription = 'Walgreens Linux in storage account {0}' -f $destStorageAccount
    Add-AzureVMImage -ImageName $imageName -MediaLocation $imageDisk -OS Linux -Label $imageLabel -Description $imageDescription -ImageFamily $imageFamily -PublishedDate (Get-Date) -ShowInGui
    $count++
}

# Create the cloud services
New-AzureService -ServiceName 'pccperfwuweb1' -Location $location
New-AzureService -ServiceName 'pccperfwuapp1' -Location $location
New-AzureService -ServiceName 'pccperfwudb1' -Location $location

# Reserve the VIPs associated with the cloud services
New-AzureReservedIP -Location $location -ReservedIPName 'pccperfwuweb1vip'
New-AzureReservedIP -Location $location -ReservedIPName 'pccperfwuapp1vip'
New-AzureReservedIP -Location $location -ReservedIPName 'pccperfwudb1vip'

# Create Web VM #1
$serviceName = 'pccperfwuweb1'
$vmName = 'ULWB-AZPCC01'
$imageName = 'wagslinuxweb1'
$vmSize = 'Standard_D11'
$avSetName = 'pccperfwuwebavset'
$storageAccount = 'pccperfwuweb1'
$osDisk = 'https://{0}.blob.core.windows.net/vhds/{1}-os-1.vhd' -f $storageAccount, $vmName
$dataDisk1 = 'https://{0}.blob.core.windows.net/vhds/{1}-data-1.vhd' -f $storageAccount, $vmName
$sshEndpointName = 'SSH'
$sshEndpointPort = '57101'
$subnetName = 'WEB'
$staticIPAddress = '172.17.38.4'

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
$osDisk = 'https://{0}.blob.core.windows.net/vhds/{1}-os-1.vhd' -f $storageAccount, $vmName
$dataDisk1 = 'https://{0}.blob.core.windows.net/vhds/{1}-data-1.vhd' -f $storageAccount, $vmName
$dataDisk2 = 'https://{0}.blob.core.windows.net/vhds/{1}-data-2.vhd' -f $storageAccount, $vmName
$rdpEndpointName = 'RemoteDesktop'
$rdpEndpointPort = '57201'
$subnetName = 'App'
$staticIPAddress = '172.17.34.69'
$domainJoin = 'devwalgreenco.net'
$domain = 'walgreenco'
$ou = 'OU=Azure,OU=Servers,DC=devwalgreenco,DC=net'

New-AzureVMConfig -Name $vmName -InstanceSize $vmSize -ImageName $imageName -AvailabilitySetName $avSetName -MediaLocation $osDisk | `
	Add-AzureProvisioningConfig -WindowsDomain -JoinDomain $domainJoin -Domain $domain -AdminUsername $userName -Password $password -MachineObjectOU $ou -NoWinRMEndpoint | `	
    Set-AzureEndpoint -Name $rdpEndpointName -PublicPort $rdpEndpointPort | `
    Set-AzureSubnet -SubnetNames $subnetName | `
    Set-AzureStaticVNetIP -IPAddress $staticIPAddress | `
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 1' -LUN 1 -MediaLocation $dataDisk1 | `
    Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'Data 2' -LUN 2 -MediaLocation $dataDisk2 | `
    New-AzureVM -ServiceName $serviceName -VNetName $vnetName -DnsSettings $dns

# Associate the Reserved VIPs with the cloud services
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwuweb1vip' -ServiceName 'pccperfwuweb1'
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwuapp1vip' -ServiceName 'pccperfwuapp1'
Set-AzureReservedIPAssociation -ReservedIPName 'pccperfwudb1vip' -ServiceName 'pccperfwudb1'
