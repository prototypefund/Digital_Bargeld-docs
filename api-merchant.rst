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


  The merchant frontend API described here describes the minimal set of HTTP requests that a web shop
  needs to understand in order to support Taler payments.  The names `proposal_url`, `pay_url` and `fulfillment_url`
  are placeholders for the actual URLs that the merchant frontend uses.

  Please refer to the `glossary <https://docs.taler.net/glossary.html>`_ for terms
  like `order`, `proposal`, `contract`, and others.


.. http:get:: proposal_url

  Requesting this URL generates a proposal.  Note that the wallet will get properly triggered by the merchant in order
  to issue this GET request.  The merchant will also instruct the wallet whether or
  not to provide the optional `nonce` parameter.  `Payment protocol <https://docs.taler.net/integration-merchant.html#payprot>`_ explains how the wallet is triggered to
  fetch the proposal.

  **Request:**

  :query nonce: Any string value.  This value will be
    included in the proposal, so that when the wallet receives the proposal it can
    easily check whether it was the genuine receiver of the proposal it got.
    This value is needed to avoid proposals' replications.

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
      // a free-form identifier identifying the order that is being payed for
      order_id: string;

      // Public key of the merchant.  Used to identify the merchant instance.
      merchant_pub: EddsaSignature;

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


.. http:get:: fulfillment_url

  URL that shows the product after it has been purchased.  Going to the a fulfillment URL
  before the payment was completed must trigger the payment process.

  For products that are intended to be purchased only once (such as online news
  articles), the fulfillment URL should map one-to-one to an article, so that
  when the user visits the page after they cleared their cookies, the purchase
  can be replayed.

  For purchases that can be repeated, the fulfillment URL should map one-to-one to
  a proposal, e.g. by including the order id.

  Following these rules allows sharing of links and bookmarking to work correctly,
  and produces nicely looking semantic URLs.

  .. note::
    By "replaying" a payment, we mean that the user reuses the same coins he
    used the first time he/she bought those items, thus not spending new coins
    (and therefore not spending additional money).


.. http:get:: refund_url

  Although this POST is issued by the merchant UI, wallets are supposed to catch
  its response.  In the successful case, this response will have a `402 Payment Required`
  status code, and a `X-Taler-Refund-Url` header containing the refund data URL.

.. http:POST:: user_tipping_url

  URL that the customer's wallet can post coin planchets to, and will receive withdraw
  permissions in return.

------------------------------
The Merchant Backend HTTP API
------------------------------

The following API are made available by the merchant's `backend` to the merchant's `frontend`.

