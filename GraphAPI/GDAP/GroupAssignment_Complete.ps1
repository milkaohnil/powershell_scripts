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
Write-Host "GDAP-Enrollment Solution-Group for All Tenants" -ForegroundColor Cyan
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
		        accessContainerId = "94d37159-4162-49eb-8fc3-e64e9add33d3"
		        accessContainerType = "securityGroup"
	            }
            accessDetails = @{
		    unifiedRoles = @(
			    @{
				    roleDefinitionId = "29232cdf-9323-42fd-ade2-1d097af3e4de"
			    }
			    @{
				    roleDefinitionId = "45d8d3c5-c802-45c6-b32a-1d70b5e1e86e"
			    }
			    @{
				    roleDefinitionId = "892c5842-a9a6-463a-8041-72aa08ca3cf6"
			    }
			    @{
				    roleDefinitionId = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
			    }
			    @{
				    roleDefinitionId = "69091246-20e8-4a56-aa4d-066075b2a7a8"
			    }
			    @{
				    roleDefinitionId = "d37c8bed-0711-4417-ba38-b4abe66ce4c2"
			    }
			    @{
				    roleDefinitionId = "2b745bdf-0803-4d80-aa65-822c4493daac"
			    }
			    @{
				    roleDefinitionId = "11648597-926c-4cf3-9c36-bcebb0ba8dcc"
			    }
			    @{
				    roleDefinitionId = "0964bb5e-9bdb-4d7b-ac29-58e794862a40"
			    }
			    @{
				    roleDefinitionId = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
			    }
			    @{
				    roleDefinitionId = "3a2c62db-5318-420d-8d74-23affee5d9d5"
			    }
			    @{
				    roleDefinitionId = "38a96431-2bdf-4b4c-8b6e-5d3d8abac1a4"
			    }
			    @{
				    roleDefinitionId = "644ef478-e28f-4e28-b9dc-3fdde9aa0b1f"
			    }
			    @{
				    roleDefinitionId = "c4e39bd9-1100-46d3-8c65-fb160da0071f"
			    }
			    @{
				    roleDefinitionId = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
			    }
			    @{
				    roleDefinitionId = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
			    }
			    @{
				    roleDefinitionId = "4d6ac14f-3453-41d0-bef9-a3e0c569773a"
			    }
			    @{
				    roleDefinitionId = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
			    }
			    @{
				    roleDefinitionId = "e8611ab8-c189-46e8-94e1-60213ab1f814"
			    }
			    @{
				    roleDefinitionId = "fe930be7-5e62-47db-91af-98c3a49a38b1"
			    }			    
                @{
				    roleDefinitionId = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
			    }
			    @{
				    roleDefinitionId = "be2f45a1-457d-42af-a067-6ec1fa63bc45"
			    }
			    @{
				    roleDefinitionId = "95e79109-95c0-4d8e-aee3-d01accf2d47b"
			    }
			    @{
				    roleDefinitionId = "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2"
			    }
			    @{
				    roleDefinitionId = "b0f54661-2d74-4c50-afa3-1ec803f12efe"
			    }
			    @{
				    roleDefinitionId = "f023fd81-a637-4b56-95fd-791ac0226033"
			    }
			    @{
				    roleDefinitionId = "9360feb5-f418-4baa-8175-e2a00bac4301"
			    }
			    @{
				    roleDefinitionId = "8329153b-31d0-4727-b945-745eb3bc5f31"
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
				    roleDefinitionId = "0526716b-113d-4c15-b2c8-68e3c22b9f80"
			    }
			    @{
				    roleDefinitionId = "5c4f9dcd-47dc-4cf7-8c9a-9e4207cbfc91"
			    }
			    @{
				    roleDefinitionId = "c430b396-e693-46cc-96f3-db01bf8bb62a"
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
Write-Host "GDAP-Enrollment ServiceTeam-Group for All Tenants" -ForegroundColor Cyan
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
		        accessContainerId = "82504849-68c0-4e4c-bd67-aa2a786f5206"
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
			    @{
				    roleDefinitionId = "29232cdf-9323-42fd-ade2-1d097af3e4de"
			    }
			    @{
				    roleDefinitionId = "3a2c62db-5318-420d-8d74-23affee5d9d5"
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
Write-Host "GDAP-Enrollment ServiceDesk-Group for All Tenants" -ForegroundColor Cyan
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
Write-Host "GDAP-Enrollment Collab-Group for All Tenants" -ForegroundColor Cyan
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
Write-Host "GDAP-Enrollment KAM-Group for All Tenants" -ForegroundColor Cyan
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
		        accessContainerId = "fa26e0c0-e143-41a3-acfb-3311eb222b38"
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
        Write-Host "GDAP-Enrollment Backoffice-Group for All Tenants" -ForegroundColor Cyan
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
		        accessContainerId = "cdcf96d9-0c91-485b-b505-41b61a6361e5"
		        accessContainerType = "securityGroup"
	            }
            accessDetails = @{
		    unifiedRoles = @(
			    @{
				    roleDefinitionId = "b0f54661-2d74-4c50-afa3-1ec803f12efe"
			    }
			    @{
				    roleDefinitionId = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b"
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