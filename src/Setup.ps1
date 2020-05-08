param(
	[string] $subDomain = "Ci",
	[string] $topDomain = "PossumLab.com",
	[string] $infrastructureGroup = "possumlabinfrastructure"
)

Import-Module PSYaml

$global:subDomain = $subDomain

function ReadYaml($name){
	[string[]]$fileContent = Get-Content $name
	$content = ''
	foreach ($line in $fileContent) { $content = $content + "`n" + $line }
	return  ConvertFrom-YAML $content
}

function WriteYaml($yaml, $name){
	$newPath = "$($subDomain)\$name";
	ConvertTo-YAML $yaml | Out-File -filepath "$($newPath)"
	return  $newPath
}

function SaveRespone($object, $name){
	$newPath = "$($subDomain)\$name";
	ConvertTo-Json $object | Out-File -filepath "$($newPath)"
	return  $newPath
}

function SaveScript($script, $name){
	$newPath = "$($subDomain)\$name";
	$script | Out-File -filepath "$($newPath)"
	return  $newPath
}

#this is to work around azure caching issue around aks
$stamp = Get-Date -format "HHmmss"
$group = "TestResultUploader-$($subDomain)-rg"
$queue = "TRU$($subDomain)Queue".ToLower()
$storage = "TRU$($subDomain)Storage".ToLower()
$blob = "TRU$($subDomain)Blobs".ToLower()
$uploadFunction = "TRU$($subDomain)Upload".ToLower()
$appInsights = "TRU-$($subDomain)-ai"
$region = "centralus"
$plan = "TRU-$($subDomain)-plan"
$keyvault ="TRU-$($subDomain)-keyvault"
$sasWriteOnly = "TRU$($subDomain)SasWriteOnly".ToLower()
$servicePrinicpal = "http://TRU.($subDomain).$($topDomain)"
$endpointName = "TRU-$($subDomain)-endpoint"
$profileName = "TRU-$($subDomain)-profile"
$ipName = "TRU-$($subDomain)-IP"
$cdnCustomDomain = "TRU-$($subDomain)-DomainName"

$accounts = az account list --query "[?IsDefault==true].id" | ConvertFrom-Json
$subscriptionId = $accounts[0]

Write-Host "////// folder cleanup"
if(Test-Path $subDomain)
{
	Remove-Item -Force -Recurse -Path "$($subDomain)"
}
$mkdir = New-Item -ItemType directory -Path  "$($subDomain)"

Write-Host "////// group create"
$groupCreate = az group create --location "$($region)" -n "$($group)" --tags client="$($subDomain)" | ConvertFrom-Json
SaveRespone $groupCreate "group-create.json"

Write-Host "////// static ip"
$staticIpCreate = az network public-ip create `
	--resource-group "$($group)" `
	--name "$($ipName)" `
	--allocation-method static | ConvertFrom-Json
$staticIp = $staticIpCreate.publicIp.ipAddress
Write-Host "Static Ip :$($staticIp)"
SaveRespone $staticIpCreate "public-ip-create.json"

Write-Host "////// dns update"
az network dns record-set a add-record `
	-g "$($infrastructureGroup)" `
	-z "$($topDomain)" `
	-n "*.$($subDomain).tru" `
	-a $staticIp

az network dns record-set a add-record `
	-g "$($infrastructureGroup)" `
	-z "$($topDomain)" `
	-n "$($subDomain).tru" `
	-a $staticIp

Write-Host "////// storage account create"
$saCreate = az storage account create `
    -n "$($storage)" `
    --resource-group "$($group)" `
    --location "$($region)" `
    --sku Standard_ZRS `
    --encryption-services blob | ConvertFrom-Json
SaveRespone $saCreate "storage-account-create.json"

Write-Host "////// storage account 5 day expiration"
$t = az storage account management-policy create `
	--account-name "$($storage)" `
	--resource-group "$($group)" `
    --policy ".\delete-policy.json" | ConvertFrom-Json
SaveRespone $t "storage-account-management-policy-create.json"
   


Start-Sleep -Seconds 30

Write-Host "////// storage account key"
$saKeys =az storage account keys list -g "$($group)" -n "$($storage)" | ConvertFrom-Json
$saKey = $saKeys[0].Value
Write-Host "////// storage account key"

Write-Host "saKey: $($saKey)"

$containerCreate = az storage container create `
    --n "$($blob)" `
    --account-name "$($storage)" `
	--account-key "$($saKey)" | ConvertFrom-Json
SaveRespone $containerCreate "storage-container-create.json"

Write-Host "////// storage queu create"

$queueCreate = az storage queue create `
	-n "$($queue)" `
	--account-name "$($storage)" `
	--account-key "$($saKey)" | ConvertFrom-Json
SaveRespone $queueCreate "storage-queue-create.json"

Write-Host "////// monitor app-insights component create"

$appInsightsCreate = az monitor app-insights component create `
	--app "$($appInsights)" `
	--location "$($region)" `
	--kind web `
	-g "$($group)" `
	--application-type web | ConvertFrom-Json
SaveRespone $appInsightsCreate "app-insights-component-create.json"

Write-Host "////// appservice plan create"

$servicePlanCreate = az appservice plan create -g "$($group)" -n "$($plan)"| ConvertFrom-Json
SaveRespone $servicePlanCreate "appservice-plan-create.json"

