main.pdf: main.tex figures/incidence.pdf references.bib figures/components.pdf .PHONY
	./latexrun $<

figures/incidence.pdf: figures/incidence.R figures/utils.R model-outputs/mechanistic/predictive.csv model-outputs/phenomenological/region.rds model-outputs/poststrat.csv
	Rscript $<

figures/components.pdf: figures/components.R figures/utils.R model-outputs/mechanistic/params.csv
	Rscript $<

.PHONY: FORCE