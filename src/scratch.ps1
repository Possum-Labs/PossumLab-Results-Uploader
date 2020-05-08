Write-Host "////// set local settings"
Push-Location -Path "PossumLab.TestResults.Uploader"
$a = Get-Content 'local.settings.json' -raw | ConvertFrom-Json
$a.Values | Add-Member -NotePropertyName "StorageAccountKey" -NotePropertyValue "bob" -Force
$a | ConvertTo-Json -depth 32| set-content 'local.settings.json'
Pop-Location