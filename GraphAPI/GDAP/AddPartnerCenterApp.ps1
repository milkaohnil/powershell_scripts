$DisplayName = "Partner Center Application"
$ConfigurePreconsent = $true
 
$ErrorActionPreference = "Stop"
 
# Check if the Azure AD PowerShell module has already been loaded.
if ( ! ( Get-Module AzureAD ) ) {
    # Check if the Azure AD PowerShell module is installed.
    if ( Get-Module -ListAvailable -Name AzureAD ) {
        # The Azure AD PowerShell module is not load and it is installed. This module
        # must be loaded for other operations performed by this script.
        Write-Host -ForegroundColor Green "Loading the Azure AD PowerShell module..."
        Import-Module AzureAD
    }
    else {
        Install-Module AzureAD -Scope CurrentUser
    }
}
 
try {
    Write-Host -ForegroundColor Green "When prompted please enter the appropriate credentials..."
 
    if ([string]::IsNullOrEmpty($TenantId)) {
        Connect-AzureAD | Out-Null
        $TenantName = (Get-AzureADTenantDetail).DisplayName
        $TenantId = (Get-AzureADTenantDetail).ObjectId
    }
    else {
        Connect-AzureAD -TenantId $TenantId | Out-Null
    }
}
catch [Microsoft.Azure.Common.Authentication.AadAuthenticationCanceledException] {
    # The authentication attempt was canceled by the end-user. Execution of the script should be halted.
    Write-Host -ForegroundColor Yellow "The authentication attempt was canceled. Execution of the script will be halted..."
    Exit
}
catch {
    # An unexpected error has occurred. The end-user should be notified so that the appropriate action can be taken.
    Write-Error "An unexpected error has occurred. Please review the following error message and try again." `
        "$($Error[0].Exception)"
}
 
$adAppAccess = [Microsoft.Open.AzureAD.Model.RequiredResourceAccess]@{
    ResourceAppId  = "00000002-0000-0000-c000-000000000000";
    ResourceAccess =
    [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id   = "5778995a-e1bf-45b8-affa-663a9f3f4d04";
        Type = "Role"
    },
    [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id   = "a42657d6-7f20-40e3-b6f0-cee03008a62a";
        Type = "Scope"
    },
    [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6";
        Type = "Scope"
    }
}
 
$graphAppAccess = [Microsoft.Open.AzureAD.Model.RequiredResourceAccess]@{
    ResourceAppId  = "00000003-0000-0000-c000-000000000000";
    ResourceAccess =
    [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id   = "bf394140-e372-4bf9-a898-299cfc7564e5";
        Type = "Role"
    },
    [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61";
        Type = "Role"
    }
}
 
$partnerCenterAppAccess = [Microsoft.Open.AzureAD.Model.RequiredResourceAccess]@{
    ResourceAppId  = "fa3d9a0c-3fb0-42cc-9193-47c7ecd2edbd";
    ResourceAccess =
    [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id   = "1cebfa2a-fb4d-419e-b5f9-839b4383e05a";
        Type = "Scope"
    }
}
 
$SessionInfo = Get-AzureADCurrentSessionInfo
 
Write-Host -ForegroundColor Green "Creating the Azure AD application and related resources..."
 
$app = New-AzureADApplication -AvailableToOtherTenants $true -DisplayName $DisplayName -IdentifierUris "https://$($SessionInfo.TenantDomain)/$((New-Guid).ToString())" -RequiredResourceAccess $adAppAccess, $graphAppAccess, $partnerCenterAppAccess -ReplyUrls @("urn:ietf:wg:oauth:2.0:oob","https://localhost","http://localhost")
$password = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId
$spn = New-AzureADServicePrincipal -AppId $app.AppId -DisplayName $DisplayName
 
if ($ConfigurePreconsent) {
    $adminAgentsGroup = Get-AzureADGroup -Filter "DisplayName eq 'AdminAgents'"
    Add-AzureADGroupMember -ObjectId $adminAgentsGroup.ObjectId -RefObjectId $spn.ObjectId
}
 
Write-Host "ApplicationId       = $($app.AppId)"
Write-Host "ApplicationSecret   = $($password.Value)"
 
[pscustomobject][ordered]@{
    ApplicationName = $DisplayName
    TenantName      = $tenantname
    TenantId        = $tenantid
    clientId        = $app.AppId
    clientSecret    = $password.value
} | Export-Csv C:\temp\azureadapps.csv -NoTypeInformation -Append
