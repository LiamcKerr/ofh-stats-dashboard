# OneFootball Heads — Stats Dashboard

Static analytics dashboard for the OneFootballHeads GIF channel: GIPHY daily
views and KLIPY daily impressions, range filters, stat tiles, top GIFs, and
country breakdown. Pure HTML/JS/SVG — no build step, no dependencies.

## Data

The page reads the CSVs in `data/` at load time. They are produced by the
stats scraper in the (private, local) GIF Pipeline project and copied in by
`publish.ps1`.

## Refresh & deploy

```powershell
py "D:\Claude\GIF Pipeline\scripts\stats-scraper.py" pull   # pull fresh stats
pwsh -File publish.ps1                                       # copy CSVs, commit, push
```

Netlify redeploys automatically on push.

## Local preview

```powershell
pwsh -File serve.ps1    # http://localhost:8125/
```
