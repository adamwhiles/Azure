<#
.SYNOPSIS
    Add a device to an Azure AD Group
.DESCRIPTION
    This script is meant to run on the target machine and complete the following tasks.

    1. Grab the Device ID of the current machine using the dsregcmd command.
    2. Authenticate using Azure App Registration
    3. Collect the Current Group Members
    4. Get the Object ID of the device using the Device ID
    5. Check if the device is already a member of the group
    6. Add the device if it isn't already a member

    Requirements
    -------------------

    Azure App Registration
        Permissions
            Device.Read.All
            GroupMember.ReadWrite.All

    Tenant ID
    Group Object ID

.NOTES
    FileName:    AddDeviceToGroup.ps1
    Author:      Adam Whiles
    Created:     2023-03-17
    Version history:
    1.0.0 - (3/16/2023) Script created.
#>


# Define the tenant, group id from azure, graph api address and version
$Tenant = ""
$GroupID = ""
$MSGraphHost = "graph.microsoft.com"
$MsGraphVersion = "beta"

# App registration values
$ClientId = ""
$ClientSecret = ""

# Get the device Id of the current machine and set to the global DeviceId variable
$RegStatus = dsregcmd /status
if ($RegStatus -match "DeviceId") {
    $global:DeviceId = (($RegStatus -match "DeviceId").Split(":").trim())[1]
} else {
Write-Host "No device Id Found"
exit 1
}

# Set request headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

# Set up request body to include app registration details
$body = "client_id=$($ClientId)&client_secret=$($ClientSecret)&grant_type=client_credentials&scope=https%3A%2F%2Fgraph.microsoft.com%2F.default"

# Authenticate and get the auth token to be stored in the AccessToken variable
$response = Invoke-RestMethod "https://login.microsoftonline.com/$($Tenant)/oauth2/v2.0/token" -Method POST -Headers $headers -Body $body
$response | ConvertTo-Json | Out-Null
$AccessToken = $response.access_token
# Add token to request header
$headers.Add("Authorization", "Bearer $($AccessToken)")

# Get the current members of the group
$GroupMembers = Invoke-RestMethod -Method Get -uri "https://$MSGraphHost/$MsGraphVersion/groups/$GroupID/members" -Headers $headers | Select-Object -ExpandProperty Value
# Get the Object ID of the device using the Device ID
$DeviceObjId = Invoke-RestMethod -Method Get "https://graph.microsoft.com/v1.0/devices?`$filter=(deviceId eq '$($DeviceId)')&`$select=id"  -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json'}

# Check if the device is already a member of the group
if ($GroupMembers.ID -contains $DeviceObjId.value.id) {
    Write-Host -ForegroundColor Yellow "($($DeviceObjId.value.id)) is in the Group"   
} else {
    # Add device to group
    Write-Host -ForegroundColor Green "Adding ($($DeviceId)) To The Group"
    $BodyContent = @{"@odata.id"="https://graph.microsoft.com/v1.0/devices/$($DeviceObjId.value.id)"} | ConvertTo-Json

    # Make POST request to add device to the group using the Object ID
    Invoke-RestMethod -Method POST -uri "https://$MSGraphHost/v1.0/groups/$GroupID/members/`$ref" -Headers @{Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json'} -Body $BodyContent
}
