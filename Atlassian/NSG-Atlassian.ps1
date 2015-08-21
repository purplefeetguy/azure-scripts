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


################################################################################
# Main
#
# Initialize variables
$Global:SUBSCRIPTION_NAME = 'Atlassian Subscription (NSEN)'
$Global:VNET_NAME = 'WBA Atlassian Azure'
$Global:LOCATION = 'West US'

### Configure the NSG for the Web subnet ###
$Global:NSG_NAME = 'ATL-NSG'
$Global:SUBNET_NAMES = @('WBA-ATL-WEB','WBA-ATL-APP','WBA-ATL-DB')


Write-ColorOutput "Red" "BOBFIX-CHANGE:  Need to handle all subnets"
Set-PSDebug -trace 1 -strict
$Global:subnetName = 'WBA-ATL-WEB'
Set-PSDebug -trace 0 -strict


$Global:PRIORITY_START = 1000

$Global:SOURCE_ADDRESSES = @()
Write-ColorOutput "Red" "BOBFIX-CHANGE:  Need to handle all SOURCE addresses"
$Global:SOURCE_ADDRESSES += "83.103.45.48/28"
$Global:SOURCE_ADDRESSES += "204.15.116.0/22"
$Global:SOURCE_ADDRESSES += "63.73.199.0/24"
$Global:SOURCE_ADDRESSES += "195.59.119.74"
$Global:SOURCE_ADDRESSES += "195.59.118.166"
$Global:SOURCE_ADDRESSES += "195.89.36.246"
$Global:SOURCE_ADDRESSES += "95.172.74.0/24"
$Global:SOURCE_ADDRESSES += "185.46.212.0/24"
$Global:SOURCE_ADDRESSES += "193.130.87.58"
$Global:SOURCE_ADDRESSES += "193.133.138.40"

Write-ColorOutput "Red" "BOBFIX-CHANGE:  Need to handle all required ports"

Write-ColorOutput "Red" "BOBFIX-CHANGE:  Need to handle intra-Azure required ports"

$Global:currentNSG = $null

$Global:NSG_DETAILED = $null

Write-ColorOutput "Red" "BOBFIX-CHANGE:  Need to enable Creation when doesnt exist"
$Global:PERFORM_CREATE = $false

$Global:GET_NSG_BASE = "Get-AzureNetworkSecurityGroup -Name $NSG_NAME"
#
################################################################################


################################################################################
# Get_NSG_Detailed - Get Network Security Group Detailed
#
function Get_NSG_Detailed()
{
    $detailedCommand = "$Global:GET_NSG_BASE -Detailed"

    Execute_Command 0 "$detailedCommand"; $thisRc = $?
    if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
    Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ANSG-Detailed]: [$thisRc|$Global:ecRc]"
    if ($Global:ecRc -eq $true) {
	$Global:NSG_DETAILED = $Global:ecOutput
	Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-ANSG-Detailed]: $Global:NSG_DETAILED'
    }
    else {
	Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-ANSG-Detailed]: [$Global:ecVariableError]"
    }
}
#
################################################################################


################################################################################
# Get_NSG_Base - Get Network Security Group Base
#
function Get_NSG_Base()
{
    Write-ColorOutput "Green" ">> EXECUTE: `$Global:currentNSG = Invoke-Expression $GET_NSG_BASE"
    $thisRc = $Global:ecRc
    $Global:currentNSG = Invoke-Expression $GET_NSG_BASE; $thisRc = $?
    $Global:ecRc = $thisRc
    Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ANSG]: [$thisRc|$Global:ecRc]"
    if ($Global:ecRc -eq $true ) {
	Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-ANSG-currentNSG]: $Global:currentNSG'
    }
    else {
	Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-ANSG-Base]: [$Global:ecVariableError]"
    }
}
#
################################################################################


################################################################################
# Create_NSG - Create Network Security Group
#
function Create_NSG()
{
Set-PSDebug -trace 1 -strict
    # Create the NSG for the Web subnet if it does not already exist
    $createCommand = "New-AzureNetworkSecurityGroup -Name $NSG_NAME -Location $LOCATION -Label 'Network Security Group for all subnets in West US'"
    if ($PERFORM_CREATE -eq $true) {
	Write-ColorOutput "Green" ">> EXECUTE: `$Global:currentNSG = Invoke-Expression $thisCommand"
	$thisRc = $Global:ecRc
	$Global:currentNSG = Invoke-Expression $thisCommand; $thisRc = $?
	$Global:ecRc = $thisRc
	Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ANSG]: [$thisRc|$Global:ecRc]"
	Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[N-ANSG-currentNSG]: $Global:currentNSG'
    }
    else {
	Write-ColorOutput "Red" "BOBFIX-SKIPPING:  Need to handle all subnets"
	Write-ColorOutput "Yellow" ">> TESTING: `$Global:currentNSG = Invoke-Expression $thisCommand"
    }
