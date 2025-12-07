# Understanding Code Testing - A Beginner's Guide

## What is Code Testing?

**Code testing** is the practice of writing additional code that verifies your main code works correctly. Think of it like a quality control checklist for your software.

### Why Write Tests?

1. **Catch Bugs Early**: Find problems before users do
2. **Confidence in Changes**: Know that modifications don't break existing functionality
3. **Documentation**: Tests show how your code is supposed to work
4. **Refactoring Safety**: Change code structure without fear
5. **Faster Development**: Less time debugging, more time building

## Types of Tests

### 1. Unit Tests
Test individual functions or small pieces of code in isolation.

**Example**: Testing that a single parameter is validated correctly.

```powershell
It "Should accept GroupName parameter" {
    $params = (Get-Command $scriptPath).Parameters
    $params.ContainsKey('GroupName') | Should -Be $true
}
```

### 2. Integration Tests
Test how different parts of your code work together.

**Example**: Testing that your script connects to Microsoft Graph and retrieves data correctly.

```powershell
It "Should connect to Microsoft Graph and retrieve members" {
    # This tests the full workflow of connection + data retrieval
}
```

### 3. End-to-End (E2E) Tests
Test the entire application from start to finish, simulating real user behavior.

**Example**: Running the script with actual parameters and verifying the CSV output.

## Pester: PowerShell's Testing Framework

**Pester** is the standard testing framework for PowerShell. It's like a specialized tool designed specifically for testing PowerShell code.

### Key Pester Concepts

#### 1. `Describe` Block
Groups related tests together. Think of it as a chapter in a book.

```powershell
Describe "Get-EntraGroupMembers - Parameter Validation" {
    # All parameter-related tests go here
}
```

#### 2. `Context` Block
Groups related tests within a `Describe` block. Like sections within a chapter.

```powershell
Context "When validating required parameters" {
    # Tests for required parameters
}
```

#### 3. `It` Block
A single test case. This is where you write what you're testing.

```powershell
It "Should require either GroupName or GroupId parameter" {
    # The actual test code
}
```

#### 4. `Should` Assertions
Verify that something is true. This is how you check if your code behaves correctly.

```powershell
$result | Should -Be $expected        # Values should match
$result | Should -BeTrue              # Should be true
$result | Should -Contain "text"      # Should contain something
{ SomeCode } | Should -Throw          # Should throw an error
```

#### 5. `Mock`
Replaces real functions with fake ones during testing. Essential when you don't want to:
- Make actual API calls
- Connect to real databases
- Send real emails
- Make expensive operations

```powershell
Mock Connect-MgGraph { }  # Pretend to connect without actually connecting
```

#### 6. `BeforeAll` and `BeforeEach`
Run setup code before tests.

```powershell
BeforeAll {
    # Runs once before all tests in this block
    $scriptPath = ".\Get-EntraGroupMembers.ps1"
}

BeforeEach {
    # Runs before each individual test
    $testData = @()
}
```

## Understanding the Test File Structure

Let's break down the test file I created for your script:

### Test Organization

```
Get-EntraGroupMembers.Tests.ps1
├── Parameter Validation Tests (Unit)
│   ├── Required parameters exist
│   ├── Optional parameters exist
│   └── Parameter sets are correct
├── Module Dependencies Tests (Unit)
│   ├── Checks for required modules
│   └── Provides installation help
├── Integration Tests (Mocked)
│   ├── Connection to Graph API
│   ├── Group retrieval
│   └── Member filtering
├── CSV Export Tests (Unit)
│   ├── Filename generation
│   ├── Directory creation
│   └── Export functionality
├── Error Handling Tests (Unit)
│   ├── Try-catch blocks exist
│   ├── Handles missing groups
│   └── Handles retrieval failures
└── Output Format Tests (Unit)
    ├── Custom object creation
    └── Property verification
```

## Example Test Walkthrough

Let's examine one test in detail:

```powershell
It "Should accept GroupName parameter" {
    # 1. Get information about the script's parameters
    $params = (Get-Command $scriptPath).Parameters
    
    # 2. Check if GroupName parameter exists
    $params.ContainsKey('GroupName') | Should -Be $true
    
    # 3. Verify it's marked as mandatory
    $params['GroupName'].Attributes.Mandatory | Should -Be $true
}
```

**What this test does:**
1. Retrieves metadata about your script
2. Checks that `GroupName` parameter exists
3. Verifies it's required (mandatory)

**Why it matters:**
If someone accidentally removes the parameter or makes it optional, this test will fail and alert you.

## Running Tests

### Install Pester

```powershell
# Install Pester (if not already installed)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Verify installation
Get-Module -Name Pester -ListAvailable
```

### Run All Tests

```powershell
# Navigate to your project folder
cd C:\Users\bdobbs\source\LocalDemo

# Run all tests
Invoke-Pester

# Run tests with detailed output
Invoke-Pester -Output Detailed
```

### Run Specific Tests

```powershell
# Run only unit tests
Invoke-Pester -TagFilter "Unit"

# Run only integration tests
Invoke-Pester -TagFilter "Integration"

# Run a specific test file
Invoke-Pester -Path .\Get-EntraGroupMembers.Tests.ps1
```

### Understanding Test Output

```
Describing Get-EntraGroupMembers - Parameter Validation
  Context When validating required parameters
    [+] Should accept GroupName parameter 45ms (43ms|2ms)
    [+] Should accept GroupId parameter 12ms (10ms|2ms)
    [+] Should have ExportToCsv as optional switch parameter 8ms (7ms|1ms)
```

