# create users from csv file in AD
# Enhanced with secure password handling
# Defien CSV file path
param(
    [string]$CSVPath = "source.csv",
    [switch]$PromptForPasswords = $false
)

# Import CSV file
$CSV = Import-Csv -Path $CSVPath

# Import Active Directory module

# Define domain name
$domain = "dc.Domain.com" # Change to your domain

# Define OU path where users will be created
$DomainOU = "OU=TEST,DC=dc,DC=Domain,DC=com" # Change to your domain and OU
# create users
foreach ($U in $CSV) {

    $Location = $U.Location
    $Department = $U.Department
    $Title = $U.Title
    $Name = $U.Employee
    $FirstName = $Name.Split(" ")[0]
    $LastName = $Name.Split(" ")[1]

    $username = $U.Username
    # if $U.Username is not empty then use it as username
    if ($U.Username) {
        $username = $U.Username
    }
    else {
        # if you want to use first letter of first name and dot and last name then uncomment line below
        $username = $FirstName.Substring(0, 1) + "." + $LastName
        # $username = $FirstName.Substring(0, 1) + $LastName
        $username = $Company + "-" + $username        
    }

    # convert to lowercase
    $username = $username.ToLower()
    
    # Secure password handling
    if ($PromptForPasswords) {
        # Most secure option: prompt for each password
        Write-Host "Enter password for user: $username" -ForegroundColor Yellow
        $Password = Read-Host -AsSecureString -Prompt "Password"
    } else {
        # Generate a secure random password and require password change on first login
        Write-Host "Generating secure password for $username" -ForegroundColor Yellow
        # Generate a secure random password using cryptographically secure methods
        $randomBytes = New-Object byte[] 16
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $rng.GetBytes($randomBytes)
        $randomPassword = [Convert]::ToBase64String($randomBytes) + "!"
        $Password = ConvertTo-SecureString $randomPassword -AsPlainText -Force
        Write-Host "Generated password for $username : $randomPassword" -ForegroundColor Green
        Write-Host "User will be required to change password on first login" -ForegroundColor Yellow
        $rng.Dispose()
    }
    
    # Note: CSV files should not contain Password columns for security reasons
    $UserPrincipal = $username + "@" + $domain
    $Email = $U.Email
    $Description = $U.Title_Description
    $Mobile = $U.Mobile
    $Company = # Change to your company name


    Write-host "Checking $Name"
    Write-host "Username: $username"
    Write-Host $DomainOU
    # Checking if user exists and if not then create
    if (Get-ADUser -Filter {SamAccountName -eq $username}) {
        Write-Host "User $username already exists in AD" -ForegroundColor Green
        # Set-ADUser -Identity $username -EmailAddress $Email -Description $Description -Office $Location -Department $Department -Title $Title -Mobile $Mobile -Company $Company
        Set-ADUser -Identity $username -UserPrincipalName $UserPrincipal
    } else {
        Write-Host "Creating user $username"
         # Use secure default password instead of hardcoded plaintext
        # $secureDefaultPassword = ConvertTo-SecureString -AsPlainText "Password1234!" -Force
        # New-ADUser -Name $Name -SamAccountName $username -Path $DomainOU -AccountPassword $secureDefaultPassword -Enabled $true -ChangePasswordAtLogon $true -PasswordNeverExpires $false -EmailAddress $Email -DisplayName $Name -Description $Description -Office $Location -Department $Department -Title $Title -Mobile $Mobile -GivenName $FirstName -Surname $LastName
        New-ADUser -Name $Name -SamAccountName $username -UserPrincipalName $UserPrincipal -Path $DomainOU -AccountPassword $Password -Enabled $true -ChangePasswordAtLogon $true -PasswordNeverExpires $false -EmailAddress $Email -DisplayName $Name -Description $Description -Office $Location -Department $Department -Title $Title -Mobile $Mobile -GivenName $FirstName -Surname $LastName -Company $Company
    }
    
    # export created usernames to csv file
    $username | Out-File -FilePath "usernames.csv" -Append       

}