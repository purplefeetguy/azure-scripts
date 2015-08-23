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
#$Global:SUBNET_NAMES = @('WBA-ATL-WEB','WBA-ATL-APP','WBA-ATL-DB')
$Global:SUBNET_NAMES = @()
$Global:SUBNET_NAMES += 'WBA-ATL-WEB'
$Global:SUBNET_NAMES += 'WBA-ATL-APP'
$Global:SUBNET_NAMES += 'WBA-ATL-DB'
$Global:SUBNET_NAMES += 'WBA-ATL-INF'
$Global:SUBNET_NAMES += 'WBA-ATL-RES-1'
$Global:SUBNET_NAMES += 'WBA-ATL-VIP'
$Global:SUBNET_NAMES += 'WBA-ATL-RES-2'
$Global:SUBNET_NAMES += 'WBA-ATL-MGT-WEB'
$Global:SUBNET_NAMES += 'WBA-ATL-MGT-APP'
$Global:SUBNET_NAMES += 'WBA-ATL-MGT-DB'
$Global:SUBNET_NAMES += 'WBA-ATL-MGT-INF'
$Global:SUBNET_NAMES += 'WBA-ATL-MGT-RES2'
$Global:SUBNET_NAMES += 'Gateway'
Write-ColorOutput "Red" "BOBFIX-CHANGE:  Need to handle all subnets"


################################################################################
# Azure Network Security Group Rule range for priority: 100 - 4096
#
$Global:INTERNET_PREFIX = "Internet_Inbound_Allow"
$Global:INTERNET_PORT_NAMES = @("SSH","HTTPS","ODBC","STAR")
$Global:INTERNET_PORT_NUMBERS = @{}
$Global:INTERNET_PORT_NUMBERS = @{"SSH" = "22";"HTTPS" = "443";"ODBC" = "1521";"STAR" = "*"}
$Global:PRIORITY_START = @{}
$Global:PRIORITY_START.SSH = 200
$Global:PRIORITY_START.HTTPS = 400
$Global:PRIORITY_START.ODBC = 500
$Global:PRIORITY_START.STAR = 900
Write-ColorOutput "Green" "BOBFIX-CHANGE:  Handling all known ports"
#
################################################################################


################################################################################
# Setup Source Internet Addresses for WBA locations
#
$Global:SOURCE_ADDRESSES = @()
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
Write-ColorOutput "Magenta" "BOBFIX-CHANGE:  Need to handle all SOURCE addresses"


Write-ColorOutput "Red" "BOBFIX-CHANGE:  Need to handle intra-Azure required ports"

$Global:currentNSG = $null

$Global:NSG_DETAILED = $null


################################################################################
# Setup Perform or not perform Creation of NSG
#
$Global:PERFORM_CREATE_NSG = $false
if ($Global:PERFORM_CREATE_NSG -eq $true) { $Global:performCreateNSG = 0; $thisColor = "Green" } else { $Global:performCreateNSG = 1; $thisColor = "Red" }
Write-ColorOutput "$thisColor" "BOBFIX:  Creation of Network Security Groups [GREEN:ENABLED / RED:DISABLED]"
if ($Global:PERFORM_CREATE_NSG -eq $true) { $Global:performCreateNSG = 0 } else { $Global:performCreateNSG = 1 }
# $Global:PERFORM_CREATE_NSG; $Global:performCreateNSG
#
################################################################################


################################################################################
# Setup Perform or not perform Creation of NSG Rule
#
$Global:PERFORM_CREATE_RULE = $false
if ($Global:PERFORM_CREATE_RULE -eq $true) { $Global:performCreateRule = 0; $thisColor = "Green" } else { $Global:performCreateRule = 1; $thisColor = "Red" }
Write-ColorOutput "$thisColor" "BOBFIX:  Creation of Network Security Group RULEs [GREEN:ENABLED / RED:DISABLED]"
# $Global:PERFORM_CREATE_RULE; $Global:performCreateRule
#
################################################################################


