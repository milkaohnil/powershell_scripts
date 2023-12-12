Import-Module Microsoft.Graph.Identity.Partner

$delegatedAdminRelationshipId = "fdc881be-c445-4fdd-bb26-ea3292b2ddab-1f172007-fcd5-40f9-9e4c-2008123e6942"

$params = @{
	accessContainer = @{
		accessContainerId = "f7b4682b-ded9-44b0-ac07-2424b3ca8cb8"
		accessContainerType = "securityGroup"
	}
	accessDetails = @{
		unifiedRoles = @(
			@{
				roleDefinitionId = "29232cdf-9323-42fd-ade2-1d097af3e4de"
			}
			@{
				roleDefinitionId = "3a2c62db-5318-420d-8d74-23affee5d9d5"
			}
			@{
				roleDefinitionId = "158c047a-c907-4556-b7ef-446551a6b5f7"
			}
			@{
				roleDefinitionId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
			}
		)
	}
}

New-MgTenantRelationshipDelegatedAdminRelationshipAccessAssignment -DelegatedAdminRelationshipId $delegatedAdminRelationshipId -BodyParameter $params
