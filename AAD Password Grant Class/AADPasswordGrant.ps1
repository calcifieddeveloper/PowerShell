#  References.
#  https://docs.microsoft.com/en-us/azure/active-directory/develop/v1-protocols-oauth-code
#  https://www.reddit.com/r/PowerShell/comments/9clts3/powershell_automation_with_oauth2/
#

#
# Class to get an OAuth 2.0 authentication token from BC using a Password Grant.
#
class AADPasswordGrant {
    [string]$tokens                 #Token that we need to get to Authenticate with later
    [string]$tenantId               #BC Tenant ID
    [string]$clientId               #The ApplicationId that was registed for BC in AAD.   
    [string]$username               #BC username
    [string]$password               #BC Password 
    [System.Security.SecureString]$securePasswordStr #BC Password we will convert to a secure string later
    [string]$securePasswordBStr     #BSTR version of the secure password  
    [string]$clientSecret           #Key that was generated when registring BC in AAD
    [string]$grantType      = "password"  #This must be password so we are not challenged or have to use a form.  
    [string]$callbackUrl    = "https://businesscentral.dynamics.com/"              #The same callback registered for BC in AAD
    [string]$accessTokenUrl = "https://login.windows.net/{tenantId}/oauth2/token"  #Url to request the token from
    [string]$resourceUrl    = "https://api.businesscentral.dynamics.com"           #The resource we want to talk to
    [string]$scopeUrl       = "https://api.businesscentral.dynamics.com"           #The resource we want to talk to
    

    
    AADPasswordGrant([string]$tenandId, [string]$clientId, [string]$clientSecret, [string]$userName, [string]$password) {
        $this.tenantId     = $tenandId
        $this.clientId     = $clientId
        $this.clientSecret = $clientSecret
        $this.userName     = $userName
        $this.securePasswordStr  = (ConvertTo-SecureString -String $password -AsPlainText -Force)
        $this.securePasswordBStr = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($this.securePasswordStr))
        $this.accessTokenUrl     = $this.accessTokenUrl.Replace('{tenantId}', $tenandId)
    }

    [void]TryGetAuthorisationToken () {
        $body = @{
            grant_type    = $this.grantType
            username      = $this.userName
            password      = $this.securePasswordBStr
            client_id     = $this.clientId
            client_secret = $this.clientSecret
            scope         = $this.scopeUrl
            redirect_uri  = $this.callbackUrl
            resource      = $this.resourceUrl
        }
        $authResult = Invoke-RestMethod -Method Post -Uri $this.accessTokenUrl -Body $body
        $this.token =$authResult.access_token
    }
}

#
# Test the Class Here
#


$tenantId     = 'fa75f4db-5231-6eb5-9ec4-ddb74cd648e'      #Your BC tennantID
$clientId     = 'b94639c8-553a-6a7d-ad54-d36463d3729'      #The id that BC is registered with in AAD  
$clientSecret = '5P00Zg29GGg6rnllUg0Fad9SSFC8lWVGJyOnsF0=' #The secret key that was created when registering BC for AAD Auth
$username     = 'bcuser@domain.onmicrosoft.com'            #Username for the passowrd grant
$password     = 'user.password@1234'                       #Password in plain text

[AADPasswordGrant]$aadPasswordGrant = [AADPasswordGrant]::new($tenantId, $clientId, $clientSecret, $username, $password)
$aadPasswordGrant.TryGetAuthorisationToken()

$companiesUrl = "https://api.businesscentral.dynamics.com/v1.0/api/microsoft/automation/beta/companies"
$requestHeaders = @{ 'Authorization' = 'Bearer ' + $aadAuthLogin.token }
$result = Invoke-RestMethod -Uri $usersUrl -Headers $requestHeaders -Method Get
$result.value | Out-GridView