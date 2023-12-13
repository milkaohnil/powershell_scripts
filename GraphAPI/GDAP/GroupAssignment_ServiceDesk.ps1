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
		        accessContainerId = "68253a36-8948-46a1-83eb-54d69e93ba75"
		        accessContainerType = "securityGroup"
	            }
            accessDetails = @{
		    unifiedRoles = @(
			    @{
				    roleDefinitionId = "31392ffb-586c-42d1-9346-e59415a2cc4e"
			    }
			    @{
				    roleDefinitionId = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
			    }
			    @{
				    roleDefinitionId = "baf37b3a-610e-45da-9e62-d9d1e5e8914b"
			    }
			    @{
				    roleDefinitionId = "3d762c5a-1b6c-493f-843e-55a3b42923d4"
			    }
			    @{
				    roleDefinitionId = "2b745bdf-0803-4d80-aa65-822c4493daac"
			    }
			    @{
				    roleDefinitionId = "7698a772-787b-4ac8-901f-60d6b08affd2"
			    }
			    @{
				    roleDefinitionId = "e8cef6f1-e4bd-4ea8-bc07-4b8d950f4477"
			    }
			    @{
				    roleDefinitionId = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
			    }
			    @{
				    roleDefinitionId = "4d6ac14f-3453-41d0-bef9-a3e0c569773a"
			    }
			    @{
				    roleDefinitionId = "fe930be7-5e62-47db-91af-98c3a49a38b1"
			    }
			    @{
				    roleDefinitionId = "158c047a-c907-4556-b7ef-446551a6b5f7"
			    }
			    @{
				    roleDefinitionId = "95e79109-95c0-4d8e-aee3-d01accf2d47b"
			    }
			    @{
				    roleDefinitionId = "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2"
			    }
			    @{
				    roleDefinitionId = "f023fd81-a637-4b56-95fd-791ac0226033"
			    }
			    @{
				    roleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
			    }
			    @{
				    roleDefinitionId = "5f2222b1-57c3-48ba-8ad5-d4759f1fde6f"
			    }
			    @{
				    roleDefinitionId = "0526716b-113d-4c15-b2c8-68e3c22b9f80"
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