# =============================================================================
# Session_lws_us_exploration.R
# Purpose: LISSY query — US LWS wealth decomposition (proof of concept)
# Reads:   LWS us19wh, us22wh (household-level wealth files)
# Outputs: Printed summary tables (returned via LISSY job output)
#
# Submit this script to LISSY at:
#   https://www.lisdatacenter.org/data-access/lissy/
#
# Variable mapping:
#   hanr   = real estate (housing)
#   hafis  = stocks and equity
#   hafc   = deposits and cash
#   hafi   = financial investments (bonds + stocks + funds)
#   hannb  = business equity
#   hlr    = real estate liabilities (mortgage)
#   hln    = non-housing liabilities
#   hl     = total liabilities
#   dnw    = disposable net worth (han + haf - hl)
#   dhi    = disposable household income
#   nhhmem = household size
#   hpopwgt = household population weight
# =============================================================================

library(dplyr)
library(tidyr)

# -----------------------------------------------------------------------------
# 1. Load US LWS household data — pre and post pandemic
# -----------------------------------------------------------------------------

# LISSY read function (adjust syntax if needed based on LISSY version)
us19 <- read.LWS("us19", "wh", vars = c(
  "hid", "dname", "hpopwgt", "nhhmem", "dhi",
  "hanr", "hanrp", "hanro",
  "hafis", "hafiss", "hafiso",
  "hafc", "hafct", "hafcs",
  "hafi", "hafib", "hafii",
  "hannb",
  "hl", "hlrp", "hlro", "hlr", "hln",
  "dnw",
  "ha", "han", "haf"
))

us22 <- read.LWS("us22", "wh", vars = c(
  "hid", "dname", "hpopwgt", "nhhmem", "dhi",
  "hanr", "hanrp", "hanro",
  "hafis", "hafiss", "hafiso",
  "hafc", "hafct", "hafcs",
  "hafi", "hafib", "hafii",
  "hannb",
  "hl", "hlrp", "hlro", "hlr", "hln",
  "dnw",
  "ha", "han", "haf"
))

# Tag waves
us19$wave <- "pre"
us22$wave <- "post"

# Combine
df <- bind_rows(us19, us22)

# -----------------------------------------------------------------------------
# 2. Construct equivalized income quintiles (within each wave)
# -----------------------------------------------------------------------------

# Equivalized income: dhi / sqrt(household size)
df <- df %>%
  mutate(
    eq_income = dhi / sqrt(pmax(nhhmem, 1, na.rm = TRUE))
  )

# Assign quintiles within each wave using population weights
assign_quintiles <- function(data) {
  data <- data %>% filter(!is.na(eq_income) & !is.na(hpopwgt))

  # Weighted quintile breaks
  breaks <- Hmisc::wtd.quantile(
    data$eq_income,
    weights = data$hpopwgt,
    probs = c(0, 0.2, 0.4, 0.6, 0.8, 1)
  )

  data$quintile <- cut(
    data$eq_income,
    breaks = breaks,
    labels = c("Q1", "Q2", "Q3", "Q4", "Q5"),
    include.lowest = TRUE
  )

  return(data)
}

df <- df %>%
  group_by(wave) %>%
  group_modify(~ assign_quintiles(.x)) %>%
  ungroup()

# -----------------------------------------------------------------------------
# 3. Compute weighted means of asset components by quintile and wave
# -----------------------------------------------------------------------------

# Key asset/liability components for decomposition
asset_vars <- c(
  "hanr",   # real estate (total)
  "hanrp",  # principal residence
  "hanro",  # other real estate
  "hafis",  # stocks and equity
  "hafc",   # deposits and cash
  "hafi",   # financial investments (broader)
  "hannb",  # business equity
  "hlr",    # mortgage (real estate liabilities)
  "hln",    # non-housing liabilities
  "hl",     # total liabilities
  "dnw",    # disposable net worth
  "ha",     # total assets
  "han",    # non-financial assets
  "haf"     # financial assets
)

# Weighted mean function
wmean <- function(x, w) {
  idx <- !is.na(x) & !is.na(w)
  if (sum(idx) == 0) return(NA_real_)
  sum(x[idx] * w[idx]) / sum(w[idx])
}

# Compute means by wave x quintile
summary_qw <- df %>%
  group_by(wave, quintile) %>%
  summarise(
    n_hh = n(),
    across(
      all_of(asset_vars),
      ~ wmean(.x, hpopwgt),
      .names = "mean_{.col}"
    ),
    .groups = "drop"
  )

# Also compute overall means by wave (all quintiles pooled)
summary_w <- df %>%
  group_by(wave) %>%
  summarise(
    n_hh = n(),
    quintile = "All",
    across(
      all_of(asset_vars),
      ~ wmean(.x, hpopwgt),
      .names = "mean_{.col}"
    ),
    .groups = "drop"
  )

summary_all <- bind_rows(summary_qw, summary_w) %>%
  arrange(wave, quintile)

# -----------------------------------------------------------------------------
# 4. Print summary: levels by wave and quintile
# -----------------------------------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("TABLE 1: Mean Wealth Components by Income Quintile and Wave (USD)\n")
cat("================================================================\n\n")

print(as.data.frame(summary_all), row.names = FALSE)

# -----------------------------------------------------------------------------
# 5. Compute changes (post - pre) by quintile
# -----------------------------------------------------------------------------

