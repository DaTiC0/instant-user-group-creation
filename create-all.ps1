# Import Active Directory
Import-Module activedirectory

$ROOT = Get-ADDomain | Select-Object DistinguishedName

# Main OU
$OU = "TEST"

# Create OU
New-ADOrganizationalUnit -Name $OU -Path $ROOT.DistinguishedName

# Create path for OUs
$DC = "OU=" + $OU + "," + $ROOT.DistinguishedName

# Import the organizational units
$OUS = Import-csv ou.csv

# Create the organizational units
foreach ($ou in $OUS) {

    $name = $ou.Name
    $description = $ou.Description

    New-ADOrganizationalUnit -Name $name -path $DC -Description $description

}

# Create the Security Groups
$SGS = Import-csv sg.csv
foreach ($sg in $SGS) {

    $name = $sg.Name
    $description = $sg.Description
    $ou = $sg.OU
    $groups = $sg.Groups
    $groups = $groups.split(",")


    New-ADGroup -Name $name -path $ou -Description $description

    # Add the groups to the security group
    foreach ($group in $groups) {

        $group = $group.trim()
        $group = "CN=" + $group + "," + $ou

        Add-ADGroupMember -Group $name -Member $group

    }

}

# Create the Users
$USERS = Import-csv usr.csv

# Create the Users
foreach ($user in $USERS) {

    $name = $user.Name
    $description = $user.Description
    $ou = $user.OU
    $password = $user.Password
    $mail = $user.Mail
    $enabled = $user.Enabled
    $groups = $user.Groups
    $groups = $groups.split(",")

    New-ADUser -Name $name -path $ou -Description $description -Password $password -Enabled $enabled -mail $mail

    # Add the groups to the user
    foreach ($group in $groups) {
        $group = $group.Name

        Add-ADGroupMember -Identity $group -Member $name
    }
}

