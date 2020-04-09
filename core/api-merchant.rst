..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016, 2017 Taler Systems SA

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

.. contents:: Table of Contents



------------------
Receiving Payments
------------------

.. _post-order:

.. http:post:: /order

  Create a new order that a customer can pay for.

  This request is **not** idempotent unless an ``order_id`` is explicitly specified.

  .. note::

    This endpoint does not return a URL to redirect your user to confirm the payment.
    In order to get this URL use :http:get:`/check-payment`.  The API is structured this way
    since the payment redirect URL is not unique for every order, there might be varying parameters
    such as the session id.

  **Request:**

  The request must be a `PostOrderRequest`.

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
      // it has been paid for.  The wallet will always automatically append
      // the order_id as a query parameter.
      fulfillment_url: string;
    }

  .. ts:def:: PostOrderResponse

    interface PostOrderResponse {
      // Order ID of the response that was just created
      order_id: string;
    }


.. http:get:: /check-payment

  Check the payment status of an order.  If the order exists but is not payed yet,
  the response provides a redirect URL.
  When the user goes to this URL, they will be prompted for payment.

  **Request:**

  :query order_id: order id that should be used for the payment
  :query session_id: *Optional*. Session ID that the payment must be bound to.  If not specified, the payment is not session-bound.
  :query timeout: *Optional*. Timeout in seconds to wait for a payment if the answer would otherwise be negative (long polling).

  **Response:**

  Returns a `CheckPaymentResponse`, whose format can differ based on the status of the payment.

  .. ts:def:: CheckPaymentResponse

    type CheckPaymentResponse = CheckPaymentPaidResponse | CheckPaymentUnpaidResponse

  .. ts:def:: CheckPaymentPaidResponse

    interface CheckPaymentPaidResponse {
      paid: true;

      // Was the payment refunded (even partially)
      refunded: boolean;

      // Amount that was refunded, only present if refunded is true.
      refund_amount?: Amount;

      // Contract terms
      contract_terms: ContractTerms;
    }

  .. ts:def:: CheckPaymentUnpaidResponse

    interface CheckPaymentUnpaidResponse {
      paid: false;

      // URI that the wallet must process to complete the payment.
      taler_pay_uri: string;

      // Alternative order ID which was paid for already in the same session.
      // Only given if the same product was purchased before in the same session.
      already_paid_order_id?: string;
    }


--------------
Giving Refunds
--------------


.. http:post:: /refund

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
      // Order id of the transaction to be refunded
      order_id: string;

      // Amount to be refunded
      refund: Amount;

      // Human-readable refund justification
      reason: string;
    }

  .. ts:def:: MerchantRefundResponse

    interface MerchantRefundResponse {

      // Hash of the contract terms of the contract that is being refunded.
      h_contract_terms: HashCode;

      // URL (handled by the backend) that the wallet should access to
      // trigger refund processing.
      taler_refund_url: string;
    }


--------------------
Giving Customer Tips
--------------------


.. http:post:: /tip-authorize

  Authorize a tip that can be picked up by the customer's wallet by POSTing to
  ``/tip-pickup``.  Note that this is simply the authorization step the back
  office has to trigger first.  The user should be navigated to the ``tip_redirect_url``
  to trigger tip processing in the wallet.

  **Request**

  The request body is a `TipCreateRequest` object.

  **Response**

  :status 200 OK:
    A tip has been created. The backend responds with a `TipCreateConfirmation`
  :status 404 Not Found:
    The instance is unknown to the backend.
  :status 412 Precondition Failed:
    The tip amount requested exceeds the available reserve balance for tipping, or
    the instance was never configured for tipping.
  :status 424 Failed Dependency:
    We are unable to process the request because of a problem with the exchange.
    Likely returned with an "exchange_code" in addition to a "code" and
    an "exchange_http_status" in addition to our own HTTP status. Also may
    include the full exchange reply to our request under "exchange_reply".
    Naturally, those diagnostics may be omitted if the exchange did not reply
    at all, or send a completely malformed response.
  :status 503 Service Unavailable:
    We are unable to process the request, possibly due to misconfiguration or
    disagreement with the exchange (it is unclear which party is to blame).
    Likely returned with an "exchange_code" in addition to a "code" and
    an "exchange_http_status" in addition to our own HTTP status. Also may
    include the full exchange reply to our request under "exchange_reply".

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
      // Token that will be handed to the wallet,
      // contains all relevant information to accept
      // a tip.
      tip_token: string;

      // URL that will directly trigger procesing
      // the tip when the browser is redirected to it
      tip_redirect_url: string;
    }


