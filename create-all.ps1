# Import Active Directory
Import-Module activedirectory

$ROOT = Get-ADDomain | Select-Object DistinguishedName

# Main OU
$OU = Read-Host "Enter Main OU"

# Create OU
New-ADOrganizationalUnit -Name $OU -Path $ROOT.DistinguishedName
Write-Host "OU $OU created"
# Create path for OUs
$DC = "OU=" + $OU + "," + $ROOT.DistinguishedName

# Import the organizational units
$OUS = Import-csv ou.csv

# Create the organizational units
foreach ($ou in $OUS) {

    $name = $ou.Name
    $description = $ou.Description

    New-ADOrganizationalUnit -Name $name -path $DC -Description $description
    Write-Host "OU $name created"

}

# Create the Security Groups
$SGS = Import-csv sg.csv
foreach ($sg in $SGS) {

    $name = $sg.Name
    $description = $sg.Description
    $ou = $sg.OU
    $ou = "OU=" + $ou + "," + $DC
    $groups = $sg.Groups
    $groups = $groups.split(",")


    New-ADGroup -Name $name -path $ou -Description $description -GroupScope Global
    Write-Host "SG $name created"

    # Add the groups to the security group
    foreach ($group in $groups) {

        Add-ADGroupMember -Identity $group -Member $name
        Write-Host "Group $group added to SG $name"

    }

}

# Create the Users
$USERS = Import-csv usr.csv

# Create the Users
foreach ($user in $USERS) {

    $name = $user.Name
    $givenname = $user.GivenName
    $description = $user.Description
    $ou = $user.OU
    $ou = "OU=" + $ou + "," + $DC
    $password = convertto-securestring $user.Password -asplaintext -force
    # $mail = $user.Mail
    # $enabled = $user.Enabled
    $groups = $user.Groups
    $groups = $groups.split(",")

    New-ADUser -Name $name -GivenName $givenname $-path $ou -Description $description -Enabled $true -Accountpassword $password # -Enabled $enabled -mail $mail
    Write-Host "User $name created"

    # Add the groups to the user
    foreach ($group in $groups) {

        Add-ADGroupMember -Identity $group -Member $name
        Write-Host "Group $group added to User $name"


    }
}

