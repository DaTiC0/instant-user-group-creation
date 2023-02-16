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
Function CreateSG {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Description
    )
    ## it does not check if in name there is a special character
    ## needs to be added later
    # limit name to 64 characters
    if ($Name.Length -gt 64) {
        $Name = $Name.Substring(0, 64)
    }
    # Check if SG already exist
    $SGExist = Get-ADGroup -Filter { Name -eq $Name } -SearchBase $Path -ErrorAction SilentlyContinue
    # if SG already exist
    if ($SGExist) {
        Write-Host "SG $Name already exist" -ForegroundColor Yellow
        # if Description exist
        if ($Description) {
            Write-Host "Updating SG $Name Description" -ForegroundColor Green
            Set-ADGroup -Identity "CN=$Name,$Path" -Description $Description
        }
    }
    # if SG not exist
    else {
        Write-Host "Creating SG $Name"
        New-ADGroup -Name $Name -Path $Path -Description $Description -GroupScope Global
    }
}


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

## Create Static OUs
$SubOUs = "Groups", "Users", "Computers"
foreach ($SubOU in $SubOUs) {
    
    $Name = $SubOU
    $OU = "OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU
}

## Create Static Group OUs in Groups OU
$SubGroupOUs = "Locations", "Departments", "Titles", "Share Folder Groups"
foreach ($SubGroupOU in $SubGroupOUs) {
    
    $Name = $SubGroupOU
    $SubOU = $SubOUs.Item(0)
    $OU = "OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU
}

## Create Location OUs
$Locations = $CSV | Sort-Object Location -Unique

foreach ($Location in $Locations) {

    $Name = $Location.Location
    $SubOU = $SubOUs.Item(1)
    $OU = "OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU
    #### needs refactor         
    $SubOU = $SubOUs.Item(2)
    $OU = "OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU
}

## Create Department OUs
foreach ($Department in $CSV) {

    $Name = $Department.Department
    $Description = $Department.Department_Description
    $SubOU = $SubOUs.Item(1)
    $OU = "OU=$($Department.Location),OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU -Description $Description
}

# Create Security Groups By Department
foreach ($Department in $CSV) {

    $Location = $Department.Location
    $Department = $Department.Department
    $Name = $Location + "_" + $Department
    $Description = $Department.Department_Description
    $SubOU = $SubOUs.Item(0)
    $SubGroupOU = $SubGroupOUs.Item(1)
    $OU = "OU=$SubGroupOU,OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateSG
    CreateSG -Name $Name -Path $OU -Description $Description
}

# Create Security Groups By Title In Department OUs
# And add Security Group to Department Security Group
foreach ($Title in $CSV) {
    
    $Location = $Title.Location
    $Department = $Title.Department
    $Name = $Title.Title
    $Name = $Location + "_" + $Department + "_" + $Name
    $Description = $Title.Title_Description
    $SubOU = $SubOUs.Item(0)
    $SubGroupOU = $SubGroupOUs.Item(2)
    $OU = "OU=$SubGroupOU,OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateSG
    CreateSG -Name $Name -Path $OU -Description $Description
    # Add Security Group to Department Security Group

}

# Add Users to Security Groups

