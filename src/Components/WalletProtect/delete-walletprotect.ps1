param (
	[Alias('p')][Parameter(Mandatory=$true)]
	$profile, 
	$domain=''
)

function Console([string]$msg) { Write-Host -BackgroundColor DarkGray -noNewLine $msg; Write-Host }

$component= "walletprotect"
$stackName = "$component$domain`Stack"

Console "Set profile: $profile"
$env:AWS_PROFILE ="$profile"
$env:SAM_CLI_TELEMETRY = 0

$confirmation = Read-Host "Really delete '$stackName' `? [y]"
if ($confirmation -eq 'y') {    

	Write-Host "Delete $stackName`..."
	aws --profile $profile `
			cloudformation delete-stack `
				--stack-name $stackName

}