main.pdf: main.tex figures/incidence.pdf references.bib figures/rw.pdf figures/children.pdf .PHONY
	./latexrun $<

figures/incidence.pdf: figures/incidence.R figures/utils.R model-outputs/mechanistic/predictive.csv model-outputs/phenomenological/region.rds model-outputs/phenomenological/region_age.rds model-outputs/poststrat.csv
	Rscript $<

figures/rw.pdf: figures/rw.R figures/utils.R model-outputs/mechanistic/params.csv
	Rscript $<

figures/children.pdf: figures/children.R figures/utils.R model-outputs/mechanistic/params.csv
	Rscript $<

.PHONY: FORCE