# =============================================================================
# Session_lws_us_exploration.R
# Purpose: LISSY query — US LWS wealth decomposition (proof of concept)
# Reads:   LWS us19wh, us22wh (household-level wealth files)
# Outputs: Printed summary tables (returned via LISSY job output)
#
# Submit this script to LISSY at:
#   https://www.lisdatacenter.org/data-access/lissy/
#
# LISSY notes:
#   - read.LIS() works for both LIS and LWS datasets
#   - LWS data has implicates (inum variable) — average across implicates
#   - dplyr is available (dependency of lissyrtools)
#   - Hmisc is NOT confirmed — use manual weighted quantile
#   - Output is plain ASCII only (printed to job log)
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
#   inum   = implicate number (LWS multiply-imputed data)
# =============================================================================

library(dplyr)
library(tidyr)

# -----------------------------------------------------------------------------
# Helper: weighted quantile (no Hmisc dependency)
# -----------------------------------------------------------------------------
weighted_quantile <- function(x, w, probs) {
  idx <- !is.na(x) & !is.na(w) & w > 0
  x <- x[idx]
  w <- w[idx]
  ord <- order(x)
  x <- x[ord]
  w <- w[ord]
  cum_w <- cumsum(w) / sum(w)
  sapply(probs, function(p) {
    if (p <= 0) return(min(x))
    if (p >= 1) return(max(x))
    i <- which(cum_w >= p)[1]
    x[i]
  })
}

# Weighted mean function
wmean <- function(x, w) {
  idx <- !is.na(x) & !is.na(w)
  if (sum(idx) == 0) return(NA_real_)
  sum(x[idx] * w[idx]) / sum(w[idx])
}

# -----------------------------------------------------------------------------
# 1. Load US LWS household data — pre and post pandemic
#    read.LIS() works for both LIS and LWS; dataset alias determines source
# -----------------------------------------------------------------------------

us19 <- read.LIS("us19wh")
us22 <- read.LIS("us22wh")

# Tag waves
us19$wave <- "pre"
us22$wave <- "post"

# Combine
df <- bind_rows(us19, us22)

# Check what variables are available
cat("================================================================\n")
cat("AVAILABLE VARIABLES IN DATASET\n")
cat("================================================================\n\n")
cat("Columns:", paste(names(df), collapse = ", "), "\n\n")

# -----------------------------------------------------------------------------
# 2. Handle implicates
#    LWS data is multiply imputed. The inum variable identifies implicates.
#    Strategy: compute statistics within each implicate, then average across.
#    For this exploratory script, we first average wealth values across
#    implicates at the household level, then proceed with analysis.
# -----------------------------------------------------------------------------

# Check if inum exists and how many implicates
if ("inum" %in% names(df)) {
  cat("Implicates found. Values of inum:\n")
  print(table(df$wave, df$inum))
  cat("\n")

  # Variables to average across implicates
  wealth_vars <- c("hanr", "hanrp", "hanro", "hafis", "hafiss", "hafiso",
                   "hafc", "hafct", "hafcs", "hafi", "hafib", "hafii",
                   "hannb", "hl", "hlrp", "hlro", "hlr", "hln",
                   "dnw", "ha", "han", "haf")

  # Keep only variables that exist in the data
  wealth_vars <- wealth_vars[wealth_vars %in% names(df)]

  # Non-wealth variables to keep (take first value per household)
  id_vars <- c("hid", "dname", "hpopwgt", "nhhmem", "dhi", "wave")
  id_vars <- id_vars[id_vars %in% names(df)]

  # Average wealth across implicates within each household
  df <- df %>%
    group_by(across(all_of(id_vars))) %>%
    summarise(
      across(all_of(wealth_vars), ~ mean(.x, na.rm = TRUE)),
      .groups = "drop"
    )

  cat("After averaging implicates:", nrow(df), "household-wave observations\n\n")
} else {
  cat("No inum variable found — single implicate or non-imputed data.\n\n")
}

# -----------------------------------------------------------------------------
# 3. Construct equivalized income quintiles (within each wave)
# -----------------------------------------------------------------------------

# Equivalized income: dhi / sqrt(household size)
df <- df %>%
  mutate(
    eq_income = dhi / sqrt(pmax(nhhmem, 1, na.rm = TRUE))
  )

