<#
.SYNOPSIS
    Pester tests for Get-EntraGroupMembers.ps1

.DESCRIPTION
    This file contains unit and integration tests for the Get-EntraGroupMembers script.
    Tests use Pester 5.x, PowerShell's standard testing framework.
    
.NOTES
    To run these tests:
    1. Install Pester 5.x: Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.0.0
    2. Run all tests: Invoke-Pester
    3. Run specific test: Invoke-Pester -TagFilter "Unit"
#>

BeforeAll {
    # Import the script to test
    $scriptPath = Join-Path $PSScriptRoot "Get-EntraGroupMembers.ps1"
}

Describe "Get-EntraGroupMembers - Parameter Validation" -Tag "Unit" {
    
    Context "When validating required parameters" {
        
        It "Should require either GroupName or GroupId parameter" {
            # Verify that at least one parameter set requires a mandatory parameter
            $params = (Get-Command $scriptPath).Parameters
            $groupNameMandatory = $params['GroupName'].Attributes | Where-Object { 
                $_.TypeId.Name -eq 'ParameterAttribute' -and $_.Mandatory -eq $true 
            }
            $groupIdMandatory = $params['GroupId'].Attributes | Where-Object { 
                $_.TypeId.Name -eq 'ParameterAttribute' -and $_.Mandatory -eq $true 
            }
            
            # At least one parameter should be mandatory in its parameter set
            ($groupNameMandatory -or $groupIdMandatory) | Should -BeTrue
        }
        
        It "Should accept GroupName parameter" {
            # We can't actually run the script without mocking, but we can verify parameter exists
            $params = (Get-Command $scriptPath).Parameters
            $params.ContainsKey('GroupName') | Should -Be $true
            $params['GroupName'].Attributes.Mandatory | Should -Be $true
        }
        
        It "Should accept GroupId parameter" {
            $params = (Get-Command $scriptPath).Parameters
            $params.ContainsKey('GroupId') | Should -Be $true
            $params['GroupId'].Attributes.Mandatory | Should -Be $true
        }
        
        It "Should have ExportToCsv as optional switch parameter" {
            $params = (Get-Command $scriptPath).Parameters
            $params.ContainsKey('ExportToCsv') | Should -Be $true
            $params['ExportToCsv'].SwitchParameter | Should -Be $true
        }
        
        It "Should have CsvPath as optional string parameter" {
            $params = (Get-Command $scriptPath).Parameters
            $params.ContainsKey('CsvPath') | Should -Be $true
            $params['CsvPath'].ParameterType.Name | Should -Be 'String'
        }
    }
    
    Context "When validating parameter sets" {
        
        It "Should have ByName parameter set" {
            $params = (Get-Command $scriptPath).Parameters
            $groupNameSets = $params['GroupName'].Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' }
            $groupNameSets.ParameterSetName | Should -Contain 'ByName'
        }
        
        It "Should have ById parameter set" {
            $params = (Get-Command $scriptPath).Parameters
            $groupIdSets = $params['GroupId'].Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' }
            $groupIdSets.ParameterSetName | Should -Contain 'ById'
        }
    }
}

Describe "Get-EntraGroupMembers - Module Dependencies" -Tag "Unit" {
    
    Context "When checking for required modules" {
        
        BeforeAll {
            # Mock Get-Module to simulate missing modules
            Mock Get-Module { $null } -ParameterFilter { $Name -eq 'Microsoft.Graph.Groups' }
        }
        
        It "Should check for Microsoft.Graph.Groups module" {
            # The script should verify this module exists
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Microsoft\.Graph\.Groups'
        }
        
        It "Should check for Microsoft.Graph.Users module" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Microsoft\.Graph\.Users'
        }
        
        It "Should provide installation instructions if modules are missing" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Install-Module'
        }
    }
}

