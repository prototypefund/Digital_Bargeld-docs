..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016 INRIA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Marcello Stanisci
  @author Florian Dold
  @author Christian Grothoff

.. _merchant-api:

============
Merchant API
============

Before reading the API reference documentation, see the
`merchant architecture <https://docs.taler.net/dev-merchant.html#merchant-arch>`_
and the `payment protocol <https://docs.taler.net/integration-merchant.html#payprot>`_

---------------------
The Frontend HTTP API
---------------------

  Please refer to the `glossary <https://docs.taler.net/glossary.html>`_ for terms
  like `sketch`, `proposal`, `contract`, and others.


.. http:get:: proposal_url

  Requesting this URL generates a proposal, typically with a new (and unique) transaction id.  Note that the wallet will get properly triggered by the merchant in order
  to issue this GET request.  The merchant will also instruct the wallet whether or
  not to provide the optional `nonce` parameter.  `Payment protocol <https://docs.taler.net/integration-merchant.html#payprot>`_ explains how the wallet is triggered to
  fetch the proposal.

  **Request:**

  :query nonce: any value that is invertible by the wallet.  This value will be included in the sketch, so that when the wallet receives the proposal it can easily check whether it was the genuine receiver of the proposal it got.  This value is needed to avoid proposals' replications.

  **Response**

  :status 200 OK: The request was successful.  The body contains a :ref:`proposal <proposal>`.
  :status 400 Bad Request: Request not understood.
  :status 500 Internal Server Error:
    In most cases, some error occurred while the backend was generating the
    proposal. For example, it failed to store it into its database.

.. _pay:
.. http:post:: pay_url


  Send the deposit permission to the merchant. The client should POST a `DepositPermission`_
  object.  If the payment was processed successfully by the merchant, this URL will set session
  state that allows the fulfillment URL to show the final product.

  .. _DepositPermission:
  .. code-block:: tsref

    interface DepositPermission {
      // the hashed `wire details <wireformats>`_ of this merchant.
      // The wallet takes this value as-is from the proposal
      H_wire: HashCode;

      // `base32`_ encoded `TALER_ContractPS`_. The wallet can choose whether
      // to take this value obtained from the field `H_proposal` in the Proposal
      // it got beforehand, or regenerating one starting from the values it gets
      // within the contract
      H_proposal: HashCode;

      // a free-form identifier indiacting the current transaction.
      transaction_id: string;

      // total amount being paid as per the contract (the sum of the amounts
      // from the `coins` may be larger to cover deposit fees not covered by
      // the merchant)
      total_amount: Amount;

      // maximum fees merchant agreed to cover as per the contract
      max_fee: Amount;

      // The `merchant instance <https://docs.taler.net/operate-merchant.html#instances-lab>`_
      // which is going to receive the final wire transfer.
      instance: string;

      // Signature of `TALER_ContractPS`_
      merchant_sig: EddsaSignature;

      // a timestamp of this deposit permission. It equals just the proposal's timestamp
      timestamp: Timestamp;

      // Deadline for the customer to be refunded for this purchase
      refund_deadline: Timestamp;

      // Deadline for the customer to pay for this purchase. Note that it is up
      // to the frontend to make sure that this value matches the one the backend
      // signed over when the proposal was generated. The frontend should never
      // verify if the payment is still on time, because when payments are replayed
      // it is expxectable that this deadline is expired, and only the backend
      // can detect if a payment is a reply or not. 
      pay_deadline: Timestamp;

      // the chosen exchange's base URL
      exchange: string;

      // the coins used to sign the proposal
      coins: DepositedCoin[];

    }

  .. _`tsref-type-DepositedCoin`:

  .. code-block:: tsref

    interface DepositedCoin {
      // the amount this coin is paying for
      amount: Amount;

      // coin's public key
      coin_pub: RsaPublicKey;

      // denomination key
      denom_pub: RsaPublicKey;

      // exchange's signature over this `coin's public key <eddsa-coin-pub>`_
      ub_sig: RsaSignature;

      // Signature of `TALER_DepositRequestPS`_
      coin_sig: EddsaSignature;
    }

  **Success Response:**

  :status 301 Redirection: the merchant should redirect the client to his fullfillment page, where the good outcome of the purchase must be shown to the user.

  **Failure Responses:**

  The error codes and data sent to the wallet are a mere copy of those gotten from the exchange when attempting to pay. The section about :ref:`deposit <deposit>` explains them in detail.


