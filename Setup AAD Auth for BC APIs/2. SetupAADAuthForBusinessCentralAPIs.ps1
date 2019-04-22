# 
#  References http://vjeko.com/how-do-i-really-set-up-azure-active-directory-based-authentication-for-business-central-apis/
#             https://github.com/Microsoft/navcontainerhelper/blob/master/AzureAD/Create-AadAppsForNav.ps1
#             https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/itpro-introduction-to-automation-apis


$bcAppDisplayName = "BC OAuth 2.0"
$bcSignOnURL      = "https://businesscentral.dynamics.com/"
$bcAuthURL        = "https://login.windows.net/{bcDirectoryId}/oauth2/authorize?resource=https://api.businesscentral.dynamics.com"
$bcAccessTokenURL = "https://login.windows.net/{bcDirectoryId}/oauth2/token?resource=https://api.businesscentral.dynamics.com"

function Create-AesKey {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    $aesManaged.GenerateKey()
    [System.Convert]::ToBase64String($aesManaged.Key)
}

$AesKey = Create-AesKey

# Login to AzureRm
$AadAdminCredential = Get-Credential
$account = Connect-AzureAD -Credential $AadAdminCredential
$bcDirectoryId = $account.Tenant.Id

#Delete The Old Ones
Get-AzureADApplication -All $true | Where-Object { $_.DisplayName.Contains($bcAppDisplayName) } | Remove-AzureADApplication

#Create New One
$ssoAdApp = New-AzureADApplication -DisplayName $bcAppDisplayName -Homepage $bcSignOnURL -ReplyUrls ($bcSignOnURL)

# Add a key to the AAD App Properties
$SsoAdAppId = $ssoAdApp.AppId.ToString()
$AdProperties = @{}
$AdProperties["AadTenant"] = $account.TenantId
$AdProperties["SsoAdAppId"] = $SsoAdAppId
$startDate = Get-Date
New-AzureADApplicationPasswordCredential -ObjectId $ssoAdApp.ObjectId `
                                         -Value $AesKey `
                                         -StartDate $startDate `
                                         -EndDate $startDate.AddYears(10) | Out-Null
#
#Set the permissions
#

# Windows Azure Active Directory -> Delegated permissions for Sign in and read user profile (User.Read)
$req1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess" 
$req1.ResourceAppId = "00000002-0000-0000-c000-000000000000"
$req1.ResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "311a71cc-e848-46a1-bdf8-97ff7156d8e6","Scope"

# Dynamics 365 Business Central -> Delegated permissions for Access as the signed-in user (Financials.ReadWrite.All)
$req2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess" 
$req2.ResourceAppId = "996def3d-b36c-4153-8607-a6fd3c01b89f"
$req2.ResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "2fb13c28-9d89-417f-9af2-ec3065bc16e6","Scope"

Set-AzureADApplication -ObjectId $ssoAdApp.ObjectId -RequiredResourceAccess @($req1, $req2)

#Write out information for the developer
Write-Host "AesKey / Client Secret" $AesKey
Write-Host "Directory Id" $bcDirectoryId
Write-Host "Application Id / Client ID" $ssoAdApp.AppId
Write-Host "Call Back Url" $bcSignOnURL
Write-Host "Auth URL" $bcAuthURL.Replace('{bcDirectoryId}', $bcDirectoryId)
Write-Host "Access Token URL" $bcAccessTokenURL.Replace('{bcDirectoryId}', $bcDirectoryId)

                                