===========================
Taler licensing information
===========================

This file gives an overview of all Taler component's licensing
and of runtime dependencies thereof. For "component" here is meant
a set of source files which can be retrieved from a single repository

+++++++++++++++++++++++++
API (git://taler.net/api)
+++++++++++++++++++++++++

This project has been jointly developed by INRIA and by individuals
being under the juridical subject called 'GNUnet e.V.'. For each source
file, the header indicated whose is holding the copyright, since some
parts have been taken "verbatim" from the GNUnet e.V. licensed code, and
some other have been developed at INRIA "ex novo".

Generally, GNU GPLv3 license is used for them; see COPYING.GPL

--------------------
Runtime dependencies
--------------------
This component has no runtime dependencies as it is supposed to generate
HTML.

++++++++++++++++++++++++++++++++++++++++++++++++++++++
Firefox/Android/Python Wallet (git://taler.net/wallet)
++++++++++++++++++++++++++++++++++++++++++++++++++++++
This project is divided between INRIA and individuals working/studying
at TUM, so does the copyright. Please refer to each source file to obtain
information about the copyright holder. License GNU GPLv3 is used for "final
applications", like for example a browser extension, and LGPL is used for
libraries made available

--------------------
Runtime dependencies
--------------------
We list as 'runtime dependencies'

* shared libraries (namely \*.so files)
* running services (like databases)
* languages interpreters (like PHP)

The following list encompasses all the runtime dependencies for this project,
and gives the copyright holder for each of them

* Python:   Python Software Foundation License, LGPL-Compatible, Python Software Foundation
* Mozilla Firefox:   Mozilla Public License, LGPL-Compatible, Mozilla Foundation

+++++++++++++++++++++++++++++++++++++++++++++++++++
WebExtensions Wallet (git://taler.net/wallet-webex)
+++++++++++++++++++++++++++++++++++++++++++++++++++

Project developed 100% at INRIA with legacy from GNUnet e.V. owned software.
So each source carries its own copyright holder(s), but it is generally licensed
under GPL.

--------------------
Runtime dependencies
--------------------
There is no specific runtime dependency since this component just uses API defined
by Google, but it is not specifically tied to any Google product

+++++++++++++++++++++++++++++++++++
Merchant (git://taler.net/merchant)
+++++++++++++++++++++++++++++++++++
This project contains code under two different licenses,
and whose copyright is held by INRIA and/or GNUnet e.V..
Please refer to each source file to know which party holds
the copyright.

The merchant's backend (i.e. all the code in src/backend/)
is under the GNU GPLv3+ and/or the GNU Affero GPL as it
depends on libgnunetutil.  Note that the use of the Affero
GPL has little impact as the backend is not supposed to be
directly accessible to the Internet).  The license for this
code is in COPYING.GPL and COPYING.AGPL.

The merchant's frontend logic (i.e. JavaScript interacting with
the wallet, sample code for a shop) is under the GNU LGPL (but
we may choose to change this to be in the public domain or
BSD-licensed if necessary; the code is so short that there is
anyway the question whether it is copyrightable).  Under this same
license, it comes the merchant library (src/lib/) as it can be linked
with more diverse licensed software.  The license text for this code
is in COPYING.LGPL.


In examples/blog/articles/ we included a book by Richard Stallman.
It comes with its own permissive license (see COPYING in the
directory).

--------------------
Runtime dependencies
--------------------
We list as 'runtime dependencies'

* shared libraries (namely \*.so files)
* running services (like databases)
* languages interpreters (like PHP)

The following list encompasses all the runtime dependencies for this project,
and gives the copyright holder for each of them

* libjansson : MIT License, AGPL- and LGPL-Compatible, owned by Petri Lehtinen and other individuals
* libgcrypt : LGPL, owned by Free Software Foundation
* postgresql : PostgreSQL License, AGPL- and LGPL-Compatible, owned by The PostgreSQL Global Development Group
* libgnunet (in all of its variants) : LGPL/GPL, owned by GNUnet e.V.
* PHP :  PHP License, AGPL- and LGPL-Compatible, owned by The PHP Group

+++++++++++++++++++++++++++
Bank (git://taler.net/bank)
+++++++++++++++++++++++++++

---------
Licensing
---------

This project has been jointly developed by INRIA and by individuals
being under the juridical subject called 'GNUnet e.V.'. For each source
file, the header indicated whose is holding the copyright, since some
parts have been taken "verbatim" from the GNUnet e.V. licensed code, and
some other have been developed at INRIA "ex novo".  A GNU LGPL is used
for this project, as it is meant to be a online "service"

Source files of interest are located in the following directories:
(The repository holds also scaffolded files autogenerated by Django,
which do not have legal significance in this context)

* TalerBank/Bank/
* TalerBank/Bank/templates/
* TalerBank/my-static/
* website/

--------------------
Runtime dependencies
--------------------
We list as 'runtime dependencies'

* shared libraries (namely \*.so files)
* running services (like databases)
* languages interpreters (like PHP)

The following list encompasses all the runtime dependencies for this project,
and gives the copyright holder for each of them

* Django:   BSD License, AGPL-Compatible, owned by Django Software Foundation
* validictory:   BSD License, AGPL-Compatible, owned by James Turk 
* django-simple-math-captcha:   Apache Software License, LGPL-Compatible (FIXME), Brandon Taylor
* requests:   Apache2 License, AGPL-Compatible, owned by Kenneth Reitz
* Python:   Python Software Foundation License, AGPL-Compatible, Python Software Foundation
* PHP:   PHP License, AGPL-Compatible, owned by The PHP Group

+++++++++++++++++++++++++++++++++++
Exchange (git://taler.net/exchange)
+++++++++++++++++++++++++++++++++++

Mostly developed by TUM students/researcher, therefore the copyright for this
component is mainly owned by GNUnet e.V.. The licensing broads between GNU GPL/AGPL/LGPL

--------------------
Runtime dependencies
--------------------
We list as 'runtime dependencies'

* shared libraries (namely \*.so files)
* running services (like databases)
* languages interpreters (like PHP)

The following list encompasses all the runtime dependencies for this project,
and gives the copyright holder for each of them

* libjansson : MIT License, AGPL- and LGPL-Compatible, owned by Petri Lehtinen and other individuals
* libgcrypt : LGPL, owned by Free Software Foundation
* postgresql : PostgreSQL License, AGPL- and LGPL-Compatible, owned by The PostgreSQL Global Development Group
* libgnunet (in all of its variants) : LGPL/GPL, owned by GNUnet e.V.

+++++++++++++++++++++++++++++++++++++++++
Web includes (git://taler.net/web-common)
+++++++++++++++++++++++++++++++++++++++++
All copyright owned by INRIA. Sources licensed with GNU LGPL
