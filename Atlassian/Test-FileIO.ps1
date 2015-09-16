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

. "../../PS_Funcs/PS_Funcs_Std.ps1"


Function Load-Variables() {
    Get-Content $SOURCE_FILE | Foreach-Object {
	$var = $_.Split('=')
	New-Variable -Name $var[0] -Scope Script -Value $var[1]
	$Global:Input_Array += @{ $var[0] = $var[1] }
    }
}


function Display_Info()
{
Set-PSDebug -trace 1 -strict 
    $INPUT_DATA

    $Input_Array
Set-PSDebug -trace 0 -strict 
}


######################################################################################################
# Test File-IO
#

# Set-PSDebug -trace 1 -strict 

$Global:Input_Array = @{}

$SOURCE_FILE = ".\DATA\Atlassian.configuration"

$INPUT_DATA = Get-Content $SOURCE_FILE

Load-Variables
Display_Info


Set-PSDebug -trace 0 -strict
Exit

