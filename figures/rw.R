library(dplyr)
library(ggdist)
library(ggplot2)
library(purrr)
library(lubridate)
library(tidyr)
source(here::here("figures/utils.R"))

start_date = ymd("2020-08-31")

tbl_rw = readr::read_csv(here::here("model-outputs", "mechanistic", "params.csv.gz")) |>
    # Find beta parameters and parse name index
    filter(
        stringr::str_starts(parameter, "beta"),
        iteration >= 1e6,
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
            exp(),
        date = start_date + i * 7,
    )

create_rw_plot = function(data) {
    data |>
        group_by(date, region) |>
        median_qi(beta) |>
        ggplot(aes(factor(date), beta)) +
        geom_pointrange(aes(ymin = .lower, ymax = .upper), size = 0.1) +
        standard_plot_theming() +
        # tick labels every 3 weeks
        scale_x_discrete(
            breaks = function(x) x[c(TRUE, rep(FALSE, 3))]
        ) +
        geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.5) +
        # Angle text for readability
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
        labs(
            x = "Date",
            y = "Relative transmission"
        )
}

# A violin plot of the posterior distribution of beta for each region and week.
p_walk_London = tbl_rw |>
    filter(region == "London") |>
    create_rw_plot()
save_plot(
    filename = "rw_London.pdf",
    plot = p_walk_London
)

p_walk_other = tbl_rw |>
    filter(region != "London") |>
    create_rw_plot() +
    facet_wrap(~region, ncol = 2)
save_plot(
    filename = "rw_non-London.pdf",
    plot = p_walk_other,
    full_page = TRUE
)
