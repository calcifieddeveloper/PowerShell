# 
#  References http://vjeko.com/how-do-i-really-set-up-azure-active-directory-based-authentication-for-business-central-apis/
#             https://github.com/Microsoft/navcontainerhelper/blob/master/AzureAD/Create-AadAppsForNav.ps1
#             https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/itpro-introduction-to-automation-apis

#
#  Install the following Modules
#
if (!(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction Ignore)) {
    Write-Host "Installing NuGet Package Provider"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -WarningAction Ignore | Out-Null
}

if (!(Get-Package -Name AzureAD -ErrorAction Ignore)) {
    Write-Host "Installing AzureAD PowerShell package"
    Install-Package AzureAD -Force -WarningAction Ignore | Out-Null
}