.. http:post:: fulfillment_url

  Every fulfillment URL accounts for one purchase.  If the user buys three movies
  and one e-book, then the fulfillment URL will be such that for the merchant is
  possible to understand that the user wants those three movies and that e-book.

  It is also possible for the user to bookmark the fulfillment URL, so that he/she
  can replay the purchase and get the same items again in the future.

  .. note::
    By "replaying" a payment, we mean that the user reuses the same coins he
    used the first time he/she bought those items, thus not spending new coins
    (and therefore not spending additional money).


.. http:get:: /history

  Return a list of fulfilled contracts.  Typically used by backoffice interfaces.

  **Request**

  :query days: a number indicating that we request contracts from now up to `days` days ago.

  **Response**
  
  :status 200 OK: The response is a JSON array of  `TransactionHistory`_.

..
  BE AWARE: /map is some old naming from the backend.  Better name here as well?

.. http:get:: /map

  Takes a transaction ID and return the related contract.
  Typically used by backoffice interfaces.

  **Request**

  :query transaction_id: transaction ID of the contract we want to retrieve.

  **Return**

  :status 200 OK:
    The body contains the `contract`_ associated to `transaction_id`.

  :status 404 Not Found:
    There is no contract associated to `transaction_id`.


------------------------------
The Merchant Backend HTTP API
------------------------------

The following API are made available by the merchant's `backend` to the merchant's `frontend`.

.. http:post:: /contract/propose

  Ask the backend to complete the sketch.

  **Request:**

.. _sketch:

  The backend expects a `sketch` as input.  The sketch is a :ref:`proposal <proposal>`
  object **missing** the fields:

  * `exchanges`
  * `auditors`
  * `H_wire`
  * `merchant_pub`

  The frontend may or may not provide a `instance` field in the sketch, depending on its logic.
  The ``default`` instance will be used if no `instance` field is found by the backend.

  **Response**

  :status 200 OK:
    The backend has successfully created the proposal.  It responds with a :ref:`proposal <proposal>`. On success, the `frontend` should pass this response verbatim to the wallet.

  :status 403 Forbidden:
    The frontend used the same transaction ID twice.  This is only allowed if the response from the backend was lost ("instant" replay), but to assure that frontends usually create fresh transaction IDs this is forbidden if the contract was already paid.  So attempting to have the backend sign a proposal for a contract that was already paid by a wallet (and thus was generated by the frontend a "long" time ago), is forbidden and results in this error.  Frontends must make sure that they never use the same transaction ID.

.. http:post:: /pay

  Asks the `backend` to execute the transaction with the exchange and deposit the coins.

  **Request:**

  The `frontend` passes the :ref:`deposit permission <DepositPermission>`
  received from the wallet, and optionally adds a field named `wire_transfer_deadline`,
  indicating a deadline by which he would expect to receive the bank transfer
  for this deal.  Note that the `wire_transfer_deadline` must be after the `refund_deadline`.
  The backend calculates the `wire_transfer_deadline` by adding the `wire_transfer_delay`
  value found in the configuration to the current time.

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins. The body is a `PaymentResponse`_.
    The `frontend` should now fullfill the contract.
  :status 412 Precondition Failed:
    The given exchange is not acceptable for this merchant, as it is not in the
    list of accepted exchanges and not audited by an approved auditor.
  :status 403 Forbidden:
    The exchange rejected the payment because a coin was already spent before.
    The response will include the `coin_pub` for which the payment failed,
    in addition to the response from the exchange to the `/deposit` request.

  The `backend` will return verbatim the error codes received from the exchange's
  :ref:`deposit <deposit>` API.  If the wallet made a mistake, like by
  double-spending for example, the `frontend` should pass the reply verbatim to
  the browser/wallet. This should be the expected case, as the `frontend`
  cannot really make mistakes; the only reasonable exception is if the
  `backend` is unavailable, in which case the customer might appreciate some
  reassurance that the merchant is working on getting his systems back online.

  .. _PaymentResponse:
  .. code-block:: tsref

    interface PaymentResponse {
      // Signature of `TALER_PaymentResponsePS`_
      merchant_sig: EddsaSignature;

      // Contract's hash being signed over
      h_proposal_data: HashCode;
    }