.. http:post:: /tip-query

  Query the status of a tipping reserve.

  **Response**

  :status 200 OK:
    A tip has been created. The backend responds with a `TipQueryResponse`
  :status 404 Not Found:
    The instance is unknown to the backend.
  :status 412 Precondition Failed:
    The merchant backend instance does not have a tipping reserve configured.
  :status 424 Failed Dependency:
    We are unable to process the request because of a problem with the exchange.
    Likely returned with an "exchange_code" in addition to a "code" and
    an "exchange_http_status" in addition to our own HTTP status. Also may
    include the full exchange reply to our request under "exchange_reply".
    Naturally, those diagnostics may be omitted if the exchange did not reply
    at all, or send a completely malformed response.
  :status 503 Service Unavailable:
    We are unable to process the request, possibly due to misconfiguration or
    disagreement with the exchange (it is unclear which party is to blame).
    Likely returned with an "exchange_code" in addition to a "code" and
    an "exchange_http_status" in addition to our own HTTP status. Also may
    include the full exchange reply to our request under "exchange_reply".

  .. ts:def:: TipQueryResponse

    interface TipQueryResponse {
      // Amount still available
      amount_available: Amount;

      // Amount that we authorized for tips
      amount_authorized: Amount;

      // Amount that was picked up by users already
      amount_picked_up: Amount;

      // Timestamp indicating when the tipping reserve will expire
      expiration: Timestamp;

      // Reserve public key of the tipping reserve
      reserve_pub: EddsaPublicKey;
    }


------------------------
Tracking Wire Transfers
------------------------

