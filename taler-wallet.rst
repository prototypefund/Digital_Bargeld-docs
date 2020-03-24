GNU Taler Wallet Manual
#######################

The GNU Taler wallet allows customers to withdraw and spend digital cash.

.. _command-line-wallet:

Command-line Wallet
===================

The command-line wallet is used primarily for testing by developers.

Building from source
--------------------

.. code-block:: sh

  $ git clone https://git.taler.net/wallet-core.git
  $ ./bootstrap
  $ cd wallet-core
  $ ./configure --prefix=$INSTALL_PREFIX
  $ make && make install

The wallet command-line interface should then be available as ``taler-wallet-cli`` under ``$INSTALL_PREFIX/bin``.

Installation via NPM
--------------------

The wallet can also obtained via NPM, the Node Package Manager.

To install the wallet as a global package, run:

.. code-block:: sh

  $ npm install -g taler-wallet
  # check if installation was successful
  $ taler-wallet-cli --version

To install the wallet only for your user, run:

.. code-block:: sh

  $ npm install -g --prefix=$HOME/local taler-wallet
  # check if installation was successful
  $ taler-wallet-cli --version
  # If this fails, make sure that $HOME/local/bin is in your $PATH

To use the wallet as a library in your own project, run:

.. code-block:: sh

  $ npm install taler-wallet


WebExtension Wallet
===================

Building from source
--------------------

.. code-block:: sh

  $ git clone https://git.taler.net/wallet-core.git
  $ cd wallet-core
  $ ./configure
  $ make webex-stable
  # Packaged extension now available as:
  # dist/taler-wallet-$VERSION.zip


Android Wallet
==============

*TBD.*


APIs and Data Formats
=====================

*TBD.*