.. http:post:: /proposal

  Generate a new proposal, based on the `order` given in the request.  This request is idempotent.

  **Request:**

  The backend expects an `order` as input.  The order is a `ProposalData`_
  object **without** the fields:

  * `exchanges`
  * `auditors`
  * `H_wire`
  * `merchant_pub`
  * `timestamp`

  The following fields from `ProposalData`_ are optional and will be filled
  in by the backend if not present:

  * `merchant.instance` (default instance will be used)
  * `order_id` (random alphanumeric identifier will be used)
  * `refund_deadline` (instance's default will be used)
  * `pay_deadline` (instance's default will be used)

  **Response**

  :status 200 OK:
    The backend has successfully created the proposal.  It responds with a :ref:`proposal <proposal>`. On success, the `frontend` should pass this response verbatim to the wallet.

  :status 403 Forbidden:
    The frontend used the same order ID with different content in the order.

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
      // Signature on `TALER_PaymentResponsePS`_ with the public
      // key of the instance in the proposal.
      sig: EddsaSignature;

      // Proposal data hash being signed over
      h_proposal_data: HashCode;

      // Proposal, send for convenience so the frontend
      // can do order processing without a second lookup on
      // a successful payment
      proposal: Proposal;
    }

.. http:post:: /refund

  Increase the refund amount associated with a given order.

  **Request**

  The request body is a `RefundRequest`_ object.

  **Response**
  
  :status 200 OK:
    The refund amount has been increased, the backend responds with a `RefundConfirmation`_
  :status 400 Bad request:
    The refund amount is not consistent: it is not bigger than the previous one.

  .. _RefundRequest:
  .. code-block:: tsref

    interface RefundRequest {
      // Order id of the transaction to be refunded
      order_id: string;

      // Amount to be refunded
      refund: Amount;

      // Human-readable refund justification
      reason: string;

      // Merchant instance issuing the request
      instance: string;
    }

  .. _RefundConfirmation:
  .. code-block:: tsref

    interface RefundConfirmation {
      // Merchant signature over the hashed order id. Note
      // that the purpose is set to zero.  However, this value
      // is not meant to be soon verified by the frontend, but
      // could be showed in court.
      sig: EddsaSignature  
    }
  
.. http:get:: /refund

  Shows the refund situation about a transaction

  **Request**

  :query instance: the merchant instance issuing the request
  :query order_id: the order id whose refund situation is being queried

  **Response**

  If case of success, an *array of* `RefundLookup`_ objects is returned.

  .. _RefundLookup:
  .. code-block:: tsref
    
    interface RefundLookup {

      // Coin from which the refund is going to be taken
      coin_pub: EddsaPublicKey;     

      // Refund amount taken from coin_pub
      refund_amount: Amount;

      // Refund fee
      refund_fee: Amount;

      // Identificator of the refund
      rtransaction_id: number;

      // Merchant public key
      merchant_pub: EddsaPublicKey

      // Merchant signature of a TALER_RefundRequestPS object
      merchant_sig: EddsaSignature;
    }


.. http:post:: /tip

  Authorize a tip that can be picked up by the customer's wallet by POSTing to `/tip`. 

  **Request**

  The request body is a `TipCreateRequest`_ object.

  **Response**
  
  :status 200 OK:
    The refund amount has been increased, the backend responds with a `TipCreateConfirmation`_
  :status 400 Bad request:
    The refund amount is not consistent: it is not bigger than the previous one.

  .. _RefundRequest:
  .. code-block:: tsref

    interface RefundRequest {
      // Amount that the customer should be tipped
      refund: Amount;

      // Human-readable refund justification
      reason: string;

      // Merchant instance issuing the request
      instance: string;
    }

  .. _TipCreateConfirmation:
  .. code-block:: tsref

    interface TipCreateConfirmation {
      // Identifier for the tip authorization
      tip_id: string;
    }

.. http:get:: /track/transfer

  Provides deposits associated with a given wire transfer.

  **Request**

  :query wtid: raw wire transfer identifier identifying the wire transfer (a base32-encoded value)
  :query exchange: base URI of the exchange that made the wire transfer
  :query instance: (optional) identificative token of the merchant `instance <https://docs.taler.net/operate-merchant.html#instances-lab>`_ which is being tracked.

  **Response:**

  :status 200 OK:
    The wire transfer is known to the exchange, details about it follow in the body.
    The body of the response is a `MerchantTrackTransferResponse`_.  Note that
    the similarity to the response given by the exchange for a /track/transfer
    is completely intended.

  :status 404 Not Found:
    The wire transfer identifier is unknown to the exchange.

  :status 424 Failed Dependency: The exchange provided conflicting information about the transfer. Namely,
    there is at least one deposit among the deposits aggregated by `wtid` that accounts for a coin whose
    details don't match the details stored in merchant's database about the same keyed coin.
    The response body contains the `TrackTransferConflictDetails`_.

  .. _MerchantTrackTransferResponse:
  .. _tsref-type-TrackTransferResponse:
  .. code-block:: tsref

    interface TrackTransferResponse {
      // Total amount transferred
      total: Amount;

      // Applicable wire fee that was charged
      wire_fee: Amount;

      // public key of the merchant (identical for all deposits)
      merchant_pub: EddsaPublicKey;

      // hash of the wire details (identical for all deposits)
      H_wire: HashCode;

      // Time of the execution of the wire transfer by the exchange
      execution_time: Timestamp;

      // details about the deposits
      deposits_sums: TrackTransferDetail[];

      // signature from the exchange made with purpose
      // `TALER_SIGNATURE_EXCHANGE_CONFIRM_WIRE_DEPOSIT`
      exchange_sig: EddsaSignature;

      // public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  Again given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      exchange_pub: EddsaSignature;
    }

  .. _tsref-type-TrackTransferDetail:
  .. code-block:: tsref

    interface TrackTransferDetail {
      // Business activity associated with the wire tranfered amount
      // `deposit_value`.
      order_id: string;

      // The total amount the exchange paid back for `order_id`.
      deposit_value: Amount;

      // applicable fees for the deposit
      deposit_fee: Amount;
    }


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
    the similarity to the response given by the exchange for a /track/order
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

      // Total amount that has been wire transfered
      // to the merchant
      amount: Amount;
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
      // (A response from `/track/order`).
      transaction_tracking_claim: TrackTransactionResponse;

      // Public key of the coin for which we got conflicting information.
      coin_pub: CoinPublicKey;

    }


.. http:get:: /contract/lookup

  Retrieve a proposal, given its order ID.

  **Request**

  :query order_id: transaction ID of the proposal to retrieve.

  **Response**

  :status 200 OK:
    The body contains the `proposal`_ pointed to by `order_id`.

  :status 404 Not Found:
    No proposal corresponds to `order_id`.

