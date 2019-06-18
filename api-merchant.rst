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

------------------
Receiving Payments
------------------

.. _post-order:

.. http:post:: /order

  Create a new order that a customer can pay for.

  This request is not idempotent unless an `order_id` is explicitly specified.

  .. note::

    This endpoint does not return a URL to redirect your user to confirm the payment.
    In order to get this URL use :http:get:`/check-payment`.  The API is structured this way
    since the payment redirect URL is not unique for every order, there might be varying parameters
    such as the session id.

  **Request:**

  The request must be a `PostOrderRequest`_.

  **Response**

  :status 200 OK:
    The backend has successfully created the proposal.  The response is a
    `PostOrderResponse`_.

  .. _PostOrderRequest:
  .. code-block:: tsref

    interface PostOrderRequest {
      // The order must at least contain the minimal
      // order detail, but can override all
      order: MinimalOrderDetail | ContractTerms;
    }

  The following fields of the `ContractTerms`_

  .. _MinimalOrderDetail:
  .. _tsref-type-MinimalOrderDetail:
  .. code-block:: tsref

    interface MinimalOrderRequest {
      // Amount to be paid by the customer
      amount: Amount

      // Short summary of the order
      summary: string;

      // URL that will show that the order was successful after
      // it has been paid for.  The wallet will automatically append
      // the order_id (always) and the session_sig (if applicable).
      fulfillment_url: string;

      // Merchant instance to use (leave empty to use instance "default")
      instance?: string;
    }

  .. _PostOrderResponse:
  .. code-block:: tsref

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
  :query contract_url: FIXME-FLORIAN
  :query instance: *Optional*. Instance used for the payment. Defaults to the instance named "default".
  :query resource_url: *Optional*. A resource URL that allows the wallet to identify whether it has already paid for this resource.
    Typically corresponds to the fulfillment URL.
  :query session_id: *Optional*. Session ID that the payment must be bound to.  If not specified, the payment is not session-bound.
  :query session_sig: *Optional*. Signature from the wallet to prove that it paid with the given session_id.  Not specified
    if the wallet has not paid yet or still has to replay payment to bound the payment to the session id.

  **Response:**

  Returns a `CheckPaymentResponse`_, whose format can differ based on the status of the payment.

  .. _CheckPaymentResponse:
  .. code-block:: tsref

    type CheckPaymentResponse = CheckPaymentPaidResponse | CheckPaymentUnpaidResponse

  .. _CheckPaymentPaidResponse:
  .. _tsref-type-CheckPaymentPaidResponse:
  .. code-block:: tsref

    interface CheckPaymentPaidResponse {
      paid: true;

      // Was the payment refunded (even partially)
      refunded: boolean;

      // Amount that was refunded
      refund_amount: Amount;

      // Contract terms
      contract_terms: ContractTerms;
    }

  .. _CheckPaymentUnpaidResponse:
  .. _tsref-type-CheckPaymentUnpaidResponse:
  .. code-block:: tsref

    interface CheckPaymentUnpaidResponse {
      paid: false;

      // URL to redirect the customer to pay,
      // replay payment or confirm that the payment
      // is bound to a session.
      payment_redirect_url: string;
    }


--------------
Giving Refunds
--------------


.. http:post:: /refund

  Increase the refund amount associated with a given order.  The user should be
  redirected to the `refund_redirect_url` to trigger refund processing in the wallet.

  **Request**

  The request body is a `RefundRequest`_ object.

  **Response**

  :status 200 OK:
    The refund amount has been increased, the backend responds with a `MerchantRefundResponse`_
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
      instance?: string;
    }

  .. _MerchantRefundResponse:
  .. code-block:: tsref

    interface MerchantRefundResponse {
      // Public key of the merchant
      merchant_pub: string;


      // Contract terms hash of the contract that
      // is being refunded.
      h_contract_terms: string;

      // The signed refund permissions, to be sent to the exchange.
      refund_permissions: MerchantRefundPermission[];

      // URL (handled by the backend) that will
      // trigger refund processing in the browser/wallet
      refund_redirect_url: string;
    }

  .. _MerchantRefundPermission:
  .. _tsref-type-MerchantRefundPermissoin:
  .. code-block:: tsref

    interface MerchantRefundPermission {
      // Amount to be refunded.
      refund_amount: AmountJson;

      // Fee for the refund.
      refund_fee: AmountJson;

      // Public key of the coin being refunded.
      coin_pub: string;

      // Refund transaction ID between merchant and exchange.
      rtransaction_id: number;

      // Signature made by the merchant over the refund permission.
      merchant_sig: string;
    }


