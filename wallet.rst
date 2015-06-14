====================
The Wallet Reference
====================

  .. note::
     
     This documentation goes in parallel with the wallet's development, so is to be considered as `work in pregress`
     until a first operative version of the wallet will be released. 


This section explains how to set up a wallet. It is worth noting that there are two versions for
this componenet - one browser based and the other implemented as an `app` for mobile systems.

--------------------
Browser based wallet
--------------------

This paragraph gives instructions on how to proceed from getting the source code to build the final `.xpi` that can be installed into the Web browser.

  .. note::

     In this phase of development only support for Mozilla Firefox is provided.


.. ^^^^^^^^^^^^^^^^^^^^^^^.
.. Getting the source code.
.. ^^^^^^^^^^^^^^^^^^^^^^^.

*clone* into our repository to get the latest version of the code,

  .. sourcecode:: bash

     git clone http://git.taler.net/wallet.git

the actual build of the `.xpi` file is managed by `make`, so

  .. sourcecode:: bash

     cd wallet/wallet_button/firefox_src/
     make

The extension is now placed in ``wallet/wallet_button/bin/``, called ``taler-button.xpi``. To load
it into the Web browser, it suffices to open it as a normal file or it could even be placed on the
Web and installed by just visiting its URI.


^^^^^^^^^^
Emscripten
^^^^^^^^^^

Since the wallet makes extensive use of cryptographic primitives, it relies on a library called ``libgnunetutils_taler_wallet``
from the `gnunet <https://gnunet.org>`_ project. Moreover, since that library depends on `libgpg-error`, `libgcrypt` and `libunistring`,
and the non markup part of the extension is JavaScript, a language-to-language compiler such as `Emscripten <http://emscripten.org>`_ has
been used to port `C` sources to JavaScript.

  .. note::
     
     To just compile the extension and install it into your browser, it suffices to follow the above steps and simply ignore
     this section. That is possible since `git master` ships a previously made JavaScript version of ``libgnunetutil_taler_wallet``,
     that the extension is properly linked against to. So this section is dedicated to those who want to reproduce the steps
     needed to port all the required libraries to JavaScript.


 We begin by getting the sources for all the needed parts, so issue the following commands


  .. sourcecode:: bash

     git://git.gnupg.org/libgpg-error.git # code downloaded in 'libgpg-error/'
     git://git.gnupg.org/libgcrypt.git # code downloaded in 'libgcrypt/'
     git://git.savannah.gnu.org/libunistring.git # code downloaded in 'libunistring/'
     svn co https://gnunet.org/svn/gnunet # code downloaded in 'gnunet/'

Before delving into the proper compilation, let's assume that the wallet `git master` has been cloned into
some direcory called ``wallet``.
In ``wallet/wallet_button/emscripten/${component}``, where ``${component}`` ranges over ``libgpg-error``, ``libgcrypt``,
``libunistring`` and ``gnunet``, there is a shell script called ``myconf-${component}.sh`` that will take care of
configuring and building any component.

To install emscripten, refer to the `official documentation <http://kripken.github.io/emscripten-site/docs/getting_started/downloads.html#sdk-download-and-install>`_.
It is worth noting that all our tests have been run using the `emscripten SDK`, though any other alternative method of setting up emscripten should work.

At the time of this writing the following versions have been used for each component

* libgcrypt  1.7 (commit a36ee7501f68ad7ebcfe31f9659430b9d2c3ddd1)
* libgpg-error  1.19 (commit 4171d61a97d9628532db84b590a9c135f360fa90)
* libunistring  0.9.5 (commit 4b0cfb0e39796400149767bdeb6097927895635a)
* gnunet 0.10.1 (commit r35923)
* emscripten 1.33.2

To configure and build any component, it suffices to copy the provided script into any tree of the targeted component,

  .. sourcecode:: bash

     cp wallet/wallet_button/emscripten/${component}/myconf-${component}.sh ${component}/

Then to generate the native configure script,


  .. sourcecode:: bash

     cd ${component}
     ./autogen.sh

Finally, run the provided script (any final file will be placed under ``/tmp``)

  .. sourcecode:: bash

     ./myconf-${component}.sh

At this point, you have the header files and the static library for each component compiled in the `LLVM` intermediate
form. To see some final JavaScript, it is needed to compile a `C` program, though that is not the only way (once again,
refer to the official `emscripten's documentation <http://kripken.github.io/emscripten-site/docs/compiling/Building-Projects.html#building-projects>`_),
against the libraries we have just built.

Some simple tests written in `C` are placed into our wallte's source tree, so

  .. sourcecode:: bash

     cd wallet/wallet_button/emscripten/hello_world/
     source final_build-${X} # with ${X} being the prefix of some ${X}.c

Your environment has now two functions, ``assmb`` and ``linkit``, where the former will just assemble
the test ``${X}.c`` (leaving a file named ``${X}.o`` inspectable by ``llvm-nm`` or ``llvm-objdump``) and
the latter will link the final JavaScript called ``${X}.js``.

Thus, to see the final product, issue


  .. sourcecode:: bash

     assmb
     linkit
     nodejs ${X}.js # some pretty output will show up!
