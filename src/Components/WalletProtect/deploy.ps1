param (
	[Alias('p')][Parameter(Mandatory=$true)]
	$profile, 
	$domain='',
	$configuration='Release', 
	$logLevel='Information', # [Debug | Information | Warning]
	[String[]]
	$emails, #coma-separated
	$budget = 1, # USD
	$threshold = 100.01, # GREATER_THAN % of budget
	[switch]$build,		# re-build & re-package function
	[switch]$cleanup,	# clean up ALL binaries
	[switch]$prod		# skip all dev only things. use for real production deploymant
)

function Console([string]$msg) { Write-Host -BackgroundColor DarkGray -noNewLine $msg; Write-Host }

if ($prod) {
	$build = $True

	$cleanup = $True
	$logLevel='Warning'
}

$component='walletprotect'

$rootPath = Resolve-Path "..\..\..\"
$srcPath =  "$rootPath\src"
$componentPath = "$srcPath\components\$component"

$deploy = "$rootPath\~deploy\$component$domain`\provision"
if (!(Test-Path $deploy -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $deploy
}
#$deploy = Resolve-Path $deploy
$deployPackages = "$deploy\packages"
$package = "$deployPackages\BLambda.ProtectWallet.zip"
$templates = "$deploy\templates"

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
	Get-ChildItem $componentPath -include bin,obj -Recurse | ForEach-Object ($_) { Write-Host $_.FullName; Remove-Item $_.FullName -Force -Recurse  -ErrorAction SilentlyContinue | Out-Null }
	Remove-Item -LiteralPath $deployPackages -Force -Recurse  -ErrorAction SilentlyContinue | Out-Null
}

if ($build) {
	$functionPath = "$componentPath`\BLambda.Functions.LockLambdas"
	Console "Rebuild Lambda (dotnet publish inside): $functionPath" 
	dotnet lambda package `
		--project-location $functionPath `
		--configuration "Release" `
		--framework "net7.0" `
		--function-architecture "x86_64" `
		--msbuild-parameters "--self-contained true" `
		--package-type "zip" `
		--output-package $package
}

### CREATE stacks
Console "Creating templates..."
Remove-Item -LiteralPath $templates -Force -Recurse  -ErrorAction SilentlyContinue | Out-Null


$cdkPath = "$componentPath\.cdk"
Console "Deploying stack: $cdkPath"
Push-Location -Path $cdkPath

#cdk synth	--all --json `
#			--no-path-metadata --no-asset-metadata --no-version-reporting `
#			--outputs-file "$deploy\result.json" `
#			--output=$templates `
#			--context name=$component `
#			--context log-level=$logLevel `
#			--context bot-package=$botPackage `
#			--context will-package=$willPackage

cdk deploy	--all --json `
			--no-path-metadata --no-asset-metadata --no-version-reporting `
			--outputs-file "$deploy\result.json" `
			--output=$templates `
			--context name=$component `
			--context domain=$domain `
			--context log-level=$logLevel `
			--context package=$package `
			--context emails=$emails `
			--context budget=$budget `
			--context threshold=$threshold `

Pop-Location #-PassThru

}