changes <- summary_all %>%
  pivot_wider(
    id_cols = quintile,
    names_from = wave,
    values_from = starts_with("mean_")
  ) %>%
  mutate(
    # Changes in levels
    chg_hanr   = mean_hanr_post   - mean_hanr_pre,
    chg_hafis  = mean_hafis_post  - mean_hafis_pre,
    chg_hafc   = mean_hafc_post   - mean_hafc_pre,
    chg_hafi   = mean_hafi_post   - mean_hafi_pre,
    chg_hannb  = mean_hannb_post  - mean_hannb_pre,
    chg_hlr    = mean_hlr_post    - mean_hlr_pre,
    chg_hln    = mean_hln_post    - mean_hln_pre,
    chg_dnw    = mean_dnw_post    - mean_dnw_pre,
    chg_ha     = mean_ha_post     - mean_ha_pre,
    # Percentage changes
    pct_chg_hanr  = chg_hanr  / abs(mean_hanr_pre)  * 100,
    pct_chg_hafis = chg_hafis / abs(mean_hafis_pre) * 100,
    pct_chg_hafc  = chg_hafc  / abs(mean_hafc_pre)  * 100,
    pct_chg_dnw   = chg_dnw   / abs(mean_dnw_pre)   * 100
  )

cat("\n")
cat("================================================================\n")
cat("TABLE 2: Change in Mean Wealth Components, Pre to Post (USD)\n")
cat("================================================================\n\n")

changes_print <- changes %>%
  select(quintile, chg_hanr, chg_hafis, chg_hafc, chg_hannb,
         chg_hlr, chg_hln, chg_dnw)
print(as.data.frame(changes_print), row.names = FALSE)

cat("\n")
cat("================================================================\n")
cat("TABLE 3: Percentage Change in Key Components, Pre to Post\n")
cat("================================================================\n\n")

pct_print <- changes %>%
  select(quintile, pct_chg_hanr, pct_chg_hafis, pct_chg_hafc, pct_chg_dnw)
print(as.data.frame(pct_print), row.names = FALSE)

# -----------------------------------------------------------------------------
# 6. Asset composition shares (portfolio structure) by quintile
# -----------------------------------------------------------------------------

shares <- summary_all %>%
  mutate(
    shr_housing  = mean_hanr  / mean_ha * 100,
    shr_equity   = mean_hafis / mean_ha * 100,
    shr_deposits = mean_hafc  / mean_ha * 100,
    shr_business = mean_hannb / mean_ha * 100,
    shr_other_fin = (mean_haf - mean_hafc - mean_hafis) / mean_ha * 100
  ) %>%
  select(wave, quintile, shr_housing, shr_equity, shr_deposits,
         shr_business, shr_other_fin)

cat("\n")
cat("================================================================\n")
cat("TABLE 4: Asset Composition (% of Total Assets) by Quintile\n")
cat("================================================================\n\n")

print(as.data.frame(shares), row.names = FALSE)

# -----------------------------------------------------------------------------
# 7. Shift-share exposure calculation
#    Exposure = sum_k (pre_share_k * global_shock_k)
#    where k = asset class, pre_share = portfolio weight, shock = % change
# -----------------------------------------------------------------------------

# Compute quintile-level portfolio shares (pre-pandemic only) and
# asset-class-level shocks (overall % change pre to post)

pre_shares <- summary_all %>%
  filter(wave == "pre") %>%
  mutate(
    w_housing  = mean_hanr  / mean_ha,
    w_equity   = mean_hafis / mean_ha,
    w_deposits = mean_hafc  / mean_ha,
    w_business = mean_hannb / mean_ha
  ) %>%
  select(quintile, w_housing, w_equity, w_deposits, w_business)

# Overall (all-quintile) percentage changes as the "shock" vector
overall_shocks <- changes %>%
  filter(quintile == "All") %>%
  transmute(
    shock_housing  = pct_chg_hanr / 100,
    shock_equity   = pct_chg_hafis / 100,
    shock_deposits = pct_chg_hafc / 100,
    shock_business = chg_hannb / abs(mean_hannb_pre) # compute manually
  )

# Shift-share exposure by quintile
exposure <- pre_shares %>%
  mutate(
    exp_housing  = w_housing  * overall_shocks$shock_housing,
    exp_equity   = w_equity   * overall_shocks$shock_equity,
    exp_deposits = w_deposits * overall_shocks$shock_deposits,
    exp_business = w_business * overall_shocks$shock_business,
    exposure_total = exp_housing + exp_equity + exp_deposits + exp_business
  )

cat("\n")
cat("================================================================\n")
cat("TABLE 5: Shift-Share Wealth Exposure by Income Quintile\n")
cat("  (pre-pandemic portfolio share * overall asset-class shock)\n")
cat("================================================================\n\n")

print(as.data.frame(exposure), row.names = FALSE)

# -----------------------------------------------------------------------------
# 8. Observation counts and data quality checks
# -----------------------------------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("DATA QUALITY CHECKS\n")
cat("================================================================\n\n")

# Observation counts
cat("Observations per wave:\n")
df %>% count(wave) %>% print(row.names = FALSE)

cat("\nObservations per wave x quintile:\n")
df %>% count(wave, quintile) %>% print(row.names = FALSE)

# Missing rates for key variables
cat("\nMissing rates (% of observations):\n")
miss_rates <- df %>%
  group_by(wave) %>%
  summarise(
    across(
      all_of(c("dhi", "dnw", "hanr", "hafis", "hafc", "hannb", "hl")),
      ~ mean(is.na(.x)) * 100,
      .names = "pct_miss_{.col}"
    ),
    .groups = "drop"
  )
print(as.data.frame(miss_rates), row.names = FALSE)

cat("\n\n=== END OF LISSY OUTPUT ===\n")