.. http:get:: /track/transfer

  Provides deposits associated with a given wire transfer.

  **Request:**

  :query wtid: raw wire transfer identifier identifying the wire transfer (a base32-encoded value)
  :query exchange: base URI of the exchange that made the wire transfer
  :query instance: (optional) identificative token of the merchant `instance <https://docs.taler.net/operate-merchant.html#instances-lab>`_ which is being tracked.

  **Response:**

  :status 200 OK:
    The wire transfer is known to the exchange, details about it follow in the body.
    The body of the response is a :ref:`TrackTransferResponse <TrackTransferResponse>`.  Note that
    the similarity to the response given by the exchange for a /track/transfer
    is completely intended.

  :status 404 Not Found:
    The wire transfer identifier is unknown to the exchange.

  :status 424 Failed Dependency: The exchange provided conflicting information about the transfer. Namely,
    there is at least one deposit among the deposits aggregated by `wtid` that accounts for a coin whose
    details don't match the details stored in merchant's database about the same keyed coin.
    The response body contains the `TrackTransferConflictDetails`_.


  **Details:**

  .. _tsref-type-TrackTransferConflictDetails:
  .. _TrackTransferConflictDetails:
  .. code-block:: tsref

    interface TrackTransferConflictDetails {
      // Numerical `error code <error-codes>`_
      code: number;

      // Text describing the issue for humans.
      hint: String;

      // A /deposit response matching `coin_pub` showing that the
      // exchange accepted `coin_pub` for `amount_with_fee`.
      exchange_deposit_proof: DepositSuccess;

      // Offset in the `exchange_transfer_proof` where the
      // exchange's response fails to match the `exchange_deposit_proof`.
      conflict_offset: number;

      // The response from the exchange which tells us when the
      // coin was returned to us, except that it does not match
      // the expected value of the coin.
      exchange_transfer_proof: TrackTransferResponse;

      // Public key of the coin for which we have conflicting information.
      coin_pub: EddsaPublicKey;

      // Merchant transaction in which `coin_pub` was involved for which
      // we have conflicting information.
      transaction_id: number;

      // Expected value of the coin.
      amount_with_fee: Amount;

      // Expected deposit fee of the coin.
      deposit_fee: Amount;

    }


