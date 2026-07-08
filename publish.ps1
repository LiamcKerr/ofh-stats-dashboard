# Refresh the dashboard data and deploy: copies the latest CSVs from the GIF
# Pipeline stats folder, commits, and pushes - Netlify redeploys automatically.
# Full cycle:  py "D:\Claude\GIF Pipeline\scripts\stats-scraper.py" pull
#              pwsh -File publish.ps1
$ErrorActionPreference = "Stop"
$repo = $PSScriptRoot
$stats = "D:\Claude\GIF Pipeline\data\stats"
$files = @("giphy-daily.csv", "giphy-views.csv", "giphy-leaderboard.csv",
           "klipy-impressions-daily.csv", "klipy-top-performing.csv",
           "klipy-top-countries.csv")
foreach ($f in $files) {
  Copy-Item (Join-Path $stats $f) (Join-Path $repo "data\$f") -Force
}
Set-Location $repo
git add -A
if (git status --porcelain) {
  git commit -m "data refresh $(Get-Date -Format yyyy-MM-dd)"
  git push
  Write-Host "Pushed - Netlify will redeploy shortly."
} else {
  Write-Host "No data changes to publish."
}
