# Created By DaTi_Co #
# In Active Directory Create OUs and Security Groups With permmisions in this OUs and add users to this groups from csv file 
# import-module ActiveDirectory
# import-module CSV


# import CSV file
$CSV = Import-Csv -Path "source.csv"
# Domain name and Main OU Name
$Domain = "dc.domain.com"    # This must be Change
$MainOU = "MAIN"            # This must be Change
# check if domain top-level-domain or subdomain

# split domain and calculate length
$DomainSplit = $Domain.Split(".")
$DomainLength = $DomainSplit.Length
# if domain is subdomain
if ($DomainLength -gt 2) {
    # get domain name and domain extension
    $SubDomainName = $DomainSplit[0]
    $DomainName = $DomainSplit[1]
    $DomainExtension = $DomainSplit[2]
    # Define Domain OU
    $DomainOU = "DC=$SubDomainName,DC=$DomainName,DC=$DomainExtension"
}
# if domain is top-level-domain
else {
    # get domain name and domain extension
    $DomainName = $DomainSplit[0]
    $DomainExtension = $DomainSplit[1]
    # Define Domain OU
    $DomainOU = "DC=$DomainName,DC=$DomainExtension"
}

# Write domain name and domain extension and main OU name
if ($SubDomainName) {
    Write-Host "Sub Domain Name: $SubDomainName" -ForegroundColor Green
}
Write-Host "Domain Name: $DomainName" -ForegroundColor Blue
Write-Host "Domain Extension: $DomainExtension" -ForegroundColor Magenta
Write-Host "Main OU: $MainOU" -ForegroundColor Yellow

# Function To create Organizational Units with Description
Function CreateOU {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter]
        [string]$Description
    )
    # Check if OU already exist
    $OUExist = Get-ADOrganizationalUnit -Filter { Name -eq $Name } -SearchBase $Path -ErrorAction SilentlyContinue
    # if OU already exist
    if ($OUExist) {
        Write-Host "OU $Name already exist" -ForegroundColor Yellow
        # if Description exist
        if ($Description) {
            Write-Host "Updating OU $Name Description" -ForegroundColor Green
            Set-ADOrganizationalUnit -Identity "OU=$Name,$Path" -Description $Description
        }
    }
    # if OU not exist
    else {
        Write-Host "Creating OU $Name"
        New-ADOrganizationalUnit -Name $Name -Path $Path -Description $Description
    }
}

# Function To create Security Groups with Description


## Create Main OU
# Check if OU already exist
$MainOUExist = Get-ADOrganizationalUnit -Filter { Name -eq $MainOU } -SearchBase $DomainOU -ErrorAction SilentlyContinue
# if OU already exist
if ($MainOUExist) {
    Write-Host "OU $MainOU already exist" -ForegroundColor Yellow
}
# if OU not exist
else {
    Write-Host "Creating OU $MainOU"
    New-ADOrganizationalUnit -Name $MainOU -Path $DomainOU
}

## Create Location OUs
$SubOUs = "Groups", "Users", "Computers"
foreach ($SubOU in $SubOUs) {
    # Check if OU already exist
    $Name = $SubOU
    $OU = "OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU
}

## Create Location OUs
$Locations = $CSV | Sort-Object Location -Unique
$SubOU = $SubOUs.Item(0)
foreach ($Location in $Locations) {
    # Check if OU already exist
    $Name = $Location.Location   
    $OU = "OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU
}

## Create Department OUs

foreach ($Department in $CSV) {
    # Check if OU already exist
    $Name = $Department.Department
    $Description = $Department.Department_Description
    $OU = "OU=$($Department.Location),OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU -Description $Description
}

# Create Security Groups By Department
# Check if Security Group already exist and create if not exist from imported csv file In Location OUs

foreach ($Department in $CSV) {
    # Check if Security Group already exist
    $Location = $Department.Location
    $Department = $Department.Department
    $Name = $Location + "_" + $Department
    $Description = $Department.Department_Description
    $OU = "OU=$Department,OU=$Location,OU=$SubOU,OU=$MainOU,$DomainOU"
    $SecurityGroupExist = Get-ADGroup -Filter { Name -eq $Name } -SearchBase $OU -ErrorAction SilentlyContinue
    # if Security Group already exist
    if ($SecurityGroupExist) {
        Write-Host "Security Group $Name already exist in $Location" -ForegroundColor Yellow
    }
    # if Security Group not exist
    else {
        Write-Host "Creating Security Group $Name in $Location"
        New-ADGroup -Name $Name -GroupScope Global -Path $OU -Description $Description
    }
}

# Create Security Groups By Title In Department OUs
# And add Security Group to Department Security Group
foreach ($Title in $CSV) {
    
    $Location = $Title.Location
    $Department = $Title.Department
    $Name = $Title.Title
    $Name = $Location + "_" + $Department + "_" + $Name
    # $Description = $Title.Description
    $Description = $Title.Title_Description
    $OU = "OU=$Department,OU=$Location,OU=$SubOU,OU=$MainOU,$DomainOU"
    # Check if Security Group already exist
    $SecurityGroupExist = Get-ADGroup -Filter { Name -eq $Name } -SearchBase $OU -ErrorAction SilentlyContinue
    # if Security Group already exist
    if ($SecurityGroupExist) {
        Write-Host "Security Group $Name already exist in $Department" -ForegroundColor Yellow
        # Update Description
        Set-ADGroup -Identity "CN=$Name,$OU" -Description $Description
        # # Add Security Group to Department Security Group
        # Add-ADGroupMember -Identity "OU=$Department,OU=$Location,OU=$MainOU,$DomainOU" -Members "OU=$Name,OU=$Department,OU=$Location,OU=$MainOU,$DomainOU"
    }
    # if Security Group not exist
    else {
        Write-Host "Creating Security Group $Name in $Department"
        New-ADGroup -Name $Name -GroupScope Global -Path $OU -Description $Description
        # # Add Security Group to Department Security Group
        # Add-ADGroupMember -Identity "OU=$Department,OU=$Location,OU=$MainOU,$DomainOU" -Members "OU=$Name,OU=$Department,OU=$Location,OU=$MainOU,$DomainOU"
    }
}
# Add Users to Security Groups

