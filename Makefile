main.pdf: main.tex figures/incidence.pdf references.bib .PHONY
	./latexrun $<

figures/incidence.pdf: figures/incidence.R figures/utils.R model-outputs/mechanistic/predictive.csv model-outputs/phenomenological/region.rds model-outputs/poststrat.csv
	Rscript $<

.PHONY: FORCE