from pygments.token import *
from pygments.lexer import RegexLexer, ExtendedRegexLexer, bygroups, using, \
     include, this
import re

class BetterTypeScriptLexer(RegexLexer):
    """
    For `TypeScript <https://www.typescriptlang.org/>`_ source code.
    """

    name = 'TypeScript'
    aliases = ['ts']
    filenames = ['*.ts']
    mimetypes = ['text/x-typescript']

    flags = re.DOTALL
    tokens = {
        'commentsandwhitespace': [
            (r'\s+', Text),
            (r'<!--', Comment),
            (r'//.*?\n', Comment.Single),
            (r'/\*.*?\*/', Comment.Multiline)
        ],
        'slashstartsregex': [
            include('commentsandwhitespace'),
            (r'/(\\.|[^[/\\\n]|\[(\\.|[^\]\\\n])*])+/'
             r'([gim]+\b|\B)', String.Regex, '#pop'),
            (r'(?=/)', Text, ('#pop', 'badregex')),
            (r'', Text, '#pop')
        ],
        'badregex': [
            (r'\n', Text, '#pop')
        ],
        'typeexp': [
            (r'[a-zA-Z]+', Keyword.Type),
            (r'\s+', Text),
            (r'[|]', Text),
            (r'\n', Text, "#pop"),
            (r';', Text, "#pop"),
            (r'', Text, "#pop"),
        ],
        'root': [
            (r'^(?=\s|/|<!--)', Text, 'slashstartsregex'),
            include('commentsandwhitespace'),
            (r'\+\+|--|~|&&|\?|:|\|\||\\(?=\n)|'
             r'(<<|>>>?|==?|!=?|[-<>+*%&\|\^/])=?', Operator, 'slashstartsregex'),
            (r'[{(\[;,]', Punctuation, 'slashstartsregex'),
            (r'[})\].]', Punctuation),
            (r'(for|in|while|do|break|return|continue|switch|case|default|if|else|'
             r'throw|try|catch|finally|new|delete|typeof|instanceof|void|'
             r'this)\b', Keyword, 'slashstartsregex'),
            (r'(var|let|const|with|function)\b', Keyword.Declaration, 'slashstartsregex'),
            (r'(abstract|boolean|byte|char|class|const|debugger|double|enum|export|'
             r'extends|final|float|goto|implements|import|int|interface|long|native|'
             r'package|private|protected|public|short|static|super|synchronized|throws|'
             r'transient|volatile)\b', Keyword.Reserved),
            (r'(true|false|null|NaN|Infinity|undefined)\b', Keyword.Constant),
            (r'(Array|Boolean|Date|Error|Function|Math|netscape|'
             r'Number|Object|Packages|RegExp|String|sun|decodeURI|'
             r'decodeURIComponent|encodeURI|encodeURIComponent|'
             r'Error|eval|isFinite|isNaN|parseFloat|parseInt|document|this|'
             r'window)\b', Name.Builtin),
            # Match stuff like: module name {...}
            (r'\b(module)(\s*)(\s*[a-zA-Z0-9_?.$][\w?.$]*)(\s*)',
             bygroups(Keyword.Reserved, Text, Name.Other, Text), 'slashstartsregex'),
            # Match variable type keywords
            (r'\b(string|bool|number)\b', Keyword.Type),
            # Match stuff like: constructor
            (r'\b(constructor|declare|interface|as|AS)\b', Keyword.Reserved),
            # Match stuff like: super(argument, list)
            (r'(super)(\s*)\(([a-zA-Z0-9,_?.$\s]+\s*)\)',
             bygroups(Keyword.Reserved, Text), 'slashstartsregex'),
            # Match stuff like: function() {...}
            (r'([a-zA-Z_?.$][\w?.$]*)\(\) \{', Name.Other, 'slashstartsregex'),
            # Match stuff like: (function: return type)
            (r'([a-zA-Z0-9_?.$][\w?.$]*)(\s*:\s*)([a-zA-Z0-9_?.$][\w?.$]*)',
             bygroups(Name.Other, Text, Keyword.Type)),
            # Match stuff like: type Foo = Bar | Baz
            (r'\b(type)(\s*)([a-zA-Z0-9_?.$]+)(\s*)(=)(\s*)',
             bygroups(Keyword.Reserved, Text, Name.Other, Text, Operator, Text), 'typeexp'),
            (r'[$a-zA-Z_][a-zA-Z0-9_]*', Name.Other),
            (r'[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?', Number.Float),
            (r'0x[0-9a-fA-F]+', Number.Hex),
            (r'[0-9]+', Number.Integer),
            (r'"(\\\\|\\"|[^"])*"', String.Double),
            (r"'(\\\\|\\'|[^'])*'", String.Single),
        ]
    }
