# Running Tests Before Pull Request Completion

This guide covers multiple strategies to ensure tests run before completing a pull request.

## Strategy 1: GitHub Actions (Automated CI/CD) ⭐ Recommended

### What It Does
Automatically runs tests on every push and pull request. Tests run in the cloud before code can be merged.

### Setup
A GitHub Actions workflow file has been created at `.github/workflows/test.yml`.

### How It Works
1. When you push code or create a pull request
2. GitHub automatically runs the workflow
3. Tests execute in a clean Windows environment
4. Results appear directly in the pull request
5. You can require tests to pass before merging

### Enabling Branch Protection
To **require** tests to pass before merging:

1. Go to your GitHub repository
2. Click **Settings** → **Branches**
3. Under "Branch protection rules", click **Add rule**
4. For "Branch name pattern", enter: `main`
5. Check these options:
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
   - In the search box, find and select: **Run Pester Tests**
6. Check: ✅ **Require conversation resolution before merging** (optional but recommended)
7. Click **Create** or **Save changes**

Now pull requests **cannot be merged** until tests pass!

### Viewing Test Results
- Go to the **Pull Request** page
- Scroll to the bottom to see "Checks"
- Click **Details** next to "Run Pester Tests" to see full output
- Green checkmark ✅ = Tests passed
- Red X ❌ = Tests failed (click to see why)

### Benefits
✅ Automatic - no manual steps needed  
✅ Consistent - same environment every time  
✅ Visible - results shown in PR  
✅ Enforceable - can block merging  
✅ Free for public repositories  

## Strategy 2: Pre-Commit Hook (Local Validation)

### What It Does
Runs tests automatically on your local machine before every commit.

### Setup
Create a pre-commit hook in your repository:

```powershell
# Create the hooks directory if it doesn't exist
$hookPath = ".git\hooks\pre-commit"

# Create the pre-commit hook
@'
#!/usr/bin/env pwsh
# Pre-commit hook to run Pester tests

Write-Host "Running Pester tests before commit..." -ForegroundColor Cyan

# Import Pester 5.x
Import-Module Pester -MinimumVersion 5.0.0 -Force -ErrorAction Stop

# Run tests
$result = Invoke-Pester -Path ".\Get-EntraGroupMembers.Tests.ps1" -PassThru

if ($result.FailedCount -gt 0) {
    Write-Host "Tests FAILED! Commit aborted." -ForegroundColor Red
    Write-Host "Failed: $($result.FailedCount), Passed: $($result.PassedCount)" -ForegroundColor Red
    exit 1
}

Write-Host "All tests PASSED! Proceeding with commit." -ForegroundColor Green
exit 0
'@ | Out-File -FilePath $hookPath -Encoding UTF8

# Make it executable (on Unix-like systems)
# On Windows, this isn't necessary
```

### How It Works
1. You run `git commit`
2. Hook automatically runs tests
3. If tests fail, commit is blocked
4. If tests pass, commit proceeds

### Benefits
✅ Catches issues before they reach GitHub  
✅ Fast feedback loop  
✅ Works offline  

### Drawbacks
⚠️ Only protects your local commits  
⚠️ Can be bypassed with `git commit --no-verify`  
⚠️ Teammates need to set up their own hooks  

## Strategy 3: Pre-Push Hook (Before Pushing)

### What It Does
Runs tests before code is pushed to GitHub.

### Setup

```powershell
# Create pre-push hook
$hookPath = ".git\hooks\pre-push"

@'
#!/usr/bin/env pwsh
# Pre-push hook to run Pester tests

Write-Host "Running Pester tests before push..." -ForegroundColor Cyan

Import-Module Pester -MinimumVersion 5.0.0 -Force -ErrorAction Stop

$result = Invoke-Pester -PassThru

if ($result.FailedCount -gt 0) {
    Write-Host "Tests FAILED! Push aborted." -ForegroundColor Red
    Write-Host "Failed: $($result.FailedCount), Passed: $($result.PassedCount)" -ForegroundColor Red
    exit 1
}

Write-Host "All tests PASSED! Proceeding with push." -ForegroundColor Green
exit 0
'@ | Out-File -FilePath $hookPath -Encoding UTF8
```

### Benefits
✅ Catches issues before code reaches remote  
✅ Allows multiple commits before testing  

## Strategy 4: Manual Testing Checklist

### What It Does
Create a pull request template with a testing checklist.

### Setup
Create `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Pull Request Checklist

Before submitting this PR, please ensure:

- [ ] I have run all tests locally (`Invoke-Pester`)
- [ ] All tests pass
- [ ] I have added tests for new functionality (if applicable)
- [ ] Code follows the project style guidelines
- [ ] Documentation has been updated (if applicable)

## Test Results

Please paste your test results below:

\`\`\`
# Run: Invoke-Pester -Output Detailed
# Paste output here
\`\`\`

## Description

_Describe your changes here_

## Related Issues

Closes #[issue number]
```