# Set-PSDebug -trace 0 -strict
}
#
################################################################################


################################################################################
# Setup_NSG - Setup Network Security Group
#
function Setup_NSG()
{
    Get_NSG_Detailed

    if ($Global:ecRc -eq $false ) {
	Create_NSG
	if ($Global:ecRc -eq $true ) {
	    Get_NSG_Detailed
	}
	else {
	    Write-ColorOutput "Yellow" ">> TESTING: `$Global:currentNSG = Invoke-Expression $thisCommand"
	}
    }
    else {
	Get_NSG_Base
    }

}
#
################################################################################


################################################################################
# Create_NSG_Rule
#
function Create_NSG_Rule($cnrName)
{
Set-PSDebug -trace 1 -strict

    $thisCommand = "Set-AzureNetworkSecurityRule -NetworkSecurityGroup "+'$Global:currentNSG'+" -Name '$thisName' -Type Inbound -Priority $priorityNumber -Action Allow -SourceAddressPrefix '$sourceAddress' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'"
    Execute_Command 1 "$thisCommand"; $thisRc = $?

Set-PSDebug -trace 0 -strict;Exit 1
}
#
################################################################################


################################################################################
# Setup_NSG_Rules
#
function Setup_NSG_Rules($snrName)
{
# Set-PSDebug -trace 1 -strict

    $Global:ruleCount = 1
    foreach($sourceAddress in $SOURCE_ADDRESSES) {
	$priorityNumber = $PRIORITY_START + $Global:ruleCount
	$thisName = "Internet_Inbound_Allow_$Global:ruleCount"

	$testEntry = $Global:NSG_DETAILED.Rules | where Name -match $thisName
	$thisRc = $?
#	Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ANSG]: [$thisRc|$Global:ecRc]"
	if ($thisRc -eq $false -or $testEntry -eq $null ) {
	    Create_NSG_Rule "$cnrName"
	}
#	else { Write-ColorOutput-SingleQ "Yellow" 'BOBFIX-OUTPUT[NSG-Rule-Exists]:  $testEntry' }

	$Global:ruleCount++
   }

}
#
################################################################################


################################################################################
# Main Body
#
    # Sign in to your Azure account
    #Add-AzureAccount

    # Set the current subscription
    Select-AzureSubscription -SubscriptionName $SUBSCRIPTION_NAME

    Setup_NSG

    if ($Global:ecRc -eq $true) {
	Setup_NSG_Rules $Global:currentNSG
    }
#
################################################################################


Set-PSDebug -trace 0 -strict;Exit 1

# Get info for the NSG assigned to the Web subnet
<#
$Global:currentNSG = Get-AzureNetworkSecurityGroup -Name $NSG_NAME
Get-AzureNetworkSecurityGroup -Name $NSG_NAME -Detailed
Get-AzureNetworkSecurityGroup -Name $NSG_NAME -Detailed > ATL_NSG.txt
Get-AzureNetworkSecurityGroupForSubnet -VirtualNetworkName $VNET_NAME -SubnetName $subnetName -Detailed
#>

# Assign the NSG to all subnets
<#
$Global:currentNSG | Set-AzureNetworkSecurityGroupToSubnet -VirtualNetworkName $VNET_NAME -SubnetName $subnetName
#>

# Remove the NSG assigned to the Web subnet
<#
Remove-AzureNetworkSecurityGroupFromSubnet -VirtualNetworkName $VNET_NAME -SubnetName $subnetName -Name $NSG_NAME
Remove-AzureNetworkSecurityGroup -Name $NSG_NAME
#>

# Define the NSG rules for all subnets
$Global:currentNSG | Set-AzureNetworkSecurityRule -Name 'Internet_Inbound_Allow_1' -Type Inbound -Priority 100 -Action Allow -SourceAddressPrefix '83.102.45.48/28' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'
$Global:currentNSG | Set-AzureNetworkSecurityRule -Name 'Internet_Inbound_Allow_2' -Type Inbound -Priority 101 -Action Allow -SourceAddressPrefix '204.15.116.0/22' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'
$Global:currentNSG | Set-AzureNetworkSecurityRule -Name 'Internet_Inbound_Allow_3' -Type Inbound -Priority 102 -Action Allow -SourceAddressPrefix '63.73.199.0/24' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol 'TCP'

# Assign the NSG to all subnets
$Global:currentNSG | Set-AzureNetworkSecurityGroupToSubnet -VirtualNetworkName $VNET_NAME -SubnetName WBA-ATL-WEB
$Global:currentNSG | Set-AzureNetworkSecurityGroupToSubnet -VirtualNetworkName $VNET_NAME -SubnetName WBA-ATL-APP
$Global:currentNSG | Set-AzureNetworkSecurityGroupToSubnet -VirtualNetworkName $VNET_NAME -SubnetName WBA-ATL-DB

Exit 1
