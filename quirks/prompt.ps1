function prompt {
  if (-not (Test-GitRepository)) {
    $global:ProfileGitPromptSignature = ""
    return "PS $($executionContext.SessionState.Path.CurrentLocation) > "
  }

  $branch = Get-CurrentGitBranch
  $ahead, $behind = Get-GitCommitDivergence
  $aheadText = Format-GitCommitCount -Count $ahead -Indicator "↑"
  $behindText = Format-GitCommitCount -Count $behind -Indicator "↓"
  $global:ProfileGitPromptSignature = Get-GitPromptSignature

  "PS $($executionContext.SessionState.Path.CurrentLocation) [$branch $aheadText $behindText] > "
}

function Test-GitRepository {
  return (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
}

function Get-CurrentGitBranch {
    return git rev-parse --abbrev-ref HEAD 2>$null
}

function Get-GitComparisonRef {
    $upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $upstream) {
        return $upstream
    }

    $currentBranch = Get-CurrentGitBranch
    foreach ($baseBranch in @("main", "master")) {
        git show-ref --verify --quiet "refs/heads/$baseBranch" 2>$null
        if ($LASTEXITCODE -eq 0 -and $baseBranch -ne $currentBranch) {
            return $baseBranch
        }
    }

    return ""
}

function Get-GitCommitDivergence {
    $comparisonRef = Get-GitComparisonRef
    if (-not $comparisonRef) {
        return @(0, 0)
    }

    $counts = git rev-list --left-right --count "$comparisonRef...HEAD" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $counts) {
        return @(0, 0)
    }

    $behind, $ahead = $counts -split "\s+"
    return @([int]$ahead, [int]$behind)
}

function Get-GitPromptSignature {
  $gitDirectory = git rev-parse --absolute-git-dir 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $gitDirectory) {
    return ""
  }

  $head = git rev-parse HEAD 2>$null
  $comparisonRef = Get-GitComparisonRef
  $comparisonCommit = if ($comparisonRef) {
    git rev-parse $comparisonRef 2>$null
  } else {
    ""
  }

  return "$gitDirectory|$head|$comparisonRef|$comparisonCommit"
}

function Format-GitCommitCount {
  param(
    [int]$Count,
    [string]$Indicator
  )

  $color = if ($Count -le 15) {
    $PSStyle.Foreground.Green
  } elseif ($Count -le 50) {
    "`e[38;5;208m"
  } else {
    $PSStyle.Foreground.Red
  }

  return "$color$Indicator$Count$($PSStyle.Reset)"
}

function Get-CommitCountAhead {
  $ahead = (Get-GitCommitDivergence)[0]
  return Format-GitCommitCount -Count $ahead -Indicator "↑"
}

function Get-CommitCountBehind {
  $behind = (Get-GitCommitDivergence)[1]
  return Format-GitCommitCount -Count $behind -Indicator "↓"
}

function Enable-GitPromptAutoRefresh {
  if (-not (Get-Module PSReadLine)) {
    return
  }

  if ($global:ProfileGitPromptSubscriptionId) {
    Unregister-Event -SubscriptionId $global:ProfileGitPromptSubscriptionId -ErrorAction SilentlyContinue
  }

  if ($global:ProfileGitPromptEventJobId) {
    Remove-Job -Id $global:ProfileGitPromptEventJobId -Force -ErrorAction SilentlyContinue
  }

  $global:ProfileGitPromptSignature = Get-GitPromptSignature
  $global:ProfileGitPromptLastCheck = 0L

  $eventJob = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -Action {
    $now = [Environment]::TickCount64
    if ($now - $global:ProfileGitPromptLastCheck -lt 1000) {
      return
    }

    $global:ProfileGitPromptLastCheck = $now
    $signature = Get-GitPromptSignature
    if ($signature -eq $global:ProfileGitPromptSignature) {
      return
    }

    $global:ProfileGitPromptSignature = $signature
    $useSynchronizedOutput = $Host.UI.SupportsVirtualTerminal
    if ($useSynchronizedOutput) {
      [Console]::Write("`e[?2026h")
    }

    try {
      [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt($null, $null)
    } finally {
      if ($useSynchronizedOutput) {
        [Console]::Write("`e[?2026l")
      }
    }
  }

  $subscriber = Get-EventSubscriber -SourceIdentifier PowerShell.OnIdle |
    Where-Object { $_.Action.Id -eq $eventJob.Id } |
    Select-Object -First 1

  $global:ProfileGitPromptEventJobId = $eventJob.Id
  $global:ProfileGitPromptSubscriptionId = $subscriber.SubscriptionId
}

Enable-GitPromptAutoRefresh