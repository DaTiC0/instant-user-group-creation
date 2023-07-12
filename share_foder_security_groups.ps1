# Description: This script creates security groups in Active Directory based on a list of folder names.

# Import the Active Directory module
Import-Module ActiveDirectory

# Define the file path containing the folder names
$folderNamesFilePath = "FolderList.csv" # Replace with the path to the folder names file

# Get the domain OU path
# $domain = (Get-ADDomain).DistinguishedName

# Define OU path where the security groups will be created
# $ou = ""  # Replace with the name of the OU where the security groups will be created
# $ouPath = "OU=$ou,$domain"

# Define Full path where the security groups will be created
# Ask for the path to the OU where the security groups will be created
$Path = Read-Host "Enter the path to the OU where the security groups will be created (e.g. OU=Groups,OU=Security,DC=domain,DC=com): "


# Import the folder names from the file
$folderNames = Import-Csv -Path $folderNamesFilePath | Select-Object -ExpandProperty Name



# Loop through the folder names and create security groups in Active Directory
foreach ($folderName in $folderNames) {
    $readGroupName = "READ_$folderName"
    $modifyGroupName = "MODIFY_$folderName"
    $fullGroupName = "FULL_$folderName"
    $Description = $folderName

    # Check if the groups already exist
    $existingGroups = Get-ADGroup -Filter { Name -like "$readGroupName" -or Name -like "$modifyGroupName" -or Name -like "$fullGroupName" }
    foreach ($existingGroup in $existingGroups) {
        Write-Host "Group $($existingGroup.Name) already exists. Skipping creation..."
        # Remove the existing group from the list of groups to create
        $readGroupName = $readGroupName -replace $existingGroup.Name, ""
        $modifyGroupName = $modifyGroupName -replace $existingGroup.Name, ""
        $fullGroupName = $fullGroupName -replace $existingGroup.Name, ""
    }

    # Create the security groups that do not already exist
    if ($readGroupName) {
        try {
            # New-ADGroup -Name $Name -Path $Path -GroupScope Global -Description $Description
            New-ADGroup -Name $readGroupName -Path $Path -GroupScope Global -Description $Description -ErrorAction Stop
            Write-Host "Group $readGroupName created successfully."
        }
        catch {
            Write-Host "Error creating group $readGroupName : $_"
            Write-host "Updating Description" -ForegroundColor Blue
            Set-ADGroup -Identity "CN=$readGroupName,$Path" -Description $Description

        }
    }

    if ($modifyGroupName) {
        try {
            New-ADGroup -Name $modifyGroupName -Path $Path -GroupScope Global -Description $Description -ErrorAction Stop
            Write-Host "Group $modifyGroupName created successfully."
        }
        catch {
            Write-Host "Error creating group $modifyGroupName : $_"
            Write-host "Updating Description" -ForegroundColor Blue
            Set-ADGroup -Identity "CN=$modifyGroupName,$Path" -Description $Description
        }
    }

    if ($fullGroupName) {
        try {
            New-ADGroup -Name $fullGroupName -Path $Path -GroupScope Global -Description $Description -ErrorAction Stop
            Write-Host "Group $fullGroupName created successfully."
        }
        catch {
            Write-Host "Error creating group $fullGroupName : $_"
            Write-host "Updating Description" -ForegroundColor Blue
            Set-ADGroup -Identity "CN=$fullGroupName,$Path" -Description $Description
        }
    }
}
