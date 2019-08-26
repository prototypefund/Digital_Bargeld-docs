====================
The taler URI scheme
====================

The `taler` URI scheme represents actions that are processed by a Taler wallet.  The basic syntax is as follows:

.. code:: none

  'taler://' action '/' params

--------------------
Requesting a Payment
--------------------

Payments are requested with the `pay` action.  The parameters are a hierarchical identifier for the requested payment:


.. code:: none

  'taler://pay/' merchant-host '/' merchant-query '/' merchant-instance  '/' order-id [ '/' session-id ]

The components `merchant-host`, `merchant-query` and `order-id` identify the URL that is used to claim the contract
for this payment request.

To make the URI shorter (which is important for QR code payments), `-` (minus) can be substituted to get a default value
for some components:

* the default for `merchant-instance` is `default`
* the default for `merchant-query` is `/public/proposal`

The following is a minimal example for a payment request from the demo merchant, using the default instance and no session-bound payment:

.. code:: none

  taler://pay/backend.demo.taler.net/-/-/2019.08.26-ABCED

