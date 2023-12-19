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
				    roleDefinitionId = "44367163-eba1-44c3-98af-f5787879f96a"
			    }
			    @{
				    roleDefinitionId = "29232cdf-9323-42fd-ade2-1d097af3e4de"
			    }
			    @{
				    roleDefinitionId = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
			    }
			    @{
				    roleDefinitionId = "a9ea8996-122f-4c74-9520-8edcd192826c"
			    }
                @{
				    roleDefinitionId = "69091246-20e8-4a56-aa4d-066075b2a7a8"
			    }
			    @{
				    roleDefinitionId = "2b745bdf-0803-4d80-aa65-822c4493daac"
			    }
			    @{
				    roleDefinitionId = "11648597-926c-4cf3-9c36-bcebb0ba8dcc"
			    }
			    @{
				    roleDefinitionId = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
			    }
			    @{
				    roleDefinitionId = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
			    }
			    @{
				    roleDefinitionId = "fe930be7-5e62-47db-91af-98c3a49a38b1"
			    }
			    @{
				    roleDefinitionId = "9360feb5-f418-4baa-8175-e2a00bac4301"
			    }
			    @{
				    roleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
			    }
			    @{
				    roleDefinitionId = "17315797-102d-40b4-93e0-432062caca18"
			    }
			    @{
				    roleDefinitionId = "e6d1a23a-da11-4be4-9570-befc86d067a7"
			    }
			    @{
				    roleDefinitionId = "194ae4cb-b126-40b2-bd5b-6091b380977d"
			    }
			    @{
				    roleDefinitionId = "7495fdc4-34c4-4d15-a289-98788ce399fd"
			    }
			    @{
				    roleDefinitionId = "5c4f9dcd-47dc-4cf7-8c9a-9e4207cbfc91"
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