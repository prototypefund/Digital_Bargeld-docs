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

.. warning::

  These APIs are still a work in progress and *not* final.

Transactions
------------

Transactions are all operations or events that are affecting the balance.

:name: ``"transactions"``
:description: Get a list of past and pending transactions.
:request:
  .. ts:def:: TransactionsRequest

    interface TransactionsRequest {
      // return only transactions in the given currency
      currency: string;

      // if present, results will be limited to transactions related to the given search string
      search?: string;
    }
:response:
  .. ts:def:: TransactionsResponse

    interface TransactionsResponse {
      // a list of past and pending transactions
      transactions: Transaction[];
    }

  .. ts:def:: Transaction

    interface Transaction {
      // opaque unique ID for the transaction, used as a starting point for paginating queries
      // and for invoking actions on the transaction (e.g. deleting/hiding it from the history)
      transactionId: string;

      // the type of the transaction; different types might provide additional information
      type: TransactionType;

      // main timestamp of the transaction
      timestamp: Timestamp;

      // true if the transaction is still pending, false otherwise
      pending: boolean;
    }

  .. ts:def:: TransactionType

    type TransactionType = (
      TransactionWithdrawal |
      TransactionPayment |
      TransactionRefund |
      TransactionTip
    )

  .. ts:def:: TransactionWithdrawal

    // This should only be used for actual withdrawals
    // and not for tips that have their own transactions type.
    interface TransactionWithdrawal extends Transaction {
      type: string = "withdrawal",

      // Exchange that was withdrawn from.
      exchangeBaseUrl: string;

      // true if the bank has confirmed the withdrawal, false if not.
      // An unconfirmed withdrawal usually requires user-input and should be highlighted in the UI.
      // See also bankConfirmationUrl below.
      confirmed: boolean;

      // If the withdrawal is unconfirmed, this can include a URL for user initiated confirmation.
      bankConfirmationUrl?: string;

      // Amount that has been subtracted from the reserve's balance for this withdrawal.
      amountRaw: Amount;

      // Amount that actually was (or will be) added to the wallet's balance.
      amountEffective: Amount;
    }

  .. ts:def:: TransactionPayment

    interface TransactionPayment extends Transaction {
      type: string = "payment",

      // Additional information about the payment.
      info: TransactionInfo;

      // Amount that was paid, including deposit, wire and refresh fees.
      amountEffective: Amount;
    }

  .. ts:def:: TransactionInfo

    interface TransactionInfo {
      // Order ID, uniquely identifies the order within a merchant instance
      orderId: string;

      // More information about the merchant
      merchant: Merchant;

      // Amount that must be paid for the contract
      amount: Amount;

      // Summary of the order, given by the merchant
      summary: string;

      // Map from IETF BCP 47 language tags to localized summaries
      summary_i18n?: { [lang_tag: string]: string };

      // List of products that are part of the order
      products: Product[];

      // URL of the fulfillment, given by the merchant
      fulfillmentUrl: string;
    }

  .. ts:def:: TransactionRefund

    interface TransactionRefund extends Transaction {
      type: string = "refund",

      // Additional information about the refunded payment
      info: TransactionInfo;

      // Part of the refund that couldn't be applied because the refund permissions were expired
      amountInvalid: Amount;

      // Amount that has been refunded by the merchant
      amountRaw: Amount;

      // Amount will be added to the wallet's balance after fees and refreshing
      amountEffective: Amount;
    }

  .. ts:def:: TransactionTip

    interface TransactionTip extends Transaction {
      type: string = "tip",

      // true if the user still needs to accept/decline this tip
      waiting: boolean;

      // true if the user has accepted this top, false otherwise
      accepted: boolean;

      // Exchange that the tip will be (or was) withdrawn from
      exchangeBaseUrl: string;

      // More information about the merchant that sent the tip
      merchant: Merchant;

      // Raw amount of the tip, without extra fees that apply
      amountRaw: Amount;

      // Amount will be (or was) added to the wallet's balance after fees and refreshing
      amountEffective: Amount;
    }

Refunds
-------

:name: ``"applyRefund"``
:description: Process a refund from a ``taler://refund`` URI.
:request:
  .. ts:def:: WalletApplyRefundRequest

    interface WalletApplyRefundRequest {
      talerRefundUri: string;
    }
:response:
  .. ts:def:: WalletApplyRefundResponse

    interface WalletApplyRefundResponse {
      // Identifier for the purchase that was refunded
      contractTermsHash: string;
    }


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

