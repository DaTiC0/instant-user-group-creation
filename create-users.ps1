# create users from csv file in AD
# Defien CSV file path
$CSVPath = "source.csv"
# Import CSV file
$CSV = Import-Csv -Path $CSVPath

# Import Active Directory module

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

    $username = $Name.Split(" ")[0].Substring(0, 1) + "." + $Name.Split(" ")[1]
    # convert to lowercase
    $username = $username.ToLower()
    $Email = $U.Email
    $Description = $U.Title_Description
    $Mobile = $U.Mobile
    $Company = # Change to your company name


    Write-host "Creating $Name"
    Write-host "Username: $username"
    Write-Host $DomainOU
    # Checking if user exists and if not then create
    if (Get-ADUser -Filter {SamAccountName -eq $username}) {
        Write-Host "User $username already exists in AD"
    } else {
        Write-Host "Creating user $username"
         # Password is Password1234! you can change it
        New-ADUser -Name $Name -SamAccountName $username -Path $DomainOU -AccountPassword (ConvertTo-SecureString -AsPlainText "Password1234!" -Force) -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true -EmailAddress $Email -DisplayName $Name -Description $Description -Office $Location -Department $Department -Title $Title -Mobile $Mobile -GivenName $Name.Split(" ")[0] -Surname $Name.Split(" ")[1]

    }
    
           

}