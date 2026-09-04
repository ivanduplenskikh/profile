function which {
    param([string]$Name)
    Get-Command -Name $Name -ErrorAction SilentlyContinue
}