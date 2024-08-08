main.pdf: main.tex references.bib figures/incidence_England.pdf figures/incidence_stratified.pdf figures/rw.pdf figures/children.pdf .PHONY
	python3 latexrun $<

figures/incidence_England.pdf figures/incidence_stratified.pdf: figures/incidence.R figures/utils.R model-outputs/mechanistic/predictive.csv model-outputs/phenomenological/region.rds model-outputs/phenomenological/age.rds model-outputs/poststrat.csv
	Rscript $<

figures/rw.pdf: figures/rw.R figures/utils.R model-outputs/mechanistic/params.csv
	Rscript $<

figures/children.pdf: figures/children.R figures/utils.R model-outputs/mechanistic/params.csv
	Rscript $<

.PHONY: FORCE