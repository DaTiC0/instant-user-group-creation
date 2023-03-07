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
        $Name = $Name.TrimEnd()
    }
    # Check if SG already exist in this location
    $SGExist = Get-ADGroup -Filter { Name -eq $Name } -SearchBase $Path -ErrorAction SilentlyContinue
    # Need To Add Check if SG exist in another location
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
        New-ADGroup -Name $Name -Path $Path -GroupScope Global -Description $Description
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
foreach ($D in $CSV) {

    $Name = $D.Department
    $Description = $D.Department_Description
    $SubOU = $SubOUs.Item(1)
    $OU = "OU=$($D.Location),OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU -Description $Description
    # Create Department OUs in Computers OU
    $SubOU = $SubOUs.Item(2)
    $OU = "OU=$($D.Location),OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateOU
    CreateOU -Name $Name -Path $OU -Description $Description
}

# Create Security Groups By Location
foreach ($L in $Locations) {

    $Name = $L.Location
    $Description = $L.Location_Description
    $SubOU = $SubOUs.Item(0)
    $SubGroupOU = $SubGroupOUs.Item(0)
    $OU = "OU=$SubGroupOU,OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateSG
    CreateSG -Name $Name -Path $OU -Description $Description
}

# Create Security Groups By Department
foreach ($D in $CSV) {

    $Location = $D.Location
    $Department = $D.Department
    $Name = $Location + "_" + $Department
    $Description = $D.Department_Description
    $SubOU = $SubOUs.Item(0)
    $SubGroupOU = $SubGroupOUs.Item(1)
    $OU = "OU=$SubGroupOU,OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateSG
    CreateSG -Name $Name -Path $OU -Description $Description
    # Add Security Group to Location Security Group
    # limit name to 64 characters
    if ($Name.Length -gt 64) {
        $Name = $Name.Substring(0, 64)
        $Name = $Name.TrimEnd()
    }
    $LocationSG = $Location
    if ($LocationSG.Length -gt 64) {
        $LocationSG = $LocationSG.Substring(0, 64)
        $LocationSG = $LocationSG.TrimEnd()
    }
    Add-ADGroupMember -Identity $LocationSG -Members $Name
}

# Create Security Groups By Title In Department OUs
# And add Security Group to Department Security Group
foreach ($T in $CSV) {
    
    $Location = $T.Location
    $Department = $T.Department
    $Name = $T.Title
    $Name = $Location + "_" + $Department + "_" + $Name
    $Description = $T.Title_Description

    $SubOU = $SubOUs.Item(0)
    $SubGroupOU = $SubGroupOUs.Item(2)
    $OU = "OU=$SubGroupOU,OU=$SubOU,OU=$MainOU,$DomainOU"
    # Run Function CreateSG
    CreateSG -Name $Name -Path $OU -Description $Description
    # Add Security Group to Department Security Group
    # limit name to 64 characters and if there is a space in the end of the string remove it
    if ($Name.Length -gt 64) {
        $Name = $Name.Substring(0, 64)
        $Name = $Name.TrimEnd()
    }
    $DepartmentSG = $Location + "_" + $Department
    if ($DepartmentSG.Length -gt 64) {
        $DepartmentSG = $DepartmentSG.Substring(0, 64)
        $DepartmentSG = $DepartmentSG.TrimEnd()
    }
    Write-Host "Adding $Name to $LocationSG Group" -BackgroundColor Black -ForegroundColor Green
    Add-ADGroupMember -Identity $DepartmentSG -Members $Name

}

$Log = 'error.log'
# Add header to log file
Set-Content -Path $Log -Value "Error Log" -Force
# Add Users to Security Groups
foreach ($U in $CSV) {

    $Location = $U.Location
    $Department = $U.Department
    $Title = $U.Title
    $Name = $U.Employee
    $Description = $U.Title_Description
    $Mobile = $U.Mobile

    $TitleSG = $Location + "_" + $Department + "_" + $Title

    if ($TitleSG.Length -gt 64) {
        $TitleSG = $TitleSG.Substring(0, 64)
        $TitleSG = $TitleSG.TrimEnd()
    }
    Write-host "Searching for $Name"
    $User = Get-ADUser -Filter "DisplayName -eq '$Name'" -SearchBase $DomainOU -ErrorAction SilentlyContinue
    if ($User) {
        if ($Description) {
            Write-Host "Updating $Name Description" -ForegroundColor Cyan
            Set-ADUser -Identity $User -Description $Description
        }
        # $User = $User.SamAccountName
        Write-Host "Adding $Name to $TitleSG"
        Add-ADGroupMember -Identity $TitleSG -Members $User

        if ($Mobile) {
            Write-Host "Updating $Name Mobile"
            Set-ADUser -Identity $User -Mobile $Mobile
        }
        if ($Title) {
            Write-Host "Updating $Name Title"
            Set-ADUser -Identity $User -Title $Title
        }
        if ($Department) {
            Write-Host "Updating $Name Department"
            Set-ADUser -Identity $User -Department $Department
        }
        if ($Location) {
            Write-Host "Updating $Name Office"
            Set-ADUser -Identity $User -Office $Location
        }


    }
    else {
        Write-Host "User $Name not found" -ForegroundColor Red
        # Save to log file
        Add-Content -Path $Log -Value $Name
        continue
    }

}