--------------------
Giving Customer Tips
--------------------


.. http:post:: /tip-authorize

  Authorize a tip that can be picked up by the customer's wallet by POSTing to
  `/tip-pickup`.  Note that this is simply the authorization step the back
  office has to trigger first.  The user should be navigated to the `tip_redirect_url`
  to trigger tip processing in the wallet.

  **Request**

  The request body is a `TipCreateRequest`_ object.

  **Response**

  :status 200 OK:
    A tip has been created. The backend responds with a `TipCreateConfirmation`_
  :status 404 Not Found:
    The instance is unknown to the backend, expired or was never enabled or
    the reserve is unknown to the exchange or expired (see detailed status
    either being TALER_EC_RESERVE_STATUS_UNKNOWN or
    TALER_EC_TIP_AUTHORIZE_INSTANCE_UNKNOWN or
    TALER_EC_TIP_AUTHORIZE_INSTANCE_DOES_NOT_TIP or
    TALER_EC_TIP_AUTHORIZE_RESERVE_EXPIRED.
  :status 412 Precondition Failed:
    The tip amount requested exceeds the available reserve balance for tipping.

  .. _TipCreateRequest:
  .. code-block:: tsref

    interface TipCreateRequest {
      // Amount that the customer should be tipped
      amount: Amount;

      // Merchant instance issuing the request
      instance?: string;

      // Justification for giving the tip
      justification: string;

      // URL that the user should be directed to after tipping,
      // will be included in the tip_token.
      next_url: string;
    }

  .. _TipCreateConfirmation:
  .. code-block:: tsref

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

  Query the status of an instance's tipping reserve.

  **Request**

  :query instance: instance to query

  **Response**

  :status 200 OK:
    A tip has been created. The backend responds with a `TipQueryResponse`_
  :status 404 Not Found:
    The instance is unknown to the backend.
  :status 412 Precondition Failed:
    The instance does not have a tipping reserve configured.

  .. _TipQueryResponse:
  .. code-block:: tsref

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
      reserve_pub: string;
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
      // Business activity associated with the wire transferred amount
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
  :query instance:  merchant instance

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
    The exchange previously claimed that a deposit was not included in a wire
    transfer, and now claims that it is.  This means that the exchange is
    dishonest.  The response contains the cryptographic proof that the exchange
    is misbehaving in the form of a `TransactionConflictProof`_.

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


-------------------
Transaction history
-------------------

.. http:get:: /history

  Returns transactions up to some point in the past

  **Request**

  :query date: time threshold, see `delta` for its interpretation.
  :query start: row number threshold, see `delta` for its interpretation.  Defaults to `UINT64_MAX`, namely the biggest row id possible in the database.
  :query delta: takes value of the form `N (-N)`, so that at most `N` values strictly younger (older) than `start` and `date` are returned.  Defaults to `-20`.
  :query instance: on behalf of which merchant instance the query should be accomplished.
  :query ordering: takes value `descending` or `ascending` according to the results wanted from younger to older or vice versa.  Defaults to `descending`.

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
    a `InstancesResponse`_.

  .. InstancesResponse:
  .. code-block:: tsref

    interface InstancesResponse {
      // List of instances that are present in the backend(see `below <Instance>`_)
      instances: Instance[];
    }

The `instance` object describes the instance registered with the backend. It has the following structure:

  .. Instance:
  .. _tsref-type-Instance:
  .. code-block:: tsref

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

  The request must be a `CreateInstanceRequest`_.

  **Response**

  :status 200 OK:
    The backend has successfully created the instance.  The response is a
    `CreateInstanceResponse`_.

  .. CreateInstanceRequest:
  .. code-block:: tsref

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

  .. CreateInstanceResponse:
  .. code-block:: tsref

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
    a `QueryInstancesResponse`_.

  .. QueryInstancesResponse:
  .. code-block:: tsref

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

  The request must be a `PostInstanceUpdateRequest`_.

  **Response**

  :status 200 OK:
    The backend has successfully updated the instance.  The response is a
    `PostInstanceUpdateResponse`_.

  .. PostInstanceUpdateRequest:
  .. code-block:: tsref

    interface PostInstanceUpdateRequest {
      // Merchant instance that is to be updaated. Required.
      instance: string;

      // New URL where the wallet has to send coins.
      // payto://-URL of the merchant's bank account. Required.
      payto: string;

      // Merchant name coreesponding to this instance.
      name: string;

    }

  .. PostInstanceUpdateResponse:
  .. code-block:: tsref

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
    `PostInstanceRemoveResponse`_.

  .. PostInstanceRemoveResponse:
  .. code-block:: tsref

    interface PostInstanceRemoveResponse {
      deleted: true;
    }


------------------
The Contract Terms
------------------

The `contract terms` must have the following structure:

  .. _ContractTerms:
  .. _tsref-type-ContractTerms:
  .. code-block:: tsref

    interface ContractTerms {
      // Human-readable description of the whole purchase
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
      quantity?: string;

      // The price of the product; this is the total price for the amount specified by `quantity`
      price: Amount;

      // merchant-internal identifier for the product
      product_id?: string;

      // a list of objects indicating a `taxname` and its amount. Again, italics denotes the object field's name.
      taxes?: any[];

      // time indicating when this product should be delivered
      delivery_date: Timestamp;

      // where to deliver this product. This may be an URL for online delivery
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


-------------------
Customer-facing API
-------------------

The `/public/*` endpoints are publicly exposed on the internet and accessed
both by the user's browser and their wallet.


.. http:post:: /public/pay

  Pay for a proposal by giving a deposit permission for coins.  Typically used by
  the customer's wallet.  Can also be used in `abort-refund` mode to refund coins
  that were already deposited as part of a failed payment.

  **Request:**

  The request must be a :ref:`pay request <PayRequest>`.

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins. The body is a `PaymentResponse`_ if the request used the mode "pay", or a `MerchantRefundResponse`_ if the request used was the mode "abort-refund".
    The `frontend` should now fullfill the contract.
  :status 412 Precondition Failed:
    The given exchange is not acceptable for this merchant, as it is not in the
    list of accepted exchanges and not audited by an approved auditor.
  :status 401 Unauthorized:
    One of the coin signatures was not valid.
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


  .. _PayRequest:
  .. code-block:: tsref

    interface PayRequest {
      // Signature on `TALER_PaymentResponsePS`_ with the public
      // key of the instance in the proposal.
      sig: EddsaSignature;

      // Proposal data hash being signed over
      h_proposal_data: HashCode;

      // Proposal, send for convenience so the frontend
      // can do order processing without a second lookup on
      // a successful payment
      proposal: Proposal;

      // Coins with signature.
      coins: CoinPaySig[];

      // The merchant public key, used to uniquely
      // identify the merchant instance.
      merchant_pub: string;

      // Order ID that's being payed for.
      order_id: string;

      // Mode for /pay ("pay" or "abort-refund")
      mode: "pay" | "abort-refund";
    }


.. http:get:: /public/proposal

  Retrieve and take ownership (via nonce) over a proposal.

  **Request**

  :query instance: the merchant instance issuing the request
  :query order_id: the order id whose refund situation is being queried
  :query nonce: the nonce for the proposal

  **Response**

  :status 200 OK:
    The backend has successfully retrieved the proposal.  It responds with a :ref:`proposal <proposal>`.

  :status 403 Forbidden:
    The frontend used the same order ID with different content in the order.


.. http:post:: /public/tip-pickup

  Handle request from wallet to pick up a tip.

  **Request**

  The request body is a `TipPickupRequest`_ object.

  **Response**

  :status 200 OK:
    A tip is being returned. The backend responds with a `TipResponse`_
  :status 401 Unauthorized:
    The tip amount requested exceeds the tip.
  :status 404 Not Found:
    The tip identifier is unknown.
  :status 409 Conflict:
    Some of the denomination key hashes of the request do not match those currently available from the exchange (hence there is a conflict between what the wallet requests and what the merchant believes the exchange can provide).

  .. _TipPickupRequest:
  .. code-block:: tsref

    interface TipPickupRequest {

      // Identifier of the tip.
      tip_id: HashCode;

      // List of planches the wallet wants to use for the tip
      planchets: PlanchetDetail[];
    }

    interface PlanchetDetail {
      // Hash of the denomination's public key (hashed to reduce
      // bandwidth consumption)
      denom_pub_hash: HashCode;

      // coin's blinded public key
      coin_ev: CoinEnvelope;

    }

  .. _TipResponse:
  .. code-block:: tsref

    interface TipResponse {
      // Public key of the reserve
      reserve_pub: EddsaPublicKey;

      // The order of the signatures matches the planchets list.
      reserve_sigs: EddsaSignature[];
    }


.. http:get:: /public/refund

  Pick up refunds for an order.

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


.. http:get:: /public/trigger-pay

  Used to trigger processing of payments, refunds and tips in the browser.  The exact behavior
  can be dependent on the user's browser.