### Benefits
✅ Simple to set up  
✅ Documents test results  
✅ Encourages good practices  

### Drawbacks
⚠️ Relies on developer discipline  
⚠️ Can be ignored  

## Strategy 5: VS Code Task (Quick Testing)

### What It Does
Creates a keyboard shortcut to run tests in VS Code.

### Setup
Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run Pester Tests",
      "type": "shell",
      "command": "Import-Module Pester -MinimumVersion 5.0.0 -Force; Invoke-Pester -Output Detailed",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "presentation": {
        "reveal": "always",
        "panel": "new"
      },
      "problemMatcher": []
    },
    {
      "label": "Run Pester Tests (Quick)",
      "type": "shell",
      "command": "Import-Module Pester -MinimumVersion 5.0.0 -Force; Invoke-Pester",
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

### Usage
- Press `Ctrl+Shift+P`
- Type "Run Test Task"
- Or use keyboard shortcut: `Ctrl+Shift+T` (may vary)

### Benefits
✅ Quick and convenient  
✅ Integrated into VS Code  
✅ Visual feedback  

## Strategy 6: Required Status Checks + CODEOWNERS

### What It Does
Combines automated testing with required code reviews.

### Setup

1. **Create `.github/workflows/test.yml`** (already done!)

2. **Create `CODEOWNERS` file**:
```
# Require review from these people
* @bcdobbs

# Specific files need specific reviewers
*.Tests.ps1 @bcdobbs
```

3. **Enable branch protection** (see Strategy 1)

### Benefits
✅ Tests + human review  
✅ Ensures quality at multiple levels  
✅ Tracks accountability  

## Recommended Approach 🎯

**Use Multiple Strategies Together:**

### Minimum Setup (Good)
1. ✅ GitHub Actions workflow (`.github/workflows/test.yml`) - Already created!
2. ✅ Enable branch protection rules
3. ✅ Run tests manually before creating PR

### Recommended Setup (Better)
1. ✅ GitHub Actions workflow
2. ✅ Branch protection rules
3. ✅ VS Code task for quick testing
4. ✅ PR template with checklist

### Complete Setup (Best)
1. ✅ GitHub Actions workflow
2. ✅ Branch protection rules
3. ✅ Pre-push git hook
4. ✅ VS Code task
5. ✅ PR template
6. ✅ CODEOWNERS file

## Quick Reference Commands

```powershell
# Run tests locally (quick)
Invoke-Pester

# Run tests with detailed output
Invoke-Pester -Output Detailed

# Run specific test file
Invoke-Pester -Path .\Get-EntraGroupMembers.Tests.ps1

# Run only unit tests
Invoke-Pester -TagFilter "Unit"

# Run tests and generate coverage report
Invoke-Pester -CodeCoverage .\Get-EntraGroupMembers.ps1

# Run tests and output to file
Invoke-Pester -OutputFile test-results.xml -OutputFormat NUnitXml
```

## Troubleshooting

### Tests Pass Locally But Fail in GitHub Actions

**Possible Causes:**
- Environment differences
- Missing dependencies
- Hard-coded paths
- Different PowerShell versions

**Solution:**
- Review the GitHub Actions logs
- Ensure all dependencies are installed in the workflow
- Use relative paths, not absolute paths
- Test with the same PowerShell version locally

### GitHub Actions Not Running

**Check:**
1. Workflow file is in `.github/workflows/` directory
2. File has `.yml` or `.yaml` extension
3. Syntax is correct (YAML is whitespace-sensitive)
4. Go to **Actions** tab in GitHub to see if it's enabled

### Branch Protection Not Working

**Verify:**
1. You have admin rights on the repository
2. Branch name pattern matches (e.g., `main`, `master`, `develop`)
3. Status check name matches the job name in workflow
4. Push changes to trigger the workflow at least once

## Best Practices

1. **Run Tests Before Every Commit** - Catch issues early
2. **Keep Tests Fast** - Slow tests won't get run
3. **Write Tests for Bug Fixes** - Prevent regressions
4. **Review Test Results** - Don't just check if they pass
5. **Update Tests With Code** - Keep them in sync
6. **Don't Skip Tests** - Even if you're in a hurry

## Next Steps

1. ✅ Commit the `.github/workflows/test.yml` file
2. ✅ Push to GitHub
3. ✅ Create a test pull request
4. ✅ Watch the tests run automatically
5. ✅ Enable branch protection rules
6. ✅ Configure additional checks as needed

Your tests are now integrated into your development workflow! 🚀
