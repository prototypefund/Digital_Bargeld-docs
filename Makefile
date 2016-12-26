# Makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
PAPER         =
APIBUILDDIR   = api/_build
DOCSBUILDDIR  = docs/_build

# User-friendly check for sphinx-build
ifeq ($(shell which $(SPHINXBUILD) >/dev/null 2>&1; echo $$?), 1)
$(error The '$(SPHINXBUILD)' command was not found. Make sure you have Sphinx installed, then set the SPHINXBUILD environment variable to point to the full path of the '$(SPHINXBUILD)' executable. Alternatively you can add the directory with the executable to your PATH. If you don't have Sphinx installed, grab it from http://sphinx-doc.org/)
endif

# Internal variables.
PAPEROPT_a4     = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter
ALLSPHINXOPTS   = -d $(PWD)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS)
# the i18n builder cannot share the environment and doctrees with the others
I18NSPHINXOPTS  = $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) .

.PHONY: help clean html dirhtml singlehtml pickle json htmlhelp qthelp devhelp epub latex latexpdf text man changes linkcheck doctest gettext

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  html       to make standalone HTML files"
	@echo "  dirhtml    to make HTML files named index.html in directories"
	@echo "  singlehtml to make a single large HTML file"
	@echo "  pickle     to make pickle files"
	@echo "  json       to make JSON files"
	@echo "  htmlhelp   to make HTML files and a HTML help project"
	@echo "  qthelp     to make HTML files and a qthelp project"
	@echo "  devhelp    to make HTML files and a Devhelp project"
	@echo "  epub       to make an epub"
	@echo "  latex      to make LaTeX files, you can set PAPER=a4 or PAPER=letter"
	@echo "  latexpdf   to make LaTeX files and run them through pdflatex"
	@echo "  latexpdfja to make LaTeX files and run them through platex/dvipdfmx"
	@echo "  text       to make text files"
	@echo "  man        to make manual pages"
	@echo "  texinfo    to make Texinfo files"
	@echo "  info       to make Texinfo files and run them through makeinfo"
	@echo "  gettext    to make PO message catalogs"
	@echo "  changes    to make an overview of all changed/added/deprecated items"
	@echo "  xml        to make Docutils-native XML files"
	@echo "  pseudoxml  to make pseudoxml-XML files for display purposes"
	@echo "  linkcheck  to check all external links for integrity"
	@echo "  doctest    to run all doctests embedded in the documentation (if enabled)"

