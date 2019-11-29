.. _taler-uri-scheme:

=======================
The taler:// URI scheme
=======================

The ``taler`` URI scheme represents actions that are processed by a Taler wallet.  The basic syntax is as follows:

.. code:: none

  'taler://' action '/' params

--------------------
Requesting a Payment
--------------------

Payments are requested with the ``pay`` action.  The parameters are a hierarchical identifier for the requested payment:


.. code:: none

  'taler://pay/' merchant-host '/' merchant-public-prefix '/' merchant-instance  '/' order-id [ '/' session-id ]

The components ``merchant-host``, ``merchant-prefix`` and ``order-id`` identify the URL that is used to claim the contract
for this payment request.

To make the URI shorter (which is important for QR code payments), ``-`` (minus) can be substituted to get a default value
for some components:

* the default for ``merchant-instance`` is ``default``
* the default for ``merchant-public-prefix`` is ``public``

The following is a minimal example for a payment request from the demo merchant, using the default instance and no session-bound payment:

.. code:: none

  taler://pay/backend.demo.taler.net/-/-/2019.08.26-ABCED


------------------------
Withdrawing (Initiation)
------------------------

.. code:: none

  'taler://withdraw/' bank-host '/' bank-query '/' withdraw-uid

When ``bank-query`` is ``-``, the default ``withdraw-operation`` will be used.

Example:

.. code:: none

  'taler://withdraw/bank.taler.net/-/ABDE123

--------------------------
Withdrawing (Confirmation)
--------------------------

.. code:: none

  'taler://notify-reserve/' [ reserve-pub ]

Notify the wallet that the status of a reserve has changed.  Used
by the bank to indicate that the withdrawal has been confirmed by the
user (e.g. via 2FA / mTAN / ...).  The wallet the re-checks the
status of all unconfirmed reserves.

Optionally, ``reserve-pub`` can be specified to also indicate the reserve that
has been updated.


-------------------------
Low-level Reserve Actions
-------------------------

The following actions are deprecated.  They might not be supported
in newer wallets.

.. code:: none

  'taler://reserve-create/' reserve-pub

.. code:: none

  'taler://reserve-confirm/' query

----------------------------
Special URLs for fulfillment
----------------------------

The special ``fulfillment-success`` action can be used in a fulfillment URI to indicate success
with a message, without directing the user to a website.  This is useful in applications that are not Web-based:

When wallets encounter this URI in any other circumstance than going to a fulfillment URL, they must raise an error.

Example:

.. code:: none

  taler://fulfillment-success/Thank+you+for+donating+to+GNUnet