- **[+]** = Test passed ✓
- **[-]** = Test failed ✗
- **[!]** = Test skipped
- **Time** = How long the test took

## Common Testing Patterns

### Pattern 1: Arrange-Act-Assert (AAA)

```powershell
It "Should export users to CSV" {
    # ARRANGE: Set up test data
    $testUsers = @(
        [PSCustomObject]@{ Name = "John"; Email = "john@test.com" }
    )
    $csvPath = "TestDrive:\test.csv"
    
    # ACT: Execute the code being tested
    $testUsers | Export-Csv -Path $csvPath -NoTypeInformation
    
    # ASSERT: Verify the results
    Test-Path $csvPath | Should -Be $true
    $imported = Import-Csv $csvPath
    $imported.Count | Should -Be 1
    $imported[0].Name | Should -Be "John"
}
```

### Pattern 2: Test Edge Cases

```powershell
It "Should handle empty group membership" {
    Mock Get-MgGroupMember { @() }  # Return empty array
    
    $result = & $scriptPath -GroupName "EmptyGroup"
    
    $result | Should -BeNullOrEmpty
}

It "Should handle groups with special characters in name" {
    $groupName = "Test-Group (2024) [Active]"
    
    # Test sanitization
    $sanitized = $groupName -replace '[\\/:*?"<>|]', '_'
    
    $sanitized | Should -Be "Test-Group (2024) [Active]"
}
```

### Pattern 3: Test Error Conditions

```powershell
It "Should throw error when group doesn't exist" {
    Mock Get-MgGroup { $null }
    
    { & $scriptPath -GroupName "NonExistentGroup" } | Should -Throw
}
```

## Best Practices for Testing

### 1. Test Names Should Be Descriptive

❌ **Bad**: `It "Works correctly"`

✅ **Good**: `It "Should export users to CSV with UTF8 encoding"`

### 2. One Assertion Per Test (When Possible)

❌ **Bad**:
```powershell
It "Tests everything" {
    $param1 | Should -Be $true
    $param2 | Should -Be "value"
    $param3 | Should -BeGreaterThan 5
}
```

✅ **Good**:
```powershell
It "Should have valid param1" {
    $param1 | Should -Be $true
}

It "Should have correct param2 value" {
    $param2 | Should -Be "value"
}
```

### 3. Tests Should Be Independent

Each test should work on its own and not depend on other tests running first.

### 4. Use Mocks to Avoid External Dependencies

Don't make real API calls, database connections, or file operations in tests (when possible).

### 5. Test Both Success and Failure Paths

```powershell
# Success path
It "Should connect successfully with valid credentials" { }

# Failure path
It "Should handle connection failure gracefully" { }
```

## Your Script's Test Coverage

The test file I created covers:

1. ✅ **Parameter Validation** - All parameters are defined correctly
2. ✅ **Module Dependencies** - Required modules are checked
3. ✅ **Connection Logic** - Graph API connection is attempted
4. ✅ **Group Retrieval** - Groups can be found by name or ID
5. ✅ **Member Filtering** - Only users are retrieved (not devices, etc.)
6. ✅ **CSV Export** - Export functionality works correctly
7. ✅ **Error Handling** - Errors are caught and handled
8. ✅ **Output Format** - Data is formatted correctly

## Next Steps for Your Learning

### Beginner Level (Start Here!)
1. Install Pester and run the existing tests
2. Read through each test and understand what it checks
3. Modify one test slightly and see what happens
4. Add a simple new test (e.g., check for another property)

### Intermediate Level
1. Write a test for a new feature before implementing it (Test-Driven Development)
2. Add more integration tests with mocked Graph API calls
3. Measure code coverage (what percentage of code is tested)
4. Practice writing tests for edge cases

### Advanced Level
1. Implement full integration tests with a test Azure AD tenant
2. Set up automated testing in CI/CD pipeline
3. Write performance tests
4. Create test data generators for complex scenarios

## Common Questions

### "Do I need to test everything?"

No! Focus on:
- Critical functionality (data retrieval, export)
- Complex logic (filtering, error handling)
- Bug-prone areas (parameter validation)

Simple getters/setters usually don't need tests.

### "When should I write tests?"

**Three approaches:**

1. **Test-Driven Development (TDD)**: Write tests BEFORE code
2. **Test-After**: Write tests AFTER code is working
3. **Test-When-Fixing**: Write tests when you find bugs

All are valid! Start with what feels comfortable.

### "How many tests are enough?"

Aim for:
- All critical paths covered
- Major error conditions tested
- Feel confident making changes

Don't aim for 100% coverage. Aim for confidence.

### "What if my tests fail?"

That's good! Tests failing means:
1. They're working (finding issues)
2. You have a safety net
3. You know exactly what broke

Fix the code or update the test if requirements changed.

## Resources for Learning More

- **Pester Documentation**: https://pester.dev/
- **Pester GitHub**: https://github.com/pester/Pester
- **PowerShell Testing Guide**: https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/create-standard-library-binary-module

## Summary

Testing is about **confidence**. It's not about perfection—it's about catching problems early and knowing your code works as intended. Start small, add tests gradually, and you'll soon see the benefits!

The test file I created gives you:
- A working example to learn from
- Protection against breaking changes
- Documentation of expected behavior
- A foundation to build upon

Happy testing! 🚀