.. http:get:: /track/transaction

  Provide the wire transfer identifier associated with an (existing) deposit operation.

  **Request:**

  :query id: ID of the transaction we want to trace (an integer)
  :query instance: identificative token for the merchant instance which is to be tracked (optional). See `<https://docs.taler.net/operate-merchant.html#instances-lab>`_. This information is needed because the request has to be signed by the merchant, thus we need to pick the instance's private key.

  **Response:**

  :status 200 OK:
    The deposit has been executed by the exchange and we have a wire transfer identifier.
     The response body is a JSON array of `TransactionWireTransfer`_ objects.


  :status 202 Accepted:
    The deposit request has been accepted for processing, but was not yet
    executed.  Hence the exchange does not yet have a wire transfer identifier.
    The merchant should come back later and ask again.
    The response body is a :ref:`TrackTransactionAcceptedResponse <TrackTransactionAcceptedResponse>`.  Note that
    the similarity to the response given by the exchange for a /track/transaction
    is completely intended.

  :status 404 Not Found: The transaction is unknown to the backend.

  :status 424 Failed Dependency:
    The exchange previously claimed that a deposit was not included in a wire transfer, and now claims that it is.  This means that the exchange is dishonest.  The response contains the cryptographic proof that the exchange is misbehaving in the form of a `TransactionConflictProof`_.

  **Details:**

  .. _tsref-type-TransactionWireTransfer:
  .. _TransactionWireTransfer:
  .. code-block:: tsref

    interface TransactionWireTransfer {

      // Responsible exchange
      exchange_uri: string;

      // 32-byte wire transfer identifier
      wtid: Base32;

      // execution time of the wire transfer
      execution_time: Timestamp;

      // Array of data about coins
      coins: CoinWireTransfer[];
    }

  .. _tsref-type-CoinWireTransfer:
  .. _CoinWireTransfer:
  .. code-block:: tsref

    interface CoinWireTransfer {
      // public key of the coin that was deposited
      coin_pub: EddsaPublicKey;

      // Amount the coin was worth (including deposit fee)
      amount_with_fee: Amount;

      // Deposit fee retained by the exchange for the coin
      deposit_fee: Amount;
    }

  .. _TransactionConflictProof:
  .. _tsref-type-TransactionConflictProof:
  .. code-block:: tsref

    interface TransactionConflictProof {
      // Numerical `error code <error-codes>`_
      code: number;

      // Human-readable error description
      hint: string;

      // A claim by the exchange about the transactions associated
      // with a given wire transfer; it does not list the
      // transaction that `transaction_tracking_claim` says is part
      // of the aggregate.  This is
      // a `/track/transfer` response from the exchange.
      wtid_tracking_claim: TrackTransferResponse;

      // The current claim by the exchange that the given
      // transaction is included in the above WTID.
      // (A response from `/track/transaction`).
      transaction_tracking_claim: TrackTransactionResponse;

      // Public key of the coin for which we got conflicting information.
      coin_pub: CoinPublicKey;

    }


.. http:get:: /contract/lookup

  Retrieve a proposal, given its transaction ID.

  **Request**

  :query transaction_id: transaction ID of the proposal to retrieve.

  **Response**

  :status 200 OK:
    The body contains the `proposal`_ pointed to by `transaction_id`.

  :status 404 Not Found:
    No proposal corresponds to `transaction_id`.

.. http:get:: /history

  Returns transactions up to some point in the past

  **Request**

  :query date: only transactions *jounger* than this parameter will be returned. It's a timestamp, given in seconds.

  **Response**

  :status 200 OK: The response is a JSON `array` of  `TransactionHistory`_.

  .. _tsref-type-TransactionHistory:
  .. _TransactionHistory:
  .. code-block:: tsref

    interface TransactionHistory {
      // transaction id
      transaction_id: number;

      // Hashcode of the relevant contract
      h_proposal_data: HashCode;

      // Exchange's base URL
      exchange: string;

      // Transaction's timestamp
      timestamp: Timestamp;

      // Price payed for this transaction
      total_amount: Amount;
    }

.. _proposal:

------------
The proposal
------------

The `proposal` is obtained by filling some missing information
in the `sketch`, and then by signing it.  See below.

  .. _tsref-type-Proposal:
  .. code-block:: tsref

    interface Proposal {
      // The actual proposal
      proposal: Proposal;

      // Contract's hash, provided as a convenience.  All components that do
      // not fully trust the merchant must verify this field.
      H_proposal: HashCode ;

      // Signature over the hashcode of `proposal` made by the merchant.
      merchant_sig: EddsaSignature;
    }

.. note::
  When the proposal is signed by the merchant or the wallet, the
  signature is made over the hash of the JSON text, as the proposal may
  be confidential between merchant and customer and should not be
  exposed to the exchange.  The hashcode is generated by hashing the
  encoding of the proposal's JSON obtained by using the flags
  ``JSON_COMPACT | JSON_PRESERVE_ORDER``, as described in the `libjansson
  documentation
  <https://jansson.readthedocs.org/en/2.7/apiref.html?highlight=json_dumps#c.json_dumps>`_.

