main.pdf: main.tex references.bib .PHONY
	./latexrun $<

.PHONY: FORCE