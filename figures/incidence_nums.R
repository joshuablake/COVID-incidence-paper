suppressMessages(library(dplyr))
library(lubridate)
library(tidybayes)
library(tidyr)
source(here::here("figures/utils.R"))

tbl_phenomenological_England = load_backcalc_regions() |>
    filter(daynr > 1, region == "England")
# tbl_phenomenological_regions = load_backcalc_regions() |>
#     filter(daynr > 1, region != "England")
tbl_phenomenological_age = load_backcalc_age() |>
    filter(daynr > 1)

full_predict = load_seir_predictive()
poststrat_table = load_poststrat_table()
tbl_mechanistic_England = full_predict |>
    poststratify_SEIR(poststrat_table, new_pcr_pos)
# tbl_mechanistic_regions = full_predict |>
#     poststratify_SEIR(poststrat_table, new_pcr_pos, region)
tbl_mechanistic_age = full_predict |>
    poststratify_SEIR(poststrat_table, new_pcr_pos, age_group)

tbl_England = bind_rows(
    tbl_phenomenological_England |>
        mutate(method = "Phenomenological"),
    tbl_mechanistic_England |>
        mutate(method = "Mechanistic") |>
        rename(incidence = val),
)
tbl_age = bind_rows(
    tbl_phenomenological_age |>
        mutate(method = "Phenomenological"),
    tbl_mechanistic_age |>
        mutate(method = "Mechanistic") |>
        rename(incidence = val),
)

print("Peak autumn incidence proportion")
tbl_England |>
    filter(date < "2020-12-01") |>
    summarise(
        peak_incidence_per = max(incidence) * 100,
        .by = c(.draw, method)
    ) |>
    group_by(method) |>
    median_qi(peak_incidence_per)

print("Peak Dec/Jan incidence proportion")
tbl_England |>
    filter(date > "2020-12-01") |>
    summarise(
        peak_incidence_per = max(incidence) * 100,
        peak_incidence_day = as.integer(date[which.max(incidence)]),
        .by = c(.draw, method)
    ) |>
    group_by(method) |>
    median_qi(day = peak_incidence_day, height = peak_incidence_per) |>
    ungroup() |>
    mutate(across(contains("day"), as_date)) |>
    print(width = Inf)


print("Max/minober 12--16 year old incidence in mechanistic during Oct/Nov")
tbl_mechanistic_age |>
    filter(between(date, ymd("2020-10-01"), ymd("2020-11-15")), age_group == "12–16") |>
    summarise(
        max_val = max(val),
        max_day = as.integer(date[which.max(val)]),
        min_val = min(val),
        min_day = as.integer(date[which.min(val)]),
        .by = c(.draw)
    ) |>
    median_qi(max_val, max_day, min_val, min_day) |>
    ungroup() |>
    mutate(across(contains("day"), as_date)) |>
    print(width = Inf)
tbl_age |>
    filter(between(date, ymd("2020-10-18"), ymd("2020-11-01")), age_group == "12–16") |>
    summarise(
        cum_inc = sum(incidence),
        .by = c(.draw, method)
    ) |>
    group_by(method) |>
    median_qi(cum_inc)
