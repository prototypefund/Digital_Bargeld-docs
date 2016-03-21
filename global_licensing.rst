===========================
Taler licensing information
===========================

This file gives an overview of all Taler component's licensing and of
runtime dependencies thereof. For "component" here is meant a set of
source files which can be retrieved from a single repository.  If
components consist of sources under different licensing regimes, i.e.
because we want to enable third party developments to easily integrate
with Taler, those are described as well.

All components are generally released under Lesser GPL, GPL or Affero
GPL.  The main strategy is for libraries that third parties may need
to integrate with Taler to be under LGPL, standalone binaries and
testcases to be under GPL, and Web servers implementing Web services
to be under AGPL.

+++++++++++++++++++++++++
API (git://taler.net/api)
+++++++++++++++++++++++++

The specification has been jointly developed by INRIA and by individuals
being under the juridical subject called 'GNUnet e.V.'. For each source
file, the header indicated whose is holding the copyright, since some
parts have been taken "verbatim" from the GNUnet e.V. foundation, and
some other have been developed at INRIA "ex novo".

Generally, GNU GPLv3 license is used for them; see COPYING.GPL.


--------------------
Runtime dependencies
--------------------
This component has no runtime dependencies as it is supposed to generate
HTML.


++++++++++++++++++++++++++++++++++++++++++++++++++++++
Firefox/Android/Python Wallet (git://taler.net/wallet)
++++++++++++++++++++++++++++++++++++++++++++++++++++++

This project includes contributions from INRIA and GNUnet
e.V. developers.  Please refer to each source file to obtain
information about the copyright holder. The GNU GPLv3 is used as the
license for Wallets.  Some components may be under the LGPL.

--------------------
Runtime dependencies
--------------------

The following list encompasses all the runtime dependencies for this
project, and gives the copyright holder for each of them:

* libgnunetutil: GPLv3+, GNUnet e.V.
* libgnunetjson: GPLv3+, GNUnet e.V.
* libgcrypt: LGPL, Free Software Foundation
* libunistring: LGPL, Free Software Foundation
* Python:   Python Software Foundation License, LGPL-Compatible, Python Software Foundation
* Mozilla Firefox:   Mozilla Public License, LGPL-Compatible, Mozilla Foundation


+++++++++++++++++++++++++++++++++++++++++++++++++++
WebExtensions Wallet (git://taler.net/wallet-webex)
+++++++++++++++++++++++++++++++++++++++++++++++++++

The TypeScript code was developed 100% at INRIA, but the project
involves compiling libgnunetutil and libtalerutil to JavaScript, and
thus depends on software from GNUnet e.V.

Each source carries its own copyright holder(s), but it is generally
licensed under GPLv3+.

--------------------
Runtime dependencies
--------------------

The following list encompasses all the runtime dependencies for this
project, and gives the copyright holder for each of them:

* libgnunetutil: GPLv3+, GNUnet e.V.
* libgnunetjson: GPLv3+, GNUnet e.V.
* libgcrypt: LGPL, Free Software Foundation
* libunistring: LGPL, Free Software Foundation

Note that these dependencies are compiled into the extension and do
not appear as separate binary files.


+++++++++++++++++++++++++++++++++++
Merchant (git://taler.net/merchant)
+++++++++++++++++++++++++++++++++++

This project contains code under two different licenses, and whose
copyright is held by INRIA and/or GNUnet e.V..  Please refer to each
source file to know which party holds the copyright.

Source files are located in the following directories:

* src/lib/
* src/backend/
* src/backenddb/
* src/include/
* src/tests/
* examples/blog/
* examples/shop/
* copylib/

In examples/blog/articles/ we included a book by Richard Stallman.
It comes with its own permissive license (see COPYING in the
directory).


The merchant's backend (i.e. all the code in src/backend/) is under
the GNU Affero GPL as it depends on libgnunetutil.  Note that the use
of the Affero GPL has little impact as the backend is not supposed to
be directly accessible to the Internet).  The license for this code is
in COPYING.GPL and COPYING.AGPL.

The merchant's frontend logic (i.e. JavaScript interacting with
the wallet, sample code for a shop) is under the GNU LGPL (but
we may choose to change this to be in the public domain or
BSD-licensed if necessary; the code is so short that there is
anyway the question whether it is copyrightable).  Under this same
license, it comes the merchant library (src/lib/) as it can be linked
with more diverse licensed software.  The license text for this code
is in COPYING.LGPL.



--------------------
Runtime dependencies
--------------------

The following list encompasses all the runtime dependencies for this
project, and gives the copyright holder for each of them:

* libjansson: MIT License, AGPL- and LGPL-Compatible, owned by Petri Lehtinen and other individuals
* libgcrypt: LGPL, owned by Free Software Foundation
* postgresql: PostgreSQL License, AGPL- and LGPL-Compatible, owned by The PostgreSQL Global Development Group
* libgnunetutil (in all of its variants): GPLv3+, owned by GNUnet e.V.
* PHP:  PHP License, AGPL- and LGPL-Compatible, owned by The PHP Group

+++++++++++++++++++++++++++
Bank (git://taler.net/bank)
+++++++++++++++++++++++++++

---------
Licensing
---------

This project has been developed by INRIA.  For each source file, the
header indicated whose is holding the copyright.  The licensing plan
for the bank is to use the Affero GPLv3+.

Source files of interest are located in the following directories:
(The repository holds also scaffolded files autogenerated by Django,
which do not have legal significance in this context.)

* TalerBank/Bank/
* TalerBank/Bank/templates/
* TalerBank/my-static/
* website/

--------------------
Runtime dependencies
--------------------

The following list encompasses all the runtime dependencies for this
project, and gives the copyright holder for each of them:

* Django:   BSD License, AGPL-Compatible, owned by Django Software Foundation
* validictory:   BSD License, AGPL-Compatible, owned by James Turk
* django-simple-math-captcha:   Apache Software License, LGPL-Compatible (FIXME), Brandon Taylor
* requests:   Apache2 License, AGPL-Compatible, owned by Kenneth Reitz
* Python:   Python Software Foundation License, AGPL-Compatible, Python Software Foundation
* PHP:   PHP License, AGPL-Compatible, owned by The PHP Group


+++++++++++++++++++++++++++++++++++
Exchange (git://taler.net/exchange)
+++++++++++++++++++++++++++++++++++

This component is based on code initially developed in Munich for
GNUnet e.V.  Most recent improvements and maintenance has been done at
Inria.  The copyright is thus shared between both institutions.

The licensing for exported libraries to access the exchange is LGPL,
the exchange itself is under AGPL, and testcases and standalone
binaries are under GPL.


--------------------
Runtime dependencies
--------------------

The following list encompasses all the runtime dependencies for this
project, and gives the copyright holder for each of them:

* libjansson: MIT License, AGPL- and LGPL-Compatible, owned by Petri Lehtinen and other individuals
* libgcrypt: LGPL, owned by Free Software Foundation
* postgresql: PostgreSQL License, AGPL- and LGPL-Compatible, owned by The PostgreSQL Global Development Group
* libgnunetutil (in all of its variants): GPLv3+, owned by GNUnet e.V.
* libgnunetjson: GPLv3+, GNUnet e.V.


+++++++++++++++++++++++++++++++++++++++++
Web includes (git://taler.net/web-common)
+++++++++++++++++++++++++++++++++++++++++

All copyright owned by INRIA (but questionable whether creativity
threshold for copyright is even met).

Sources are licensed under the GNU LGPL.
