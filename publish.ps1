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

# velocity/category scorecard (optional - built by build-content-scorecard.py)
foreach ($f in @("content-scorecard.csv", "category-summary.csv")) {
  $src = Join-Path $stats $f
  if (Test-Path $src) { Copy-Item $src (Join-Path $repo "data\$f") -Force }
}

# also copy the monthly totals (used by the Google Sheet's Giphy Monthly tab)
Copy-Item (Join-Path $stats "giphy-monthly.csv") (Join-Path $repo "data\giphy-monthly.csv") -Force

# sheet-shaped exports: the Google Sheet tabs mirror the Excel workbook's
# transformed layouts (latest snapshot only, reordered columns), so IMPORTDATA
# needs these pre-shaped CSVs rather than the raw snapshot-accumulating ones
function Latest-Snapshot($rows) {
  $snap = ($rows | Measure-Object -Property snapshot_date -Maximum).Maximum
  $rows | Where-Object { $_.snapshot_date -eq $snap }
}
$gv = Latest-Snapshot (Import-Csv (Join-Path $stats "giphy-views.csv"))
$gv | Sort-Object { [int]$_.views } -Descending |
  Select-Object gif_id, title, kind, created, views |
  Export-Csv (Join-Path $repo "data\sheet-giphy-gifs.csv") -NoTypeInformation
$ki = Latest-Snapshot (Import-Csv (Join-Path $stats "klipy-items.csv"))
$ki | Sort-Object { [int]$_.impressions } -Descending |
  Select-Object title, type, impressions, views,
                @{n = "approved"; e = { $_.review_approved }}, slug |
  Export-Csv (Join-Path $repo "data\sheet-klipy-items.csv") -NoTypeInformation
$kc = Latest-Snapshot (Import-Csv (Join-Path $stats "klipy-top-countries.csv"))
$kc | Sort-Object { [int]$_.impressions } -Descending |
  Select-Object country, @{n = "code"; e = { $_.country_code }}, impressions |
  Export-Csv (Join-Path $repo "data\sheet-klipy-countries.csv") -NoTypeInformation

# combined daily series: giphy views + klipy impressions joined on date
$gd = Import-Csv (Join-Path $stats "giphy-daily.csv")
$kd = Import-Csv (Join-Path $stats "klipy-impressions-daily.csv")
$byDate = @{}
foreach ($r in $gd) { $byDate[$r.date] = @{ g = [int64]$r.views; k = [int64]0 } }
foreach ($r in $kd) {
  if (-not $byDate.ContainsKey($r.date)) { $byDate[$r.date] = @{ g = [int64]0; k = [int64]0 } }
  $byDate[$r.date].k = [int64]$r.impressions
}
$byDate.Keys | Sort-Object | ForEach-Object {
  [pscustomobject]@{
    date              = $_
    giphy_views       = $byDate[$_].g
    klipy_impressions = $byDate[$_].k
    combined          = $byDate[$_].g + $byDate[$_].k
  }
} | Export-Csv (Join-Path $repo "data\sheet-combined-daily.csv") -NoTypeInformation

Set-Location $repo
git add -A
if (git status --porcelain) {
  git commit -m "data refresh $(Get-Date -Format yyyy-MM-dd)"
  git push
  Write-Host "Pushed - Netlify will redeploy shortly."
} else {
  Write-Host "No data changes to publish."
}
