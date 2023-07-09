param (
	[Alias('p')]
	$profile='bobac--tyts-dev', 
	$component='blambda',
	$domain='', 
	$configuration='Release', 
	$logLevel='Information', # [Debug | Information | Warning]
	[switch]$will,		# re-build & re-package Will lambda
	[switch]$shall,		# re-publish UI
	[switch]$cleanup,	# clean up ALL binaries
	[switch]$prod		# skip all dev only things. use for real production deploymant
)

####### FOR Yap
####### .\deploy-edacha.ps1 -bot -p bobac--edacha-yap -domain yap



function Console([string]$msg) { Write-Host -BackgroundColor DarkGray -noNewLine $msg; Write-Host }

if ($prod) {
	$will = $True
	$shall = $True

	$cleanup = $True
	$logLevel='Warning'
}

# const
$srcPath =  Resolve-Path "..\src"

$deploy = "..\~deploy\$component$domain`\provision"
if (!(Test-Path $deploy -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $deploy
}

$deploy = Resolve-Path $deploy
$deployPackages = "$deploy\packages"
$deployShall = "$deploy\shall"
$willPackage = "$deployPackages\BLambda.Will.zip"
$templates = "$deploy\templates"

$shallPath =  "$srcPath\ui\BLambda.Shall"
$willPath =  "$srcPath\api\BLambda.Will"

Console "Set profile: $profile"
$env:AWS_PROFILE ="$profile"
$env:SAM_CLI_TELEMETRY =0


$confirmation = Read-Host "Really? [y]"
if ($confirmation -eq 'y') { 

#### Re-Build projects
#
if ($cleanup) {
	#clean up binaries
	Console "Cleaning up binaries..."
	Get-ChildItem $srcPath\ -include bin,obj -Recurse | ForEach-Object ($_) { Remove-Item $_.FullName -Force -Recurse  -ErrorAction SilentlyContinue | Out-Null }
	Remove-Item -LiteralPath $deploy -Force -Recurse  -ErrorAction SilentlyContinue | Out-Null
}

if ($will) {
	### rebuild Web API (dotnet publish inside) 
	dotnet lambda package `
		--project-location $willPath `
		--configuration "Release" `
		--framework "net6.0" `
		--msbuild-parameters "--self-contained false" `
		--package-type "zip" `
		--output-package $willPackage `
}

if ($shall) {
	### Build & publish UI locally
	## create folder to publish
	New-Item -Path $deployShall -ItemType Directory -Force
	## rebuild and publish UI
	dotnet publish $shallPath --output $deployShall -c $configuration 

	## publish just few files in order to test deployment
	## is NOT for production
	if ($prod -eq $False)
	{
		Get-ChildItem $deployShall -File -Recurse -Force -exclude index.html,favicon.ico | ForEach-Object ($_) { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue | Out-Null }
	}
}


### CREATE stacks
Console "Creating templates..."
Remove-Item -LiteralPath $templates -Force -Recurse  -ErrorAction SilentlyContinue | Out-Null


$cdkPath = "$srcPath\provision\.cdk"
Console "Deploying stack: $cdkPath"
Push-Location -Path $cdkPath

#cdk synth	--all --json `
#			--no-path-metadata --no-asset-metadata --no-version-reporting `
#			--outputs-file "$deploy\result.json" `
#			--output=$templates `
#			--context domain=$domain `
#			--context shall-subdomain=shall `
#			--context will-subdomain=will `
#			--context will-package=$willPackage `

Console "Deploying stack..."
cdk deploy	--all --json `
			--no-path-metadata --no-asset-metadata --no-version-reporting `
			--outputs-file "$deploy\result.json" `
			--output=$templates `
			--context log-level=$logLevel `
			--context name=$component `
			--context domain=$domain `
			--context shall-subdomain=shall `
			--context will-subdomain=will `
			--context will-package=$willPackage `

Pop-Location #-PassThru
	
if ($shall) {
	### Upload Shall to S3
	$uiBucketName=$(aws cloudformation describe-stacks `
		--stack-name "$domain`Stack" `
		--query "Stacks[0].Outputs[?OutputKey=='ShallBucketName'].OutputValue" `
		--output text `
	) `

	if ($uiBucketName -ne $null)
	{
		Console "Waiting UI bucket is created..."

		aws s3api wait bucket-exists --bucket $uiBucketName
		if((aws s3api head-bucket --bucket $uiBucketName) -eq $null) 
		{
			Push-Location -Path "$deployShall\wwwroot"
			aws s3 sync . s3://$uiBucketName
			Pop-Location
		}
	}
}

}