The `proposal` must have the following structure:

  .. _tsref-type-Proposal:
  .. code-block:: tsref

    interface Proposal {
      // Human-readable description of the whole purchase
      // NOTE: still not implemented
      summary: string;

      // Total price for the transaction.
      // The exchange will subtract deposit fees from that amount
      // before transfering it to the merchant.
      amount: Amount;

      // Needed by the wallet to detect if a payment needs
      // to be replayed.  It can have the values:
      // 1. 'BYURL', in this case the wallet will search for contracts
      //    where the fulfillment URL matches the one associated with the
      //    current purchase.
      // 2. <TOKEN>, in this case the wallet will search for contracts
      //    whose repurchase_correlation_id matches this field.
      // 3. If not given, no replay occurs.
      repurchase_correlation_id?: string;

      // The URL where the wallet has to send coins.
      pay_url: string;

      // The URI for this purchase.  Every time is is visited, the merchant
      // will send back to the customer the same proposal.  Clearly, this URL
      // can be bookmarked and shared by users.
      fulfillment_url: string;

      // Maximum total deposit fee accepted by the merchant for this contract
      max_fee: Amount;

      // A free-form identifier for this transaction.
      transaction_id: string;

      // List of products that are part of the purchase (see `below <Product>`_)
      products: Product[];

      // Time when this contract was generated
      timestamp: Timestamp;

      // After this deadline has passed, no refunds will be accepted.
      refund_deadline: Timestamp;

      // After this deadline, the merchant won't accept payments for the contact
      expiry: Timestamp;

      // Merchant's public key used to sign this proposal; this information
      // is typically added by the backend Note that this can be an ephemeral key.
      merchant_pub: EddsaPublicKey;

      // More info about the merchant, see below
      merchant: Merchant;

      // Which instance is working this proposal.
      // See `Merchant Instances <https://docs.taler.net/operate-merchant.html#instances-lab>`_.
      // This field is optional, as the "default" instance is not forced to provide any
      // `instance` identificator.
      instance: string;

      // The hash of the merchant instance's wire details.
      H_wire: HashCode;

      // Any exchanges audited by these auditors are accepted by the merchant.
      auditors: Auditor[];

      // Exchanges that the merchant accepts even if it does not accept any auditors that audit them.
      exchanges: Exchange[];

      // Map from labels to locations
      locations: { [label: string]: [location: Location], ... };
    }

  The wallet must select a exchange that either the mechant accepts directly by
  listing it in the exchanges arry, or for which the merchant accepts an auditor
  that audits that exchange by listing it in the auditors array.

  The `product` object describes the product being purchased from the merchant. It has the following structure:

  .. _Product:
  .. _tsref-type-Product:
  .. code-block:: tsref

    interface Product {
      // Human-readable product description.
      description: string;

      // The quantity of the product to deliver to the customer (optional, if applicable)
      quantity?: number;

      // The price of the product; this is the total price for the amount specified by `quantity`
      price: Amount;

      // merchant's 53-bit internal identification number for the product (optional)
      product_id?: number;

      // a list of objects indicating a `taxname` and its amount. Again, italics denotes the object field's name.
      taxes?: any[];

      // time indicating when this product should be delivered
      delivery_date: Timestamp;

      // where to deliver this product. This may be an URI for online delivery
      // (i.e. `http://example.com/download` or `mailto:customer@example.com`),
      // or a location label defined inside the proposition's `locations`.
      // The presence of a colon (`:`) indicates the use of an URL.
      delivery_location: string;
    }

  .. _tsref-type-Merchant:
  .. code-block:: ts

    interface Merchant {
      // label for a location with the business address of the merchant
      address: string;

      // the merchant's legal name of business
      name: string;

      // label for a location that denotes the jurisdiction for disputes.
      // Some of the typical fields for a location (such as a street address) may be absent.
      jurisdiction: string;
    }


  .. _tsref-type-Location:
  .. _Location:
  .. code-block:: ts

    interface Location {
      country?: string;
      city?: string;
      state?: string;
      region?: string;
      province?: string;
      zip_code?: string;
      street?: string;
      street_number?: string;
    }

  .. _tsref-type-Auditor:
  .. code-block:: tsref

    interface Auditor {
      // official name
      name: string;

      // Auditor's public key
      auditor_pub: EddsaPublicKey;

      // Base URL of the auditor
      url: string;
    }

  .. _tsref-type-Exchange:
  .. code-block:: tsref

    interface Exchange {
      // the exchange's base URL
      url: string;

      // master public key of the exchange
      master_pub: EddsaPublicKey;
    }
