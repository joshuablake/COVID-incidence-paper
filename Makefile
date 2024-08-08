main.pdf: main.tex .PHONY references.bib figures/incidence_England.pdf figures/incidence_stratified.pdf figures/rw_London.pdf figures/rw_non-London.pdf figures/children.pdf figures/gof.pdf
	python3 latexrun $<

figures/incidence_England.pdf figures/incidence_stratified.pdf: figures/incidence.R figures/utils.R model-outputs/mechanistic/predictive.csv model-outputs/phenomenological/region.rds model-outputs/phenomenological/age.rds model-outputs/poststrat.csv
	Rscript $<

figures/rw_London.pdf figures/rw_non-London.pdf: figures/rw.R figures/utils.R model-outputs/mechanistic/params.csv
	Rscript $<

figures/children.pdf: figures/children.R figures/utils.R model-outputs/mechanistic/params.csv
	Rscript $<

figures/gof.pdf: figures/gof.R figures/utils.R model-outputs/mechanistic/predictive.csv model-outputs/mechanistic/data.csv model-outputs/mechanistic/params.csv
	Rscript $<

.PHONY: FORCE