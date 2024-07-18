library(dplyr)
library(ggdist)
library(ggplot2)
library(purrr)
library(lubridate)
library(tidyr)
source(here::here("figures/utils.R"))

start_date = ymd("2020-08-31")

tbl_rw = readr::read_csv(here::here("model-outputs", "mechanistic", "params.csv")) |>
    # Find beta parameters and parse name index
    filter(
        stringr::str_starts(parameter, "beta"),
        iteration >= 500e3,
        region == "London"
    ) |>
    extract(
        parameter,
        into = c("parameter", "i"), 
        regex = "^([^\\[]+)(\\[[0-9]+\\])?$"
    ) |>
    transmute(
        region = normalise_region_names(region),
        # Convert 0-indexed (python) numbers to 1-indexed (R) numbers
        .chain = factor(chain + 1),
        .iteration = iteration + 1,
        .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
        # Parse index of beta
        i = if_else(
            i == "",
            NA_integer_,
            # Remove first and last character from i
            as.integer(substr(i, 2, nchar(i) - 1))
        ),
        value,
    ) |>
    # Converted from non-centered log-scale in the model to
    # centered natural scale for processing
    mutate(
        .by = c(region, .draw),
        value = if_else(
            i == 0,
            0,
            value * exp(value[i == 0])
        ),
    ) |>
    # RW1 hence cumulative sum gives actual value
    group_by(region, .draw) |>
    arrange(i, .by_group = TRUE) |>
    mutate(
        beta = value |>
            cumsum() |>
            exp()
    )

# A violin plot of the posterior distribution of beta for each region and week.
p_walk = tbl_rw |>
    mutate(date = start_date + i * 7) |>
    ggplot(aes(factor(date), beta)) +
    stat_slab(side = "both") +
    standard_plot_theming() +
    scale_y_log10(
        breaks = c(0.5, 1, 2, 0.67, 1.5),
        limits = c(0.5, NA),
        minor_breaks = numeric()
    ) +
    # tick labels every 3 weeks
    scale_x_discrete(
        breaks = function(x) x[c(TRUE, rep(FALSE, 3))]
    ) +
    geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.5) +
    # Angle text for readability
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(
        x = "Date",
        y = expression(beta[t])
    )

save_plot(
    filename = "rw.pdf",
    plot = p_walk
)
