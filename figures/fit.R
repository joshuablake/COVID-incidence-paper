library(dplyr)
library(lubridate)
library(ggplot2)
library(patchwork)
library(purrr)
library(stringr)
library(tidybayes)
library(tidyr)
source(here::here("figures/utils.R"))

# # load dispersion parameter
# tbl_theta = readr::read_csv(here::here("model-outputs", "mechanistic", "params.csv")) |>
#     filter(parameter == "theta") |>
#     transmute(
#         region = normalise_region_names(region),
#         .chain = factor(chain + 1),
#         .iteration = iteration + 1,
#         theta = exp(value)
#     )
# # load dataset used to fit SEIR model
start_date = min(tbl_mechanistic_raw$date)
end_date = max(tbl_mechanistic_raw$date)
tbl_data = readr::read_csv(here::here("model-outputs", "mechanistic", "data.csv")) |>
    filter(
        region == "North_East_England",
        between(date, start_date, end_date),
    ) |>
    mutate(
        obs_prevalence = obs_positives / num_tests,
        age_group = normalise_age_groups(age),
        region = normalise_region_names(region),
        week = floor_date(date, unit = "week"),
    ) |>
    summarise(
        prevalence = sum(obs_positives) / sum(num_tests),
        .by = week
    ) |>
    mutate(date = week + days(3))

# # Generate posterior predictives including sampling noise
# tbl_mechanistic_predictive = tbl_mechanistic_raw |>
#     left_join(tbl_data, by = join_by(region, date, age_group)) |>
#     left_join(tbl_theta, by = join_by(region, .chain, .iteration)) |>
#     mutate(
#         predict_out = VGAM::rbetabinom.ab(
#             n = n(),
#             size = num_tests,
#             shape1 = prevalence / theta,
#             shape2 = (1 - prevalence) / theta,
#         )
#     )

tbl_mechanistic_raw = load_seir_predictive()
tbl_mechanistic = tbl_mechanistic_raw |>
    filter(region == "North East") |>
    poststratify_SEIR(load_poststrat_table(), prevalence, age_group) |>
    mutate(model = "Mechanistic") |>
    rename(prevalence = val)

tbl_backcalculation = readRDS(here::here("model-outputs", "phenomenological", "region_age.rds")) |>
    filter(region == "North East", daynr > 1) |>
    mutate(model = "Phenomenological", age_group = normalise_age_groups(age_group))

p_prev = bind_rows(
    tbl_mechanistic,
    tbl_backcalculation
) |>
    # group_by(date, age_group, model) |>
    # median_qi(prevalence)
    ggplot(aes(date, prevalence)) +
    stat_lineribbon(aes(colour = model, fill = model), alpha = 0.4, linewidth = 0.2, .width = 0.95) +
    geom_point(data = tbl_data) +
    facet_wrap(~age_group) +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(
        x = "Date",
        y = "Prevalence",
        colour = "",
        fill = ""
    ) +
    standard_plot_theming() +
    theme(legend.position = "bottom")

save_plot(
    filename = "prevalence.pdf",
    plot = p_prev,
    height = 6.5
)
