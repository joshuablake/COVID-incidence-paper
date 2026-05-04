model_output_dir = here::here("model-outputs")

standard_plot_theming = function() {
    rlang::list2(
        theme_minimal(),
        ggplot2::theme(text = ggplot2::element_text(size = 7)),
    )
}

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


logit = function(x) log(x) - log(1 - x)
expit = function(x) 1 / (1 + exp(-x))

load_backcalc_regions = function() {
    readRDS(file.path(model_output_dir, "phenomenological", "region.rds")) |>
    dplyr::mutate(
        region = normalise_region_names(region),
    )
}

load_backcalc_age = function() {
    readRDS(file.path(model_output_dir, "phenomenological", "age.rds")) |>
    dplyr::mutate(
        age_group = normalise_age_groups(age_group),
    )
}

load_backcalc_region_age = function() {
    readRDS(file.path(model_output_dir, "phenomenological", "region_age.rds")) |>
    dplyr::mutate(
        region = normalise_region_names(region),
        age_group = normalise_age_groups(age_group),
    )
}

load_seir_predictive = function() {
    readr::read_csv(
        here::here("model-outputs", "mechanistic", "predictive.csv.gz"),
        col_types = readr::cols(
            region = readr::col_character(),
            chain = readr::col_integer(),
            iteration = readr::col_integer(),
            age = readr::col_character(),
            incidence = readr::col_double(),
            prevalence = readr::col_double()
        )
    ) |>
        filter(iteration %% 20e3 == 0, iteration >= 1e6) |> # thin chains, remove burn-in
        dplyr::mutate(
            .chain = factor(chain + 1),
            .iteration = iteration + 1,
            .draw = max(.iteration) * (as.integer(.chain) - 1) + .iteration,
            age_group = normalise_age_groups(age),
            region = normalise_region_names(region)
        ) |>
        dplyr::select(!c(chain, iteration, age)) |>
        rename(date = day)
}

normalise_region_names = function(in_names) {
    out = stringr::str_replace_all(in_names, "_", " ") |>
        stringr::str_replace_all(" England", "") |>
        dplyr::case_match(
            c("1_NE", "North East") ~ "North East",
            c("2_NW", "North West") ~ "North West",
            c("3_YH", "Yorkshire and the Humber", "Yorkshire") ~ "Yorkshire",
            c("4_EM", "East Midlands") ~ "East Midlands",
            c("5_WM", "West Midlands") ~ "West Midlands",
            c("6_EE", "East of England", "East", "East of") ~ "East of England",
            c("7_LD", "London") ~ "London",
            c("8_SE", "South East") ~ "South East",
            c("9_SW", "South West") ~ "South West",
            c("0_Eng", "England") ~ "England"
        )
    stopifnot(!is.na(out))
    return(out)
}

normalise_age_groups = function(in_names) {
    paste0("[", stringr::str_sub(in_names, 2, -2), ")") |>
        stringr::str_replace(stringr::fixed("+"), "Inf") |>
        stringr::str_replace(stringr::fixed(", "), ",") |>
        stringr::str_replace(stringr::fixed("[1,"), "[0,") |>
        dplyr::case_match(
            "[0,11)" ~ "0–11",
            "[11,16)" ~ "12–16",
            "[16,25)" ~ "17–25",
            "[25,50)" ~ "26–50",
            "[50,70)" ~ "51–70",
            "[70,Inf)" ~ "71+",
        )
}

load_poststrat_table = function() {
    readr::read_csv(here::here("model-outputs", "poststrat.csv"), show_col_types = FALSE) |>
        dplyr::filter(!Region_Name %in% c("Wales", "Scotland", "Northern_Ireland")) |>
        dplyr::mutate(
            region = normalise_region_names(Region_Name),
            age_group = normalise_age_groups(age_group),
        ) |>
        dplyr::select(!c(.groups, Region_Name))
}

poststratify_SEIR = function(data, poststrat_table, col, ...) {
    poststrat_table |>
        summarise(
            pop = sum(pop),
            .by = c("region", "age_group")
        ) |>
        dplyr::right_join(
            data,
            by = c("region", "age_group"),
            relationship = "one-to-many"
        ) |>
        # filter(is.na(pop)) |>
        # print()
        assertr::assert(assertr::not_na, pop) |>
        dplyr::mutate(n = {{ col }} * pop) |>
        dplyr::group_by(date, .draw, !!!ensyms(...)) |>
        dplyr::summarise(
            N = sum(pop),
            val = sum(n) / N,
            .groups = "drop"
        )
}

save_plot = function(
    filename, plot, dir = here::here("figures"),
    width = 8.7, height = 5.5, units = "cm", dpi = 1000,
    device = cairo_pdf, full_page = FALSE, ...
) {
    if (full_page) {
        width = 7
        height = 8.5
        units = "in"
    }
    ggplot2::ggsave(
        filename = file.path(dir, filename),
        plot = plot,
        width = width,
        height = height,
        units = units,
        dpi = dpi,
        device = device,
        ...
    )
}

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