.. http:get:: /track/transfer

  Provides deposits associated with a given wire transfer.

  **Request**

  :query wtid: raw wire transfer identifier identifying the wire transfer (a base32-encoded value)
  :query wire_method: name of the wire transfer method used for the wire transfer
  :query exchange: base URL of the exchange that made the wire transfer

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

  .. ts:def:: TrackTransferResponse

    interface TrackTransferResponse {
      // Total amount transferred
      total: Amount;

      // Applicable wire fee that was charged
      wire_fee: Amount;

      // public key of the merchant (identical for all deposits)
      merchant_pub: EddsaPublicKey;

      // hash of the wire details (identical for all deposits)
      h_wire: HashCode;

      // Time of the execution of the wire transfer by the exchange
      execution_time: Timestamp;

      // details about the deposits
      deposits_sums: TrackTransferDetail[];

      // signature from the exchange made with purpose
      // ``TALER_SIGNATURE_EXCHANGE_CONFIRM_WIRE_DEPOSIT``
      exchange_sig: EddsaSignature;

      // public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  Again given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
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


.. http:get:: /track/transaction

  Provide the wire transfer identifier associated with an (existing) deposit operation.

  **Request:**

  :query id: ID of the transaction we want to trace (an integer)

  **Response:**

  :status 200 OK:
    The deposit has been executed by the exchange and we have a wire transfer identifier.
    The response body is a JSON array of `TransactionWireTransfer` objects.
  :status 202 Accepted:
    The deposit request has been accepted for processing, but was not yet
    executed.  Hence the exchange does not yet have a wire transfer identifier.
    The merchant should come back later and ask again.
    The response body is a `TrackTransactionAcceptedResponse <TrackTransactionAcceptedResponse>`.  Note that
    the similarity to the response given by the exchange for a /track/order
    is completely intended.
  :status 404 Not Found: The transaction is unknown to the backend.
  :status 424 Failed Dependency:
    The exchange previously claimed that a deposit was not included in a wire
    transfer, and now claims that it is.  This means that the exchange is
    dishonest.  The response contains the cryptographic proof that the exchange
    is misbehaving in the form of a `TransactionConflictProof`.

  **Details:**

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

  .. ts:def:: CoinWireTransfer

    interface CoinWireTransfer {
      // public key of the coin that was deposited
      coin_pub: EddsaPublicKey;

      // Amount the coin was worth (including deposit fee)
      amount_with_fee: Amount;

      // Deposit fee retained by the exchange for the coin
      deposit_fee: Amount;
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


-------------------
Transaction history
-------------------

.. http:get:: /history

  Returns transactions up to some point in the past

  **Request**

  :query date: time threshold, see ``delta`` for its interpretation.
  :query start: row number threshold, see ``delta`` for its interpretation.  Defaults to ``UINT64_MAX``, namely the biggest row id possible in the database.
  :query delta: takes value of the form ``N (-N)``, so that at most ``N`` values strictly younger (older) than ``start`` and ``date`` are returned.  Defaults to ``-20``.
  :query ordering: takes value ``"descending"`` or ``"ascending"`` according to the results wanted from younger to older or vice versa.  Defaults to ``"descending"``.

  **Response**

  :status 200 OK:
    The response is a JSON ``array`` of  `TransactionHistory`.  The array is
    sorted such that entry ``i`` is younger than entry ``i+1``.

  .. ts:def:: TransactionHistory

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


-------------------------
Dynamic Merchant Instance
-------------------------

.. note::

    The endpoints to dynamically manage merchant instances has not been
    implemented yet. The bug id for this refernce is 5349.

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


.. http:put:: /instances/

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
      payto: string;

      // Merchant instance of the response to create
      // This field is optional. If it is not specified
      // then it will automatically be created.
      instance?: string;

      // Merchant name corresponding to this instance.
      name: string;

    }

  .. ts:def:: CreateInstanceResponse

    interface CreateInstanceResponse {
      // Merchant instance of the response that was created
      instance: string;

      //unique key for each merchant
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


-------------------
Customer-facing API
-------------------

The ``/public/*`` endpoints are publicly exposed on the internet and accessed
both by the user's browser and their wallet.


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

      // Base URL of the exchange this instance uses for tipping.
      // Optional, only present if the instance supports tipping.
      tipping_exchange_baseurl?: string;

    }


.. http:post:: /public/pay

  Pay for a proposal by giving a deposit permission for coins.  Typically used by
  the customer's wallet.  Can also be used in ``abort-refund`` mode to refund coins
  that were already deposited as part of a failed payment.

  **Request:**

  The request must be a `pay request <PayRequest>`.

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins. The body is a `PaymentResponse` if
    the request used the mode "pay", or a `MerchantRefundResponse` if the
    request used was the mode "abort-refund".
    The ``frontend`` should now fullfill the contract.
  :status 400 Bad request:
    Either the client request is malformed or some specific processing error
    happened that may be the fault of the client as detailed in the JSON body
    of the response.
  :status 401 Unauthorized:
    One of the coin signatures was not valid.
  :status 403 Forbidden:
    The exchange rejected the payment because a coin was already spent before.
    The response will include the 'coin_pub' for which the payment failed,
    in addition to the response from the exchange to the ``/deposit`` request.
  :status 404 Not found:
    The merchant backend could not find the proposal or the instance
    and thus cannot process the payment.
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
  the browser/wallet. This should be the expected case, as the ``frontend``
  cannot really make mistakes; the only reasonable exception is if the
  ``backend`` is unavailable, in which case the customer might appreciate some
  reassurance that the merchant is working on getting his systems back online.

  .. ts:def:: PaymentResponse

    interface PaymentResponse {
      // Signature on `TALER_PaymentResponsePS` with the public
      // key of the merchant instance.
      sig: EddsaSignature;

      // Contract terms hash being signed over.
      h_contract_terms: HashCode;
    }

  .. ts:def:: PayRequest

    interface PayRequest {
      coins: CoinPaySig[];

      // The merchant public key, used to uniquely
      // identify the merchant instance.
      merchant_pub: string;

      // Order ID that's being payed for.
      order_id: string;

      // Mode for /pay ("pay" or "abort-refund")
      mode: "pay" | "abort-refund";
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


.. http:get:: /public/pay

  Query the payment status of an order.

  **Request**

  :query hc: hash of the order's contract terms
  :query long_poll_ms: *Optional.*  If specified, the merchant backend will
    wait up to ``long_poll_ms`` milliseconds for completion of the payment before
    sending the HTTP response.  A client must never rely on this behavior, as the
    merchant backend may return a response immediately.

  **Response**

  :status 200 OK:
    The response is a `PublicPayStatusResponse`.

  .. ts:def:: PublicPayStatusResponse

    interface PublicPayStatusResponse {
      // Has the payment for this order been completed?
      paid: boolean;

      // Refunds for this payment, if any.
      refunds: RefundInfo[];
    }


  .. ts:def:: RefundInfo

    interface RefundInfo {

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


.. http:get:: /public/proposal

  Retrieve and take ownership (via nonce) over a proposal.

  **Request**

  :query order_id: the order id whose refund situation is being queried
  :query nonce: the nonce for the proposal

  **Response**

  :status 200 OK:
    The backend has successfully retrieved the proposal.  It responds with a :ref:`proposal <proposal>`.

  :status 403 Forbidden:
    The frontend used the same order ID with different content in the order.


.. http:get:: /public/[$INSTANCE]/$ORDER/refund

  Obtain a refund issued by the merchant.

  **Response:**

  :status 200 OK:
    The merchant processed the approved refund. The body is a `RefundResponse`.
    Note that a successful response from the merchant does not imply that the
    exchange successfully processed the refund. Clients must inspect the
    body to check which coins were successfully refunded. It is possible for
    only a subset of the refund request to have been processed successfully.
    Re-issuing the request will cause the merchant to re-try such unsuccessful
    sub-requests.

  .. ts:def:: RefundResponse

    interface RefundResponse {
      // hash of the contract terms
      h_contract_terms: HashCode;

      // merchant's public key
      merchant_pub: EddsaPublicKey;

      // array with information about the refunds obtained
      refunds: RefundDetail[];
    }

  .. ts:def:: RefundDetail

    interface RefundDetail {

      // public key of the coin to be refunded
      coin_pub: EddsaPublicKey;

      // Amount approved for refund for this coin
      refund_amount: Amount;

      // Refund fee the exchange will charge for the refund
      refund_fee: Amount;

      // HTTP status from the exchange. 200 if successful.
      exchange_http_status: integer;

      // Refund transaction ID.
      rtransaction_id: integer;

      // Taler error code from the exchange. Only given if the
      // exchange_http_status is not 200.
      exchange_code?: integer;

      // Full exchange response. Only given if the
      // exchange_http_status is not 200 and the exchange
      // did return JSON.
      exchange_reply?: integer;

      // Public key of the exchange used for the exchange_sig.
      // Only given if the exchange_http_status is 200.
      exchange_pub?: EddsaPublicKey;

      // Signature the exchange confirming the refund.
      // Only given if the exchange_http_status is 200.
      exchange_sig?: EddsaSignature;

    }

  :status 404 Not found:
    The merchant is unaware of having granted a refund, or even of
    the order specified.


.. http:post:: /public/tip-pickup

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
      // Public key of the reserve
      reserve_pub: EddsaPublicKey;

      // The order of the signatures matches the planchets list.
      reserve_sigs: EddsaSignature[];
    }


.. http:get:: /public/poll-payment

  Check the payment status of an order.

  **Request:**

  :query order_id: order id that should be used for the payment
  :query h_contract: hash of the contract (used to authenticate customer)
  :query session_id: *Optional*. Session ID that the payment must be bound to.  If not specified, the payment is not session-bound.
  :query timeout: *Optional*. Timeout in seconds to wait for a payment if the answer would otherwise be negative (long polling).

  **Response:**

  Returns a `PollPaymentResponse`, whose format can differ based on the status of the payment.

  .. ts:def:: PollPaymentResponse

    type CheckPaymentResponse = PollPaymentPaidResponse | PollPaymentUnpaidResponse

  .. ts:def:: PollPaymentPaidResponse

    interface PollPaymentPaidResponse {
      // value is always true;
      paid: boolean;

      // Was the payment refunded (even partially)
      refunded: boolean;

      // Amount that was refunded, only present if refunded is true.
      refund_amount?: Amount;

    }

  .. ts:def:: PollPaymentUnpaidResponse

    interface PollPaymentUnpaidResponse {
      // value is always false;
      paid: boolean;

      // URI that the wallet must process to complete the payment.
      taler_pay_uri: string;

      // Alternative order ID which was paid for already in the same session.
      // Only given if the same product was purchased before in the same session.
      already_paid_order_id?: string;

    }
