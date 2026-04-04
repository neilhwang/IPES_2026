# Who Pays, Who Punishes? Pandemic Wealth Shocks and Electoral Accountability Across Democracies

## Research Question

Did the distributional incidence of pandemic wealth shocks — which households lost how much — determine which incumbents were punished in pandemic-era elections? Does this mechanism generalize across democracies with different financial system structures?

## Authors

- Neil Hwang

## Status

- [x] IPES abstract submitted
- [ ] LWS/LIS data exploration
- [ ] Election data assembly
- [ ] Base exposure index construction
- [ ] Main estimation
- [ ] Robustness checks
- [ ] Paper draft
- [ ] Submission

## Directory Structure

```
├── CLAUDE.md                  # Instructions for Claude Code sessions
├── README.md                  # This file — project overview
├── Admin/                     # Progress log, notes, miscellaneous
├── Code/
│   ├── _Archive/              # Superseded scripts
│   ├── _Session Logs/         # Session progress logs
│   └── _Session Scripts/      # Exported script copies
│       └── _Archive/
├── Data/
│   ├── Raw/                   # Original source data (read-only)
│   └── Processed/             # Cleaned and constructed datasets
│       └── _Archive/
├── Output/
│   ├── Tables/                # LaTeX tables, CSVs
│   │   └── _Archive/
│   └── Figures/               # PDFs, PNGs
│       └── _Archive/
├── Literature/                # Reference papers and documentation
└── Paper/                     # LaTeX paper and .bib files
```

## Data Sources

### LWS/LIS Microdata (accessed via LIS Data Center remote execution)

| Country       | LWS Pre-pandemic | LWS Post-pandemic | LIS Pre-pandemic  | LIS Post-pandemic    |
|---------------|------------------|--------------------|-------------------|----------------------|
| US            | 19               | 22                 | 17, 18, 19        | 20, 21, 22, 23, 24  |
| UK            | 17, 19           | 21                 | 17, 18, 19        | 20, 21               |
| South Korea   | 17, 18, 19       | 20, 21, 22         | 17, 18, 19        | 20, 21               |
| Canada        | 19               | 23                 | 17, 18, 19        | 20, 21, 22           |
| Japan         | 17, 18, 19       | 20, 21             | 17, 18, 19        | 20                   |
| Australia     | 18               | 20                 | 18                | 20                   |
| France        | 17               | 20                 | 17, 18, 19        | 20, 21, 22           |
| Denmark       | 17, 18, 19       | 20, 21, 22         | 17, 18, 19        | 20, 21, 22           |
| Norway        | 19               | 20, 21, 22         | 19                | 20, 21, 22           |
| Spain         | 17               | 21, 22             | 17, 18, 19        | 20, 21, 22           |

### Election Data on Hand

| Dataset | Location | Description |
|---------|----------|-------------|
| UK 2019 GE | `Data/Raw/HoC-GE2019-results-by-constituency-csv.csv` | 650 constituencies, vote counts by party |
| UK 2021 Local | `Data/Raw/LEH-2021-datafile.xlsx` | 3,863 wards, candidate + ward level results |
| UK Combined | `Data/Raw/uk_data.csv` | 114 local authorities: 2016 vs 2021 elections + COVID waves + demographics |
| South Korea 2022 | `Data/Raw/korea_pres_election_2022.xlsx` | 22,753 polling stations, 2022 presidential |
| Canada COVID | `Data/Raw/canada_covid19.csv` | Provincial daily COVID cases/deaths (not election data) |

### Election Data Needed

| Country | Election | Status |
|---------|----------|--------|
| Japan | 2021 General | Need to find |
| Australia | 2022 Federal | Need to find |
| France | 2022 Presidential | Need to find |
| Denmark | 2022 General | Need to find |
| Norway | 2021 General | Need to find |
| Spain | 2023 General | Need to find |

### Inherited Python Scripts (from parent project)

| Script | Location | Description |
|--------|----------|-------------|
| Shift-share IV | `Data/Raw/20_shift_share_iv.py` | Bartik IV with bootstrap SEs, US county-level |
| Cinelli-Hazlett | `Data/Raw/22_cinelli_hazlett_sensitivity.py` | OVB sensitivity analysis + contour plots |
| Entropy balancing | `Data/Raw/24_entropy_balancing.py` | IPW reweighting + nearest-neighbor matching |

### LIS/LWS Documentation

| File | Description |
|------|-------------|
| `Data/Raw/data-lis-guide.pdf` | LIS user guide |
| `Data/Raw/data-lis-variables.pdf` | LIS variable definitions |
| `Data/Raw/data-lws-variables.pdf` | LWS variable definitions |
| `Data/Raw/contents_combined_LIS.xlsx` | LIS variable availability by country-wave |
| `Data/Raw/contents_combined_LWS.xlsx` | LWS income variable availability by country-wave |
| `Data/Raw/contents_balance_combined_LWS.xlsx` | LWS balance sheet variable availability by country-wave |
| `Data/Raw/contents_iua_combined_LIS.xlsx` | LIS transfer decomposition availability |
| `Data/Raw/contents_iua_combined_LWS.xlsx` | LWS transfer decomposition availability |

## Pipeline

Scripts run in numbered order (Python):

| Script | Input | Output | Description |
|--------|-------|--------|-------------|
| TBD | | | |

## Paper Workflow

The active paper lives in `Paper/`. Key files:
- `ipes_abstract_wealth_shocks.tex` — 500-word IPES 2026 abstract
- `ipes_project_note.md` — detailed project design note

## Key References

- Hwang et al. (2025) "Pandemics and Elections" PRQ — published predecessor
- Hwang (under review) "Who Pays, Who Punishes?" — parent single-country project
- Autor, Dorn & Hanson (2013, 2016) — trade shocks and political consequences
- Colantone & Stanig (2018) — import competition and populism
- Funke, Schularick & Trebesch (2016) — financial crises and political extremism
- Cinelli & Hazlett (2020) — sensitivity analysis framework

## Notes

- LWS is the binding constraint for wealth analysis — far fewer waves than LIS.
- South Korea and Denmark have the richest pre/post LWS coverage (3+3 waves each).
- The three inherited Python scripts read `stage2_county.pkl` from the parent project and will need adaptation for the cross-national setting.
- LIS/LWS data is accessed via remote execution at the LIS Data Center — code is submitted, results returned.
