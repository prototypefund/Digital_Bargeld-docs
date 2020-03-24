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



Integration Test Example
========================

Integration tests can be done with the low-level wallet commands.  To select which coins and denominations
to use, the wallet can dump the coins in an easy-to-process format (`CoinDumpJson <https://git.taler.net/wallet-core.git/tree/src/types/talerTypes.ts#n734>`__).

The database file for the wallet can be selected with the ``--wallet-db``
option.  This option must be passed to the ``taler-wallet-cli`` command and not
the subcommands.  If the database file doesn't exist, it will be created.

The following example does a simple withdrawal recoup:

.. code-block:: sh

  # Withdraw digital cash
  $ taler-wallet-cli --wallet-db=mydb.json testing withdraw \
      -b https://bank.int.taler.net/ \
      -e https://exchange.int.taler.net/ \
      -a INTKUDOS:10

  $ coins=$(taler-wallet-cli --wallet-db=mydb.json advanced dump-coins)

  # Find coin we want to revoke
  $ rc=$(echo "$coins" | jq -r '[.coins[] | select((.denom_value == "INTKUDOS:5"))][0] | .coin_pub')
  # Find the denom
  $ rd=$(echo "$coins" | jq -r '[.coins[] | select((.denom_value == "INTKUDOS:5"))][0] | .denom_pub_hash')
  # Find all other coins, which will be suspended
  $ susp=$(echo "$coins" | jq --arg rc "$rc" '[.coins[] | select(.coin_pub != $rc) | .coin_pub]')

  # The exchange revokes the denom
  $ taler-exchange-keyup -r $rd
  $ taler-deployment-restart

  # Now we suspend the other coins, so later we will pay with the recouped coin
  $ taler-wallet-cli --wallet-db=mydb.json advanced suspend-coins "$susp"

  # Update exchange /keys so recoup gets scheduled
  $ taler-wallet-cli --wallet-db=mydb.json exchanges update -f https://exchange.int.taler.net/

  # Block until scheduled operations are done
  $ taler-wallet-cli --wallet-db=mydb.json run-until-done

  # Now we buy something, only the coins resulting from recouped will be
  # used, as other ones are suspended
  $ taler-wallet-cli --wallet-db=mydb.json testing test-pay -m https://backend.int.taler.net/ -k sandbox -a "INTKUDOS:1" -s "foo"
  $ taler-wallet-cli --wallet-db=mydb.json run-until-done


To test refreshing, force a refresh:

.. code-block:: sh

  $ taler-wallet-cli --wallet-db=mydb.json advanced force-refresh "$coin_pub"


To test zombie coins, use the timetravel option. It **must** be passed to the
top-level command and not the subcommand:

.. code-block:: sh

  # Update exchange /keys with time travel, value in microseconds
  $ taler-wallet-cli --timetravel=1000000 --wallet-db=mydb.json exchanges update -f https://exchange.int.taler.net/

