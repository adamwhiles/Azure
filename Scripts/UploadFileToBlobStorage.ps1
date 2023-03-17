<#
.SYNOPSIS
    Upload a file to Azure Blob Storage
.DESCRIPTION
    This script is meant to upload a file to an Azure Blob Storage Container. Useful
    for uploading log files from a machine for example.

    Requirements
    -------------------

    Azure Storage Account and Storage Container
    SAS Token for Access to the Container

    Update the uri variable to include your information.

.NOTES
    FileName:    UploadFileToBlobStorage.ps1
    Author:      Adam Whiles
    Created:     2023-03-17
    Version history:
    1.0.0 - (3/17/2023) Script created.
#>

# Define the file you wish to upload
$file =""

# Set the name variable to the filename without any directories
$name = (Get-Item $file).Name

# Define the URI inlcuding the name variable to name the file
$uri = "https://yourstorage.blob.core.windows.net/yourcontainer/$($name)?your_sas_token"

# Define required headers
$headers = @{
    'x-ms-blob-type' = 'BlockBlob'
    }

# Send file to API
Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -InFile $file