.. http:get:: /history

  Returns transactions up to some point in the past

  **Request**

  :query date: only transactions *older* than this parameter will be returned. It's a timestamp, given in seconds.
               Being optional, it defaults to the current time if not given.
  :query start: only transactions having `row_id` less than `start` will be returned. Being optional, it defaults to the
                highest `row_id` contained in the DB (namely, the youngest entry).
  :query delta: at most `delta` entries will be returned. Being optional, it defaults to 20.
  :query instance: on behalf of which merchant instance the query should be accomplished.

  A typical usage is to firstly call this API without `start` and `date` parameter, then fetch the oldest
  `row_id` from the results, and then keep calling the API by using the oldest row ID as `start` parameter.
  This way we simply "scroll" results from the youngest to the oldest, `delta` entries at time.
  
  **Response**

  :status 200 OK: The response is a JSON `array` of  `TransactionHistory`_.  The array is sorted such that entry `i` is younger than entry `i+1`.

  .. _tsref-type-TransactionHistory:
  .. _TransactionHistory:
  .. code-block:: tsref

    interface TransactionHistory {
      // The serial number this entry has in the merchant's DB.
      row_id: number;

      // order ID of the transaction related to this entry.
      order_id: string;

      // Transaction's timestamp
      timestamp: Timestamp;

      // Total amount associated to this transaction.
      amount: Amount;
    }

.. _proposal:

------------
The proposal
------------

The `proposal` is obtained by filling some missing information
in the `order`, and then by signing it.  See below.

  .. _tsref-type-Proposal:
  .. code-block:: tsref

    interface Proposal {
      // The proposal data, effectively the frontend's order with some data filled in
      // by the merchant backend.
      data: ProposalData;

      // Contract's hash, provided as a convenience.  All components that do
      // not fully trust the merchant must verify this field.
      H_proposal: HashCode;

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

The `proposal data` must have the following structure:

  .. _ProposalData:
  .. _tsref-type-ProposalData:
  .. code-block:: tsref

    interface ProposalData {
      // Human-readable description of the whole purchase
      // NOTE: still not implemented
      summary: string;

      // Unique, free-form identifier for the proposal.
      // Must be unique within a merchant instance.
      // For merchants that do not store proposals in their DB
      // before the customer paid for them, the order_id can be used
      // by the frontend to restore a proposal from the information
      // encoded in it (such as a short product identifier and timestamp).
      order_id: string;

      // Total price for the transaction.
      // The exchange will subtract deposit fees from that amount
      // before transfering it to the merchant.
      amount: Amount;

      // The URL where the wallet has to send coins.
      pay_url: string;

      // The URI for this purchase.  Every time is is visited, the merchant
      // will send back to the customer the same proposal.  Clearly, this URL
      // can be bookmarked and shared by users.
      fulfillment_url: string;

      // Maximum total deposit fee accepted by the merchant for this contract
      max_fee: Amount;

      // Maximum wire fee accepted by the merchant (customer share to be
      // divided by the 'wire_fee_amortization' factor, and further reduced
      // if deposit fees are below 'max_fee').  Default if missing is zero.
      max_wire_fee: Amount;

      // Over how many customer transactions does the merchant expect to
      // amortize wire fees on average?  If the exchange's wire fee is
      // above 'max_wire_fee', the difference is divided by this number
      // to compute the expected customer's contribution to the wire fee.
      // The customer's contribution may further be reduced by the difference
      // between the 'max_fee' and the sum of the actual deposit fees.
      // Optional, default value if missing is 1.  0 and negative values are
      // invalid and also interpreted as 1.
      wire_fee_amortization: Integer;

      // List of products that are part of the purchase (see `below <Product>`_)
      products: Product[];

      // Time when this contract was generated
      timestamp: Timestamp;

      // After this deadline has passed, no refunds will be accepted.
      refund_deadline: Timestamp;

      // After this deadline, the merchant won't accept payments for the contact
      pay_deadline: Timestamp;

      // Merchant's public key used to sign this proposal; this information
      // is typically added by the backend Note that this can be an ephemeral key.
      merchant_pub: EddsaPublicKey;

      // More info about the merchant, see below
      merchant: Merchant;

      // The hash of the merchant instance's wire details.
      H_wire: HashCode;

      // Wire transfer method identifier for the wire method associated with H_wire.
      // The wallet may only select exchanges via a matching auditor if the
      // exchange also supports this wire method.
      // The wire transfer fees must be added based on this wire transfer method.
      wire_method: string;

      // Any exchanges audited by these auditors are accepted by the merchant.
      auditors: Auditor[];

      // Exchanges that the merchant accepts even if it does not accept any auditors that audit them.
      exchanges: Exchange[];

      // Map from labels to locations
      locations: { [label: string]: [location: Location], ... };

      // Nonce generated by the wallet and echoed by the merchant
      // in this field when the proposal is generated.
      nonce: string;

      // Extra data that is only interpreted by the merchant frontend.
      // Useful when the merchant needs to store extra information on a
      // contract without storing it separately in their database.
      extra?: any;
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

      // Which instance is working this proposal.
      // See `Merchant Instances <https://docs.taler.net/operate-merchant.html#instances-lab>`_.
      // This field is optional, as the "default" instance is not forced to provide any
      // `instance` identificator.
      instance: string;
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