clean:
	rm -rf $(DOCSBUILDDIR)/*
	rm -rf $(APIBUILDDIR)/*

# The html-linked builder does not support caching, so we
# remove all cached state first.
html:
	$(SPHINXBUILD) docs/ -b html-linked $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b html-linked $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished. The HTML pages are in $(APIBUILDDIR)/html."
	@echo "Build finished. The HTML pages are in $(DOCSBUILDDIR)/html."

dirhtml:
	$(SPHINXBUILD) docs/ -b dirhtml $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b dirhtml $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished. The HTML pages are in $(APIBUILDDIR)/dirhtml."
	@echo "Build finished. The HTML pages are in $(DOCSBUILDDIR)/dirhtml."

singlehtml:
	$(SPHINXBUILD) docs/ -b singlehtml $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b singlehtml $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished. The HTML page is in $(DOCSBUILDDIR)/singlehtml."
	@echo "Build finished. The HTML page is in $(APIBUILDDIR)/singlehtml."

pickle:
	$(SPHINXBUILD) api/ -b pickle $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	$(SPHINXBUILD) docs/ -b pickle $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	@echo
	@echo "Build finished; now you can process the pickle files."

json:
	$(SPHINXBUILD) docs/ -b json $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b json $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished; now you can process the JSON files."

htmlhelp:
	$(SPHINXBUILD) docs/ -b htmlhelp $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b htmlhelp $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished; now you can run HTML Help Workshop with the" \
	      ".hhp project file in $(DOCSBUILDDIR)/htmlhelp."
	@echo "Build finished; now you can run HTML Help Workshop with the" \
	      ".hhp project file in $(APIBUILDDIR)/htmlhelp."

qthelp:
	$(SPHINXBUILD) docs/ -b qthelp $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b qthelp $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished; now you can run "qcollectiongenerator" with the" \
	      ".qhcp project file in $(DOCSBUILDDIR)/qthelp, like this:"
	@echo "Build finished; now you can run "qcollectiongenerator" with the" \
	      ".qhcp project file in $(APIBUILDDIR)/qthelp, like this:"
	@echo "# qcollectiongenerator $(APIBUILDDIR)/qthelp/neuro.qhcp"
	@echo "To view the help file:"
	@echo "# assistant -collectionFile $(APIBUILDDIR)/qthelp/neuro.qhc"
	@echo "# qcollectiongenerator $(DOCSBUILDDIR)/qthelp/neuro.qhcp"
	@echo "To view the help file:"
	@echo "# assistant -collectionFile $(DOCSBUILDDIR)/qthelp/neuro.qhc"


devhelp:
	$(SPHINXBUILD) api/ -b devhelp $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	$(SPHINXBUILD) docs/ -b devhelp $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	@echo
	@echo "Build finished."
	@echo "To view the help file:"
	@echo "# mkdir -p $$HOME/.local/share/devhelp/neuro"
	@echo "# ln -s $(APIBUILDDIR)/devhelp $$HOME/.local/share/devhelp/neuro"
	@echo "# ln -s $(DOCSBUILDDIR)/devhelp $$HOME/.local/share/devhelp/neuro"
	@echo "# devhelp"

epub:
	$(SPHINXBUILD) api/ -b epub $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	$(SPHINXBUILD) docs/ -b epub $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	@echo
	@echo "Build finished. The epub file is in $(APIBUILDDIR)/epub."
	@echo "Build finished. The epub file is in $(DOCSBUILDDIR)/epub."

latex:
	$(SPHINXBUILD) api/ -b latex $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	$(SPHINXBUILD) docs/ -b latex $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	@echo
	@echo "Build finished; the LaTeX files are in $(APIBUILDDIR)/latex."
	@echo "Build finished; the LaTeX files are in $(DOCSBUILDDIR)/latex."
	@echo "Run \`make' in that directory to run these through (pdf)latex" \
	      "(use \`make latexpdf' here to do that automatically)."

latexpdf:
	$(SPHINXBUILD) api/ -b latex $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	$(SPHINXBUILD) docs/ -b latex $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	@echo "Running LaTeX files through pdflatex..."
	$(MAKE) -C $(DOCSBUILDDIR)/latex all-pdf
	$(MAKE) -C $(APIBUILDDIR)/latex all-pdf
	@echo "pdflatex finished; the PDF files are in $(APIBUILDDIR)/latex."
	@echo "pdflatex finished; the PDF files are in $(DOCSBUILDDIR)/latex."

latexpdfja:
	$(SPHINXBUILD) docs/ -b latex $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b latex $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo "Running LaTeX files through platex and dvipdfmx..."
	$(MAKE) -C $(APIBUILDDIR)/latex all-pdf-ja
	$(MAKE) -C $(DOCSBUILDDIR)/latex all-pdf-ja
	@echo "pdflatex finished; the PDF files are in $(DOCSBUILDDIR)/latex."
	@echo "pdflatex finished; the PDF files are in $(APIBUILDDIR)/latex."

text:
	$(SPHINXBUILD) docs/ -b text $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b text $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished. The text files are in $(DOCSBUILDDIR)/text."
	@echo "Build finished. The text files are in $(APIBUILDDIR)/text."

man:
	$(SPHINXBUILD) docs/ -b man $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b man $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished. The manual pages are in $(DOCSBUILDDIR)/man."
	@echo "Build finished. The manual pages are in $(APIBUILDDIR)/man."

texinfo:
	$(SPHINXBUILD) docs/ -b texinfo $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b texinfo $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished. The Texinfo files are in $(DOCSBUILDDIR)/texinfo."
	@echo "Build finished. The Texinfo files are in $(APIBUILDDIR)/texinfo."
	@echo "Run \`make' in that directory to run these through makeinfo" \
	      "(use \`make info' here to do that automatically)."

info:
	$(SPHINXBUILD) docs/ -b texinfo $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b texinfo $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo "Running Texinfo files through makeinfo..."
	make -C $(DOCSBUILDDIR)/texinfo info
	make -C $(APIBUILDDIR)/texinfo info
	@echo "makeinfo finished; the Info files are in $(DOCSBUILDDIR)/texinfo."
	@echo "makeinfo finished; the Info files are in $(APIBUILDDIR)/texinfo."

gettext:
	$(SPHINXBUILD) docs/ -b gettext $(I18NSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b gettext $(I18NSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished. The message catalogs are in $(DOCSBUILDDIR)/locale."
	@echo "Build finished. The message catalogs are in $(APIBUILDDIR)/locale."

changes:
	$(SPHINXBUILD) docs/ -b changes $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b changes $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "The overview file is in $(DOCSBUILDDIR)/changes."
	@echo "The overview file is in $(APIBUILDDIR)/changes."

linkcheck:
	$(SPHINXBUILD) docs/ -b linkcheck $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b linkcheck $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Link check complete; look for any errors in the above output " \
	      "or in $(APIBUILDDIR)/linkcheck/output.txt."
	@echo "Link check complete; look for any errors in the above output " \
	      "or in $(DOCSBUILDDIR)/linkcheck/output.txt."


doctest:
	$(SPHINXBUILD) docs/ -b doctest $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b doctest $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo "Testing of doctests in the sources finished, look at the " \
	      "results in $(APIBUILDDIR)/doctest/output.txt."
	@echo "Testing of doctests in the sources finished, look at the " \
	      "results in $(DOCSBUILDDIR)/doctest/output.txt."


xml:
	$(SPHINXBUILD) docs/ -b xml $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	$(SPHINXBUILD) api/ -b xml $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	@echo
	@echo "Build finished. The XML files are in $(DOCSBUILDDIR)/xml."
	@echo "Build finished. The XML files are in $(APIBUILDDIR)/xml."

pseudoxml:
	$(SPHINXBUILD) api/ -b pseudoxml $(ALLSPHINXOPTS)  $(APIBUILDDIR)
	$(SPHINXBUILD) docs/ -b pseudoxml $(ALLSPHINXOPTS)  $(DOCSBUILDDIR)
	@echo
	@echo "Build finished. The pseudo-XML files are in $(DOCSBUILDDIR)/pseudoxml."
	@echo "Build finished. The pseudo-XML files are in $(APIBUILDDIR)/pseudoxml."
