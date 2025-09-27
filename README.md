# instant-user-group-creation

Create OU-s Group-s and Users in Active Directory instantly

## Scripts

### Create-Structure.ps1
Create OUs and Security Groups With permissions in these OUs and add users to these groups from csv file

### create-all.ps1
Enhanced with secure password handling. Creates OUs, Security Groups, and Users.

**Usage:**
- `.\create-all.ps1 -PromptForPasswords` - Prompts for each user's password (most secure)
- `.\create-all.ps1` - Generates secure random passwords and requires password change on first login

### create-users.ps1  
Enhanced with secure password handling. Creates users from CSV file.

**Usage:**
- `.\create-users.ps1 -PromptForPasswords` - Prompts for each user's password (most secure)
- `.\create-users.ps1` - Generates secure random passwords and requires password change on first login
- `.\create-users.ps1 -CSVPath "custom.csv"` - Use custom CSV file

## Security Improvements

**⚠️ IMPORTANT SECURITY CHANGES:**

1. **Password CSV columns removed**: CSV files should NOT contain Password columns for security reasons
2. **Secure password generation**: Scripts now generate cryptographically secure random passwords
3. **Password change required**: Users must change passwords on first login when using generated passwords
4. **Interactive password input**: Use `-PromptForPasswords` for maximum security

## Files

Rename EXAMPLE files:
- `source_example.csv` → `source.csv`
- `usr_example.csv` → `usr.csv` 
- `ou_example.csv` → `ou.csv`
- `sg_example.csv` → `sg.csv`

**Note**: The example CSV files have been updated to remove password columns for security.
