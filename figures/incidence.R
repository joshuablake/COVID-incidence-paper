suppressMessages(library(dplyr))
library(ggplot2)
library(patchwork)
library(tidybayes)
library(tidyr)
source(here::here("figures/utils.R"))

incidence_plot_theming = function() {
    rlang::list2(
        standard_plot_theming(),
        labs(
            x = "Date (2020-1)",
            y = "Incidence proportion",
            fill = "",
            colour = ""
        ),
        scale_y_continuous(labels = scales::label_percent())
    )
}

model_output_dir = here::here("model-outputs")

tbl_phenomenological_England = load_backcalc_regions() |>
    filter(daynr > 1, region == "England")
tbl_phenomenological_NE_age = load_backcalc_region_age() |>
    filter(daynr > 1, region == "North East")
tbl_phenomenological_age = load_backcalc_age() |>
    filter(daynr > 1)

full_predict = load_seir_predictive()
poststrat_table = load_poststrat_table()
tbl_mechanistic_England = full_predict |>
    poststratify_SEIR(poststrat_table, new_pcr_pos)
tbl_mechanistic_age = full_predict |>
    poststratify_SEIR(poststrat_table, new_pcr_pos, age_group)
tbl_mechanistic_NE_age = full_predict |>
    filter(region == "North East") |>
    poststratify_SEIR(poststrat_table, new_pcr_pos, age_group)

p_incidence_England = bind_rows(
    tbl_phenomenological_England |>
        mutate(model = "Phenomenological"),
    tbl_mechanistic_England |>
        mutate(model = "Mechanistic") |>
        rename(incidence = val),
) |>
    ggplot(aes(date, incidence, colour = model, fill = model)) +
    stat_lineribbon(alpha = 0.4, linewidth = 0.2, .width = 0.95) +
    incidence_plot_theming()

p_incidence_regions = bind_rows(
    tbl_phenomenological_age |>
        mutate(model = "Phenomenological"),
    tbl_mechanistic_age |>
        mutate(model = "Mechanistic") |>
        rename(incidence = val),
) |>
    ggplot(aes(date, incidence, colour = model, fill = model)) +
    stat_lineribbon(alpha = 0.4, linewidth = 0.2, .width = 0.95) +
    facet_wrap(~age_group) +
    incidence_plot_theming() +
    theme(axis.title.y = element_blank())

p_combined = p_incidence_England +
    p_incidence_England_age +
    # p_NE_age +
    plot_layout(
        guides = "collect",
        widths = c(1, 1.3)
    ) +
    plot_annotation(
        tag_levels = 'A',
    ) &
    theme(legend.position = "bottom")

save_plot(
    filename = "incidence.pdf",
    plot = p_combined,
    width = 17.6,
    height = 7
)

p_NE_age = bind_rows(
    tbl_phenomenological_NE_age |>
        mutate(model = "Phenomenological"),
    tbl_mechanistic_NE_age |>
        mutate(model = "Mechanistic") |>
        rename(incidence = val),
) |>
    ggplot(aes(date, incidence, colour = model, fill = model)) +
    stat_lineribbon(alpha = 0.4, linewidth = 0.2, .width = 0.95) +
    facet_wrap(~age_group) +
    incidence_plot_theming()

save_plot(
    filename = "NE.pdf",
    plot = p_NE_age,
    height = 7
)