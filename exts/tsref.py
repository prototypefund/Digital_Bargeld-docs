"""
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015 GNUnet e.V. and INRIA
  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU Lesser General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.
  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Florian Dold
"""

"""
This extension adds a new lexer "tsref" for TypeScript, which
allows reST-style links inside comments (`LinkName`_),
and semi-automatically adds links to the definition of types.

For type TYPE, a reference to tsref-type-TYPE is added.

Known bugs and limitations:
 - The way the extension works right now interferes wiht
   Sphinx's caching, the build directory should be cleared
   before every build.
"""


from pygments.util import get_bool_opt
from pygments.token import Name, Comment, Token, _TokenType
from pygments.filter import Filter
from sphinx.highlighting import PygmentsBridge
from sphinx.builders.html import StandaloneHTMLBuilder
from sphinx.pygments_styles import SphinxStyle
from pygments.formatters import HtmlFormatter
from docutils import nodes
from docutils.nodes import make_id
import re


_escape_html_table = {
    ord('&'): u'&amp;',
    ord('<'): u'&lt;',
    ord('>'): u'&gt;',
    ord('"'): u'&quot;',
    ord("'"): u'&#39;',
}


class LinkingHtmlFormatter(HtmlFormatter):
    def __init__(self, **kwargs):
        super(LinkingHtmlFormatter, self).__init__(**kwargs)
        self._builder = kwargs['_builder']

    def _fmt(self, value, tok):
        cls = self._get_css_class(tok)
        href = tok_getprop(tok, "href")
        caption = tok_getprop(tok, "caption")
        content = caption if caption is not None else value
        if href:
            value = '<a style="color:inherit;text-decoration:underline" href="%s">%s</a>' % (href, content)
        if cls is None or cls == "":
            return value
        return '<span class="%s">%s</span>' % (cls, value)

    def _format_lines(self, tokensource):
        """
        Just format the tokens, without any wrapping tags.
        Yield individual lines.
        """
        lsep = self.lineseparator
        escape_table = _escape_html_table

        line = ''
        for ttype, value in tokensource:
            link = get_annotation(ttype, "link")

            parts = value.translate(escape_table).split('\n')

            if len(parts) == 0:
                # empty token, usually should not happen
                pass
            elif len(parts) == 1:
                # no newline before or after token
                line += self._fmt(parts[0], ttype)
            else:
                line += self._fmt(parts[0], ttype)
                yield 1, line + lsep
                for part in parts[1:-1]:
                    yield 1, self._fmt(part, ttype) + lsep
                line = self._fmt(parts[-1], ttype)

        if line:
            yield 1, line + lsep


class MyPygmentsBridge(PygmentsBridge):
    def __init__(self, builder, trim_doctest_flags):
        self.dest = "html"
        self.trim_doctest_flags = trim_doctest_flags
        self.formatter_args = {'style': SphinxStyle, '_builder': builder}
        self.formatter = LinkingHtmlFormatter


class MyHtmlBuilder(StandaloneHTMLBuilder):
    name = "html-linked"
    def init_highlighter(self):
        if self.config.pygments_style is not None:
            style = self.config.pygments_style
        elif self.theme:
            style = self.theme.get_confstr('theme', 'pygments_style', 'none')
        else:
            style = 'sphinx'
        self.highlighter = MyPygmentsBridge(self, self.config.trim_doctest_flags)

    def write_doc(self, docname, doctree):
        self._current_docname = docname
        super(MyHtmlBuilder, self).write_doc(docname, doctree)


def get_annotation(tok, key):
    if not hasattr(tok, "kv"):
        return None
    return tok.kv.get(key)


def copy_token(tok):
    new_tok = _TokenType(tok)
    # This part is very fragile against API changes ...
    new_tok.subtypes = set(tok.subtypes)
    new_tok.parent = tok.parent
    return new_tok


def tok_setprop(tok, key, value):
    tokid = id(tok)
    e = token_props.get(tokid)
    if e is None:
        e = token_props[tokid] = (tok, {})
    _, kv = e
    kv[key] = value


def tok_getprop(tok, key):
    tokid = id(tok)
    e = token_props.get(tokid)
    if e is None:
        return None
    _, kv = e
    return kv.get(key)


link_reg = re.compile(r"`([^`<]+)\s*(?:<([^>]+)>)?\s*`_")

# Map from token id to props.
# Properties can't be added to tokens
# since they derive from Python's tuple.
token_props = {}


class LinkFilter(Filter):
    def __init__(self, app, **options):
        self.app = app
        Filter.__init__(self, **options)

    def filter(self, lexer, stream):
        id_to_doc = self.app.env.domaindata.get("_tsref", {})
        for ttype, value in stream:
            if ttype in Token.Keyword.Type:
                defname = make_id('tsref-type-' + value);
                t = copy_token(ttype)
                if defname in id_to_doc:
                    docname = id_to_doc[defname]
                    href = self.app.builder.get_target_uri(docname) + "#" + defname
                    tok_setprop(t, "href", href)

                yield t, value
            elif ttype in Token.Comment:
                last = 0
                for m in re.finditer(link_reg, value):
                    pre = value[last:m.start()]
                    if pre:
                        yield ttype, pre
                    t = copy_token(ttype)
                    x1, x2 = m.groups()
                    if x2 is None:
                        caption = x1.strip()
                        id = make_id(x1)
                    else:
                        caption = x1.strip()
                        id = make_id(x2)
                    if id in id_to_doc:
                        docname = id_to_doc[id]
                        href = self.app.builder.get_target_uri(docname) + "#" + id
                        tok_setprop(t, "href", href)
                        tok_setprop(t, "caption", caption)
                    else:
                        self.app.builder.warn("unresolved link target in comment: " + id)
                    yield t, m.group(1)
                    last = m.end()
                post = value[last:]
                if post:
                    yield ttype, post
            else:
                yield ttype, value



def remember_targets(app, doctree):
    docname = app.env.docname
    id_to_doc = app.env.domaindata.get("_tsref", None)
    if id_to_doc is None:
        id_to_doc = app.env.domaindata["_tsref"] = {}
    for node in doctree.traverse():
        if not isinstance(node, nodes.Element):
            continue
        ids = node.get("ids")
        if ids:
            for id in ids:
                id_to_doc[id] = docname


def setup(app): 
    from sphinx.highlighting import lexers
    from pygments.lexers import TypeScriptLexer
    from pygments.token import Name
    from pygments.filters import NameHighlightFilter
    lexer = TypeScriptLexer()
    lexer.add_filter(LinkFilter(app))
    app.add_lexer('tsref', lexer)
    app.add_builder(MyHtmlBuilder)
    app.connect("doctree-read", remember_targets)