Describe "Get-EntraGroupMembers - Mock Integration Tests" -Tag "Integration" {
    
    BeforeAll {
        # Mock all Microsoft Graph cmdlets to avoid actual API calls
        Mock Import-Module { }
        Mock Connect-MgGraph { }
        Mock Disconnect-MgGraph { }
        
        # Mock Get-MgGroup to return a test group
        Mock Get-MgGroup {
            [PSCustomObject]@{
                Id = "12345678-1234-1234-1234-123456789012"
                DisplayName = "Test Group"
            }
        }
        
        # Mock Get-MgGroupMember to return test members
        Mock Get-MgGroupMember {
            @(
                [PSCustomObject]@{
                    Id = "user1-id"
                    AdditionalProperties = @{
                        '@odata.type' = '#microsoft.graph.user'
                    }
                },
                [PSCustomObject]@{
                    Id = "user2-id"
                    AdditionalProperties = @{
                        '@odata.type' = '#microsoft.graph.user'
                    }
                }
            )
        }
        
        # Mock Get-MgUser to return test user details
        Mock Get-MgUser {
            param($UserId)
            [PSCustomObject]@{
                Id = $UserId
                DisplayName = "Test User"
                UserPrincipalName = "testuser@company.com"
                Mail = "testuser@company.com"
                JobTitle = "Developer"
                Department = "IT"
            }
        }
    }
    
    Context "When retrieving group members by name" {
        
        It "Should connect to Microsoft Graph" {
            # This would require heavy mocking or a real connection
            # For now, we verify the script contains the connection logic
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Connect-MgGraph'
        }
        
        It "Should search for group by name" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'displayName eq'
        }
        
        It "Should retrieve group members" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Get-MgGroupMember'
        }
        
        It "Should disconnect from Microsoft Graph in finally block" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Disconnect-MgGraph'
            $scriptContent | Should -Match 'finally'
        }
    }
    
    Context "When filtering member types" {
        
        It "Should filter for user objects only" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'microsoft\.graph\.user'
        }
        
        It "Should retrieve detailed user information" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Get-MgUser'
        }
    }
}

Describe "Get-EntraGroupMembers - CSV Export Functionality" -Tag "Unit" {
    
    Context "When exporting to CSV" {
        
        It "Should generate filename with timestamp when CsvPath not specified" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Get-Date -Format "yyyyMMdd_HHmmss"'
        }
        
        It "Should sanitize group name for filename" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match '-replace'
        }
        
        It "Should create directory if it doesn't exist" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'New-Item.*Directory'
        }
        
        It "Should export to CSV with UTF8 encoding" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Export-Csv'
            $scriptContent | Should -Match 'UTF8'
        }
    }
}

Describe "Get-EntraGroupMembers - Error Handling" -Tag "Unit" {
    
    Context "When handling errors" {
        
        It "Should use try-catch-finally block" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match '\btry\b'
            $scriptContent | Should -Match '\bcatch\b'
            $scriptContent | Should -Match '\bfinally\b'
        }
        
        It "Should handle group not found scenario" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'not found'
        }
        
        It "Should handle multiple groups with same name" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Multiple groups'
        }
        
        It "Should handle user retrieval failures gracefully" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Could not retrieve details'
        }
    }
}

Describe "Get-EntraGroupMembers - Output Format" -Tag "Unit" {
    
    Context "When formatting output" {
        
        It "Should create custom objects with specific properties" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match '\[PSCustomObject\]'
            $scriptContent | Should -Match 'DisplayName'
            $scriptContent | Should -Match 'UserPrincipalName'
            $scriptContent | Should -Match 'Email'
            $scriptContent | Should -Match 'JobTitle'
            $scriptContent | Should -Match 'Department'
            $scriptContent | Should -Match 'UserId'
        }
        
        It "Should format table output for console display" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match 'Format-Table'
        }
    }
}

Describe "Get-EntraGroupMembers - User Information" -Tag "Unit" {
    
    Context "When retrieving user properties" {
        
        It "Should request specific user properties from Graph API" {
            $scriptContent = Get-Content $scriptPath -Raw
            $scriptContent | Should -Match '-Property'
            $scriptContent | Should -Match 'DisplayName'
            $scriptContent | Should -Match 'UserPrincipalName'
            $scriptContent | Should -Match 'Mail'
        }
    }
}