################################################################################
# Setup Perform or not perform Creation of NSG Subnet
#
$Global:PERFORM_CREATE_SUBNET = $true
if ($Global:PERFORM_CREATE_SUBNET -eq $true) { $Global:performCreateSubnet = 0; $thisColor = "Green" } else { $Global:performCreateSubnet = 1; $thisColor = "Red" }
Write-ColorOutput "$thisColor" "BOBFIX:  Creation of Network Security Group RULEs [GREEN:ENABLED / RED:DISABLED]"
# $Global:PERFORM_CREATE_SUBNET; $Global:performCreateSubnet
#
################################################################################


################################################################################
# Setup Base Get-NSG command
#
$Global:GET_NSG_BASE = "Get-AzureNetworkSecurityGroup -Name $NSG_NAME"
$Global:GET_NSG_SUBNET_BASE = "Get-AzureNetworkSecurityGroupForSubnet -VirtualNetworkName '$VNET_NAME' -SubnetName"
#
################################################################################


Set-PSDebug -trace 0 -strict


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
    # Create the NSG for the Web subnet if it does not already exist
    $createCommand = "New-AzureNetworkSecurityGroup -Name $NSG_NAME -Location $LOCATION -Label 'Network Security Group for all subnets in West US'"
    if ($PERFORM_CREATE_NSG -eq $true) {
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
#-------------------------------------------------------------------------------
# To Remove the NSG
<#
Remove-AzureNetworkSecurityGroup -Name $NSG_NAME
#>
#-------------------------------------------------------------------------------
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
    $cnrPortNumber = $INTERNET_PORT_NUMBERS.$Global:sourcePortType

    $thisCommand = "Set-AzureNetworkSecurityRule -NetworkSecurityGroup "+'$Global:currentNSG'+" -Name '$Global:thisNSGRuleName' -Type Inbound -Priority $Global:thisPriorityNumber -Action Allow -SourceAddressPrefix '$sourceAddress' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '$cnrPortNumber' -Protocol 'TCP'"
    Execute_Command $Global:performCreateRule "$thisCommand"; $thisRc = $?
    $Global:NSG_DETAILED = $Global:ecOutput
    Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ANSR]: [$thisRc|$Global:ecRc]"
    if ($PERFORM_CREATE_RULE ) {
	if ($thisRc -eq $false -or $Global:ecRc -eq $false -or $Global:NSG_DETAILED -eq $null ) {
	    Write-ColorOutput "Red" "BOBFIX-NOT_CREATED[S-ANSR] FAILED"
	    Write-ColorOutput "Red" "BOBFIX-NOT_CREATED[S-ANSR]: [$Global:ecVariableError]"
	}
	else {
	    Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[S-ANSGR-Detailed]: $Global:NSG_DETAILED'
	}
    }

}
#
################################################################################


################################################################################
# Setup_NSG_Rules
#
function Setup_NSG_Rules()
{

    foreach($Global:sourcePortType in $Global:INTERNET_PORT_NAMES) {
	if($Global:sourcePortType -ne "STAR") { Write-ColorOutput "Red" "BOBFIX-CHANGE:  Need to handle all required ports: Skipping[$Global:sourcePortType]"; continue }
	$snrRuleCount = 1
	foreach($sourceAddress in $SOURCE_ADDRESSES) {
	    $Global:thisPriorityNumber = $PRIORITY_START.$Global:sourcePortType + $snrRuleCount
	    $snrPrintRuleCount = $snrRuleCount.TOString("00")
	    $Global:thisNSGRuleName = "$Global:INTERNET_PREFIX-$Global:sourcePortType-$snrPrintRuleCount"

	    $testEntry = $Global:NSG_DETAILED.Rules | where Name -match $Global:thisNSGRuleName
	    $thisRc = $?
#	    Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ANSG]: [$thisRc|$Global:ecRc]"
	    if ($thisRc -eq $false -or $testEntry -eq $null ) {
		Create_NSG_Rule "$cnrName"
# if ($Global:PERFORM_CREATE_RULE) { Set-PSDebug -trace 0 -strict;Exit 1 }
	    }
#	    else { Write-ColorOutput-SingleQ "Yellow" 'BOBFIX-OUTPUT[NSG-Rule-Exists]:  $testEntry' }

	    $snrRuleCount++
	}
    }

}
#
################################################################################


