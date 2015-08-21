<#
.SYNOPSIS
	This script creates NSG rules for the PROS UAT/PT environment.
	
.DESCRIPTION
	This script creates NSG rules for the PROS UAT/PT environment.
	
.NOTES
	Author: Ed Mondek
	Date: 7/27/2015
	Revision: 1.0

.CHANGELOG
    1.0  7/27/2015  Ed Mondek  Initial commit
#>

Set-PSDebug -trace 0 -strict

. "../../PS_Funcs/PS_Funcs_Std.ps1"
Clear-Ten
$LASTEXITCODE = $false

# Sign in to your Azure account
#Add-AzureAccount

# Initialize variables
$subscriptionName = 'Atlassian Subscription (NSEN)'
$vnetName = 'WBA Atlassian Azure'
$location = 'West US'

# Set the current subscription
Select-AzureSubscription -SubscriptionName $subscriptionName

### Configure the NSG for the Web subnet ###
$nsgName = 'ATL-NSG'
$subnetName = 'WBA-ATL-WEB'


$PRIORITY_START = 1000
$SOURCE_ADDRESSES = @("83.103.45.48/28")
$sourceAddress = $SOURCE_ADDRESSES[0]


    $thisCommand = "Get-AzureNetworkSecurityGroup -Name $nsgName"
    $testCommand = "Get-AzureNetworkSecurityGroup -Name $nsgName -Detailed"
    Execute_Command 0 "$testCommand"; $thisRc = $?
    if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
    Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ANSG-Test]: [$thisRc|$Global:ecRc]"

    if ($Global:ecRc -eq $false) {
	Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-ANSG]: [$Global:ecVariableError]"

	# Create the NSG for the Web subnet if it does not already exist
	$thisCommand = "New-AzureNetworkSecurityGroup -Name $nsgName -Location $location -Label 'Network Security Group for all subnets in West US'"
	Write-ColorOutput "Green" ">> EXECUTE: `$atlNSG = Invoke-Expression $thisCommand"
	$thisRc = $Global:ecRc
# BOBFIX	$atlNSG = Invoke-Expression $thisCommand; $thisRc = $?
	$Global:ecRc = $thisRc
	Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ANSG]: [$thisRc|$Global:ecRc]"
	Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[N-ANSG-atlNSG]: $atlNSG'

    } else {
	Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-ANSG-Test]: $Global:ecOutput'

	Write-ColorOutput "Green" ">> EXECUTE: `$atlNSG = Invoke-Expression $thisCommand"
	$thisRc = $Global:ecRc
	$atlNSG = Invoke-Expression $thisCommand; $thisRc = $?
	$Global:ecRc = $thisRc
	Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ANSG-atlNSG]: [$thisRc|$Global:ecRc]"
	Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-ANSG-atlNSG]: $atlNSG'
    }

    if ($Global:ecRc -eq $true) {
	$ruleCount = 9
	$priorityCount = $PRIORITY_START + $ruleCount

	$thisCommand = "Set-AzureNetworkSecurityRule -NetworkSecurityGroup "+'$atlNSG'+" -Name 'Internet_Inbound_Allow_$ruleCount' -Type Inbound -Priority $priorityCount -Action Allow -SourceAddressPrefix '$sourceAddress' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'"
	Execute_Command 1 "$thisCommand"; $thisRc = $?

    }



Set-PSDebug -trace 0 -strict;Exit 1

# Get info for the NSG assigned to the Web subnet
<#
$atlNSG = Get-AzureNetworkSecurityGroup -Name $nsgName
Get-AzureNetworkSecurityGroup -Name $nsgName -Detailed
Get-AzureNetworkSecurityGroup -Name $nsgName -Detailed > ATL_NSG.txt
Get-AzureNetworkSecurityGroupForSubnet -VirtualNetworkName $vnetName -SubnetName $subnetName -Detailed
#>

# Assign the NSG to all subnets
<#
$atlNSG | Set-AzureNetworkSecurityGroupToSubnet -VirtualNetworkName $vnetName -SubnetName $subnetName
#>

# Remove the NSG assigned to the Web subnet
<#
Remove-AzureNetworkSecurityGroupFromSubnet -VirtualNetworkName $vnetName -SubnetName $subnetName -Name $nsgName
Remove-AzureNetworkSecurityGroup -Name $nsgName
#>

# Define the NSG rules for all subnets
$atlNSG | Set-AzureNetworkSecurityRule -Name 'Internet_Inbound_Allow_1' -Type Inbound -Priority 100 -Action Allow -SourceAddressPrefix '83.102.45.48/28' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'
$atlNSG | Set-AzureNetworkSecurityRule -Name 'Internet_Inbound_Allow_2' -Type Inbound -Priority 101 -Action Allow -SourceAddressPrefix '204.15.116.0/22' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'
$atlNSG | Set-AzureNetworkSecurityRule -Name 'Internet_Inbound_Allow_3' -Type Inbound -Priority 102 -Action Allow -SourceAddressPrefix '63.73.199.0/24' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'

# Assign the NSG to all subnets
$atlNSG | Set-AzureNetworkSecurityGroupToSubnet -VirtualNetworkName $vnetName -SubnetName WBA-ATL-WEB
$atlNSG | Set-AzureNetworkSecurityGroupToSubnet -VirtualNetworkName $vnetName -SubnetName WBA-ATL-APP
$atlNSG | Set-AzureNetworkSecurityGroupToSubnet -VirtualNetworkName $vnetName -SubnetName WBA-ATL-DB

Exit 1
