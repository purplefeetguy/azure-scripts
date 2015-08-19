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

# Create the NSG for the Web subnet if it does not already exist
$atlNSG = New-AzureNetworkSecurityGroup -Name $nsgName -Location $location -Label 'Network Security Group for all subnets in West US'

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
