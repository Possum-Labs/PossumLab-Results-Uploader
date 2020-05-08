Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

npm install -g azure-functions-core-tools@3
Install-Module -Name Az -Repository PSGallery -AllowClobber
az extension add -n application-insights
func extensions install
