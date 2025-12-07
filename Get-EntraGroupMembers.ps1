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

.PARAMETER ExportToCsv
    If specified, exports the results to a CSV file instead of displaying in the console.

.PARAMETER CsvPath
    The path where the CSV file should be saved. If not specified, saves to the current directory with a generated filename.

.EXAMPLE
    .\Get-EntraGroupMembers.ps1 -GroupName "Marketing Team"
    
.EXAMPLE
    .\Get-EntraGroupMembers.ps1 -GroupId "12345678-1234-1234-1234-123456789012"

.EXAMPLE
    .\Get-EntraGroupMembers.ps1 -GroupName "Marketing Team" -ExportToCsv

.EXAMPLE
    .\Get-EntraGroupMembers.ps1 -GroupName "Marketing Team" -ExportToCsv -CsvPath "C:\Reports\MarketingUsers.csv"

#>

[CmdletBinding(DefaultParameterSetName = 'ByName')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
    [string]$GroupName,

    [Parameter(Mandatory = $true, ParameterSetName = 'ById')]
    [string]$GroupId,

    [Parameter(Mandatory = $false)]
    [switch]$ExportToCsv,

    [Parameter(Mandatory = $false)]
    [string]$CsvPath
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
    
    Write-Host "Total members found: $($members.Count)" -ForegroundColor Cyan
    
    # Debug: Show member types
    $memberTypes = $members | Group-Object -Property '@odata.type' | Select-Object Name, Count
    if ($memberTypes) {
        Write-Host "Member types in group:" -ForegroundColor Cyan
        $memberTypes | ForEach-Object { Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor Gray }
    }

    # Filter for users only and get detailed information
    $userMembers = $members | Where-Object { 
        $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.user' -or
        $_.GetType().Name -eq 'MicrosoftGraphUser' -or
        -not $_.AdditionalProperties.ContainsKey('@odata.type')
    }
    
    Write-Host "Processing $($userMembers.Count) user member(s)..." -ForegroundColor Cyan
    
    $users = $userMembers | ForEach-Object {
        try {
            $user = Get-MgUser -UserId $_.Id -Property Id, DisplayName, UserPrincipalName, Mail, JobTitle, Department -ErrorAction Stop
            [PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                Email             = $user.Mail
                JobTitle          = $user.JobTitle
                Department        = $user.Department
                UserId            = $user.Id
            }
        }
        catch {
            Write-Warning "Could not retrieve details for member ID: $($_.Id)"
        }
    }

    # Display or export results
    if ($users) {
        Write-Host "`nFound $($users.Count) user(s) in group '$($group.DisplayName)':" -ForegroundColor Green
        
        if ($ExportToCsv) {
            # Generate filename if not specified
            if (-not $CsvPath) {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $sanitizedGroupName = $group.DisplayName -replace '[\\/:*?"<>|]', '_'
                $CsvPath = Join-Path -Path $PWD -ChildPath "EntraGroup_${sanitizedGroupName}_${timestamp}.csv"
            }
            
            # Ensure directory exists
            $directory = Split-Path -Path $CsvPath -Parent
            if ($directory -and -not (Test-Path -Path $directory)) {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
            }
            
            # Export to CSV
            $users | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8
            Write-Host "Results exported to: $CsvPath" -ForegroundColor Green
        }
        else {
            $users | Format-Table -AutoSize
        }
        
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
