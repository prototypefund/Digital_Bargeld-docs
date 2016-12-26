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
ALLSPHINXOPTS   = -d $(BUILDDIR)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) .
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
	$(SPHINXBUILD) -b html-linked $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/html
	$(SPHINXBUILD) -b html-linked $(ALLSPHINXOPTS) $(APIBUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(APIBUILDDIR)/html."
	@echo "Build finished. The HTML pages are in $(DOCSBUILDDIR)/html."

dirhtml:
	$(SPHINXBUILD) -b dirhtml $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/dirhtml
	$(SPHINXBUILD) -b dirhtml $(ALLSPHINXOPTS) $(APIBUILDDIR)/dirhtml
	@echo
	@echo "Build finished. The HTML pages are in $(APIBUILDDIR)/dirhtml."
	@echo "Build finished. The HTML pages are in $(DOCSBUILDDIR)/dirhtml."

singlehtml:
	$(SPHINXBUILD) -b singlehtml $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/singlehtml
	$(SPHINXBUILD) -b singlehtml $(ALLSPHINXOPTS) $(APIBUILDDIR)/singlehtml
	@echo
	@echo "Build finished. The HTML page is in $(DOCSBUILDDIR)/singlehtml."
	@echo "Build finished. The HTML page is in $(APIBUILDDIR)/singlehtml."

pickle:
	$(SPHINXBUILD) -b pickle $(ALLSPHINXOPTS) $(APIBUILDDIR)/pickle
	$(SPHINXBUILD) -b pickle $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/pickle
	@echo
	@echo "Build finished; now you can process the pickle files."

json:
	$(SPHINXBUILD) -b json $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/json
	$(SPHINXBUILD) -b json $(ALLSPHINXOPTS) $(APIBUILDDIR)/json
	@echo
	@echo "Build finished; now you can process the JSON files."

htmlhelp:
	$(SPHINXBUILD) -b htmlhelp $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/htmlhelp
	$(SPHINXBUILD) -b htmlhelp $(ALLSPHINXOPTS) $(APIBUILDDIR)/htmlhelp
	@echo
	@echo "Build finished; now you can run HTML Help Workshop with the" \
	      ".hhp project file in $(DOCSBUILDDIR)/htmlhelp."
	@echo "Build finished; now you can run HTML Help Workshop with the" \
	      ".hhp project file in $(APIBUILDDIR)/htmlhelp."

qthelp:
	$(SPHINXBUILD) -b qthelp $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/qthelp
	$(SPHINXBUILD) -b qthelp $(ALLSPHINXOPTS) $(APIBUILDDIR)/qthelp
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
	$(SPHINXBUILD) -b devhelp $(ALLSPHINXOPTS) $(APIBUILDDIR)/devhelp
	$(SPHINXBUILD) -b devhelp $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/devhelp
	@echo
	@echo "Build finished."
	@echo "To view the help file:"
	@echo "# mkdir -p $$HOME/.local/share/devhelp/neuro"
	@echo "# ln -s $(APIBUILDDIR)/devhelp $$HOME/.local/share/devhelp/neuro"
	@echo "# ln -s $(DOCSBUILDDIR)/devhelp $$HOME/.local/share/devhelp/neuro"
	@echo "# devhelp"

epub:
	$(SPHINXBUILD) -b epub $(ALLSPHINXOPTS) $(APIBUILDDIR)/epub
	$(SPHINXBUILD) -b epub $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/epub
	@echo
	@echo "Build finished. The epub file is in $(APIBUILDDIR)/epub."
	@echo "Build finished. The epub file is in $(DOCSBUILDDIR)/epub."

latex:
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(APIBUILDDIR)/latex
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/latex
	@echo
	@echo "Build finished; the LaTeX files are in $(APIBUILDDIR)/latex."
	@echo "Build finished; the LaTeX files are in $(DOCSBUILDDIR)/latex."
	@echo "Run \`make' in that directory to run these through (pdf)latex" \
	      "(use \`make latexpdf' here to do that automatically)."

latexpdf:
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(APIBUILDDIR)/latex
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/latex
	@echo "Running LaTeX files through pdflatex..."
	$(MAKE) -C $(DOCSBUILDDIR)/latex all-pdf
	$(MAKE) -C $(APIBUILDDIR)/latex all-pdf
	@echo "pdflatex finished; the PDF files are in $(APIBUILDDIR)/latex."
	@echo "pdflatex finished; the PDF files are in $(DOCSBUILDDIR)/latex."

latexpdfja:
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/latex
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(APIBUILDDIR)/latex
	@echo "Running LaTeX files through platex and dvipdfmx..."
	$(MAKE) -C $(APIBUILDDIR)/latex all-pdf-ja
	$(MAKE) -C $(DOCSBUILDDIR)/latex all-pdf-ja
	@echo "pdflatex finished; the PDF files are in $(DOCSBUILDDIR)/latex."
	@echo "pdflatex finished; the PDF files are in $(APIBUILDDIR)/latex."

text:
	$(SPHINXBUILD) -b text $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/text
	$(SPHINXBUILD) -b text $(ALLSPHINXOPTS) $(APIBUILDDIR)/text
	@echo
	@echo "Build finished. The text files are in $(DOCSBUILDDIR)/text."
	@echo "Build finished. The text files are in $(APIBUILDDIR)/text."

man:
	$(SPHINXBUILD) -b man $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/man
	$(SPHINXBUILD) -b man $(ALLSPHINXOPTS) $(APIBUILDDIR)/man
	@echo
	@echo "Build finished. The manual pages are in $(DOCSBUILDDIR)/man."
	@echo "Build finished. The manual pages are in $(APIBUILDDIR)/man."

texinfo:
	$(SPHINXBUILD) -b texinfo $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/texinfo
	$(SPHINXBUILD) -b texinfo $(ALLSPHINXOPTS) $(APIBUILDDIR)/texinfo
	@echo
	@echo "Build finished. The Texinfo files are in $(DOCSBUILDDIR)/texinfo."
	@echo "Build finished. The Texinfo files are in $(APIBUILDDIR)/texinfo."
	@echo "Run \`make' in that directory to run these through makeinfo" \
	      "(use \`make info' here to do that automatically)."

info:
	$(SPHINXBUILD) -b texinfo $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/texinfo
	$(SPHINXBUILD) -b texinfo $(ALLSPHINXOPTS) $(APIBUILDDIR)/texinfo
	@echo "Running Texinfo files through makeinfo..."
	make -C $(DOCSBUILDDIR)/texinfo info
	make -C $(APIBUILDDIR)/texinfo info
	@echo "makeinfo finished; the Info files are in $(DOCSBUILDDIR)/texinfo."
	@echo "makeinfo finished; the Info files are in $(APIBUILDDIR)/texinfo."

gettext:
	$(SPHINXBUILD) -b gettext $(I18NSPHINXOPTS) $(DOCSBUILDDIR)/locale
	$(SPHINXBUILD) -b gettext $(I18NSPHINXOPTS) $(APIBUILDDIR)/locale
	@echo
	@echo "Build finished. The message catalogs are in $(DOCSBUILDDIR)/locale."
	@echo "Build finished. The message catalogs are in $(APIBUILDDIR)/locale."

changes:
	$(SPHINXBUILD) -b changes $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/changes
	$(SPHINXBUILD) -b changes $(ALLSPHINXOPTS) $(APIBUILDDIR)/changes
	@echo
	@echo "The overview file is in $(DOCSBUILDDIR)/changes."
	@echo "The overview file is in $(APIBUILDDIR)/changes."

linkcheck:
	$(SPHINXBUILD) -b linkcheck $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/linkcheck
	$(SPHINXBUILD) -b linkcheck $(ALLSPHINXOPTS) $(APIBUILDDIR)/linkcheck
	@echo
	@echo "Link check complete; look for any errors in the above output " \
	      "or in $(APIBUILDDIR)/linkcheck/output.txt."
	@echo "Link check complete; look for any errors in the above output " \
	      "or in $(DOCSBUILDDIR)/linkcheck/output.txt."


doctest:
	$(SPHINXBUILD) -b doctest $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/doctest
	$(SPHINXBUILD) -b doctest $(ALLSPHINXOPTS) $(APIBUILDDIR)/doctest
	@echo "Testing of doctests in the sources finished, look at the " \
	      "results in $(APIBUILDDIR)/doctest/output.txt."
	@echo "Testing of doctests in the sources finished, look at the " \
	      "results in $(DOCSBUILDDIR)/doctest/output.txt."


xml:
	$(SPHINXBUILD) -b xml $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/xml
	$(SPHINXBUILD) -b xml $(ALLSPHINXOPTS) $(APIBUILDDIR)/xml
	@echo
	@echo "Build finished. The XML files are in $(DOCSBUILDDIR)/xml."
	@echo "Build finished. The XML files are in $(APIBUILDDIR)/xml."

pseudoxml:
	$(SPHINXBUILD) -b pseudoxml $(ALLSPHINXOPTS) $(APIBUILDDIR)/pseudoxml
	$(SPHINXBUILD) -b pseudoxml $(ALLSPHINXOPTS) $(DOCSBUILDDIR)/pseudoxml
	@echo
	@echo "Build finished. The pseudo-XML files are in $(DOCSBUILDDIR)/pseudoxml."
	@echo "Build finished. The pseudo-XML files are in $(APIBUILDDIR)/pseudoxml."
