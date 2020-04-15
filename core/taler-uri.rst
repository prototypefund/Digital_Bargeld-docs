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

  'taler://pay/' merchant-host '/' merchant-public-prefix '/' merchant-instance '/' orderId [ '/' sessionId ]

The components ``merchant-host``, ``merchant-public-prefix`` and ``orderId`` identify the URL that is used to claim the contract
for the payment request.

To make the URI shorter (which is important for QR code payments), ``merchant-public-prefix`` and/or ``merchant-instance`` can be substituted by ``-`` (minus) to get a default value
for these components:

* the default for ``merchant-public-prefix`` is ``public``
* the default for ``merchant-instance`` is ``default``

The following is a minimal example for a payment request from the demo merchant, using the default instance and no session-bound payment:

.. code:: none

  'taler://pay/backend.demo.taler.net/-/-/2019.08.26-ABCED


------------------------
Withdrawing (Initiation)
------------------------

The action ``withdraw`` is invoked when a wallet urges a bank to declench the withdrawal operation by parsing its statusUrl (e.g. "https://bank.example.com/api/withdraw-operation/12345").

.. code:: none

  'taler://withdraw/' bank-host '/' bank-query '/' withdraw-uid

When the component ``bank-query`` is substituted by ``-`` (minus), the default ``withdraw-operation`` will be used.

Example for a withdrawal request from the Taler demo bank using the default instance:

.. code:: none

  'taler://withdraw/bank.taler.net/-/ABDE123

--------------------------
Withdrawing (Confirmation)
--------------------------

.. code:: none

  'taler://notify-reserve/' [ reserve-pub ]

This action notifies the wallet that the status of a reserve has changed. It is used
by the bank to indicate that the withdrawal has been confirmed by the user (e.g. via 2FA / mTAN / ...).
The wallet the re-checks the status of all unconfirmed reserves.

Optionally, ``reserve-pub`` can be specified to also indicate the reserve that
has been updated.


---------
Refunding
---------

Refunding is an action which is applied when merchants decide to recline from contracts or to reduce the sum to be paid by the customer.
The refund URI can be parsed with or without the component ``merchant-instance``.

.. code:: none

  'taler://refund/' merchant-host '/' merchant-public-prefix '/' merchant-instance '/' orderId
  
To make the URI shorter, ``merchant-public-prefix`` and/or ``merchant-instance`` can be substituted by ``-`` (minus) to get a default value
for these components:

* the default for ``merchant-public-prefix`` is ``public``
* the default for ``merchant-instance`` is ``default``

The following is a minimal example for a refunding request by the Taler demo merchant using the default instance:

.. code:: none

  taler://refund/merchant.example.com/-/-/1234

And this is an example for a refunding request by the Taler demo merchant parsing with a specified instance:

.. code:: none

  'taler://refund/merchant.example.com/-/myinst/1234


-------
Tipping
-------

Tipping is an action declenched by merchants' website servers to transfer to their visitors little values as a recompensation for bearing ads or committing services to the website (leaving comments on bought products or submitting data into forms...). The URI is named "taler tip pickup uri".

.. code:: none

  'taler://tip/' merchant-host '' merchant-public-prefix '/' merchant-instance '/' tipid
  
The tipping URI can be parsed without an instance, with an instance or with the instances AND prefixes specified, which means either the component ``merchant-instance`` OR the components ``merchant-public-prefix`` and ``merchant-instance`` can be left out to make the URI shorter.


* the default for ``merchant-public-prefix`` is ``public``
* the default for ``merchant-instance`` is ``default``

The following is a minimal example for a tipping request by the Taler demo merchant using the default instance:

.. code:: none

  'taler://tip/merchant.example.com/-/-/tipid

This is an example for a tipping request by the Taler demo merchant parsing with a specified instance:

.. code:: none

  'taler://tip/merchant.example.com/-/tipm/tipid

And this is an example for a tipping request by the Taler demo merchant parsing with specified prefix and instance:

.. code:: none

  'taler://tip/merchant.example.com/my%2fpfx/tipm/tipid


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

