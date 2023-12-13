# Function declaration for Get-AccessToken
function Get-AccessToken {
    param (
        [Parameter(Mandatory=$true)]
        [string]$clientID,

        [Parameter(Mandatory=$true)]
        [string]$clientSecret,

        [Parameter(Mandatory=$true)]
        [string]$tenantID = “common”, # Your tenantID

        [Parameter(Mandatory=$true)]
        [string]$refreshToken, # Your refreshToken

        [string]$scope = “https://graph.microsoft.com/.default” # Default scope for Microsoft Graph
    )

    # Token endpoint
    $tokenUrl = “https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token”

    # Prepare the request body
    $body = @{
        client_id     = $clientID
        scope         = $scope
        client_secret = $clientSecret
        grant_type    = “refresh_token”
        refresh_token = $refreshToken
    }

    # Request the token
    $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -ContentType “application/x-www-form-urlencoded” -Body $body

    # Return the access token
    return $response.access_token
}

# Get AccessToken
$accessToken = Get-AccessToken

# Prompt the user for the Security Group ID
$SecurityGroup = Read-Host -Prompt “Enter the Security Group ID where your service principal is located”

# Prompt the user for the Role ID they wish to add to assignments
$RoleIDPath = Read-Host -Prompt “Enter the CSV Path incl. file.csv for the Roles you want to add to assignments”
$RoleIds = Import-Csv $RoleIDPath

# Initialize the RelationshipID variable with a blank value
$RelationshipID = “”

# Initialize the GroupAssignments variable as an empty array
$GroupAssignments = @()

# Define your Graph API endpoint for GDAP relationships
$gdapApiUrl = “https://graph.microsoft.com/v1.0/tenantRelationships/delegatedAdminRelationships?$filter=status eq ‘active'”

# Use the existing access token for authorization
$headers = @{
    Authorization = “Bearer $accessToken“
    “Content-Type” = “application/json”
}

# Function to get GDAP relationships and access assignments
Function Get-GDAPAssignments {
    param (
        [string]$apiUrl,
        [hashtable]$headers
    )

    Try {
        # Make the API call to get the GDAP assignments
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
        # Check if there are more pages of data
        while ($response.‘@odata.nextLink’) {
            # If there are more pages, update the apiUrl and perform another request
            $apiUrl = $response.‘@odata.nextLink’
            $nextPage = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $response.value += $nextPage.value
            $response.‘@odata.nextLink’ = $nextPage.‘@odata.nextLink’
        }
        # Return the list of assignments
        return $response.value
    } Catch {
        Write-Error “Error fetching GDAP assignments: $_“
    }
}

# Call the function to get GDAP assignments
$activeGDAPRelationships = Get-GDAPAssignments -apiUrl $gdapApiUrl -headers $headers

# Display the assignments (for verification)
$activeGDAPRelationships | Format-Table

# Assume $gdapRelationships is the object containing all the GDAP relationships obtained from a previous API call
foreach ($gdapRelationship in $activeGDAPRelationships) {
    # Set the RelationshipID to the current GDAP Relationship ID
    $RelationshipID = $gdapRelationship.id

    # Store the customer’s display name
    $customerDisplayName = $gdapRelationship.customer.displayName
    
    # Form the URI for the API call
    $uri = “https://graph.microsoft.com/v1.0/tenantRelationships/delegatedAdminRelationships/$RelationshipID/accessAssignments”

    # Make the API call
    $response = Invoke-RestMethod -Headers @{Authorization = “Bearer $accessToken“} -Uri $uri -Method Get

    try {
    $headers = @{
        Authorization = “Bearer $accessToken“
        ‘Content-Type’ = ‘application/json’
        }
        $updateBody = @{
            	accessContainer = @{
		        accessContainerId = "3c0d4a7b-e6c7-4620-831d-77f2986a53e2"
		        accessContainerType = "securityGroup"
	            }
            accessDetails = @{
		    unifiedRoles = @(
			    @{
				    roleDefinitionId = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b"
			    }
			    @{
				    roleDefinitionId = "5d6b6bb7-de71-4623-b4af-96380a352509"
			    }
			    @{
				    roleDefinitionId = "790c1fb9-7f7d-4f88-86a1-ef1f95c05c1b"
			    }
			    @{
				    roleDefinitionId = "75934031-6c7e-415a-99d7-48dbd49e875e"
			    }
		    )
	    }
    }  | ConvertTo-Json -Depth 5

        $uri = "https://graph.microsoft.com/v1.0/tenantRelationships/delegatedAdminRelationships/$RelationshipID/accessAssignments"

        #Execute POST request
        $response = Invoke-RestMethod -Headers $headers -Method POST -Uri $uri -Body $updateBody

        Write-Host "Success for $($gdapRelationship.displayName) $($gdapRelationship.id)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed for $($gdapRelationship.displayName) $($gdapRelationship.id)" -ForegroundColor Red
        }
        }