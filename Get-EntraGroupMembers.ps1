<#
.SYNOPSIS
    Gets all users in a specific Entra (Azure AD) group.

.DESCRIPTION
    This script retrieves all members of a specified Entra group and returns user information.
    Requires the Microsoft.Graph PowerShell module.

.PARAMETER GroupName
    The display name of the Entra group.

.PARAMETER GroupId
    The Object ID of the Entra group. Use this if you know the exact ID.

.EXAMPLE
    .\Get-EntraGroupMembers.ps1 -GroupName "Marketing Team"
    
.EXAMPLE
    .\Get-EntraGroupMembers.ps1 -GroupId "12345678-1234-1234-1234-123456789012"

#>

[CmdletBinding(DefaultParameterSetName = 'ByName')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
    [string]$GroupName,

    [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
    [string]$GroupId
)

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
    Write-Error "Microsoft.Graph.Groups module is not installed. Install it using: Install-Module Microsoft.Graph.Groups -Scope CurrentUser"
    exit 1
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Error "Microsoft.Graph.Users module is not installed. Install it using: Install-Module Microsoft.Graph.Users -Scope CurrentUser"
    exit 1
}

# Import required modules
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Users

try {
    # Connect to Microsoft Graph with required scopes
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All" -NoWelcome

    # Get the group
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        Write-Host "Searching for group: $GroupName" -ForegroundColor Cyan
        $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
        
        if (-not $group) {
            Write-Error "Group '$GroupName' not found."
            Disconnect-MgGraph | Out-Null
            exit 1
        }
        
        if ($group.Count -gt 1) {
            Write-Warning "Multiple groups found with name '$GroupName'. Using the first match."
            $group = $group[0]
        }
        
        $groupObjectId = $group.Id
    }
    else {
        $groupObjectId = $GroupId
        $group = Get-MgGroup -GroupId $groupObjectId -ErrorAction Stop
    }

    Write-Host "Found group: $($group.DisplayName) (ID: $groupObjectId)" -ForegroundColor Green

    # Get group members
    Write-Host "Retrieving group members..." -ForegroundColor Cyan
    $members = Get-MgGroupMember -GroupId $groupObjectId -All

    # Filter for users only and get detailed information
    $users = $members | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.user' } | ForEach-Object {
        $user = Get-MgUser -UserId $_.Id -Property Id, DisplayName, UserPrincipalName, Mail, JobTitle, Department
        [PSCustomObject]@{
            DisplayName       = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            Email             = $user.Mail
            JobTitle          = $user.JobTitle
            Department        = $user.Department
            UserId            = $user.Id
        }
    }

    # Display results
    if ($users) {
        Write-Host "`nFound $($users.Count) user(s) in group '$($group.DisplayName)':" -ForegroundColor Green
        $users | Format-Table -AutoSize
        
        # Return the users object
        return $users
    }
    else {
        Write-Host "No users found in group '$($group.DisplayName)'." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected from Microsoft Graph." -ForegroundColor Cyan
}