Write-Host "////// functionapps create"

$fnUploadCreate = az functionapp create `
		-g "$($group)"  `
		-p "$($plan)" `
		--app-insights "$($appInsights)" `
		-n "$($uploadFunction)" `
		--functions-version 3 `
		-s "$($storage)" | ConvertFrom-Json
SaveRespone $groupCreate "functionapp-upload-create.json"

Write-Host "////// keyvault create"
$t = az keyvault create `
	--location "$($region)" `
	--name "$($keyvault)" `
	--resource-group "$($group)" | ConvertFrom-Json
SaveRespone $t "keyvault-create.json"

Write-Host "////// role assignment create"
$t = az role assignment create `
	--role "Storage Account Key Operator Service Role" `
	--assignee 'https://vault.azure.net' `
	--scope "/subscriptions/$($subscriptionId)/resourceGroups/$($group)/providers/Microsoft.Storage/storageAccounts/$($storage)" | ConvertFrom-Json
SaveRespone $t "role-assignment-create.json"

Write-Host "////// ad sp create-for-rbac"
$t = az ad sp create-for-rbac --name "$($servicePrinicpal)"
SaveRespone $t "ad-sp-create-for-rbac.json"

Write-Host "////// keyvault set-policy"
$t = az keyvault set-policy `
	--name "$($keyvault)" `
	--spn "$($servicePrinicpal)" `
	--storage-permissions get list delete set update regeneratekey getsas listsas deletesas setsas recover backup restore purge | ConvertFrom-Json
SaveRespone $t "keyvault-set-policy.json"

Write-Host "////// keyvault storage add"
$t = az keyvault storage add `
	--vault-name "$($keyvault)" `
	-n "$($storage)" `
	--active-key-name key1 `
	--auto-regenerate-key `
	--regeneration-period P90D `
	--resource-id "/subscriptions/$($subscriptionId)/resourceGroups/$($group)/providers/Microsoft.Storage/storageAccounts/$($storage)" | ConvertFrom-Json
SaveRespone $t "keyvault-storage-add.json"

Write-Host "////// storage account generate-sas Write Only"
$t = az storage account generate-sas `
	--expiry "2000-1-1" `
	--permissions w `
	--resource-types sco `
	--services bfqt `
	--https-only `
	--account-name "$($storage)" `
	--account-key 00000000 | ConvertFrom-Json
SaveRespone $t "storage-account-generate-sas.json"
$sasCreate = $t | ConvertTo-Json -depth 32

Write-Host "////// keyvault storage sas-definition create Write Only"
$t = az keyvault storage sas-definition create `
	--vault-name "$($keyvault)" `
	--account-name "$($storage)" `
	-n "$($sasWriteOnly)" `
	--validity-period P2D `
	--sas-type account `
	--template-uri $sasCreate | ConvertFrom-Json
SaveRespone $t "keyvault-storage-sas-definition-create.json"

Write-Host "////// set local settings"
Push-Location -Path "PossumLab.TestResults.Uploader"
$a = Get-Content 'local.settings.json' -raw | ConvertFrom-Json
$a | Add-Member -NotePropertyName "StorageAccountKey" -NotePropertyValue "$($saKey)" -Force
$a | Add-Member -NotePropertyName "StorageAccountName" -NotePropertyValue "$($storage)" -Force
$a | Add-Member -NotePropertyName "BlobStorage" -NotePropertyValue "$($blob)" -Force
$a | Add-Member -NotePropertyName "Queue" -NotePropertyValue "$($queue)" -Force
$a | Add-Member -NotePropertyName "Keyvault" -NotePropertyValue "$($keyvault)" -Force
$a | Add-Member -NotePropertyName "SasWriteOnly" -NotePropertyValue "$($sasWriteOnly)" -Force
$a | ConvertTo-Json -depth 32| set-content 'local.settings.json'
Pop-Location
#@Microsoft.KeyVault(SecretUri=<YOUR_SECRET_IDENTIFIER_HERE>)


Write-Host "////// functionapps publish"
Start-Sleep -Seconds 30

Push-Location -Path "PossumLab.TestResults.Uploader"
func azure functionapp publish --publish-local-settings "$($uploadFunction)"
Pop-Location

#TODO: find the right endpoint / profile names
Write-Host "////// cdn custom-domain create"
$t = az cdn custom-domain create `
	-g "$($group)" `
	--endpoint-name "$($endpointName)" `
	--profile-name "$($profileName)" `
    -n "$($cdnCustomDomain)" `
	--hostname "$($subDomain).tru.$($topDomain)" | ConvertFrom-Json
SaveRespone $t "group-create.json"

Write-Host "////// Names"
Write-Host "Subscription Id: $($subscriptionId)"
Write-Host "Resource Group: $($group)"
Write-Host "Queue: $($queue)"
Write-Host "Storage Account: $($storage)"
Write-Host "Blob Storage: $($blob)"
Write-Host "Upload Function: $($uploadFunction)"
Write-Host "App Insights: $($appInsights)"
Write-Host "Region: $($region)"
Write-Host "AppService Plan: $($plan)"
Write-Host "Sas Write Only: $($sasWriteOnly)"

#TODO:
#getting the domains set update
#update DNS
#https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/app-service/app-service-web-tutorial-custom-domain.md
