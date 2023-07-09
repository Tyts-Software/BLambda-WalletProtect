param ($component, $configuration='Release')

####### FOR ex. WeatherForecast
####### .\build-client.ps1 -$component WeatherForecast

$cPath = "..\src\components\$component"
$apiPath = "$cPath\BLambda.Will.$component"
$clientPath = Resolve-Path "$cPath\BLambda.Will.Client.$component" | select -ExpandProperty Path

dotnet build $apiPath `
	-c $configuration `
	-p:ClientDir=$clientPath `
	-p:GenerateApiClient=true `
	-p:Component=$component `
