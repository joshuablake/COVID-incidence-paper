library(dplyr)
library(ggplot2)
library(patchwork)
library(purrr)
library(lubridate)
library(tidybayes)
library(tidyr)
source(here::here("figures/utils.R"))

tbl_susc = readr::read_csv(here::here("model-outputs", "mechanistic", "params.csv")) |>
    filter(parameter == "matrix_modifiers") |>
    mutate(value = exp(value), region = normalise_region_names(region)) |>
    group_by(region) |>
    median_qi(value) 

tbl_susc |>
    arrange(value)

p_susceptibility = tbl_susc |>
    ggplot(aes(region, value)) +
    geom_pointrange(aes(ymin = .lower, ymax = .upper), size = 0.1) +
    labs(
        x = "Region",
        y = "Relative susceptibility"
    ) +
    standard_plot_theming() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.5)

save_plot(
    filename = "children.pdf",
    plot = p_susceptibility
)
