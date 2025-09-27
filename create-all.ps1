# Import Active Directory
# Enhanced with secure password handling
param(
    [switch]$PromptForPasswords = $true
)

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
    # Secure password handling
    if ($PromptForPasswords) {
        # Most secure option: prompt for each password
        Write-Host "Enter password for user: $name" -ForegroundColor Yellow
        $password = Read-Host -AsSecureString -Prompt "Password"
    } else {
        # Generate a secure random password and require password change on first login
        Write-Host "Generating secure password for $name" -ForegroundColor Yellow
        # Generate a secure random password using cryptographically secure methods
        $randomBytes = New-Object byte[] 16
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $rng.GetBytes($randomBytes)
        $randomPassword = [Convert]::ToBase64String($randomBytes) + "!"
        $password = ConvertTo-SecureString $randomPassword -AsPlainText -Force
        Write-Host "Generated password for $name : $randomPassword" -ForegroundColor Green
        Write-Host "User will be required to change password on first login" -ForegroundColor Yellow
        $rng.Dispose()
    }
    # $mail = $user.Mail
    # $enabled = $user.Enabled
    $groups = $user.Groups
    $groups = $groups.split(",")

    $changePasswordAtLogon = if (-not $PromptForPasswords) { $true } else { $false }
    New-ADUser -Name $name -GivenName $givenname -Path $ou -Description $description -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $changePasswordAtLogon # -Enabled $enabled -mail $mail
    Write-Host "User $name created"

    # Add the groups to the user
    foreach ($group in $groups) {

        Add-ADGroupMember -Identity $group -Member $name
        Write-Host "Group $group added to User $name"


    }
}

