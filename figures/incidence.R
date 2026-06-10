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

df_incidence = bind_rows(
    tbl_phenomenological_England |>
        mutate(model = "Phenomenological"),
    full_predict |>
        poststratify_SEIR(poststrat_table, new_pcr_pos) |>
        mutate(model = "Mechanistic") |>
        rename(incidence = val),
)
p_incidence_England = df_incidence |>
    ggplot(aes(date, incidence, colour = model, fill = model)) +
    stat_lineribbon(alpha = 0.4, linewidth = 0.5, .width = 0.95) +
    incidence_plot_theming() +
    theme(legend.position = "bottom")

save_plot(
    filename = "incidence_England.pdf",
    plot = p_incidence_England,
    height = 7
)


spaghetti_plot = function(
    model, n_draws = 50,
    start_date = lubridate::as_date("2020-12-01"),
    end_date = lubridate::as_date("2021-01-15")
) {
    draw_nums = df_incidence |>
        filter(model == !!model) |>
        distinct(.draw) |>
        pull(.draw)
    df_incidence |>
        filter(
            model == !!model, .draw %in% sample(draw_nums, n_draws),
            between(date, start_date, end_date)
        ) |>
        ggplot(aes(date, incidence, group = .draw, colour = as.factor(.draw))) +
        geom_line(alpha = 0.3, linewidth = 0.5) +
        incidence_plot_theming() +
        theme(legend.position = "none")
        # scale_y_continuous(
        #     breaks = scales::breaks_extended(10),
        #     labels = scales::label_percent(accuracy = 0.01)
        # )
}
p_spaghetti = spaghetti_plot("Mechanistic") / spaghetti_plot("Phenomenological") +
    plot_layout(guides = "collect") +
    plot_annotation(tag_levels = 'A')
save_plot(
    filename = "spaghetti.pdf",
    plot = p_spaghetti,
    full_page = TRUE
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
    stat_lineribbon(alpha = 0.4, linewidth = 0.5, .width = 0.95) +
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
    stat_lineribbon(alpha = 0.4, linewidth = 0.5, .width = 0.95) +
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
