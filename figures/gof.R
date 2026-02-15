library(dplyr)
library(lubridate)
library(ggplot2)
library(patchwork)
library(purrr)
library(stringr)
library(tidybayes)
library(tidyr)
source(here::here("figures/utils.R"))

# Read posterior predictives
predictions = load_seir_predictive() |>
    select(!cutoff_date)

# Read data
data = readr::read_csv(here::here("model-outputs/mechanistic/data.csv")) |>
    filter(!region %in% c("Wales", "Scotland", "Northern_Ireland")) |>
    mutate(
        obs_prevalence = obs_positives / num_tests,
        age_group = normalise_age_groups(age),
        region = normalise_region_names(region),
    ) |>
    select(!age) |>
    filter(
        date >= min(predictions$date),
        date <= max(predictions$date),
    )

# Calculate posterior predictive intervals
prediction_intervals = predictions |>
    group_by(region, date, age_group) |>
    median_qi()

# Get theta posterior
thetas = readr::read_csv(here::here("model-outputs/mechanistic/params.csv.gz")) |>
    filter(parameter == "theta", iteration >= 1e6) |>
    transmute(
        region = normalise_region_names(region),
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        theta = exp(value)
    )

# Generate posterior predictives including sampling noise
noisy_predict = predictions |>
    left_join(data, by = join_by(region, date, age_group)) |>
    left_join(thetas, by = join_by(region, .chain, .iteration)) |>
    mutate(
        predict_out = VGAM::rbetabinom.ab(
            n = n(),
            size = num_tests,
            shape1 = prevalence / theta,
            shape2 = (1 - prevalence) / theta,
        )
    )

# Aggregate to weekly predictions because daily are too noisy to interpret
weekly_predictions = noisy_predict |>
    group_by(
        region, .draw, age_group,
        week = floor_date(date, unit = "week", week_start = "Monday") + 3,
    ) |>
    summarise(
        n = sum(num_tests),
        y = sum(obs_positives),
        p = y / n,
        pred_y = sum(predict_out),
        pred_p = pred_y / n,
        .groups = "drop"
    ) |>
    group_by(region, age_group, week) |>
    median_qi()

plot = weekly_predictions |>
    ggplot(aes(week)) +
    geom_point(aes(y = p), size = 0.5) +
    geom_ribbon(aes(ymin = pred_p.lower, ymax = pred_p.upper), alpha = 0.1) +
    geom_lineribbon(
        aes(date, prevalence, ymin = prevalence.lower, ymax = prevalence.upper),
        data = prediction_intervals,
        alpha = 0.4,
        linewidth = 0.2
    ) +
    facet_grid(region ~ age_group ) +
    standard_plot_theming() +
    labs(
        x = "Date (2020-1)",
        y = "Prevalence"
    ) +
    theme(
        legend.position = "none",
        strip.text = element_text(size = 7),
        axis.text.x = element_text(angle = 45, hjust = 1)
    )

save_plot(
    filename = "gof.pdf",
    plot = plot,
    full_page = TRUE
)

weekly_predictions |>
    ungroup() |>
    mutate(
        predict_correct = between(y, pred_y.lower, pred_y.upper),
    ) |>
    summarise(
        n = n(),
        n_correct = sum(predict_correct),
        p_correct = n_correct / n(),
    )
