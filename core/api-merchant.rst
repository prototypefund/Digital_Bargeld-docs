..
  This file is part of GNU TALER.
  Copyright (C) 2014-2020 Taler Systems SA

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

====================
Merchant Backend API
====================

WARNING: This document describes the version 1 of the merchant backend
API, which is NOT yet implemented at all!

The ``*/public/*`` endpoints are publicly exposed on the Internet and accessed
both by the user's browser and their wallet.

Most endpoints given here can be prefixed by a base URL that includes the
specific instance selected (BASE_URL/instances/$INSTANCE/).  If
``/instances/`` is missing, the default instance is to be used.

.. contents:: Table of Contents


-------------------------
Getting the configuration
-------------------------

.. http:get:: /public/config

  Return the protocol version and currency supported by this merchant backend.

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins. The body is a `VersionResponse`.

  .. ts:def:: VersionResponse

    interface VersionResponse {
      // libtool-style representation of the Merchant protocol version, see
      // https://www.gnu.org/software/libtool/manual/html_node/Versioning.html#Versioning
      // The format is "current:revision:age".
      version: string;

      // Currency supported by this backend.
      currency: string;

      // optional array with information about the instances running at this backend
      // FIXME: remove, use/provide http:get:: /instances instead!
      instances: InstanceInformation[];
    }

  .. ts:def:: InstanceInformation

    interface InstanceInformation {

      // Human-readable legal business name served by this instance
      name: string;

      // Base URL of the instance. Can be of the form "/PizzaShop/" or
      // a fully qualified URL (i.e. "https://backend.example.com/PizzaShop/").
      instance_baseurl: string;

      // Public key of the merchant/instance, in Crockford Base32 encoding.
      merchant_pub: EddsaPublicKey;

      // List of the payment targets supported by this instance. Clients can
      // specify the desired payment target in /order requests.  Note that
      // front-ends do not have to support wallets selecting payment targets.
      payment_targets: string[];

      // Base URL of the exchange this instance uses for tipping.
      // Optional, only present if the instance supports tipping.
      // FIXME: obsolete with current tipping API!
      tipping_exchange_baseurl?: string;

    }


------------------
Receiving Payments
------------------

.. _post-order:

.. http:post:: /create-order

  Create a new order that a customer can pay for.

  This request is **not** idempotent unless an ``order_id`` is explicitly specified.

  .. note::

    This endpoint does not return a URL to redirect your user to confirm the
    payment.  In order to get this URL use :http:get:`/orders/$ORDER_ID`.  The
    API is structured this way since the payment redirect URL is not unique
    for every order, there might be varying parameters such as the session id.

  **Request:**

  The request must be a `PostOrderRequest`.

  :query payment_target: optional query that specifies the payment target preferred by the client. Can be used to select among the various (active) wire methods supported by the instance.

  **Response**

  :status 200 OK:
    The backend has successfully created the proposal.  The response is a
    :ts:type:`PostOrderResponse`.

  .. ts:def:: PostOrderRequest

    interface PostOrderRequest {
      // The order must at least contain the minimal
      // order detail, but can override all
      order: MinimalOrderDetail | ContractTerms;
    }

  The following fields must be specified in the ``order`` field of the request.  Other fields from
  `ContractTerms` are optional, and will override the defaults in the merchant configuration.

  .. ts:def:: MinimalOrderDetail

    interface MinimalOrderDetail {
      // Amount to be paid by the customer
      amount: Amount

      // Short summary of the order
      summary: string;

      // URL that will show that the order was successful after
      // it has been paid for.  The wallet must always automatically append
      // the order_id as a query parameter to this URL when using it.
      fulfillment_url: string;
    }

  .. ts:def:: PostOrderResponse

    interface PostOrderResponse {
      // Order ID of the response that was just created
      order_id: string;
    }



.. http:get:: /orders

  Returns known orders up to some point in the past

  **Request**

  :query paid: *Optional*. If set to yes, only return paid orders, if no only unpaid orders. Do not give (or use "all") to see all orders regardless of payment status.
  :query aborted: *Optional*. If set to yes, only return aborted orders, if no only unaborted orders. Do not give (or use "all")  to see all orders regardless of abort status.
  :query refunded: *Optional*. If set to yes, only return refunded orders, if no only unrefunded orders. Do not give (or use "all") to see all orders regardless of refund status.
  :query wired: *Optional*. If set to yes, only return wired orders, if no only orders with missing wire transfers. Do not give (or use "all") to see all orders regardless of wire transfer status.
  :query date: *Optional.* Time threshold, see ``delta`` for its interpretation.  Defaults to the oldest or most recent entry, depending on ``delta``.
  :query start: *Optional*. Row number threshold, see ``delta`` for its interpretation.  Defaults to ``UINT64_MAX``, namely the biggest row id possible in the database.
  :query delta: *Optional*. takes value of the form ``N (-N)``, so that at most ``N`` values strictly younger (older) than ``start`` and ``date`` are returned.  Defaults to ``-20``.
  :query timeout_ms: *Optional*. Timeout in milli-seconds to wait for additional orders if the answer would otherwise be negative (long polling). Only useful if delta is positive. Note that the merchant MAY still return a response that contains fewer than delta orders.

  **Response**

  :status 200 OK:
    The response is a JSON ``array`` of  `OrderHistory`.  The array is
    sorted such that entry ``i`` is younger than entry ``i+1``.

  .. ts:def:: OrderHistory

    interface OrderHistory {
      // The serial number this entry has in the merchant's DB.
      row_id: number;

      // order ID of the transaction related to this entry.
      order_id: string;

      // Transaction's timestamp
      timestamp: Timestamp;

      // Total amount the customer should pay for this order.
      total: Amount;

      // Total amount the customer did pay for this order.
      paid: Amount;

      // Total amount the customer was refunded for this order.
      // (includes abort-refund and refunds, boolean flag
      // below can help determine which case it is).
      refunded: Amount;

      // Was the order ever fully paid?
      is_paid: boolean;

    }




.. http:post:: /public/orders/$ORDER_ID/claim

  Wallet claims ownership (via nonce) over an order.  By claiming
  an order, the wallet obtains the full contract terms, and thereby
  implicitly also the hash of the contract terms it needs for the
  other ``/public/`` APIs to authenticate itself as the wallet that
  is indeed eligible to inspect this particular order's status.

  **Request**

  The request must be a `ClaimRequest`

  .. ts:def:: ClaimRequest

    interface ClaimRequest {
      // Nonce to identify the wallet that claimed the order.
      nonce: string;
    }

  **Response**

  :status 200 OK:
    The client has successfully claimed the order.
    The response contains the :ref:`contract terms <ContractTerms>`.
  :status 404 Not found:
    The backend is unaware of the instance or order.
  :status 409 Conflict:
    The someone else claimed the same order ID with different nonce before.


.. http:post:: /public/orders/$ORDER_ID/pay

  Pay for an order by giving a deposit permission for coins.  Typically used by
  the customer's wallet.  Note that this request does not include the
  usual ``h_contract`` argument to authenticate the wallet, as the hash of
  the contract is implied by the signatures of the coins.  Furthermore, this
  API doesn't really return useful information about the order.

  **Request:**

  The request must be a `pay request <PayRequest>`.

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins.
    The body is a `payment response <PaymentResponse>`.
    The ``frontend`` should now fullfill the contract.
  :status 400 Bad request:
    Either the client request is malformed or some specific processing error
    happened that may be the fault of the client as detailed in the JSON body
    of the response.
  :status 403 Forbidden:
    One of the coin signatures was not valid.
  :status 404 Not found:
    The merchant backend could not find the order or the instance
    and thus cannot process the payment.
  :status 409 Conflict:
    The exchange rejected the payment because a coin was already spent before.
    The response will include the ``coin_pub`` for which the payment failed,
    in addition to the response from the exchange to the ``/deposit`` request.
  :status 412 Precondition Failed:
    The given exchange is not acceptable for this merchant, as it is not in the
    list of accepted exchanges and not audited by an approved auditor.
  :status 424 Failed Dependency:
    The merchant's interaction with the exchange failed in some way.
    The client might want to try later again.
    This includes failures like the denomination key of a coin not being
    known to the exchange as far as the merchant can tell.

  The backend will return verbatim the error codes received from the exchange's
  :ref:`deposit <deposit>` API.  If the wallet made a mistake, like by
  double-spending for example, the frontend should pass the reply verbatim to
  the browser/wallet.  If the payment was successful, the frontend MAY use
  this to trigger some business logic.

  .. ts:def:: PaymentResponse

    interface PaymentResponse {
      // Signature on ``TALER_PaymentResponsePS`` with the public
      // key of the merchant instance.
      sig: EddsaSignature;

    }

  .. ts:def:: PayRequest

    interface PayRequest {
      coins: CoinPaySig[];
    }

  .. ts:def:: CoinPaySig

    export interface CoinPaySig {
      // Signature by the coin.
      coin_sig: string;

      // Public key of the coin being spend.
      coin_pub: string;

      // Signature made by the denomination public key.
      ub_sig: string;

      // The denomination public key associated with this coin.
      denom_pub: string;

      // The amount that is subtracted from this coin with this payment.
      contribution: Amount;

      // URL of the exchange this coin was withdrawn from.
      exchange_url: string;
    }


.. http:post:: /public/orders/$ORDER_ID/abort

  Abort paying for an order and obtain a refund for coins that
  were already deposited as part of a failed payment.

  **Request:**

  The request must be an `abort request <AbortRequest>`.

  :query h_contract: hash of the order's contract terms (this is used to authenticate the wallet/customer in case $ORDER_ID is guessable). *Mandatory!*

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins. The body is a
    a `merchant refund response <MerchantRefundResponse>`.
  :status 400 Bad request:
    Either the client request is malformed or some specific processing error
    happened that may be the fault of the client as detailed in the JSON body
    of the response.
  :status 403 Forbidden:
    The ``h_contract`` does not match the order.
  :status 404 Not found:
    The merchant backend could not find the order or the instance
    and thus cannot process the abort request.
  :status 412 Precondition Failed:
    Aborting the payment is not allowed, as the original payment did succeed.
  :status 424 Failed Dependency:
    The merchant's interaction with the exchange failed in some way.
    The error from the exchange is included.

  The backend will return verbatim the error codes received from the exchange's
  :ref:`refund <refund>` API.  The frontend should pass the replies verbatim to
  the browser/wallet.

  .. ts:def:: AbortRequest

    interface AbortRequest {
      // List of coins the wallet would like to see refunds for.
      // (Should be limited to the coins for which the original
      // payment succeeded, as far as the wallet knows.)
      coins: AbortedCoin[];
    }

    interface AbortedCoin {
      // Public key of a coin for which the wallet is requesting an abort-related refund.
      coin_pub: EddsaPublicKey;
    }



.. http:get:: /orders/$ORDER_ID/

  Merchant checks the payment status of an order.  If the order exists but is not payed
  yet, the response provides a redirect URL.  When the user goes to this URL,
  they will be prompted for payment.  Differs from the ``/public/`` API both
  in terms of what information is returned and in that the wallet must provide
  the contract hash to authenticate, while for this API we assume that the
  merchant is authenticated (as the endpoint is not ``/public/``).

  **Request:**

  :query session_id: *Optional*. Session ID that the payment must be bound to.  If not specified, the payment is not session-bound.
  :query transfer: *Optional*. If set to "YES", try to obtain the wire transfer status for this order from the exchange. Otherwise, the wire transfer status MAY be returned if it is available.
  :query timeout_ms: *Optional*. Timeout in milli-seconds to wait for a payment if the answer would otherwise be negative (long polling).

  **Response:**

  :status 200 OK:
    Returns a `MerchantOrderStatusResponse`, whose format can differ based on the status of the payment.
  :status 404 Not Found:
    The order or instance is unknown to the backend.
  :status 409 Conflict:
    The exchange previously claimed that a deposit was not included in a wire
    transfer, and now claims that it is.  This means that the exchange is
    dishonest.  The response contains the cryptographic proof that the exchange
    is misbehaving in the form of a `TransactionConflictProof`.
  :status 424 Failed dependency:
    We failed to obtain a response from the exchange about the
    wire transfer status.

  .. ts:def:: MerchantOrderStatusResponse

    type MerchantOrderStatusResponse = CheckPaymentPaidResponse | CheckPaymentUnpaidResponse

  .. ts:def:: CheckPaymentPaidResponse

    interface CheckPaymentPaidResponse {
      paid: true;

      // Was the payment refunded (even partially)
      refunded: boolean;

      // Amount that was refunded, only present if refunded is true.
      refund_amount?: Amount;

      // Contract terms
      contract_terms: ContractTerms;

      // If available, the wire transfer status from the exchange for this order
      wire_details?: TransactionWireTransfer;
    }

  .. ts:def:: CheckPaymentUnpaidResponse

    interface CheckPaymentUnpaidResponse {
      paid: false;

      // URI that the wallet must process to complete the payment.
      taler_pay_uri: string;

      // Alternative order ID which was paid for already in the same session.
      // Only given if the same product was purchased before in the same session.
      already_paid_order_id?: string;

      // FIXME: why do we NOT return the contract terms here?
    }

  .. ts:def:: TransactionWireTransfer

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

  .. ts:def:: TransactionConflictProof

    interface TransactionConflictProof {
      // Numerical `error code <error-codes>`
      code: number;

      // Human-readable error description
      hint: string;

      // A claim by the exchange about the transactions associated
      // with a given wire transfer; it does not list the
      // transaction that ``transaction_tracking_claim`` says is part
      // of the aggregate.  This is
      // a ``/track/transfer`` response from the exchange.
      wtid_tracking_claim: TrackTransferResponse;

      // The current claim by the exchange that the given
      // transaction is included in the above WTID.
      // (A response from ``/track/order``).
      transaction_tracking_claim: TrackTransactionResponse;

      // Public key of the coin for which we got conflicting information.
      coin_pub: CoinPublicKey;

    }


.. http:get:: /public/orders/$ORDER_ID/

  Query the payment status of an order. This endpoint is for the wallet.
  When the wallet goes to this URL and it is unpaid,
  they will be prompted for payment.

  // FIXME: note that this combines the previous APIs
  // to check-payment and to obtain refunds.

  **Request**

  :query h_contract: hash of the order's contract terms (this is used to authenticate the wallet/customer in case $ORDER_ID is guessable). *Mandatory!*
  :query session_id: *Optional*. Session ID that the payment must be bound to.  If not specified, the payment is not session-bound.
  :query timeout_ms: *Optional.*  If specified, the merchant backend will
    wait up to ``timeout_ms`` milliseconds for completion of the payment before
    sending the HTTP response.  A client must never rely on this behavior, as the
    merchant backend may return a response immediately.
  :query refund=AMOUNT: *Optional*. Indicates that we are polling for a refund above the given AMOUNT. Only useful in combination with timeout.

  **Response**

  :status 200 OK:
    The response is a `PublicPayStatusResponse`, with ``paid`` true.
    FIXME: what about refunded?
  :status 402 Payment required:
    The response is a `PublicPayStatusResponse`, with ``paid`` false.
    FIXME: what about refunded?
  :status 403 Forbidden:
    The ``h_contract`` does not match the order.
  :status 404 Not found:
    The merchant backend is unaware of the order.

  .. ts:def:: PublicPayStatusResponse

    interface PublicPayStatusResponse {
      // Has the payment for this order (ever) been completed?
      paid: boolean;

      // Was the payment refunded (even partially, via refund or abort)?
      refunded: boolean;

      // Amount that was refunded in total.
      refund_amount: Amount;

      // Refunds for this payment, empty array for none.
      refunds: RefundDetail[];

      // URI that the wallet must process to complete the payment.
      taler_pay_uri: string;

      // Alternative order ID which was paid for already in the same session.
      // Only given if the same product was purchased before in the same session.
      already_paid_order_id?: string;

    }


.. http:delete:: /orders/$ORDER_ID

  Delete information about an order.  Fails if the order was paid in the
  last 10 years (or whatever TAX_RECORD_EXPIRATION is set to) or was
  claimed but is unpaid and thus still a valid offer.

  **Response**

  :status 204 No content:
    The backend has successfully deleted the order.
  :status 404 Not found:
    The backend does not know the instance or the order.
  :status 409 Conflict:
    The backend refuses to delete the order.


--------------
Giving Refunds
--------------


.. http:post:: /orders/$ORDER_ID/refund

  Increase the refund amount associated with a given order.  The user should be
  redirected to the ``taler_refund_url`` to trigger refund processing in the wallet.

  **Request**

  The request body is a `RefundRequest` object.

  **Response**

  :status 200 OK:
    The refund amount has been increased, the backend responds with a `MerchantRefundResponse`
  :status 404 Not found:
    The order is unknown to the merchant
  :status 409 Conflict:
    The refund amount exceeds the amount originally paid

  .. ts:def:: RefundRequest

    interface RefundRequest {
      // Amount to be refunded
      refund: Amount;

      // Human-readable refund justification
      reason: string;
    }

  .. ts:def:: MerchantRefundResponse

    interface MerchantRefundResponse {

      // Hash of the contract terms of the contract that is being refunded.
      // FIXME: why do we return this?
      h_contract_terms: HashCode;

      // URL (handled by the backend) that the wallet should access to
      // trigger refund processing.
      // FIXME: isn't this basically now always ``/public/orders/$ORDER_ID/``?
      // If so, why return this?
      taler_refund_url: string;
    }



------------------------
Tracking Wire Transfers
------------------------

.. http:post:: /check-transfer

  Inform the backend over an incoming wire transfer. The backend should inquire about the details with the exchange and mark the respective orders as wired.

  **Request:**

   The request must provide `transfer information <TransferInformation>`.

  **Response:**

  :status 200 OK:
    The wire transfer is known to the exchange, details about it follow in the body.
    The body of the response is a `TrackTransferResponse`.  Note that
    the similarity to the response given by the exchange for a /track/transfer
    is completely intended.

  :status 404 Not Found:
    The wire transfer identifier is unknown to the exchange.

  :status 424 Failed Dependency: The exchange provided conflicting information about the transfer. Namely,
    there is at least one deposit among the deposits aggregated by ``wtid`` that accounts for a coin whose
    details don't match the details stored in merchant's database about the same keyed coin.
    The response body contains the `TrackTransferConflictDetails`.

  .. ts:def:: TransferInformation

    interface TransferInformation {
      // how much was wired to the merchant (minus fees)
      credit_amount: Amount;

      // raw wire transfer identifier identifying the wire transfer (a base32-encoded value)
      wtid: FIXME;

      // name of the wire transfer method used for the wire transfer
      // FIXME: why not a payto URI?
      wire_method;

      // base URL of the exchange that made the wire transfer
      exchange: string;
    }

  .. ts:def:: TrackTransferResponse

    interface TrackTransferResponse {
      // Total amount transferred
      total: Amount;

      // Applicable wire fee that was charged
      wire_fee: Amount;

      // public key of the merchant (identical for all deposits)
      // FIXME: why return this?
      merchant_pub: EddsaPublicKey;

      // hash of the wire details (identical for all deposits)
      // FIXME: why return this? Isn't this the WTID!?
      h_wire: HashCode;

      // Time of the execution of the wire transfer by the exchange, according to the exchange
      execution_time: Timestamp;

      // details about the deposits
      deposits_sums: TrackTransferDetail[];

      // signature from the exchange made with purpose
      // ``TALER_SIGNATURE_EXCHANGE_CONFIRM_WIRE_DEPOSIT``
      // FIXME: why return this?
      exchange_sig: EddsaSignature;

      // public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  Again given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      // FIXME: why return this?
      exchange_pub: EddsaSignature;
    }

  .. ts:def:: TrackTransferDetail

    interface TrackTransferDetail {
      // Business activity associated with the wire transferred amount
      // ``deposit_value``.
      order_id: string;

      // The total amount the exchange paid back for ``order_id``.
      deposit_value: Amount;

      // applicable fees for the deposit
      deposit_fee: Amount;
    }


  **Details:**

  .. ts:def:: TrackTransferConflictDetails

    interface TrackTransferConflictDetails {
      // Numerical `error code <error-codes>`
      code: number;

      // Text describing the issue for humans.
      hint: string;

      // A /deposit response matching ``coin_pub`` showing that the
      // exchange accepted ``coin_pub`` for ``amount_with_fee``.
      exchange_deposit_proof: DepositSuccess;

      // Offset in the ``exchange_transfer_proof`` where the
      // exchange's response fails to match the ``exchange_deposit_proof``.
      conflict_offset: number;

      // The response from the exchange which tells us when the
      // coin was returned to us, except that it does not match
      // the expected value of the coin.
      exchange_transfer_proof: TrackTransferResponse;

      // Public key of the coin for which we have conflicting information.
      coin_pub: EddsaPublicKey;

      // Merchant transaction in which ``coin_pub`` was involved for which
      // we have conflicting information.
      transaction_id: number;

      // Expected value of the coin.
      amount_with_fee: Amount;

      // Expected deposit fee of the coin.
      deposit_fee: Amount;

    }


.. http:get:: /transfers

  Obtain a list of all wire transfers the backend has checked.

  **Request:**

   :query filter: FIXME: should have a way to filter, maybe even long-poll?

  **Response:**

  FIXME: to be specified.



--------------------
Giving Customer Tips
--------------------


.. http:post:: /create-reserve

  Create a reserve for tipping.

  **Request:**

  The request body is a `ReserveCreateRequest` object.

  **Response:**

  :status 200 OK:
    The backend is waiting for the reserve to be established. The merchant
    must now perform the wire transfer indicated in the `ReserveCreateConfirmation`.
  :status 424 Failed Depencency:
    We could not obtain /wire details from the specified exchange base URL.

  .. ts:def:: ReserveCreateRequest

    interface ReserveCreateRequest {
      // Amount that the merchant promises to put into the reserve
      initial_amount: Amount;

      // Exchange the merchant intends to use for tipping
      exchange_base_url: string;

    }

  .. ts:def:: ReserveCreateConfirmation

    interface ReserveCreateConfirmation {
      // Public key identifying the reserve
      reserve_pub: EddsaPublicKey;

      // Wire account of the exchange where to transfer the funds
      payto_url: string;

    }

.. http:get:: /reserves

   Obtain list of reserves that have been created for tipping.

   **Request:**

   :query after: *Optional*.  Only return reserves created after the given timestamp [FIXME: unit?]

   **Response:**

  :status 200 OK:
    Returns a list of known tipping reserves.
    The body is a `TippingReserveStatus`.

  .. ts:def:: TippingReserveStatus

    interface TippingReserveStatus {

      // Array of all known reserves (possibly empty!)
      reserves: ReserveStatusEntry[];

    }

  .. ts:def:: ReserveStatusEntry

     interface ReserveStatusEntry {

      // Public key of the reserve
      reserve_pub: EddsaPublicKey;

      // Timestamp when it was established
      creation_time: Timestamp;

      // Timestamp when it expires
      expiration_time: Timestamp;

      // Initial amount as per reserve creation call
      merchant_initial_amount: Amount;

      // Initial amount as per exchange, 0 if exchange did
      // not confirm reserve creation yet.
      exchange_initial_amount: Amount;

      // Amount picked up so far.
      pickup_amount: Amount;

      // Amount approved for tips that exceeds the pickup_amount.
      committed_amount: Amount;

    }


.. http:get:: /reserves/$RESERVE_PUB

   Obtain information about a specific reserve that have been created for tipping.

   **Request:**

   :query tips: *Optional*. If set to "yes", returns also information about all of the tips created

   **Response:**

  :status 200 OK:
    Returns the `ReserveDetail`.
  :status 404 Not found:
    The tipping reserve is not known.
  :status 424 Failed Dependency:
    We are having trouble with the request because of a problem with the exchange.
    Likely returned with an "exchange_code" in addition to a "code" and
    an "exchange_http_status" in addition to our own HTTP status. Also usually
    includes the full exchange reply to our request under "exchange_reply".
    This is only returned if there was actual trouble with the exchange, not
    if the exchange merely did not respond yet or if it responded that the
    reserve was not yet filled.

  .. ts:def:: ReserveDetail

    interface ReserveDetail {

      // Timestamp when it was established
      creation_time: Timestamp;

      // Timestamp when it expires
      expiration_time: Timestamp;

      // Initial amount as per reserve creation call
      merchant_initial_amount: Amount;

      // Initial amount as per exchange, 0 if exchange did
      // not confirm reserve creation yet.
      exchange_initial_amount: Amount;

      // Amount picked up so far.
      pickup_amount: Amount;

      // Amount approved for tips that exceeds the pickup_amount.
      committed_amount: Amount;

      // Array of all tips created by this reserves (possibly empty!).
      // Only present if asked for explicitly.
      tips?: TipStatusEntry[];

    }

  .. ts:def:: TipStatusEntry

    interface TipStatusEntry {

      // Unique identifier for the tip
      tip_id: HashCode;

      // Total amount of the tip that can be withdrawn.
      total_amount: Amount;

      // Human-readable reason for why the tip was granted.
      reason: String;

    }


.. http:post:: /reserves/$RESERVE_PUB/authorize-tip

  Authorize creation of a tip from the given reserve.

  **Request:**

  The request body is a `TipCreateRequest` object.

  **Response**

  :status 200 OK:
    A tip has been created. The backend responds with a `TipCreateConfirmation`
  :status 404 Not Found:
    The instance or the reserve is unknown to the backend.
  :status 412 Precondition Failed:
    The tip amount requested exceeds the available reserve balance for tipping.

  .. ts:def:: TipCreateRequest

    interface TipCreateRequest {
      // Amount that the customer should be tipped
      amount: Amount;

      // Justification for giving the tip
      justification: string;

      // URL that the user should be directed to after tipping,
      // will be included in the tip_token.
      next_url: string;
    }

  .. ts:def:: TipCreateConfirmation

    interface TipCreateConfirmation {
      // Unique tip identifier for the tip that was created.
      tip_id: HashCode;

      // Token that will be handed to the wallet,
      // contains all relevant information to accept
      // a tip.
      tip_token: string;

      // URL that will directly trigger processing
      // the tip when the browser is redirected to it
      tip_redirect_url: string;

    }


.. http:delete:: /reserves/$RESERVE_PUB

  Delete information about a reserve.  Fails if the reserve still has
  committed to tips that were not yet picked up and that have not yet
  expired.

  **Response**

  :status 204 No content:
    The backend has successfully deleted the reserve.
  :status 404 Not found:
    The backend does not know the instance or the reserve.
  :status 409 Conflict:
    The backend refuses to delete the reserve (committed tips).



.. http:get:: /tips/$TIP_ID

  Obtain information about a particular tip.

   **Request:**

   :query pickups: if set to "yes", returns also information about all of the pickups

  **Response**

  :status 200 OK:
    The tip is known. The backend responds with a `TipDetails` message
  :status 404 Not Found:
    The tip is unknown to the backend.

  .. ts:def:: TipDetails

    interface TipDetails {

      // Amount that we authorized for this tip.
      total_authorized: Amount;

      // Amount that was picked up by the user already.
      total_picked_up: Amount;

      // Human-readable reason given when authorizing the tip.
      reason: String;

      // Timestamp indicating when the tip is set to expire (may be in the past).
      expiration: Timestamp;

      // Reserve public key from which the tip is funded
      reserve_pub: EddsaPublicKey;

      // Array showing the pickup operations of the wallet (possibly empty!).
      // Only present if asked for explicitly.
      pickups?: PickupDetail[];
    }

  .. ts:def:: PickupDetail

    interface PickupDetail {

      // Unique identifier for the pickup operation.
      pickup_id: HashCode;

      // Number of planchets involved.
      num_planchets: integer;

      // Total amount requested for this pickup_id.
      requested_amount: Amount;

      // Total amount processed by the exchange for this pickup.
      exchange_amount: Amount;

    }


.. http:post:: /public/tips/$TIP_ID/pickup

  Handle request from wallet to pick up a tip.

  **Request**

  The request body is a `TipPickupRequest` object.

  **Response**

  :status 200 OK:
    A tip is being returned. The backend responds with a `TipResponse`
  :status 401 Unauthorized:
    The tip amount requested exceeds the tip.
  :status 404 Not Found:
    The tip identifier is unknown.
  :status 409 Conflict:
    Some of the denomination key hashes of the request do not match those currently available from the exchange (hence there is a conflict between what the wallet requests and what the merchant believes the exchange can provide).

  .. ts:def:: TipPickupRequest

    interface TipPickupRequest {

      // Identifier of the tip.
      tip_id: HashCode;

      // List of planches the wallet wants to use for the tip
      planchets: PlanchetDetail[];
    }

  .. ts:def:: PlanchetDetail

    interface PlanchetDetail {
      // Hash of the denomination's public key (hashed to reduce
      // bandwidth consumption)
      denom_pub_hash: HashCode;

      // coin's blinded public key
      coin_ev: CoinEnvelope;

    }

  .. ts:def:: TipResponse

    interface TipResponse {

      // Blind RSA signatures over the planchets.
      // The order of the signatures matches the planchets list.
      blind_sigs: BlindSignature[];
    }

    interface BlindSignature {

      // The (blind) RSA signature. Still needs to be unblinded.
      blind_sig: RsaSignature;
    }





-------------------------
Dynamic Merchant Instance
-------------------------

.. note::

    The endpoints to dynamically manage merchant instances has not been
    implemented yet. The bug id for this reference is #5349.

.. http:get:: /instances

  This is used to return the list of all the merchant instances

  **Response**

  :status 200 OK:
    The backend has successfully returned the list of instances stored. Returns
    a `InstancesResponse`.

  .. ts:def:: InstancesResponse

    interface InstancesResponse {
      // List of instances that are present in the backend (see `Instance`)
      instances: Instance[];
    }

  The `Instance` object describes the instance registered with the backend. It has the following structure:

  .. ts:def:: Instance

    interface Instance {
      // Merchant name corresponding to this instance.
      name: string;

      // The URL where the wallet will send coins.
      payto: string;

      // Merchant instance of the response to create
      instance: string;

      //unique key for each merchant
      merchant_id: string;
    }


.. http:put:: /instances/$INSTANCE

  This request will be used to create a new merchant instance in the backend.

  **Request**

  The request must be a `CreateInstanceRequest`.

  **Response**

  :status 200 OK:
    The backend has successfully created the instance.  The response is a
    `CreateInstanceResponse`.

  .. ts:def:: CreateInstanceRequest

    interface CreateInstanceRequest {
      // The URL where the wallet has to send coins.
      // payto://-URL of the merchant's bank account. Required.
      // FIXME: need an array, and to distinguish between
      // supported and active (see taler.conf options on accounts!)
      payto: string;

      // Merchant instance of the response to create
      // This field is optional. If it is not specified
      // then it will automatically be created.
      // FIXME: I do not understand this argument. -CG
      instance?: string;

      // Merchant name corresponding to this instance.
      name: string;

    }

  .. ts:def:: CreateInstanceResponse

    interface CreateInstanceResponse {
      // Merchant instance of the response that was created
      // FIXME: I do not understand this value, isn't it implied?
      instance: string;

      //unique key for each merchant
      // FIXME: I do not understand this value.
      merchant_id: string;
    }


.. http:get:: /instances/<instance-id>

  This is used to query a specific merchant instance.

  **Request:**

  :query instance_id: instance id that should be used for the instance

  **Response**

  :status 200 OK:
    The backend has successfully returned the list of instances stored. Returns
    a `QueryInstancesResponse`.

  .. ts:def:: QueryInstancesResponse

    interface QueryInstancesResponse {
      // The URL where the wallet has to send coins.
      // payto://-URL of the merchant's bank account. Required.
      payto: string;

      // Merchant instance of the response to create
      // This field is optional. If it is not specified
      // then it will automatically be created.
      instance?: string;

      // Merchant name corresponding to this instance.
      name: string;

      // Public key of the merchant/instance, in Crockford Base32 encoding.
      merchant_pub: EddsaPublicKey;

      // List of the payment targets supported by this instance. Clients can
      // specify the desired payment target in /order requests.  Note that
      // front-ends do not have to support wallets selecting payment targets.
      payment_targets: string[];

    }


.. http:post:: /instances/<instance-id>

  This request will be used to update merchant instance in the backend.


  **Request**

  The request must be a `PostInstanceUpdateRequest`.

  **Response**

  :status 200 OK:
    The backend has successfully updated the instance.  The response is a
    `PostInstanceUpdateResponse`.

  .. ts:def:: PostInstanceUpdateRequest

    interface PostInstanceUpdateRequest {
      // Merchant instance that is to be updaated. Required.
      instance: string;

      // New URL where the wallet has to send coins.
      // payto://-URL of the merchant's bank account. Required.
      payto: string;

      // Merchant name coreesponding to this instance.
      name: string;

    }

  .. ts:def:: PostInstanceUpdateResponse

    interface PostInstanceUpdateResponse {
      // Merchant instance of the response that was updated
      instance: string;

      //unique key for each merchant
      merchant_id: string;
    }


.. http:delete:: /instances/<instance-id>

  This request will be used to delete merchant instance in the backend.

  **Request:**

  :query instance_id: instance id that should be used for the instance

  **Response**

  :status 200 OK:
    The backend has successfully removed the instance.  The response is a
    `PostInstanceRemoveResponse`.

  .. ts:def:: PostInstanceRemoveResponse

    interface PostInstanceRemoveResponse {
      deleted: true;
    }


------------------
The Contract Terms
------------------

The contract terms must have the following structure:

  .. ts:def:: ContractTerms

    interface ContractTerms {
      // Human-readable description of the whole purchase
      summary: string;

      // Map from IETF BCP 47 language tags to localized summaries
      summary_i18n?: { [lang_tag: string]: string };

      // Unique, free-form identifier for the proposal.
      // Must be unique within a merchant instance.
      // For merchants that do not store proposals in their DB
      // before the customer paid for them, the order_id can be used
      // by the frontend to restore a proposal from the information
      // encoded in it (such as a short product identifier and timestamp).
      order_id: string;

      // Total price for the transaction.
      // The exchange will subtract deposit fees from that amount
      // before transferring it to the merchant.
      amount: Amount;

      // The URL for this purchase.  Every time is is visited, the merchant
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
      wire_fee_amortization: number;

      // List of products that are part of the purchase (see `Product`).
      products: Product[];

      // Time when this contract was generated
      timestamp: Timestamp;

      // After this deadline has passed, no refunds will be accepted.
      refund_deadline: Timestamp;

      // After this deadline, the merchant won't accept payments for the contact
      pay_deadline: Timestamp;

      // Transfer deadline for the exchange.  Must be in the
      // deposit permissions of coins used to pay for this order.
      wire_transfer_deadline: Timestamp;

      // Merchant's public key used to sign this proposal; this information
      // is typically added by the backend Note that this can be an ephemeral key.
      merchant_pub: EddsaPublicKey;

      // Base URL of the (public!) merchant backend API.
      // Must be an absolute URL that ends with a slash.
      merchant_base_url: string;

      // More info about the merchant, see below
      merchant: Merchant;

      // The hash of the merchant instance's wire details.
      h_wire: HashCode;

      // Wire transfer method identifier for the wire method associated with h_wire.
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

      // Specifies for how long the wallet should try to get an
      // automatic refund for the purchase. If this field is
      // present, the wallet should wait for a few seconds after
      // the purchase and then automatically attempt to obtain
      // a refund.  The wallet should probe until "delay"
      // after the payment was successful (i.e. via long polling
      // or via explicit requests with exponential back-off).
      //
      // In particular, if the wallet is offline
      // at that time, it MUST repeat the request until it gets
      // one response from the merchant after the delay has expired.
      // If the refund is granted, the wallet MUST automatically
      // recover the payment.  This is used in case a merchant
      // knows that it might be unable to satisfy the contract and
      // desires for the wallet to attempt to get the refund without any
      // customer interaction.  Note that it is NOT an error if the
      // merchant does not grant a refund.
      auto_refund?: RelativeTime;

      // Extra data that is only interpreted by the merchant frontend.
      // Useful when the merchant needs to store extra information on a
      // contract without storing it separately in their database.
      extra?: any;
    }

  The wallet must select a exchange that either the merchant accepts directly by
  listing it in the exchanges array, or for which the merchant accepts an auditor
  that audits that exchange by listing it in the auditors array.

  The `Product` object describes the product being purchased from the merchant. It has the following structure:

  .. ts:def:: Product

    interface Product {
      // Human-readable product description.
      description: string;

      // Map from IETF BCP 47 language tags to localized descriptions
      description_i18n?: { [lang_tag: string]: string };

      // The quantity of the product to deliver to the customer (optional, if applicable)
      quantity?: string;

      // The price of the product; this is the total price for the amount specified by 'quantity'
      price: Amount;

      // merchant-internal identifier for the product
      product_id?: string;

      // An optional base64-encoded product image
      image?: ImageDataUrl;

      // a list of objects indicating a 'taxname' and its amount. Again, italics denotes the object field's name.
      taxes?: any[];

      // time indicating when this product should be delivered
      delivery_date: Timestamp;

      // where to deliver this product. This may be an URL for online delivery
      // (i.e. 'http://example.com/download' or 'mailto:customer@example.com'),
      // or a location label defined inside the proposition's 'locations'.
      // The presence of a colon (':') indicates the use of an URL.
      delivery_location: string;
    }

  .. ts:def:: Merchant

    interface Merchant {
      // label for a location with the business address of the merchant
      address: string;

      // the merchant's legal name of business
      name: string;

      // label for a location that denotes the jurisdiction for disputes.
      // Some of the typical fields for a location (such as a street address) may be absent.
      jurisdiction: string;
    }


  .. ts:def:: Location

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

  .. ts:def:: Auditor

    interface Auditor {
      // official name
      name: string;

      // Auditor's public key
      auditor_pub: EddsaPublicKey;

      // Base URL of the auditor
      url: string;
    }

  .. ts:def:: Exchange

    interface Exchange {
      // the exchange's base URL
      url: string;

      // master public key of the exchange
      master_pub: EddsaPublicKey;
    }
