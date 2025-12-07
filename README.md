# Get-EntraGroupMembers PowerShell Script

A comprehensive PowerShell script for retrieving and exporting user membership information from Microsoft Entra (Azure AD) groups.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Parameters](#parameters)
- [Examples](#examples)
- [Output](#output)
- [Error Handling](#error-handling)
- [Permissions](#permissions)
- [Troubleshooting](#troubleshooting)

## Overview

`Get-EntraGroupMembers.ps1` is a PowerShell script that connects to Microsoft Graph API to retrieve detailed information about users who are members of a specific Entra (Azure AD) group. The script can either display results in the console or export them to a CSV file for further analysis.

## Features

- **Flexible Group Selection**: Find groups by display name or object ID
- **Detailed User Information**: Retrieves display name, UPN, email, job title, department, and user ID
- **CSV Export**: Optional export functionality with customizable file paths
- **Auto-Generated Filenames**: Creates timestamped CSV files with sanitized group names
- **Member Type Filtering**: Automatically filters for user members only (excludes service principals, devices, etc.)
- **Error Handling**: Comprehensive error handling with informative messages
- **Connection Management**: Automatic connection and disconnection from Microsoft Graph
- **Multiple Group Handling**: Warns when multiple groups match the same name

## Prerequisites

### Required Software
- **PowerShell**: Version 5.1 or higher (PowerShell 7+ recommended)
- **Microsoft.Graph PowerShell SDK**: Modules for Groups and Users

### Required Permissions
The script requires the following Microsoft Graph API permissions:
- `Group.Read.All` - To read group information and membership
- `User.Read.All` - To read user profile information

### Azure/Entra Requirements
- An active Microsoft Entra (Azure AD) tenant
- User account with appropriate permissions to read groups and users
- MFA-capable authentication if required by your organization

## Installation

### Step 1: Install Microsoft Graph PowerShell Modules

```powershell
# Install the required Microsoft Graph modules
Install-Module Microsoft.Graph.Groups -Scope CurrentUser
Install-Module Microsoft.Graph.Users -Scope CurrentUser
```

### Step 2: Download the Script

Download or clone the script to your local machine:

```powershell
# Clone the repository (if applicable)
git clone <repository-url>

# Or download the script directly to a folder
# Ensure the file is saved as Get-EntraGroupMembers.ps1
```

### Step 3: Unblock the Script (if downloaded from the internet)

```powershell
Unblock-File -Path .\Get-EntraGroupMembers.ps1
```

## Usage

### Basic Syntax

```powershell
.\Get-EntraGroupMembers.ps1 -GroupName <string> [-ExportToCsv] [-CsvPath <string>]
# OR
.\Get-EntraGroupMembers.ps1 -GroupId <string> [-ExportToCsv] [-CsvPath <string>]
```

## Parameters

### `-GroupName` (Mandatory in ByName parameter set)
- **Type**: String
- **Description**: The display name of the Entra group you want to query
- **Example**: `"Marketing Team"`, `"PBI-Ops"`
- **Note**: If multiple groups have the same name, the script will use the first match and display a warning

### `-GroupId` (Mandatory in ById parameter set)
- **Type**: String
- **Description**: The Object ID (GUID) of the Entra group
- **Example**: `"12345678-1234-1234-1234-123456789012"`
- **Note**: Use this parameter when you know the exact group ID or need to avoid ambiguity

### `-ExportToCsv` (Optional)
- **Type**: Switch
- **Description**: When specified, exports the results to a CSV file instead of displaying in console
- **Default**: Results are displayed in console as a formatted table

### `-CsvPath` (Optional)
- **Type**: String
- **Description**: The full path where the CSV file should be saved
- **Default**: If not specified, the script creates a file in the current directory with format: `EntraGroup_<GroupName>_<Timestamp>.csv`
- **Example**: `"C:\Reports\MarketingUsers.csv"`

## Examples

### Example 1: Display Group Members in Console

```powershell
.\Get-EntraGroupMembers.ps1 -GroupName "Marketing Team"
```

**Output**: Displays a formatted table of users in the console.

### Example 2: Export to CSV with Auto-Generated Filename

```powershell
.\Get-EntraGroupMembers.ps1 -GroupName "PBI-Ops" -ExportToCsv
```

**Output**: Creates a CSV file like `EntraGroup_PBI-Ops_20251207_143022.csv` in the current directory.

### Example 3: Export to Specific CSV Path

```powershell
.\Get-EntraGroupMembers.ps1 -GroupName "Marketing Team" -ExportToCsv -CsvPath "C:\Reports\MarketingUsers.csv"
```

**Output**: Creates or overwrites `C:\Reports\MarketingUsers.csv` with the results.

### Example 4: Query Group by Object ID

```powershell
.\Get-EntraGroupMembers.ps1 -GroupId "12345678-1234-1234-1234-123456789012"
```

**Output**: Displays members of the group with the specified ID.

### Example 5: Query Group by ID and Export

```powershell
.\Get-EntraGroupMembers.ps1 -GroupId "12345678-1234-1234-1234-123456789012" -ExportToCsv -CsvPath ".\GroupMembers.csv"
```

**Output**: Exports the members to `GroupMembers.csv` in the current directory.

## Output

### Console Output

When not using `-ExportToCsv`, the script displays:

```
DisplayName       UserPrincipalName              Email                  JobTitle         Department UserId
-----------       -----------------              -----                  --------         ---------- ------
John Doe          john.doe@company.com          john.doe@company.com   Developer        IT         a1b2c3...
Jane Smith        jane.smith@company.com        jane.smith@company.com Manager          Marketing  d4e5f6...
```

### CSV Output Format

The CSV file contains the following columns:

| Column | Description |
|--------|-------------|
| **DisplayName** | The user's full display name |
| **UserPrincipalName** | The user's UPN (username@domain) |
| **Email** | The user's primary email address |
| **JobTitle** | The user's job title |
| **Department** | The department the user belongs to |
| **UserId** | The unique Azure AD Object ID for the user |

### CSV Filename Format

Auto-generated CSV files follow this naming convention:
```
EntraGroup_<SanitizedGroupName>_<Timestamp>.csv
```

- **SanitizedGroupName**: Group name with special characters replaced by underscores
- **Timestamp**: Format `yyyyMMdd_HHmmss` (e.g., `20251207_143022`)

Example: `EntraGroup_Marketing_Team_20251207_143022.csv`

## Error Handling

The script includes comprehensive error handling for common scenarios:

### Module Not Installed
```
Microsoft.Graph.Groups module is not installed. Install it using: Install-Module Microsoft.Graph.Groups -Scope CurrentUser
```
**Resolution**: Install the required module as shown in the error message.

### Group Not Found
```
Group 'Marketing Team' not found.
```
**Resolution**: Verify the group name spelling or use `-GroupId` if you know the exact ID.

### Multiple Groups Found
```
WARNING: Multiple groups found with name 'Marketing Team'. Using the first match.
```
**Resolution**: Use `-GroupId` parameter to specify the exact group you want.

### User Details Retrieval Failed
```
WARNING: Could not retrieve details for member ID: 12345678-1234-1234-1234-123456789012
```
**Resolution**: This typically means the member is not a user object or you lack permissions to read their details.

### Connection Failures
```
An error occurred: <error details>
```
**Resolution**: Check your network connection, credentials, and permissions.

## Permissions

### Microsoft Graph Permissions Required

The script requests the following delegated permissions when you sign in:

- **Group.Read.All**
  - Allows reading of all group properties and memberships
  - Required to query group membership

- **User.Read.All**
  - Allows reading of all user profiles
  - Required to retrieve detailed user information

### Required Azure AD Roles

To successfully run this script, your account needs one of the following roles:

- **Global Administrator**
- **Global Reader**
- **Groups Administrator**
- **User Administrator**
- **Directory Readers** (minimum for read-only operations)

Alternatively, you can have specific permissions assigned via custom roles or security groups.

## Troubleshooting

### Issue: Script Fails to Connect to Microsoft Graph

**Symptoms**: Authentication window doesn't appear or connection fails

**Solutions**:
1. Ensure you have internet connectivity
2. Verify your credentials are correct
3. Check if MFA is properly configured on your account
4. Try running: `Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All"` manually
5. Clear cached credentials: `Disconnect-MgGraph` then retry

### Issue: "Access Denied" or Permission Errors

**Symptoms**: Script connects but fails to retrieve data

**Solutions**:
1. Verify your account has the necessary Azure AD roles
2. Request an administrator to grant the required API permissions
3. Check if conditional access policies are blocking the connection
4. Ensure your organization allows Microsoft Graph PowerShell connections

### Issue: No Users Found in Group

**Symptoms**: Script shows "No users found in group"

**Possible Causes**:
1. The group is empty
2. The group only contains non-user members (devices, service principals, nested groups)
3. You lack permission to read user objects

**Solutions**:
1. Verify the group membership in Azure Portal
2. Check the "Member types in group" output for object types
3. Ensure you have `User.Read.All` permission

### Issue: CSV Export Fails

**Symptoms**: Error when trying to save CSV file

**Solutions**:
1. Verify the destination folder exists or the script has permission to create it
2. Check if the file is not currently open in Excel or another application
3. Ensure you have write permissions to the destination folder
4. Try using a different path or the default auto-generated path

### Issue: Multiple Groups Warning

**Symptoms**: Script warns about multiple groups with the same name

**Solutions**:
1. Use the Azure Portal to find the exact Group Object ID
2. Run the script with `-GroupId` parameter instead of `-GroupName`
3. Review your group naming conventions to avoid duplicates

### Issue: Module Import Errors

**Symptoms**: "Module cannot be loaded" errors

**Solutions**:
1. Ensure modules are installed: `Get-Module -ListAvailable Microsoft.Graph.*`
2. Update to the latest version: `Update-Module Microsoft.Graph.Groups, Microsoft.Graph.Users`
3. Check PowerShell execution policy: `Get-ExecutionPolicy`
4. Set appropriate execution policy: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned`

## Script Workflow

The script follows this execution flow:

1. **Parameter Validation**: Validates input parameters based on parameter set
2. **Module Check**: Verifies required Microsoft Graph modules are installed
3. **Module Import**: Imports Microsoft.Graph.Groups and Microsoft.Graph.Users
4. **Authentication**: Connects to Microsoft Graph with required scopes
5. **Group Lookup**: Finds the group by name or ID
6. **Member Retrieval**: Gets all members of the group
7. **Type Filtering**: Filters members to include only user objects
8. **Details Retrieval**: Fetches detailed information for each user
9. **Output Processing**: Displays in console or exports to CSV
10. **Cleanup**: Disconnects from Microsoft Graph

## Best Practices

1. **Use Group ID for Production**: When automating, use `-GroupId` to avoid ambiguity
2. **Schedule Exports**: Set up scheduled tasks for regular membership exports
3. **Secure CSV Files**: Store exported CSV files in secure locations with appropriate permissions
4. **Monitor Large Groups**: For groups with many members, consider adding progress indicators
5. **Version Control**: Keep the script in version control to track changes
6. **Test Environment**: Test the script in a non-production environment first
7. **Logging**: Consider adding logging functionality for audit trails

## Additional Resources

- [Microsoft Graph PowerShell SDK Documentation](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)
- [Microsoft Graph API Reference](https://learn.microsoft.com/en-us/graph/api/overview)
- [Azure AD Groups Overview](https://learn.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-groups-view-azure-portal)

## Support and Contributing

For issues, questions, or contributions, please refer to the repository's issue tracker and contribution guidelines.

## License

[Specify your license here]

## Author

[Your name/organization]

## Version History

- **1.0.0** - Initial release with core functionality
  - Group lookup by name or ID
  - User information retrieval
  - CSV export capability
  - Comprehensive error handling
