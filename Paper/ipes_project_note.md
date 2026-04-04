# IPES 2026 Project: Pandemic Wealth Shocks and Electoral Accountability

## Project Overview

**Title:** Who Pays, Who Punishes? Pandemic Wealth Shocks and Electoral Accountability Across Democracies

**Target:** IPES 2026 (Yale, October 23-24, 2026)
**Deadline:** Likely mid-April 2026 — check https://form.jotform.com/260061862224349
**Submission format:** 500-word abstract (filed at Paper/ipes_abstract_wealth_shocks.tex — currently 500 words exactly)
**Topic label for form:** Money & Finance

## Research Question

Did the distributional incidence of pandemic wealth shocks — which households lost how much — determine which incumbents were punished in pandemic-era elections? Does this mechanism generalize across democracies with different financial system structures?

## Core Argument

The personal-cost accountability mechanism documented in Hwang (2025, under review) for the US generalizes cross-nationally: countries where the incumbent's electoral base bore disproportionate pandemic wealth losses showed stronger anti-incumbent voting. The distribution of these losses was shaped by pre-pandemic financial structure (stock-market vs. bank-based economies, household asset composition), creating quasi-exogenous variation in political exposure to the pandemic shock.

## Empirical Design

### Stage 1: Measure pandemic wealth redistribution
- **Data:** Luxembourg Wealth Study (LWS) pre/post-pandemic waves
- Decompose changes in household net worth by asset class (housing, equities, deposits, debt) and income quintile
- Construct a "base exposure index" measuring whether the incumbent's supporters were disproportionately hit

### Stage 2: Test accountability across countries
- **Data:** Subnational election returns from pandemic-era elections
- Within-country: local wealth vulnerability → vote change
- Cross-country: pool estimates, test whether base exposure predicts accountability magnitude

### Identification
- Shift-share IV: pre-pandemic asset composition (structurally determined) × global pandemic shock
- Supplements: entropy balancing, Cinelli & Hazlett sensitivity analysis (tools already built in parent project)

## Countries with LWS Pre/Post + Pandemic Elections

| Country | LWS Pre | LWS Post | Election | Election Data Status |
|---------|---------|----------|----------|---------------------|
| US | 2019 | 2022 | 2020 Presidential | Have county + CES individual |
| UK | 2017, 2019 | 2021 | 2021 Local | Have constituency data |
| South Korea | 2017-2019 | 2020-2022 | 2022 Presidential | Have precinct data |
| Canada | 2019 | 2023 | 2021 Federal | Have provincial COVID data |
| Japan | 2017-2019 | 2020-2021 | 2021 General | Need to find |
| Australia | 2018 | 2020 | 2022 Federal | Need to find |
| France | 2017 | 2020 | 2022 Presidential | Need to find |
| Denmark | 2017-2019 | 2020-2022 | 2022 General | Need to find |
| Norway | 2019 | 2020-2022 | 2021 General | Need to find |
| Spain | 2017 | 2021-2022 | 2023 General | Need to find |

## Relationship to Parent Project (psych_polisci)

This project extends Hwang "Who Pays, Who Punishes?" (currently under review) from a single-country US study to a 10-country comparative framework. Key assets inherited:

- **Causal inference toolkit:** Shift-share IV, entropy balancing, Cinelli-Hazlett sensitivity — all coded in Python in the parent project's Code/ directory
- **US results:** County-level and CES individual-level evidence serves as "preliminary evidence" in the IPES abstract
- **UK/Korea/Canada data:** Already partially assembled in parent project's Data/Raw/

## Neil's Methodological Strengths to Leverage

- **Network statistics** (JASA 2024): Community detection for clustering countries by financial structure
- **Change-point detection** (Sankhya A 2022): Identifying when pandemic wealth shocks hit different asset classes
- **Causal inference:** IV, mediation, sensitivity analysis (current project)
- **Finance/accounting:** Balance sheet analysis, asset class decomposition
- **Countries:** US, UK, Canada, Australia, South Korea, Japan, Taiwan

## Key References

- Hwang et al. (2025) "Pandemics and Elections" PRQ — the published predecessor
- Hwang (under review) "Who Pays, Who Punishes?" — the parent project
- Autor, Dorn & Hanson (2013, 2016) — trade shocks and political consequences
- Colantone & Stanig (2018) — import competition and populism
- Funke, Schularick & Trebesch (2016) — financial crises and political extremism
- Broz, Frieden & Weymouth (2021) — populism and the economy
- Margalit (2013) — economic insecurity and political preferences
- Cinelli & Hazlett (2020) — sensitivity analysis framework

## Data Access Notes

- **LIS/LWS:** Data accessed via the LIS Data Center (www.lisdatacenter.org). Remote execution system — code is submitted, results returned. Need active LIS account.
- **LIS variable guide:** Data/Raw/data-lis-guide.pdf, Data/Raw/data-lis-variables.pdf, Data/Raw/data-lws-variables.pdf
- **LIS contents files:** Data/Raw/contents_combined_LIS.xlsx, contents_combined_LWS.xlsx, contents_balance_combined_LWS.xlsx

## Immediate Next Steps

1. **Submit IPES abstract** (deadline imminent)
2. Set up LIS/LWS remote access and run exploratory queries for the 6 countries with election data in hand
3. Assemble election data for Japan 2021, Australia 2022, France 2022, Denmark 2022
4. Construct base exposure index for US (proof of concept) using LWS us19 and us22 waves
5. Replicate the parent project's shift-share IV at the cross-national level
