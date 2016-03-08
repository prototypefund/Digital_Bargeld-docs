..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016 INRIA
  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU Lesser General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.
  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Marcello Stanisci
  @author Florian Dold

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
and a Taler exchange.



------------------------------
The Frontent HTTP API
------------------------------

.. http:get:: /taler/contract

  Triggers the contract generation. Note that the URL may differ between
  merchants.

  **Request:**

  The request depends entirely on the merchant implementation.

  **Response**

  :status 200 OK: The request was successful.  The body contains an :ref:`offer <offer>`.
  :status 400 Bad Request: Request not understood.
  :status 500 Internal Server Error:
    In most cases, some error occurred while the backend was generating the
    contract. For example, it failed to store it into its database.


------------------------------
The Merchant Backend HTTP API
------------------------------

The following API are made available by the merchant's `backend` to the merchant's `frontend`.

.. http:post:: /hash-contract
  
  Ask the backend to compute the hash of the `contract` given in the POST's body (the full contract
  should be the value of a JSON field named `contract`). This feature allows frontends to verify
  that names of resources which are going to be sold are actually `in` the paid cotnract. Without
  this feature, a malicious wallet can request resource A and pay for resource B without the frontend
  being aware of that.

  **Response**

  :status 200 OK:
    hash succesfully computed. The returned value is a JSON having one field called `hash` containing
    the hashed contract
  :status 400 Bad Request:
    Request not understood. The JSON was invalid. Possibly due to some error in
    formatting the JSON by the `frontend`.

.. http:post:: /contract

  Ask the backend to add some missing (mostly related to cryptography) information to the contract.

  **Request:**

  The `proposition` that is to be sent from the frontend is a `contract` object without the fields

  * `merchant_pub`
  * `exchanges`
  * `H_wire`

  The `backend` then completes this information based on its configuration.

  **Response**

  :status 200 OK:
    The backend has successfully created the contract.
  :status 400 Bad Request:
    Request not understood. The JSON was invalid. Possibly due to some error in
    formatting the JSON by the `frontend`.

  On success, the `frontend` should pass this response verbatim to the wallet.


.. http:post:: /pay

  Asks the `backend` to execute the transaction with the exchange and deposit the coins.

  **Request:**

  The `frontend` passes the :ref:`deposit permission <deposit-permission>`
  received from the wallet, by adding the fields `max_fee`, `amount` (see
  :ref:`contract`) and optionally adding a field named `edate`, indicating a
  deadline by which he would expect to receive the bank transfer for this deal

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins. The `frontend` should now fullfill the
    contract.  This response has no meaningful body, the frontend needs to
    generate the fullfillment page.
  :status 400 Precondition failed:
    The given exchange is not acceptable for this merchant, as it is not in the
    list of accepted exchanges and not audited by an approved auditor.


  The `backend` will return verbatim the error codes received from the exchange's
  :ref:`deposit <deposit>` API.  If the wallet made a mistake, like by
  double-spending for example, the `frontend` should pass the reply verbatim to
  the browser/wallet. This should be the expected case, as the `frontend`
  cannot really make mistakes; the only reasonable exception is if the
  `backend` is unavailable, in which case the customer might appreciate some
  reassurance that the merchant is working on getting his systems back online.
