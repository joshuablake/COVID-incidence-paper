suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("figures/utils.R"))

model_output_dir = here::here("model-outputs")

tbl_phenomenological = load_backcalc_regions() |>
    filter(daynr > 1, region == "England")

full_predict = load_seir_predictive()
tbl_mechanistic = full_predict |>
    poststratify_SEIR(load_poststrat_table(), new_pcr_pos)

p_incidence = bind_rows(
    tbl_phenomenological |>
        mutate(model = "Phenomenological"),
    tbl_mechanistic |>
        mutate(model = "Mechanistic") |>
        rename(incidence = val),
) |>
    ggplot(aes(date, incidence, colour = model, fill = model)) +
    stat_lineribbon(alpha = 0.4, linewidth = 0.2, .width = 0.95) +
    standard_plot_theming() +
    theme(legend.position = "bottom") +
    scale_y_continuous(labels = scales::label_percent()) +
    labs(
        x = "Date (2020-1)",
        y = "Incidence proportion",
        fill = "",
        colour = ""
    ) +
    # make boxes of colour in the legend smaller
    theme(legend.key.size = unit(0.5, "cm"))

ggsave(
    filename = here::here("figures", "incidence.pdf"),
    width = 8.7,
    height = 5.5,
    units = "cm",
    dpi = 300
)
