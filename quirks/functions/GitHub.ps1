function Set-GitHubConfig {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Username
    )

    Write-Host "Setting GitHub config for user $Username" -ForegroundColor Yellow
    $Response = Invoke-RestMethod "https://api.github.com/users/$Username"
    $name = $Response.name
    if (-not $name) {
        $name = $Response.login
    }
    Write-Host "Configuring git with:" -ForegroundColor Green
    Write-Host "  Email: $($Response.id)+$($Response.login)@users.noreply.github.com" -ForegroundColor Green
    Write-Host "  Name: $name" -ForegroundColor Green
    git config user.email "$($Response.id)+$($Response.login)@users.noreply.github.com"
    git config user.name $name
    Write-Host "GitHub config set successfully for user $Username" -ForegroundColor Yellow
}