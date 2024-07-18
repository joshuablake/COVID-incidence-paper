main.pdf: main.tex figures/incidence.pdf references.bib figures/components.pdf .PHONY
	./latexrun $<

figures/incidence.pdf: figures/incidence.R figures/utils.R model-outputs/mechanistic/predictive.csv model-outputs/phenomenological/region.rds model-outputs/phenomenological/region_age.rds model-outputs/poststrat.csv
	Rscript $<

figures/components.pdf: figures/components.R figures/utils.R model-outputs/mechanistic/params.csv
	Rscript $<

figures/prevalence.pdf: figures/fit.R figures/utils.R model-outputs/mechanistic/data.csv model-outputs/phenomenological/region.rds model-outputs/mechanistic/predictive.csv
	Rscript $<

.PHONY: FORCE