# Assign quintiles within each wave using population weights
assign_quintiles <- function(data) {
  data <- data %>% filter(!is.na(eq_income) & !is.na(hpopwgt))

  breaks <- weighted_quantile(
    data$eq_income,
    data$hpopwgt,
    probs = c(0, 0.2, 0.4, 0.6, 0.8, 1)
  )
  # Ensure breaks are unique (nudge duplicates)
  breaks[1] <- breaks[1] - 1
  breaks[length(breaks)] <- breaks[length(breaks)] + 1

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
# 4. Compute weighted means of asset components by quintile and wave
# -----------------------------------------------------------------------------

# Key asset/liability components for decomposition
asset_vars <- c("hanr", "hanrp", "hanro", "hafis", "hafc", "hafi",
                "hannb", "hlr", "hln", "hl", "dnw", "ha", "han", "haf")

# Keep only variables that exist
asset_vars <- asset_vars[asset_vars %in% names(df)]

# Means by wave x quintile
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

# Overall means by wave (all quintiles pooled)
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
# 5. Print summary: levels by wave and quintile
# -----------------------------------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("TABLE 1: Mean Wealth Components by Income Quintile and Wave (USD)\n")
cat("================================================================\n\n")

print(as.data.frame(summary_all), row.names = FALSE)

# -----------------------------------------------------------------------------
# 6. Compute changes (post - pre) by quintile
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
    chg_hannb  = mean_hannb_post  - mean_hannb_pre,
    chg_hlr    = mean_hlr_post    - mean_hlr_pre,
    chg_hln    = mean_hln_post    - mean_hln_pre,
    chg_dnw    = mean_dnw_post    - mean_dnw_pre,
    chg_ha     = mean_ha_post     - mean_ha_pre,
    # Percentage changes (guard against division by zero)
    pct_chg_hanr  = ifelse(abs(mean_hanr_pre) > 0,
                           chg_hanr / abs(mean_hanr_pre) * 100, NA),
    pct_chg_hafis = ifelse(abs(mean_hafis_pre) > 0,
                           chg_hafis / abs(mean_hafis_pre) * 100, NA),
    pct_chg_hafc  = ifelse(abs(mean_hafc_pre) > 0,
                           chg_hafc / abs(mean_hafc_pre) * 100, NA),
    pct_chg_dnw   = ifelse(abs(mean_dnw_pre) > 0,
                           chg_dnw / abs(mean_dnw_pre) * 100, NA)
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
# 7. Asset composition shares (portfolio structure) by quintile
# -----------------------------------------------------------------------------

shares <- summary_all %>%
  mutate(
    shr_housing  = ifelse(mean_ha > 0, mean_hanr  / mean_ha * 100, NA),
    shr_equity   = ifelse(mean_ha > 0, mean_hafis / mean_ha * 100, NA),
    shr_deposits = ifelse(mean_ha > 0, mean_hafc  / mean_ha * 100, NA),
    shr_business = ifelse(mean_ha > 0, mean_hannb / mean_ha * 100, NA),
    shr_other_fin = ifelse(mean_ha > 0,
      (mean_haf - mean_hafc - mean_hafis) / mean_ha * 100, NA)
  ) %>%
  select(wave, quintile, shr_housing, shr_equity, shr_deposits,
         shr_business, shr_other_fin)

cat("\n")
cat("================================================================\n")
cat("TABLE 4: Asset Composition (% of Total Assets) by Quintile\n")
cat("================================================================\n\n")

print(as.data.frame(shares), row.names = FALSE)

# -----------------------------------------------------------------------------
# 8. Shift-share exposure calculation
#    Exposure = sum_k (pre_share_k * global_shock_k)
#    where k = asset class, pre_share = portfolio weight, shock = % change
# -----------------------------------------------------------------------------

pre_shares <- summary_all %>%
  filter(wave == "pre" & mean_ha > 0) %>%
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
    shock_business = ifelse(!is.na(mean_hannb_pre) & abs(mean_hannb_pre) > 0,
                            chg_hannb / abs(mean_hannb_pre), NA)
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
# 9. Observation counts and data quality checks
# -----------------------------------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("DATA QUALITY CHECKS\n")
cat("================================================================\n\n")

cat("Observations per wave:\n")
df %>% count(wave) %>% as.data.frame() %>% print(row.names = FALSE)

cat("\nObservations per wave x quintile:\n")
df %>% count(wave, quintile) %>% as.data.frame() %>% print(row.names = FALSE)

# Missing rates for key variables
miss_vars <- c("dhi", "dnw", "hanr", "hafis", "hafc", "hannb", "hl")
miss_vars <- miss_vars[miss_vars %in% names(df)]

cat("\nMissing rates (% of observations):\n")
miss_rates <- df %>%
  group_by(wave) %>%
  summarise(
    across(
      all_of(miss_vars),
      ~ mean(is.na(.x)) * 100,
      .names = "pct_miss_{.col}"
    ),
    .groups = "drop"
  )
print(as.data.frame(miss_rates), row.names = FALSE)

# Median net worth by quintile (useful sanity check)
cat("\nMedian net worth (dnw) by wave x quintile:\n")
if ("dnw" %in% names(df)) {
  df %>%
    group_by(wave, quintile) %>%
    summarise(median_dnw = median(dnw, na.rm = TRUE), .groups = "drop") %>%
    as.data.frame() %>%
    print(row.names = FALSE)
}

cat("\n\n=== END OF LISSY OUTPUT ===\n")
