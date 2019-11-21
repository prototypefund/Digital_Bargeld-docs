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

This section describes the wallet backend API.  The goal of this API is to
be easy to consume without having to implement Taler-specific data formats
or algorithms.  This is why some redundancy is present, for example in
how amounts are returned.

Balance
-------

The balance is computed with different types of "slicing":

* ``byExchange``:  Balance by the exchange it was withdrawn from
* ``byAuditor``:  Balance by each auditor trusted by the wallet
* ``byCurrency``: Balance by currency

Each balance entry contains the following information:

* ``amountCurrent``: Amount available to spend **right now**
* ``amountAvailable``: Amount available to spend after refresh and withdrawal
  operations have completed.
* ``amountPendingOutgoing``:  Amount that is allocated to be spent on a payment
  but hasn't been spent yet.
* ``amountPendingIncoming``: Amount that will be available but is not available yet
  (from refreshing and withdrawal)
* ``amountPendingIncomingWithdrawal``: Amount that will be available from pending withdrawals
* ``amountPendingIncomingRefresh``: Amount that will be available from pending refreshes


History
-------

All events contain a ``type``, a ``timestamp`` and a ``eventUID``.  When
querying the event history, a level can be specified.  Only events with a
verbosity level ``<=`` the queried level are returned.

The following event types are available:

``exchange-added``
  Emitted when an exchange has ben added to the wallet.

``exchange-update-started``
  Emitted when updating an exchange has started.

``exchange-update-finished``
  Emitted when updating an exchange has started.

``reserve-created`` (Level 1)
  A reserve has been created.  Contains the following detail fields:

  * ``exchangeBaseUrl``
  * ``reservePub``: Public key of the reserve
  * ``expectedAmount``: Amount that is expected to be in the reserve.
  * ``reserveType``: How was the reserve created?  Can be ``taler-withdraw`` when
    created by dereferencing a ``taler://pay`` URI or ``manual`` when the reserve
    has been created manually.

``reserve-bank-confirmed`` (Level 1)
  Only applies to reserves with ``reserveType`` of ``taler-withdraw``.
  This event is emitted when the wallet has successfully sent the details about the
  withdrawal (reserve key, selected exchange).

``reserve-exchange-confirmed`` (Level 0)
  This event is emitted the first time that the exchange returns a success result
  for querying the status of the resere.

  * ``exchangeBaseUrl``
  * ``reservePub``: Public key of the reserve
  * ``currentAmount``: Amount that is expected to be in the reserve.

``reserve-exchange-updated`` (Level 0)
  Emitted when a reserve has been updated **and** the remaining amount has changed.

``withdraw-started`` (Level 1)
  Emitted when the wallet starts a withdrawal from a reserve.  Contains the following detail fields:

  * ``withdrawReason``:  Why was the withdraw started?  Can be ``initial`` (first withdrawal to drain a
    reserve), ``repeat`` (withdrawing from a manually topped-up reserve) or ``tip``
  * ``withdrawRawAmount``: Amount that is subtracted from the reserve, includes fees.
  * ``withdrawEffectiveAmount``: Amount that will be added to the balance.

``withdraw-coin-finished`` (Level 2)
  An individual coin has been successfully withdrawn.
  
``withdraw-finished`` (Level 0)
  Withdraw was successful.  Details:

  * ``withdrawRawAmount``: Amount that is subtracted from the reserve, includes fees.
  * ``withdrawEffectiveAmount``: Amount that will be added to the balance.

``order-offered`` (Level 1)
  A merchant has offered the wallet to download an order.

``order-claimed`` (Level 1)
  The wallet has downloaded and claimed an order.

``order-pay-confirmed`` (Level 0)
  The wallet's user(-agent) has confirmed that a payment should
  be made for this order.

``pay-coin-finished`` (Level 2)
  A coin has been sent successfully to the merchant.

``pay-finished`` (Level 0)
  An order has been paid for successfully for the first time.
  This event is not emitted for payment re-playing.

``refresh-started`` (Level 1)
  A refresh session (one or more coins) has been started.  Details:

  * ``refreshReason``: One of ``forced``, ``pay`` or ``refund``.

``refresh-coin-finished`` (Level 2)
  Refreshing a single coin has succeeded.

``refresh-finished`` (Level 0)
  A refresh session has succeeded.

``tip-offered`` (Level 1)
  A tip has been offered, but not accepted yet.

``tip-accepted`` (Level 1)
  A tip has been accepted.  Together with this event,
  a corresponding ``withdraw-started`` event is also emitted.

``refund`` (Level 0)
  The wallet has been notified about a refund.  A corresponding
  ``refresh-started`` event with ``refreshReason`` set to ``refund``
  will be emitted as well.


Pending Operations
------------------


``exchange-update``:
  Shown when exchange information (``/keys`` and ``/wire``) is being updated.

``reserve``:
  Shown when a reserve has been created (manually or via dereferencing a ``taler://withdraw`` URI),
  but the reserve has not been confirmed yet.

  Details:

  * ``reserveType``: How was the reserve created?  Can be ``taler-withdraw`` when
    created by dereferencing a ``taler://pay`` URI or ``manual`` when the reserve
    has been created manually.
  * ``expectedAmount``:  Amount we expect to be in the reserve.
  * ``status``: Either ``new`` or ``confirmed-bank``.
  * ``lastError``:  If present, contains the last error pertaining to the reserve,
    either from the bank or from the exchange.

  **Rendering**: The pending operation is rendered as "waiting for money transfer".

``withdrawal``
  Shown when a withdrawal is in progress (either from a reserve in the wallet or
  from tipping).

  Details:

  * ``exchangeBaseUrl``
  * ``coinsPending``
  * ``coinsWithdrawn``
  * ``amountWithdrawn``
  * ``amountPending``
  * ``totalWithdrawnAmount``:  Amount actually subtracted from the reserve, including fees
  * ``totalEffectiveAmount``: Amount that will be added to the balance
  * ``lastErrors``:  If present, contains the last error for every coin that is
    part of this withdrawal operation.

  **Rendering**: The pending operation is rendered as "withdrawing digital cash".

``pay``
  Shown when a payment is in progress.

  Details:

  * ``amountPrice``: Price of the order that is being purchased
  * ``coinsPaid``: Number of coins successfully submitted as payment.
  * ``coinsPending``: Number of coins successfully submitted as payment.
  * ``amountEffectivePrice``: Effective price, including fees for refreshing *and*
    coins that are too small to refresh.
  * ``lastErrors``:  If present, contains the last error for every coin that is
    part of this pay operation.

  **Rendering**: The pending operation is rendered as "paying".

``refresh``
  Shown when a refresh is in progress, either one that's manually forced, one
  after payment, or one after a refund.

  Details:

  * ``refreshReason``: One of ``forced``, ``pay`` or ``refund``
  * ``totalRefreshedAmount``: Amount that has been successfully refreshed
    as part of this session
  * ``coinsPending``: Number of coins that are part of the refresh operation, but
    haven't been processed yet.
  * ``coinsMelted``:  Number of coins that have been successfully melted.
  * ``coinsRefreshed``: Number of coins that have been successfully refreshed.
  * ``lastErrors``:  If present, contains the last error for every coin that is
    part of this refresh operation.

  **Rendering**: The pending operation is rendered as "fetching change", optionally
  with "(after manual request)", "(after payment") or "(after refund)".

``refund``
  Shown when a merchant's refund permission is handed to the exchange.

``tip``
  Shown when a tip is being picked up from the merchant
