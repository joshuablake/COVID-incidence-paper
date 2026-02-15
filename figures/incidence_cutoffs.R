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
p_cutoffs <- ggplot(panel_data, aes(x = day)) +
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
        colour = "#56B4E9"
    ) +
    facet_wrap(~cutoff_date) +
    incidence_plot_theming()

save_plot(
    filename = "incidence_cutoffs.pdf",
    plot = p_cutoffs,
    width = 17.6, # Same width as other large plots
    height = 12   # Adjust height as needed for panels
)