################################################################################
# Get_NSG_Subnet_Detailed - Get Network Security Group Subnet Detailed
#
function Get_NSG_Subnet_Detailed()
{
    $detailedCommand = "$Global:baseSubnetCommand -Detailed"

    Execute_Command 0 "$detailedCommand"; $thisRc = $?
    if ($Global:ecOutput -eq $null) { $Global:ecRc = $false }
    Write-ColorOutput "Magenta" "BOBFIX-RETURN[G-ANSGS-Detailed]: [$thisRc|$Global:ecRc]"
    if ($Global:ecRc -eq $true) {
	$Global:NSG_SUBNET_DETAILED = $Global:ecOutput
	Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[G-ANSGS-Detailed]: $Global:NSG_SUBNET_DETAILED'
    }
    else {
	Write-ColorOutput "Magenta" "BOBFIX-NOT_CREATED[G-ANSGS-Detailed]: [$Global:ecVariableError]"
    }

}
#
################################################################################


################################################################################
# Create_NSG_Subnet
#
function Create_NSG_Subnet()
{
    $thisCommand = "Set-AzureNetworkSecurityGroupToSubnet -Name $Global:NSG_NAME -VirtualNetworkName '$Global:VNET_NAME' -SubnetName '$Global:subnetName'"
    Execute_Command $Global:performCreateSubnet "$thisCommand"; $thisRc = $?
    Write-ColorOutput "Magenta" "BOBFIX-RETURN[N-ANSR]: [$thisRc|$Global:ecRc]"
    if ($PERFORM_CREATE_SUBNET ) {
	if ($thisRc -eq $false -or $Global:ecRc -eq $false -or $Global:NSG_SUBNET_DETAILED -eq $null ) {
	    Write-ColorOutput "Red" "BOBFIX-NOT_CREATED[S-ANSGTS] FAILED"
	    Write-ColorOutput "Red" "BOBFIX-NOT_CREATED[S-ANSGTS]: [$Global:ecVariableError]"
	}
	else {
	    Write-ColorOutput-SingleQ "Cyan" 'BOBFIX-OUTPUT[S-ANSGTS-Detailed]: $Global:NSG_SUBNET_DETAILED'
	}
    }

#-------------------------------------------------------------------------------
# To Remove the NSG assigned to a subnet
<#
Remove-AzureNetworkSecurityGroupFromSubnet -VirtualNetworkName '$Global:VNET_NAME' -SubnetName '$Global:subnetName' -Name $Global:NSG_NAME
#>
#-------------------------------------------------------------------------------
}
#
################################################################################


################################################################################
# Setup_NSG_Subnets
#
function Setup_NSG_Subnets()
{

    foreach($Global:subnetName in $Global:SUBNET_NAMES) {
	$Global:baseSubnetCommand = "$Global:GET_NSG_SUBNET_BASE $Global:subnetName"
	Get_NSG_Subnet_Detailed
	if ($Global:ecRc -eq $false ) {
# Set-PSDebug -trace 1 -strict
	    Create_NSG_Subnet
	    if ($Global:ecRc -eq $true ) {
		Get_NSG_Subnet_Detailed
	    }
	    else {
		Write-ColorOutput "Yellow" ">> TESTING: `$Global:currentNSG = Invoke-Expression $thisCommand"
	    }
# Set-PSDebug -trace 0 -strict;Exit 1
	}
    }

# Set-PSDebug -trace 0 -strict;Exit 1
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
	Setup_NSG_Rules
    }

    if ($Global:ecRc -eq $true) {
	Setup_NSG_Subnets
    }

#
################################################################################


Set-PSDebug -trace 0 -strict
Exit 0
