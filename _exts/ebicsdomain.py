"""
EBICS documentation domain.

:copyright: Copyright 2019 by Taler Systems SA
:license: LGPLv3+
:author: Florian Dold
"""

import re

from docutils import nodes
from typing import List, Optional, Iterable, Dict, Tuple
from typing import cast

from docutils import nodes
from docutils.nodes import Element, Node
from docutils.statemachine import StringList

from sphinx import addnodes
from sphinx.roles import XRefRole
from sphinx.domains import Domain, ObjType, Index
from sphinx.directives import directives
from sphinx.util.docutils import SphinxDirective
from sphinx.util.nodes import make_refnode
from sphinx.util import logging

logger = logging.getLogger(__name__)

def make_glossary_term(env: "BuildEnvironment", textnodes: Iterable[Node], index_key: str,
                       source: str, lineno: int, new_id: str = None) -> nodes.term:
    # get a text-only representation of the term and register it
    # as a cross-reference target
    term = nodes.term('', '', *textnodes)
    term.source = source
    term.line = lineno

    gloss_entries = env.temp_data.setdefault('gloss_entries', set())
    termtext = term.astext()
    if new_id is None:
        new_id = nodes.make_id('ebics-order-' + termtext.lower())
        if new_id == 'ebics-order':
            # the term is not good for node_id.  Generate it by sequence number instead.
            new_id = 'ebics-order-%d' % env.new_serialno('ebics')
    while new_id in gloss_entries:
        new_id = 'ebics-order-%d' % env.new_serialno('ebics')
    gloss_entries.add(new_id)

    ebics = env.get_domain('ebics')
    ebics.add_object('order', termtext.lower(), env.docname, new_id)

    term['ids'].append(new_id)
    term['names'].append(new_id)

    return term


def split_term_classifiers(line: str) -> List[Optional[str]]:
    # split line into a term and classifiers. if no classifier, None is used..
    parts = re.split(' +: +', line) + [None]
    return parts


class EbicsOrders(SphinxDirective):
    has_content = True
    required_arguments = 0
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec = {
        'sorted': directives.flag,
    }

    def run(self):
        node = addnodes.glossary()
        node.document = self.state.document

        # This directive implements a custom format of the reST definition list
        # that allows multiple lines of terms before the definition.  This is
        # easy to parse since we know that the contents of the glossary *must
        # be* a definition list.

        # first, collect single entries
        entries = []  # type: List[Tuple[List[Tuple[str, str, int]], StringList]]
        in_definition = True
        in_comment = False
        was_empty = True
        messages = []  # type: List[nodes.Node]
        for line, (source, lineno) in zip(self.content, self.content.items):
            # empty line -> add to last definition
            if not line:
                if in_definition and entries:
                    entries[-1][1].append('', source, lineno)
                was_empty = True
                continue
            # unindented line -> a term
            if line and not line[0].isspace():
                # enable comments
                if line.startswith('.. '):
                    in_comment = True
                    continue
                else:
                    in_comment = False

                # first term of definition
                if in_definition:
                    if not was_empty:
                        messages.append(self.state.reporter.warning(
                            _('glossary term must be preceded by empty line'),
                            source=source, line=lineno))
                    entries.append(([(line, source, lineno)], StringList()))
                    in_definition = False
                # second term and following
                else:
                    if was_empty:
                        messages.append(self.state.reporter.warning(
                            _('glossary terms must not be separated by empty lines'),
                            source=source, line=lineno))
                    if entries:
                        entries[-1][0].append((line, source, lineno))
                    else:
                        messages.append(self.state.reporter.warning(
                            _('glossary seems to be misformatted, check indentation'),
                            source=source, line=lineno))
            elif in_comment:
                pass
            else:
                if not in_definition:
                    # first line of definition, determines indentation
                    in_definition = True
                    indent_len = len(line) - len(line.lstrip())
                if entries:
                    entries[-1][1].append(line[indent_len:], source, lineno)
                else:
                    messages.append(self.state.reporter.warning(
                        _('glossary seems to be misformatted, check indentation'),
                        source=source, line=lineno))
            was_empty = False

        # now, parse all the entries into a big definition list
        items = []
        for terms, definition in entries:
            termtexts = []          # type: List[str]
            termnodes = []          # type: List[nodes.Node]
            system_messages = []    # type: List[nodes.Node]
            for line, source, lineno in terms:
                parts = split_term_classifiers(line)
                # parse the term with inline markup
                # classifiers (parts[1:]) will not be shown on doctree
                textnodes, sysmsg = self.state.inline_text(parts[0], lineno)

                # use first classifier as a index key
                term = make_glossary_term(self.env, textnodes, parts[1], source, lineno)
                term.rawsource = line
                system_messages.extend(sysmsg)
                termtexts.append(term.astext())
                termnodes.append(term)

            termnodes.extend(system_messages)

            defnode = nodes.definition()
            if definition:
                self.state.nested_parse(definition, definition.items[0][1],
                                        defnode)
            termnodes.append(defnode)
            items.append((termtexts,
                          nodes.definition_list_item('', *termnodes)))

        if 'sorted' in self.options:
            items.sort(key=lambda x:
                       unicodedata.normalize('NFD', x[0][0].lower()))

        dlist = nodes.definition_list()
        dlist['classes'].append('glossary')
        dlist.extend(item[1] for item in items)
        node += dlist
        return messages + [node]


class EbicsDomain(Domain):
    """Ebics domain."""

    name = 'ebics'
    label = 'EBICS'

    object_types = {
        'order': ObjType('order', 'ebics'),
    }

    directives = {
        'orders': EbicsOrders,
    }

    roles = {
        'order': XRefRole(lowercase=True, warn_dangling=True, innernodeclass=nodes.inline),
    }

    dangling_warnings = {
        'order': 'undefined EBICS order type: %(target)s',
    }

    @property
    def objects(self) -> Dict[Tuple[str, str], Tuple[str, str]]:
        return self.data.setdefault('objects', {})  # (objtype, name) -> docname, labelid

    def clear_doc(self, docname):
        for key, (fn, _l) in list(self.objects.items()):
            if fn == docname:
                del self.objects[key]

    def resolve_xref(self, env, fromdocname, builder, typ, target,
                     node, contnode):
        try:
            info = self.objects[(str(typ), str(target))]
        except KeyError:
            return None
        else:
            anchor = "ebics-order-{}".format(str(target))
            title = typ.upper() + ' ' + target
            return make_refnode(builder, fromdocname, info[0], anchor,
                                contnode, title)

    def add_object(self, objtype: str, name: str, docname: str, labelid: str) -> None:
        self.objects[objtype, name] = (docname, labelid)


def setup(app):
    app.add_domain(EbicsDomain)
