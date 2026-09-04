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

function Get-CommitCountAhead {
    $ahead = (Get-GitCommitDivergence)[0]
    if (-not $ahead -or $ahead -eq 0) {
        return "↑0"
    }
    return "↑$ahead"
}

function Get-CommitCountBehind {
    $behind = (Get-GitCommitDivergence)[1]
    if (-not $behind -or $behind -eq 0) {
        return "↓0"
    }
    return "↓$behind"
}