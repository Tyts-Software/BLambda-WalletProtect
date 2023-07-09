param ($profile='default', $appName='BLambda')

function Console([string]$msg) { Write-Host -BackgroundColor DarkGray $msg }

$appStackName = "$appName`Stack"

Console "Set profile: $profile"
$env:AWS_PROFILE ="$profile"
$env:SAM_CLI_TELEMETRY = 0

$confirmation = Read-Host "Really? [y]"
if ($confirmation -eq 'y') {  

	$appBucketName=$(aws cloudformation describe-stacks `
		--stack-name $appStackName `
		--query "Stacks[0].Outputs[?OutputKey=='AppBucketName'].OutputValue" `
		--output text `
	) `

	#echo AppBucketName=$AppBucketName
	if ($appBucketName -ne $null)
	{
		aws --profile $profile `
				s3 rb --force s3://$appBucketName `
	}



	$shallBucketName=$(aws cloudformation describe-stacks `
		--stack-name $appStackName `
		--query "Stacks[0].Outputs[?OutputKey=='ShallBucketName'].OutputValue" `
		--output text `
	) `

	if ($shallBucketName -ne $null)
	{
		aws --profile $profile `
				s3 rb --force s3://$shallBucketName `
	}



	aws --profile $profile `
			cloudformation delete-stack `
				--stack-name $appStackName `

}