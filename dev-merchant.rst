=================================
Merchant Reference Implementation
=================================

-----------------------
Architectural Overview
-----------------------

The merchant reference implementationis divided into two independent
compontents, the `frontend` and the `backend`.

The `frontend` is the existing shopping portal of the merchant.
The architecture tries to minimize the amount of modifications necessary
to the `frontend` as well as the trust that needs to be placed into the
`frontend` logic.  Taler requires the frontend to facilitate two
JSON-based interactions between the wallet and the `backend`, and
one of those is trivial.

The `backend` is a standalone C application intended to implement all
the cryptographic routines required to interact with the Taler wallet
and a Taler mint.


------------------------------
The Merchant Backend HTTP API
------------------------------

The following API are made available by the merchant's `backend` to the merchant's `frontend`.

.. http:post:: /contract

  Ask the backend to add some missing (mostly related to cryptography) information to the contract.

  :reqheader Content-Type: application/json

  The `proposition` that is to be sent from the frontend is a `contract` object without the fields

  * `merchant_pub`
  * `mints`
  * `H_wire`

  The `backend` then completes this information based on its configuration.

  **Success Response**

  :status 200 OK: The backend has successfully created the contract.
  :resheader Content-Type: application/json

  The `frontend` should pass this response verbatim to the wallet.

  **Failure Responses: Bad contract**

  :status 400 Bad Request: Request not understood. The JSON was invalid. Possibly due to some error in formatting the JSON by the `frontend`.

.. http:post:: /pay

  Asks the `backend` to execute the transaction with the mint and deposit the coins.

  :reqheader Content-Type: application/json

  The `frontend` passes the :ref:`deposit permission <deposit-permission>` received from the wallet, by adding the fields `max_fee`, `amount` (see :ref:`contract`) and optionally adding a field named `edate`, indicating a deadline by which he would expect to receive the bank transfer for this deal

  **Success Response: OK**

  :status 200 OK: The mint accepted all of the coins. The `frontend` should now fullfill the contract.  This response has no meaningful body, the frontend needs to generate the fullfillment page.

  **Failure Responses: Bad mint**

  :status 400 Precondition failed: The given mint is not acceptable for this merchant, as it is not in the list of accepted mints and not audited by an approved auditor.


  **Failure Responses: Mint trouble**

  The `backend` will return verbatim the error codes received from the mint's :ref:`deposit <deposit>` API.  If the wallet made a mistake, like by double-spending for example, the `frontend` should pass the reply verbatim to the browser/wallet. This should be the expected case, as the `frontend` cannot really make mistakes; the only reasonable exception is if the `backend` is unavailable, in which case the customer might appreciate some reassurance that the merchant is working on getting his systems back online.
