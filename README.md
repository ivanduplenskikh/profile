# PowerShell Profile

A small, modular PowerShell profile that adds a few conveniences to interactive shell sessions.

## What is it?

The profile loads scripts from the `quirks` directory and currently provides:

- A `which` function backed by `Get-Command`.
- A `PROFILE_VERSION` environment variable.
- A custom prompt that shows the current Git branch and the number of commits ahead of or behind its upstream branch.
- A fallback comparison against a local `main` or `master` branch when the current branch has no upstream.

## Why use it?

It keeps common PowerShell customizations small and organized instead of placing everything directly in the system profile. The Git-aware prompt also makes the current repository state visible while working from the command line.

## Install

### 1. Clone the repository

```powershell
git clone <repository-url> "$HOME\profile"
```

Replace `<repository-url>` with this repository's clone URL. You may choose a different destination, but use that same path in the next step.

### 2. Add it to your PowerShell profile

Create the profile file if it does not exist:

```powershell
New-Item -ItemType File -Path $PROFILE -Force
```

Open it:

```powershell
code $PROFILE
```

Add this line:

```powershell
. "$HOME\profile\profile.ps1"
```

### 3. Reload the profile

```powershell
. $PROFILE
```

The custom prompt and helper functions should now be available in new PowerShell sessions.

## Test locally

Load the repository directly in the current PowerShell session:

```powershell
. .\profile.ps1
```

Verify the environment variable:

```powershell
$env:PROFILE_VERSION
```

Verify the `which` helper:

```powershell
which git
```

To test the Git prompt, enter a Git repository and invoke the prompt function:

```powershell
Set-Location path\to\a\git-repository
prompt
```

The output should include the current branch and divergence counters similar to:

```text
PS C:\path\to\repository [main ↑0 ↓0] >
```

To test without changing the current session, start a clean PowerShell process that loads only this profile:

```powershell
pwsh -NoProfile -Command '. .\profile.ps1; $env:PROFILE_VERSION; which git; Write-Output (prompt)'
```

## Requirements

- PowerShell 7 or later (`pwsh`).
- Git, for branch and commit divergence information in the prompt.
- VS Code is optional and is only used by the installation example to edit `$PROFILE`.
