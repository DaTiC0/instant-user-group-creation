# Description: This script will set NTFS permissions on a folder for each group
#

# Import the Active Directory module
Import-Module ActiveDirectory

# Define Domain
$DOMAIN = "ad"

# Define the ROOT folder path
$ROOT = "C:\Users\Public\Documents\" # Replace with the actual folder path


# Define the file path containing the folder names
$folderNamesFilePath = "FolderList.csv" # Replace with the path to the folder names file

# Import the folder names from the file
$folderNames = Import-Csv -Path $folderNamesFilePath | Select-Object -ExpandProperty Name


# Loop through the folder names and Define security groups
foreach ($folderName in $folderNames) {
    $readGroupName = "READ_$folderName"
    $modifyGroupName = "MODIFY_$folderName"
    $fullGroupName = "FULL_$folderName"


    # Check if the groups already exist
    $existingGroups = Get-ADGroup -Filter { Name -like "$readGroupName" -or Name -like "$modifyGroupName" -or Name -like "$fullGroupName" }
    foreach ($existingGroup in $existingGroups) {
        Write-Host "Group $($existingGroup.Name) already exists. Skipping creation..."
        # Remove the existing group from the list of groups to create
        $readGroupName = $readGroupName -replace $existingGroup.Name, ""
        $modifyGroupName = $modifyGroupName -replace $existingGroup.Name, ""
        $fullGroupName = $fullGroupName -replace $existingGroup.Name, ""
    }

    # Set NTFS permissions on the folder for each security group
    $folderPath = "$ROOT\$folderName"
    $acl = Get-Acl -Path $folderPath

    # Add READ group with Read&Execute, List folder contents, and Read permissions
    $readGroup = "$DOMAIN\$readGroupName"
    $readPermissions = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute, `
        [System.Security.AccessControl.FileSystemRights]::ListDirectory, `
        [System.Security.AccessControl.FileSystemRights]::Read
    $readAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($readGroup, $readPermissions, "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($readAccessRule)

    # Add MODIFY group with Modify permission
    $modifyGroup = "$DOMAIN\$modifyGroupName"
    $modifyPermissions = [System.Security.AccessControl.FileSystemRights]::Modify
    $modifyAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($modifyGroup, $modifyPermissions, "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($modifyAccessRule)

    # Add FULL group with Full Control permission
    $fullGroup = "$DOMAIN\$fullGroupName"
    $fullPermissions = [System.Security.AccessControl.FileSystemRights]::FullControl
    $fullAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($fullGroup, $fullPermissions, "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($fullAccessRule)

    # Set the modified ACL on the folder
    Set-Acl -Path $folderPath -AclObject $acl

}
