suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("figures/utils.R"))

tbl_phenomenological_England = load_backcalc_regions() |>
    filter(daynr > 1, region == "England")
tbl_phenomenological_regions = load_backcalc_regions() |>
    filter(daynr > 1, region != "England")
tbl_phenomenological_age = load_backcalc_age() |>
    filter(daynr > 1)

full_predict = load_seir_predictive()
poststrat_table = load_poststrat_table()

p_incidence_England = bind_rows(
    tbl_phenomenological_England |>
        mutate(model = "Phenomenological"),
    full_predict |>
        poststratify_SEIR(poststrat_table, new_pcr_pos) |>
        mutate(model = "Mechanistic") |>
        rename(incidence = val),
) |>
    ggplot(aes(date, incidence, colour = model, fill = model)) +
    stat_lineribbon(alpha = 0.4, linewidth = 0.2, .width = 0.95) +
    incidence_plot_theming() +
    theme(legend.position = "bottom")

save_plot(
    filename = "incidence_England.pdf",
    plot = p_incidence_England,
    height = 7
)

p_incidence_age = bind_rows(
    tbl_phenomenological_age |>
        mutate(model = "Phenomenological"),
    full_predict |>
        poststratify_SEIR(poststrat_table, new_pcr_pos, age_group) |>
        mutate(model = "Mechanistic") |>
        rename(incidence = val),
) |>
    ggplot(aes(date, incidence, colour = model, fill = model)) +
    stat_lineribbon(alpha = 0.4, linewidth = 0.2, .width = 0.95) +
    facet_wrap(~age_group, nrow = 3) +
    incidence_plot_theming() +
    theme(axis.title.y = element_blank())

p_incidence_regions = bind_rows(
    tbl_phenomenological_regions |>
        mutate(model = "Phenomenological"),
    full_predict |>
        poststratify_SEIR(poststrat_table, new_pcr_pos, region) |>
        mutate(model = "Mechanistic") |>
        rename(incidence = val),
) |>
    ggplot(aes(date, incidence, colour = model, fill = model)) +
    stat_lineribbon(alpha = 0.4, linewidth = 0.2, .width = 0.95) +
    facet_wrap(~region, nrow = 3) +
    incidence_plot_theming()

p_combined = p_incidence_regions +
    p_incidence_age +
    plot_layout(
        guides = "collect",
        widths = c(3, 2)
    ) +
    plot_annotation(
        tag_levels = 'A',
    ) &
    theme(legend.position = "bottom")

save_plot(
    filename = "incidence_stratified.pdf",
    plot = p_combined,
    width = 17.6,
    height = 13
)
