#************************************************************************
# Purpose:     Generate ADADAS dataset
# Input:       DM, QS, and ADSL datasets
# Output:      adadas.rds
#************************************************************************

# Note to Reviewer
# To rerun the code below, please refer ADRG appendix.
# After required package are installed, the path variable needs to be defined
# in the .Rprofile file

# Setup -----------------
## Load libraries -------
library(dplyr)
library(tidyr)
library(admiral)
library(metacore)
library(metatools)
library(stringr)
library(xportr)
library(datasetjson)
library(purrr)

## Load datasets ------------
dat_to_load <- list(
  dm = file.path(path$sdtm, "dm.rds"),
  qs = file.path(path$sdtm, "qs.rds"),
  adsl = file.path(path$adam, "adsl.rds")
)

datasets <- map(
  dat_to_load,
  ~ convert_blanks_to_na(readRDS(.x))
)

list2env(datasets, envir = .GlobalEnv)

## Load dataset specs -----------
metacore <- spec_to_metacore(
  file.path(path$adam, "adam-pilot-5.xlsx"),
  where_sep_sheet = FALSE
)

### Get the specifications for the dataset we are currently building
adadas_spec <- metacore %>%
  select_dataset("ADADAS")

### Pull together all the predecessor variables
adadas_pred <- build_from_derived(
  adadas_spec,
  ds_list = list("ADSL" = adsl, "QS" = qs, "DM" = dm)
)

# Create ADADAS dataset -----------------
## Derive ADY and ADT -------------------
adas1 <- adadas_pred %>%
  derive_vars_merged(
    dataset_add = qs,
    new_vars = exprs(QSDTC, QSSTRESN, QSTEST),
    by_vars = exprs(STUDYID, USUBJID, QSSEQ)
  ) %>%
  filter(
    PARAMCD %in%
      c(str_c("ACITM", str_pad(1:14, 2, pad = "0")), "ACTOT")
  ) %>%
  # ADT
  derive_vars_dt(
    new_vars_prefix = "A",
    dtc = QSDTC
  ) %>%
  # ADY
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ADT))

## Derive AVISIT, AVAL, PARAM, AVISITN, PARAMN ----------
adas2 <- adas1 %>%
  mutate(
    AVISIT = case_when(
      ADY <= 1 ~ "Baseline",
      ADY >= 2 & ADY <= 84 ~ "Week 8",
      ADY >= 85 & ADY <= 140 ~ "Week 16",
      ADY > 140 ~ "Week 24",
      TRUE ~ NA_character_
    ),
    AVAL = QSSTRESN,
    PARAM = QSTEST %>% str_to_title()
  ) %>%
  create_var_from_codelist(adadas_spec, AVISIT, AVISITN) %>%
  create_var_from_codelist(adadas_spec, PARAM, PARAMN)

## Derive AWRANGE, AWTARGET, AWTDIFF, AWLO, AWHI, AWU -----------
aw_lookup <- tribble(
  ~AVISIT, ~AWRANGE, ~AWTARGET, ~AWLO, ~AWHI,
  "Baseline", "<=1", 1, NA_integer_, 1,
  "Week 8", "2-84", 56, 2, 84,
  "Week 16", "85-140", 112, 85, 140,
  "Week 24", ">140", 168, 141, NA_integer_
)

adas3 <- derive_vars_merged(
  adas2,
  dataset_add = aw_lookup,
  by_vars = exprs(AVISIT)
) %>%
  mutate(
    AWTDIFF = abs(AWTARGET - ADY),
    AWU = "DAYS"
  )

## Derive ANL01FL -----------
adas4 <- adas3 %>%
  mutate(diff = AWTARGET - ADY) %>%
  restrict_derivation(
    derivation = derive_var_extreme_flag,
    args = params(
      by_vars = exprs(USUBJID, PARAMCD, AVISIT),
      order = exprs(AWTDIFF, diff),
      new_var = ANL01FL,
      mode = "first"
    ),
    filter = !is.na(AVISIT)
  )

## Derive PARAMCD=ACTOT, DTYPE=LOCF -------------
# A dataset with combinations of PARAMCD, AVISIT which are expected.
actot_expected_obsv <- tibble::tribble(
  ~PARAMCD, ~AVISITN, ~AVISIT,
  "ACTOT", 0, "Baseline",
  "ACTOT", 8, "Week 8",
  "ACTOT", 16, "Week 16",
  "ACTOT", 24, "Week 24"
)

adas_locf2 <- adas4 %>%
  restrict_derivation(
    derivation = derive_locf_records,
    args = params(
      dataset_ref = actot_expected_obsv,
      by_vars = exprs(
        STUDYID, SITEID, SITEGR1, USUBJID, TRTSDT, TRTEDT,
        TRTP, TRTPN, AGE, AGEGR1, AGEGR1N, RACE, RACEN, SEX,
        ITTFL, EFFFL, COMP24FL, PARAMCD
      ),
      order = exprs(AVISITN, AVISIT),
      keep_vars = exprs(VISIT, VISITNUM, ADY, ADT, PARAM, PARAMN, QSSEQ)
    ),
    filter = !is.na(ANL01FL)
  ) %>%
  # assign ANL01FL for new records
  mutate(ANL01FL = if_else(is.na(DTYPE), ANL01FL, "Y")) %>%
  # re-derive AWRANGE/AWTARGET/AWTDIFF/AWLO/AWHI/AWU
  select(-c("AWRANGE", "AWTARGET", "AWLO", "AWHI")) %>%
  derive_vars_merged(
    dataset_add = aw_lookup,
    by_vars = exprs(AVISIT)
  ) %>%
  mutate(
    AWTDIFF = abs(AWTARGET - ADY),
    AWU = "DAYS"
  )

## Derive BASE, CHG, PCHG -----------
adas5 <- adas_locf2 %>%
  # Calculate BASE
  derive_var_base(
    by_vars = exprs(STUDYID, USUBJID, PARAMCD),
    source_var = AVAL,
    new_var = BASE
  ) %>%
  # Calculate CHG
  restrict_derivation(
    derivation = derive_var_chg,
    filter = is.na(ABLFL)
  ) %>%
  # Calculate PCHG
  restrict_derivation(
    derivation = derive_var_pchg,
    filter = is.na(ABLFL)
  ) %>%
  ungroup()

# Export to xpt ---------------
adas <- adas5 %>%
  convert_na_to_blanks() %>%
  drop_unspec_vars(adadas_spec) %>%
  sort_by_key(adadas_spec) %>%
  check_ct_data(adadas_spec, na_acceptable = TRUE) %>%
  xportr_label(adadas_spec) %>%
  xportr_order(adadas_spec) %>%
  xportr_format(adadas_spec) %>%
  xportr_df_label(adadas_spec, domain = "adadas")


# FIX: attribute issues where sas.format attributes set to DATE9. are changed to DATE9,
# and missing formats are set to NULL (instead of an empty character vector)
# when reading original xpt file
for (col in colnames(adas)) {
  if (attr(adas[[col]], "format.sas") == "") {
    attr(adas[[col]], "format.sas") <- NULL
  } else if (attr(adas[[col]], "format.sas") == "DATE9.") {
    attr(adas[[col]], "format.sas") <- "DATE9"
  }
}

# Saving the dataset as rds format --------------
saveRDS(adas, file.path(path$adam, "adadas.rds"))
