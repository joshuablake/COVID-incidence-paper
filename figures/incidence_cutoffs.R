suppressMessages(library(dplyr))
library(ggplot2)
library(readr)
source(here::here("figures/utils.R"))

# Load data
incidence_stats <- read_csv(
    here::here("model-outputs/mechanistic/incidence_summary_statistics.csv"),
    show_col_types = FALSE
) |>
    mutate(
        day = as.Date(day),
        cutoff_date = as.Date(cutoff_date)
    )

# Filter for England
england_stats <- incidence_stats |>
    filter(region == "England")

# Identify final cutoff date (Gold Standard)
final_date <- max(england_stats$cutoff_date)

# Create Gold Standard dataset (remove cutoff_date to show on all facets)
gold_standard <- england_stats |>
    filter(cutoff_date == final_date) |>
    select(-cutoff_date)

# Create dataset for panels (exclude final cutoff)
panel_data <- england_stats |>
    filter(cutoff_date < final_date)

# Plot
p_cutoffs_eng <- ggplot(panel_data, aes(x = day)) +
    # Gold Standard (Background)
    geom_ribbon(
        data = gold_standard,
        aes(ymin = q025, ymax = q975),
        fill = "grey50",
        alpha = 0.2
    ) +
    geom_line(
        data = gold_standard,
        aes(y = median),
        colour = "grey50",
        linewidth = 0.5,
        linetype = "dashed"
    ) +
    # Panel-specific estimates
    geom_ribbon(
        aes(ymin = q025, ymax = q975),
        fill = "#56B4E9", # Nice blue
        alpha = 0.4
    ) +
    geom_line(
        aes(y = median),
        linewidth = 0.5,
        colour = "#56B4E9"
    ) +
    facet_wrap(~cutoff_date) +
    incidence_plot_theming()

save_plot(
    filename = "incidence_cutoffs.pdf",
    plot = p_cutoffs_eng,
    full_page = TRUE
)

# --- Plot 2: Regions ---

# Filter for regions (not England)
region_stats <- incidence_stats |>
    filter(region != "England")

# Create Gold Standard dataset for regions (remove cutoff_date to show on all facets)
gold_standard_regions <- region_stats |>
    filter(cutoff_date == final_date) |>
    select(-cutoff_date)

# Create dataset for panels (exclude final cutoff)
panel_data_regions <- region_stats |>
    filter(cutoff_date < final_date)

# Plot
p_cutoffs_regions <- ggplot(panel_data_regions, aes(x = day)) +
    # Gold Standard (Background)
    geom_ribbon(
        data = gold_standard_regions,
        aes(ymin = q025, ymax = q975),
        fill = "grey50",
        alpha = 0.2
    ) +
    geom_line(
        data = gold_standard_regions,
        aes(y = median),
        linewidth = 0.5,
        colour = "grey50",
        linetype = "dashed"
    ) +
    # Panel-specific estimates
    geom_ribbon(
        aes(ymin = q025, ymax = q975),
        fill = "#56B4E9", # Nice blue
        alpha = 0.4
    ) +
    geom_line(
        aes(y = median),
        linewidth = 0.5,
        colour = "#56B4E9"
    ) +
    facet_grid(region ~ cutoff_date, scales = "free_y") +
    incidence_plot_theming() +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 5),
        axis.text.y = element_text(size = 5),
        strip.text = element_text(size = 6),
        panel.spacing = unit(0.2, "lines")
    )

save_plot(
    filename = "incidence_cutoffs_region.pdf",
    plot = p_cutoffs_regions,
    full_page = TRUE
)