# COVID-19 incidence from the CIS (PNAS manuscript)

Manuscript source (`main.tex`) and the R code for its figures (`figures/`).

## Reproducing the figures

The R packages are pinned with [renv](https://rstudio.github.io/renv/). From the repository root:

```r
renv::restore()   # once, installs the versions in renv.lock
```

Then run each script in `figures/` from the repository root (e.g. `Rscript figures/incidence.R`).
The scripts read model outputs from `model-outputs/`, which is not in the repository:
`mechanistic/` comes from the CIS-seir exports and `phenomenological/` from CIS-backcalc (see the Data, Materials, and Software Availability section of the paper).
