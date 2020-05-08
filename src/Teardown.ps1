param(
	[string] $subDomain = "Ci",
	[string] $topDomain = "PossumLab.com",
	[string] $infrastructureGroup = "possumlabinfrastructure"
)

$group = "TestResultUploader-$($subDomain)-rg"
$keyvault ="TRU-$($subDomain)-keyvault"
$region = "centralus"

$staticIpCreate = Get-Content -Raw -Path "$($subDomain)\public-ip-create.json" | ConvertFrom-Json
$staticIp = $staticIpCreate.publicIp.ipAddress
Write-Host "Static Ip :$($staticIp)"

az group delete --name "$($group)" --yes
az network dns record-set a remove-record `
	-g "$($infrastructureGroup)" `
	-z $topDomain `
	-n "$($subDomain).tru" `
	--ipv4-address "$($staticIp)"
az network dns record-set a remove-record `
	-g "$($infrastructureGroup)" `
	-z $topDomain `
	-n "*.$($subDomain).tru" `
	--ipv4-address "$($staticIp)"

az keyvault list-deleted
az keyvault purge -n $keyvault
az keyvault list-deleted

