
##############################################################################
# Literate Programming rules
##############################################################################

SRCNW=OCaml.tex.nw
TEXMAIN=OCaml.tex.nw
TEX=OCaml.tex

LPSRC=dotemacs-ocaml.el Makefile.template foo.ml

#------------------------------------------------------------------------------
SYNCFLAGS=-md5sum_in_auxfile -less_marks

SYNCWEB=~/c__syncweb/syncweb $(SYNCFLAGS)
NOWEB=~/c__syncweb/scripts/noweblatex
OCAMLDOC=ocamldoc $(INCLUDES)

PDFLATEX=pdflatex --shell-escape 

#------------------------------------------------------------------------------
sync:
	for i in $(LPSRC); do $(SYNCWEB) $(SRCNW) $$i || exit 1; done 


pdf:
	$(NOWEB) $(TEXMAIN) > $(TEX)
	pdflatex $(TEX)
	pdflatex $(TEX)

lpclean::
	rm -f $(TEX)

clean::
	rm -f *.aux *.toc *.log

