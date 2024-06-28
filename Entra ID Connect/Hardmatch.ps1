# Export Users and GUID
#Get-ADUser -Filter * | select objectGuid,userprincipalname | Export-Csv C:\temp\export.csv

# Import User-CSV and Set Immutable ID
$UserIDs = Import-Csv C:\Temp\export.csv

foreach ($user in $UserIDs)
{
    $CloudUser = Get-MsolUser -UserPrincipalName $user.userprincipalname
    $CloudUser.UserPrincipalName >> C:\temp\ImmutableIdSafe.txt
    $CloudUser.ImmutableId >> C:\temp\ImmutableIdSafe.txt
    Set-MsolUser -UserPrincipalName $user.userprincipalname -ImmutableId $user.objectGuid
}
