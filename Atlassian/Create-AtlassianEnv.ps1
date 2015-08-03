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

$Error.Clear()

Clear-Screen

Set-StrictMode -Version Latest
# Set-StrictMode -Off

Set-PSDebug -trace 0 -strict
# Set-PSDebug -Off

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
$thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(A-AA): [$thisRc|$ecRc]"

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
$thisRc=$?
Write-ColorOutput "Magenta" "BOBFIX-RETURN(S-AS): [$thisRc|$ecRc]"

# Create the Standard storage accounts
$newStdStorageNames = @()
$newCloudServices = @()
$newStdStorageTypes = @('web1', 'app1', 'img1')

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

# Create the Standard storage accounts
$newHighPerfStorageNames = @()
$newHighPerfStorageTypes = @('db1')

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

# Set the current storage account (not required but a good practice)
$thisCommand = "Set-AzureSubscription -SubscriptionName `"$subscriptionName`" -CurrentStorageAccountName `"$($newStdStorageNames[0])`""
Execute_Command 0 "$thisCommand"

# Copy the Windows VM image VHDs to the storage accounts
$srcStorageAccount = 'ppsssitwuimg1'

# BOBFIX STARTING (DELETE TILL COMPLETE WHEN FIXED By Azure)
# Write-ColorOutput "Red" "BOBFIX: OVERRIDE Storage device[ppsssitwuimg1]"
# $srcStorageAccount = 'atlasswudb1'
# BOBFIX COMPLETE (DELETE Back to STARTING WHEN FIXED By Azure)

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

$destStorageAccounts = $newStdStorageNames
$destStorageAccounts += $newHighPerfStorageNames

Clear-Ten

$srcContainer = 'vhds'
$destContainer = 'vhds'

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

# Create the Windows VM Image objects
$imageWindowsNames = @('wagswin2012r2app1', 'wagswin2012r2app2', 'wagswin2012r2db1', 'wagswin2012r2as1')
$imageLinuxNames = @('wagslinuxweb1', 'wagslinuxapp2', 'wagslinuxdb1', 'wagslinuxdb2')
$imageFamily = 'Walgreens'
$count = 0

Clear-Ten

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

# $newCloudServices = @('pccperfwuweb1', 'pccperfwuapp1', 'pccperfwudb1')
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
ExitzureStorageAccount -StorageAccountName "atlasswuweb1"
