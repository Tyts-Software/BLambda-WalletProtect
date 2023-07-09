param (
	[Alias('p')]
	$profile
)

Write-Host "Set pro$profile"
$env:AWS_PROFILE ="$profile"
$env:SAM_CLI_TELEMETRY =0

$cdkStackName = "CDKToolkit"
$cdkBucketName=$(aws cloudformation describe-stacks `
	--stack-name $cdkStackName `
	--query "Stacks[0].Outputs[?OutputKey=='AppBucketName'].OutputValue" `
	--output text `
) `


#cdk destroy
aws s3 rm --recursive s3://$(aws s3 ls | grep cdk- | cut -d' ' -f3) # empty the cdktoolkit staging bucket
aws cloudformation delete-stack --stack-name $cdkStackName
aws s3 rb --force s3://$cdkBucketName
