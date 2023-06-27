# Created By DaTi_Co #
# In Active Directory search for disabled users and move them to specific OU

# Import Active Directory module
Import-Module ActiveDirectory

# Create or get OU
$ou = "Disabled Users"
$DomainOU = Get-ADDomain | Select-Object -ExpandProperty DistinguishedName
$OUExist = Get-ADOrganizationalUnit -Filter { Name -eq $ou } -SearchBase $DomainOU -ErrorAction SilentlyContinue

if (!$OUExist) {
    Write-Host "Creating OU $ou" -ForegroundColor Green
    New-ADOrganizationalUnit -Name $ou -Path $DomainOU
} else {
    Write-Host "OU $ou already exists" -ForegroundColor Yellow
}

# Move disabled users to "Disabled Users" OU
$DisabledUsers = Get-ADUser -Filter { Enabled -eq $false } -SearchBase $DomainOU -Properties *
foreach ($User in $DisabledUsers) {
    Write-Host "Moving $User to $ou" -ForegroundColor Green
    Move-ADObject -Identity $User -TargetPath "OU=$ou,$DomainOU"
}
