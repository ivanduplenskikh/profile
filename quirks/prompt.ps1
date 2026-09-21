function prompt {
    "PS $($executionContext.SessionState.Path.CurrentLocation) [$(Get-CurrentGitBranch) $(Get-CommitCountAhead) $(Get-CommitCountBehind)] > "
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