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

TODO: https://bugs.gnunet.org/view.php?id=5987#c15127
      is not yet addressed by this specification!

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

    }


--------------------------
Dynamic Merchant Instances
--------------------------

.. _instances:
.. http:get:: /instances

  This is used to return the list of all the merchant instances

  **Response:**

  :status 200 OK:
    The backend has successfully returned the list of instances stored. Returns
    a `InstancesResponse`.

  .. ts:def:: InstancesResponse

    interface InstancesResponse {
      // List of instances that are present in the backend (see `Instance`)
      instances: Instance[];
    }

  The `Instance` object describes the instance registered with the backend.
  It does not include the full details, only those that usually concern the frontend.
  It has the following structure:

  .. ts:def:: Instance

    interface Instance {
      // Merchant name corresponding to this instance.
      name: string;

      // Merchant instance this response is about ($INSTANCE)
      id: string;

      // Public key of the merchant/instance, in Crockford Base32 encoding.
      merchant_pub: EddsaPublicKey;

      // List of the payment targets supported by this instance. Clients can
      // specify the desired payment target in /order requests.  Note that
      // front-ends do not have to support wallets selecting payment targets.
      payment_targets: string[];

   }


.. http:post:: /instances

  This request will be used to create a new merchant instance in the backend.

  **Request:**

  The request must be a `InstanceConfigurationMessage`.

  **Response:**

  :status 204 No content:
    The backend has successfully created the instance.
  :status 409 Conflict:
    This instance already exists, but with other configuration options.
    Use "PATCH" to update an instance configuration.

  .. ts:def:: InstanceConfigurationMessage

    interface InstanceConfigurationMessage {
      // The URI where the wallet will send coins.  A merchant may have
      // multiple accounts, thus this is an array.  Note that by
      // removing URIs from this list
      payto_uris: string[];

      // Name of the merchant instance to create (will become $INSTANCE).
      id: string;

      // Merchant name corresponding to this instance.
      name: string;

      // The merchant's physical address (to be put into contracts).
      address: Location;

      // The jurisdiction under which the merchant conducts its business
      // (to be put into contracts).
      jurisdiction: Location;

      // Maximum wire fee this instance is willing to pay.
      // Can be overridden by the frontend on a per-order basis.
      default_max_wire_fee: Amount;

      // Default factor for wire fee amortization calculations.
      // Can be overriden by the frontend on a per-order basis.
      default_wire_fee_amortization: integer;

      // Maximum deposit fee (sum over all coins) this instance is willing to pay.
      // Can be overridden by the frontend on a per-order basis.
      default_max_deposit_fee: Amount;

      //  If the frontend does NOT specify an execution date, how long should
      // we tell the exchange to wait to aggregate transactions before
      // executing the wire transfer?  This delay is added to the current
      // time when we generate the advisory execution time for the exchange.
      default_wire_transfer_delay: RelativeTime;

      // If the frontend does NOT specify a payment deadline, how long should
      // offers we make be valid by default?
      default_pay_deadline: RelativeTime;

    }


.. http:patch:: /instances/$INSTANCE

  Update the configuration of a merchant instance.

  **Request**

  The request must be a `InstanceReconfigurationMessage`.
  Removing an existing payto_uri deactivates
  the account (it will no longer be used for future contracts).

  **Response:**

  :status 204 No content:
    The backend has successfully created the instance.
  :status 404 Not found:
    This instance is unknown and thus cannot be reconfigured.

  .. ts:def:: InstanceReconfigurationMessage

    interface InstanceReconfigurationMessage {
      // The URI where the wallet will send coins.  A merchant may have
      // multiple accounts, thus this is an array.  Note that by
      // removing URIs from this list
      payto_uris: string[];

      // Merchant name corresponding to this instance.
      name: string;

      // The merchant's physical address (to be put into contracts).
      address: Location;

      // The jurisdiction under which the merchant conducts its business
      // (to be put into contracts).
      jurisdiction: Location;

      // Maximum wire fee this instance is willing to pay.
      // Can be overridden by the frontend on a per-order basis.
      default_max_wire_fee: Amount;

      // Default factor for wire fee amortization calculations.
      // Can be overriden by the frontend on a per-order basis.
      default_wire_fee_amortization: integer;

      // Maximum deposit fee (sum over all coins) this instance is willing to pay.
      // Can be overridden by the frontend on a per-order basis.
      default_max_deposit_fee: Amount;

      //  If the frontend does NOT specify an execution date, how long should
      // we tell the exchange to wait to aggregate transactions before
      // executing the wire transfer?  This delay is added to the current
      // time when we generate the advisory execution time for the exchange.
      default_wire_transfer_delay: RelativeTime;

      // If the frontend does NOT specify a payment deadline, how long should
      // offers we make be valid by default?
      default_pay_deadline: RelativeTime;

    }


.. http:get:: /instances/$INSTANCE

  This is used to query a specific merchant instance.

  **Response:**

  :status 200 OK:
    The backend has successfully returned the list of instances stored. Returns
    a `QueryInstancesResponse`.

  .. ts:def:: QueryInstancesResponse

    interface QueryInstancesResponse {
      // The URI where the wallet will send coins.  A merchant may have
      // multiple accounts, thus this is an array.
      accounts: MerchantAccount[];

      // Merchant name corresponding to this instance.
      name: string;

      // Public key of the merchant/instance, in Crockford Base32 encoding.
      merchant_pub: EddsaPublicKey;

      // The merchant's physical address (to be put into contracts).
      address: Location;

      // The jurisdiction under which the merchant conducts its business
      // (to be put into contracts).
      jurisdiction: Location;

      // Maximum wire fee this instance is willing to pay.
      // Can be overridden by the frontend on a per-order basis.
      default_max_wire_fee: Amount;

      // Default factor for wire fee amortization calculations.
      // Can be overriden by the frontend on a per-order basis.
      default_wire_fee_amortization: integer;

      // Maximum deposit fee (sum over all coins) this instance is willing to pay.
      // Can be overridden by the frontend on a per-order basis.
      default_max_deposit_fee: Amount;

      //  If the frontend does NOT specify an execution date, how long should
      // we tell the exchange to wait to aggregate transactions before
      // executing the wire transfer?  This delay is added to the current
      // time when we generate the advisory execution time for the exchange.
      default_wire_transfer_delay: RelativeTime;

      // If the frontend does NOT specify a payment deadline, how long should
      // offers we make be valid by default?
      default_pay_deadline: RelativeTime;

    }

  .. ts:def:: MerchantAccount

    interface MerchantAccount {

      // payto:// URI of the account.
      payto_uri: string;

      // Hash over the wire details (including over the salt)
      h_wire: HashCode;

      // salt used to compute h_wire
      salt: string;

      // true if this account is active,
      // false if it is historic.
      active: boolean;
    }



.. http:delete:: /instances/$INSTANCE

  This request will be used to delete (permanently disable)
  or purge merchant instance in the backend. Purging will
  delete all offers and payments associated with the instance,
  while disabling (the default) only deletes the private key
  and makes the instance unusuable for new orders or payments.

  **Request:**

  :query purge: *Optional*. If set to YES, the instance will be fully
      deleted. Otherwise only the private key would be deleted.

  **Response**

  :status 204 NoContent:
    The backend has successfully removed the instance.  The response is a
    `PostInstanceRemoveResponse`.
  :status 404 Not found:
    The instance is unknown to the backend.
  :status 409 Conflict:
    The instance cannot be deleted because it has pending offers, or
    the instance cannot be purged because it has successfully processed
    payments that have not passed the TAX_RECORD_EXPIRATION time.
    The latter case only applies if ``purge`` was set.


--------------------
Inventory management
--------------------

.. _inventory:

Inventory management is an *optional* backend feature that can be used to
manage limited stocks of products and to auto-complete product descriptions in
contracts (such that the frontends have to do less work).  You can use the
Taler merchant backend to process payments *without* using its inventory
management.


.. http:get:: /products

  This is used to return the list of all items in the inventory.

  **Response:**

  :status 200 OK:
    The backend has successfully returned the inventory. Returns
    a `InventorySummaryResponse`.

  .. ts:def:: InventorySummaryResponse

    interface InventorySummaryResponse {
      // List of products that are present in the inventory
      products: InventoryEntry[];
    }

  The `InventoryEntry` object describes an item in the inventory. It has the following structure:

  .. ts:def:: InventoryEntry

    interface InventoryEntry {
      // Product identifier, as found in the product.
      product_id: string;

      // Amount of the product in stock. Given in product-specific units.
      // Set to -1 for "infinite" (i.e. for "electronic" books).
      stock: integer;

      // unit in which the product is metered (liters, kilograms, packages, etc.)
      unit: string;
    }


.. http:get:: /products/$PRODUCT_ID

  This is used to obtain detailed information about a product in the inventory.

  **Response:**

  :status 200 OK:
    The backend has successfully returned the inventory. Returns
    a `ProductDetail`.

  .. ts:def:: ProductDetail

    interface ProductDetail {

      // Human-readable product description.
      description: string;

      // Map from IETF BCP 47 language tags to localized descriptions
      description_i18n: { [lang_tag: string]: string };

      // unit in which the product is measured (liters, kilograms, packages, etc.)
      unit: string;

      // The price for one ``unit`` of the product. Zero is used
      // to imply that this product is not sold separately, or
      // that the price is not fixed, and must be supplied by the
      // front-end.  If non-zero, this price MUST include applicable
      // taxes.
      price: Amount;

      // An optional base64-encoded product image
      image: ImageDataUrl;

      // a list of taxes paid by the merchant for one unit of this product
      taxes: Tax[];

      // Number of units of the product in stock in sum in total,
      // including all existing sales ever. Given in product-specific
      // units.
      // A value of -1 indicates "infinite" (i.e. for "electronic" books).
      total_stocked: integer;

      // Number of units of the product that have already been sold.
      total_sold: integer;

      // Number of units of the product that were lost (spoiled, stolen, etc.)
      total_lost: integer;

      // Identifies where the product is in stock.
      location: Location;

      // Identifies when we expect the next restocking to happen.
      next_restock?: timestamp;

    }


.. http:post:: /products

  This is used to add a product to the inventory.

  **Request:**

  The request must be a `ProductAddDetail`.

  **Response:**

  :status 204 No content:
    The backend has successfully expanded the inventory.
  :status 409 Conflict:
    The backend already knows a product with this product ID, but with different details.


  .. ts:def:: ProductAddDetail

    interface ProductAddDetail {

      // product ID to use.
      product_id: string;

      // Human-readable product description.
      description: string;

      // Map from IETF BCP 47 language tags to localized descriptions
      description_i18n: { [lang_tag: string]: string };

      // unit in which the product is measured (liters, kilograms, packages, etc.)
      unit: string;

      // The price for one ``unit`` of the product. Zero is used
      // to imply that this product is not sold separately, or
      // that the price is not fixed, and must be supplied by the
      // front-end.  If non-zero, this price MUST include applicable
      // taxes.
      price: Amount;

      // An optional base64-encoded product image
      image: ImageDataUrl;

      // a list of taxes paid by the merchant for one unit of this product
      taxes: Tax[];

      // Number of units of the product in stock in sum in total,
      // including all existing sales ever. Given in product-specific
      // units.
      // A value of -1 indicates "infinite" (i.e. for "electronic" books).
      total_stocked: integer;

      // Identifies where the product is in stock.
      location: Location;

      // Identifies when we expect the next restocking to happen.
      next_restock?: timestamp;

    }



.. http:patch:: /products/$PRODUCT_ID

  This is used to update product details in the inventory. Note that the
  ``total_stocked`` and ``total_lost`` numbers MUST be greater or equal than
  previous values (this design ensures idempotency).  In case stocks were lost
  but not sold, increment the ``total_lost`` number.  All fields in the
  request are optional, those that are not given are simply preserved (not
  modified).  Note that the ``description_i18n`` and ``taxes`` can only be
  modified in bulk: if it is given, all translations must be provided, not
  only those that changed.  "never" should be used for the ``next_restock``
  timestamp to indicate no intention/possibility of restocking, while a time
  of zero is used to indicate "unknown".

  **Request:**

  The request must be a `ProductPatchDetail`.

  **Response:**

  :status 204 No content:
    The backend has successfully expanded the inventory.

  .. ts:def:: ProductPatchDetail

    interface ProductPatchDetail {

      // Human-readable product description.
      description: string;

      // Map from IETF BCP 47 language tags to localized descriptions
      description_i18n: { [lang_tag: string]: string };

      // unit in which the product is measured (liters, kilograms, packages, etc.)
      unit: string;

      // The price for one ``unit`` of the product. Zero is used
      // to imply that this product is not sold separately, or
      // that the price is not fixed, and must be supplied by the
      // front-end.  If non-zero, this price MUST include applicable
      // taxes.
      price: Amount;

      // An optional base64-encoded product image
      image: ImageDataUrl;

      // a list of taxes paid by the merchant for one unit of this product
      taxes: Tax[];

      // Number of units of the product in stock in sum in total,
      // including all existing sales ever. Given in product-specific
      // units.
      // A value of -1 indicates "infinite" (i.e. for "electronic" books).
      total_stocked: integer;

      // Number of units of the product that were lost (spoiled, stolen, etc.)
      total_lost: integer;

      // Identifies where the product is in stock.
      location: Location;

      // Identifies when we expect the next restocking to happen.
      next_restock?: timestamp;

    }



.. http:post:: /products/$PRODUCT_ID/lock

  This is used to lock a certain quantity of the product for a limited
  duration while the customer assembles a complete order.  Note that
  frontends do not have to "unlock", they may rely on the timeout as
  given in the ``duration`` field.  Re-posting a lock with a different
  ``duration`` or ``quantity`` updates the existing lock for the same UUID
  and does not result in a conflict.

  Unlocking by using a ``quantity`` of zero is is
  optional but recommended if customers remove products from the
  shopping cart. Note that actually POSTing to ``/orders`` with set
  ``manage_inventory`` and using ``lock_uuid`` will **transition** the
  lock to the newly created order (which may have a different ``duration``
  and ``quantity`` than what was requested in the lock operation).
  If an order is for fewer items than originally locked, the difference
  is automatically unlocked.

  **Request:**

  The request must be a `LockRequest`.

  **Response:**

  :status 204 No content:
    The backend has successfully locked (or unlocked) the requested ``quantity``.
  :status 404 Not found:
    The backend has does not know this product.
  :status 410 Gone:
    The backend does not have enough of product in stock.

  .. ts:def:: LockRequest

    interface LockRequest {

      // UUID that identifies the frontend performing the lock
      lock_uuid: UUID;

      // How long does the frontend intend to hold the lock
      duration: time;

      // How many units should be locked?
      quantity: integer;

    }


.. http:delete:: /products/$PRODUCT_ID

  Delete information about a product.  Fails if the product is locked by
  anyone.

  **Response:**

  :status 204 No content:
    The backend has successfully deleted the product.
  :status 404 Not found:
    The backend does not know the instance or the product.
  :status 409 Conflict:
    The backend refuses to delete the product because it is locked.


------------------
Receiving Payments
------------------

.. _post-order:

.. http:post:: /orders

  Create a new order that a customer can pay for.

  This request is **not** idempotent unless an ``order_id`` is explicitly specified.
  However, while repeating without an ``order_id`` will create another order, that is
  generally pretty harmless (as long as only one of the orders is returned to the wallet).

  .. note::

    This endpoint does not return a URL to redirect your user to confirm the
    payment.  In order to get this URL use :http:get:`/orders/$ORDER_ID`.  The
    API is structured this way since the payment redirect URL is not unique
    for every order, there might be varying parameters such as the session id.

  **Request:**

  The request must be a `PostOrderRequest`.

  **Response:**

  :status 200 OK:
    The backend has successfully created the proposal.  The response is a
    :ts:type:`PostOrderResponse`.
  :status 404 Not found:
    The order given used products from the inventory, but those were not found
    in the inventory.  Or the merchant instance is unknown.  Details in the
    error code. NOTE: no good way to find out which product is not in the
    inventory, we MAY want to specify that in the reply.
  :status 410 Gone:
    The order given used products from the inventory that are out of stock.
    The reponse is a :ts:type:`OutOfStockResponse`.


  .. ts:def:: PostOrderRequest

    interface PostOrderRequest {
      // The order must at least contain the minimal
      // order detail, but can override all
      order: Order;

      // specifies the payment target preferred by the client. Can be used
      // to select among the various (active) wire methods supported by the instance.
      payment_target?: string;

      // specifies that some products are to be included in the
      // order from the inventory.  For these inventory management
      // is performed (so the products must be in stock) and
      // details are completed from the product data of the backend.
      inventory_products?: MinimalInventoryProduct[];

      // Specifies a lock identifier that was used to
      // lock a product in the inventory.  Only useful if
      // ``manage_inventory`` is set.  Used in case a frontend
      // reserved quantities of the individual products while
      // the shopping card was being built.  Multiple UUIDs can
      // be used in case different UUIDs were used for different
      // products (i.e. in case the user started with multiple
      // shopping sessions that were combined during checkout).
      lock_uuids?: UUID[];

    }

    type Order : MinimalOrderDetail | ContractTerms;

  The following fields must be specified in the ``order`` field of the request.  Other fields from
  `ContractTerms` are optional, and will override the defaults in the merchant configuration.

  .. ts:def:: MinimalOrderDetail

    interface MinimalOrderDetail {
      // Amount to be paid by the customer
      amount: Amount;

      // Short summary of the order
      summary: string;

      // URL that will show that the order was successful after
      // it has been paid for.  The wallet must always automatically append
      // the order_id as a query parameter to this URL when using it.
      fulfillment_url: string;
    }

  The following fields can be specified if the order is inventory-based.
  In this case, the backend can compute the amounts from the prices given
  in the inventory.  Note that if the frontend does give more details
  (towards the ContractTerms), this will override those details
  (including total price) that would otherwise computed based on information
  from the inventory.

    type ProductSpecification : (MinimalInventoryProduct | Product);


  .. ts:def:: MinimalInventoryProduct

    Note that if the frontend does give details beyond these,
    it will override those details (including price or taxes)
    that the backend would otherwise fill in via the inventory.

    interface MinimalInventoryProduct {
      // Which product is requested (here mandatory!)
      product_id: string;

      // How many units of the product are requested
      quantity: integer;
    }


  .. ts:def:: PostOrderResponse

    interface PostOrderResponse {
      // Order ID of the response that was just created
      order_id: string;
    }


  .. ts:def:: OutOfStockResponse

    interface OutOfStockResponse {
      // Which items are out of stock?
      missing_products: OutOfStockEntry;
    }

    interface OutOfStockEntry {
      // Product ID of an out-of-stock item
      product_id: string;

      // Requested quantity
      requested_quantity: integer;

      // Available quantity (must be below ``requested_quanitity``)
      available_quantity: integer;

      // When do we expect the product to be again in stock?
      // Optional, not given if unknown.
      restock_expected?: timestamp;
    }



.. http:get:: /orders

  Returns known orders up to some point in the past.

  **Request:**

  :query paid: *Optional*. If set to yes, only return paid orders, if no only unpaid orders. Do not give (or use "all") to see all orders regardless of payment status.
  :query refunded: *Optional*. If set to yes, only return refunded orders, if no only unrefunded orders. Do not give (or use "all") to see all orders regardless of refund status.
  :query wired: *Optional*. If set to yes, only return wired orders, if no only orders with missing wire transfers. Do not give (or use "all") to see all orders regardless of wire transfer status.
  :query date: *Optional.* Time threshold, see ``delta`` for its interpretation.  Defaults to the oldest or most recent entry, depending on ``delta``.
  :query start: *Optional*. Row number threshold, see ``delta`` for its interpretation.  Defaults to ``UINT64_MAX``, namely the biggest row id possible in the database.
  :query delta: *Optional*. takes value of the form ``N (-N)``, so that at most ``N`` values strictly younger (older) than ``start`` and ``date`` are returned.  Defaults to ``-20``.
  :query timeout_ms: *Optional*. Timeout in milli-seconds to wait for additional orders if the answer would otherwise be negative (long polling). Only useful if delta is positive. Note that the merchant MAY still return a response that contains fewer than delta orders.

  **Response:**

  :status 200 OK:
    The response is an `OrderHistory`.

  .. ts:def:: OrderHistory

    interface OrderHistory {
      // timestamp-sorted array of all orders matching the query.
      // The order of the sorting depends on the sign of ``delta``.
      orders : OrderHistory[];
    }


  .. ts:def:: OrderHistoryEntry

    interface OrderHistoryEntry {
      // The serial number this entry has in the merchant's DB.
      row_id: number;

      // order ID of the transaction related to this entry.
      order_id: string;

      // Transaction's timestamp
      timestamp: Timestamp;

      // Total amount the customer should pay for this order.
      total: Amount;

      // Total amount the customer did pay for this order.  Payments
      // that were later aborted (/abort) are NOT included.
      paid: Amount;

      // Total amount the customer was refunded for this order.
      // (excludes refunds from aborts).
      refunded: Amount;

      // Was the order fully paid?
      is_paid: boolean;

    }



.. http:post:: /public/orders/$ORDER_ID/claim

  Wallet claims ownership (via nonce) over an order.  By claiming
  an order, the wallet obtains the full contract terms, and thereby
  implicitly also the hash of the contract terms it needs for the
  other ``/public/`` APIs to authenticate itself as the wallet that
  is indeed eligible to inspect this particular order's status.

  **Request:**

  The request must be a `ClaimRequest`

  .. ts:def:: ClaimRequest

    interface ClaimRequest {
      // Nonce to identify the wallet that claimed the order.
      nonce: string;
    }

  **Response:**

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

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins. The body is a
    a `merchant refund response <MerchantRefundResponse>`.
  :status 400 Bad request:
    Either the client request is malformed or some specific processing error
    happened that may be the fault of the client as detailed in the JSON body
    of the response.
  :status 403 Forbidden:
    The ``h_contract`` does not match the $ORDER_ID.
  :status 404 Not found:
    The merchant backend could not find the order or the instance
    and thus cannot process the abort request.
  :status 412 Precondition Failed:
    Aborting the payment is not allowed, as the original payment did succeed.
  :status 424 Failed Dependency:
    The merchant's interaction with the exchange failed in some way.
    The error from the exchange is included.

  The backend will return verbatim the error codes received from the exchange's
  :ref:`refund <_refund>` API.  The frontend should pass the replies verbatim to
  the browser/wallet.

  .. ts:def:: AbortRequest

    interface AbortRequest {

      // hash of the order's contract terms (this is used to authenticate the
      // wallet/customer in case $ORDER_ID is guessable).
      h_contract: HashCode;


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

      // We do we NOT return the contract terms here because they may not
      // exist in case the wallet did not yet claim them.
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

  **Request:**

  :query h_contract: hash of the order's contract terms (this is used to authenticate the wallet/customer in case $ORDER_ID is guessable). *Mandatory!*
  :query session_id: *Optional*. Session ID that the payment must be bound to.  If not specified, the payment is not session-bound.
  :query timeout_ms: *Optional.*  If specified, the merchant backend will
    wait up to ``timeout_ms`` milliseconds for completion of the payment before
    sending the HTTP response.  A client must never rely on this behavior, as the
    merchant backend may return a response immediately.
  :query refund=AMOUNT: *Optional*. Indicates that we are polling for a refund above the given AMOUNT. Only useful in combination with timeout.

  **Response:**

  :status 200 OK:
    The response is a `PublicPayStatusResponse`, with ``paid`` true.
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

  **Response:**

  :status 204 No content:
    The backend has successfully deleted the order.
  :status 404 Not found:
    The backend does not know the instance or the order.
  :status 409 Conflict:
    The backend refuses to delete the order.


--------------
Giving Refunds
--------------

.. _refund:
.. http:post:: /orders/$ORDER_ID/refund

  Increase the refund amount associated with a given order.  The user should be
  redirected to the ``taler_refund_url`` to trigger refund processing in the wallet.

  **Request:**

  The request body is a `RefundRequest` object.

  **Response:**

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

      // URL (handled by the backend) that the wallet should access to
      // trigger refund processing.
      // taler://refund/[$H_CONTRACT/$AMOUNT????]
      taler_refund_uri: string;
    }



------------------------
Tracking Wire Transfers
------------------------

.. http:post:: /transfers

  Inform the backend over an incoming wire transfer. The backend should inquire about the details with the exchange and mark the respective orders as wired.  Note that the request will fail if the WTID is not unique (which should be guaranteed by a correct exchange).
  This request is idempotent and should also be used to merely re-fetch the
  transfer information from the merchant's database (assuming we got a non-error
  response from the exchange before).

  **Request:**

   The request must provide `transfer information <TransferInformation>`.

  **Response:**

  :status 200 OK:
    The wire transfer is known to the exchange, details about it follow in the body.
    The body of the response is a `TrackTransferResponse`.  Note that
    the similarity to the response given by the exchange for a "GET /transfer"
    is completely intended.
  :status 202 Accepted:
    The exchange provided conflicting information about the transfer. Namely,
    there is at least one deposit among the deposits aggregated by ``wtid``
    that accounts for a coin whose
    details don't match the details stored in merchant's database about the same keyed coin.
    The response body contains the `TrackTransferConflictDetails`.
    This is indicative of a malicious exchange that claims one thing, but did
    something else.  (With respect to the HTTP specficiation, it is not
    precisely that we did not act upon the request, more that the usual
    action of filing the transaction as 'finished' does not apply.  In
    the future, this is a case where the backend actually should report
    the bad behavior to the auditor -- and then hope for the auditor to
    resolve it. So in that respect, 202 is the right status code as more
    work remains to be done for a final resolution.)
  :status 404 Not Found:
    The instance is unknown to the exchange.
  :status 409 Conflict:
    The wire transfer identifier is already known to us, but for a different amount,
    wire method or exchange.
  :status 424 Failed Dependency:
    The exchange returned an error when we asked it about the "GET /transfer" status
    for this wire transfer. Details of the exchange error are returned.

  .. ts:def:: TransferInformation

    interface TransferInformation {
      // how much was wired to the merchant (minus fees)
      credit_amount: Amount;

      // raw wire transfer identifier identifying the wire transfer (a base32-encoded value)
      wtid: WireTransferIdentifierRawP;

      // target account that received the wire transfer
      payto_uri: string;

      // base URL of the exchange that made the wire transfer
      exchange: string;
    }

  .. ts:def:: TrackTransferResponse

    interface TrackTransferResponse {
      // Total amount transferred
      total: Amount;

      // Applicable wire fee that was charged
      wire_fee: Amount;

      // Time of the execution of the wire transfer by the exchange, according to the exchange
      execution_time: Timestamp;

      // details about the deposits
      deposits_sums: TrackTransferDetail[];

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

      // Offset in the ``exchange_transfer`` where the
      // exchange's response fails to match the ``exchange_deposit_proof``.
      conflict_offset: number;

      // The response from the exchange which tells us when the
      // coin was returned to us, except that it does not match
      // the expected value of the coin.
      exchange_transfer: TrackTransferResponse;

      // Proof data we have for the ``exchange_transfer`` data (signatures from exchange)
      exchange_proof: TrackTransferProof;

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

    .. ts:def:: TrackTransferProof

    interface TrackTransferProof {
      // signature from the exchange made with purpose
      // ``TALER_SIGNATURE_EXCHANGE_CONFIRM_WIRE_DEPOSIT``
      exchange_sig: EddsaSignature;

      // public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  Again given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      exchange_pub: EddsaSignature;

      // hash of the wire details (identical for all deposits)
      // Needed to check the ``exchange_sig``
      h_wire: HashCode;
    }



.. http:get:: /transfers

  Obtain a list of all wire transfers the backend has checked.

  **Request:**

   :query payto_uri: *Optional*. Filter for transfers to the given bank account (subject and amount MUST NOT be given in the payto URI)
   :query before: *Optional*. Filter for transfers executed before the given timestamp
   :query after: *Optional*. Filter for transfers executed after the given timestamp
   :query limit: *Optional*. At most return the given number of results. Negative for descending in execution time, positive for ascending in execution time.
   :query offset: *Optional*. Starting transfer_serial_id for an iteration.
   :query verified: *Optional*. Filter transfers by verification status.

  **Response:**

  :status 200 OK:
    The body of the response is a `TransferList`.

  .. ts:def:: TransferList

    interface TransferList {
       // list of all the transfers that fit the filter that we know
       transfers : TransferDetails[];
    }

    interface TransferDetails {
      // how much was wired to the merchant (minus fees)
      credit_amount: Amount;

      // raw wire transfer identifier identifying the wire transfer (a base32-encoded value)
      wtid: WireTransferIdentifierRawP;

      // target account that received the wire transfer
      payto_uri: string;

      // base URL of the exchange that made the wire transfer
      exchange: string;

      // Serial number identifying the transfer in the merchant backend.
      // Used for filgering via ``offset``.
      transfer_serial_id: number;

      // Time of the execution of the wire transfer by the exchange, according to the exchange
      // Only provided if we did get an answer from the exchange.
      execution_time?: Timestamp;

      // True if we checked the exchange's answer and are happy with it.
      // False if we have an answer and are unhappy, missing if we
      // do not have an answer from the exchange.
      verified?: boolean;
    }




--------------------
Giving Customer Tips
--------------------

.. _tips:
.. http:post:: /reserves

  Create a reserve for tipping.

  This request is **not** idempotent.  However, while repeating
  it will create another reserve, that is generally pretty harmless
  (assuming only one of the reserves is filled with a wire transfer).
  Clients may want to eventually delete the unused reserves to
  avoid clutter.

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

   :query after: *Optional*.  Only return reserves created after the given timestamp in milliseconds
   :query active: *Optional*.  Only return active/inactive reserves depending on the boolean given
   :query failures: *Optional*.  Only return reserves where we disagree with the exchange about the initial balance.

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

      // Is this reserve active (false if it was deleted but not purged)
      active: boolean;
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

  **Response:**

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


.. http:post:: /tips

  Authorize creation of a tip from the given reserve, except with
  automatic selection of a working reserve of the instance by the
  backend. Intentionally otherwise identical to the /authorize-tip
  endpoint given above.

  **Request:**

  The request body is a `TipCreateRequest` object.

  **Response:**

  :status 200 OK:
    A tip has been created. The backend responds with a `TipCreateConfirmation`
  :status 404 Not Found:
    The instance is unknown to the backend.
  :status 412 Precondition Failed:
    The tip amount requested exceeds the available reserve balance for tipping
    in all of the reserves of the instance.


.. http:delete:: /reserves/$RESERVE_PUB

  Delete information about a reserve.  Fails if the reserve still has
  committed to tips that were not yet picked up and that have not yet
  expired.

  **Request:**

  :query purge: *Optional*. If set to YES, the reserve and all information
      about tips it issued will be fully deleted.
      Otherwise only the private key would be deleted.

  **Response:**

  :status 204 No content:
    The backend has successfully deleted the reserve.
  :status 404 Not found:
    The backend does not know the instance or the reserve.
  :status 409 Conflict:
    The backend refuses to delete the reserve (committed tips awaiting pickup).



.. http:get:: /tips/$TIP_ID

  Obtain information about a particular tip.

   **Request:**

   :query pickups: if set to "yes", returns also information about all of the pickups

   **Response:**

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

  **Request:**

  The request body is a `TipPickupRequest` object.

  **Response:**

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





------------------
The Contract Terms
------------------

.. _contract_terms::

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
      // merchant-internal identifier for the product.
      product_id?: string;

      // Human-readable product description.
      description: string;

      // Map from IETF BCP 47 language tags to localized descriptions
      description_i18n?: { [lang_tag: string]: string };

      // The number of units of the product to deliver to the customer.
      quantity: integer;

      // The unit in which the product is measured (liters, kilograms, packages, etc.)
      unit: string;

      // The price of the product; this is the total price for ``quantity`` times ``unit`` of this product.
      price: Amount;

      // An optional base64-encoded product image
      image?: ImageDataUrl;

      // a list of taxes paid by the merchant for this product. Can be empty.
      taxes: Tax[];

      // time indicating when this product should be delivered
      delivery_date: Timestamp;

      // where to deliver this product. This may be an URL for online delivery
      // (i.e. 'http://example.com/download' or 'mailto:customer@example.com'),
      // or a location label defined inside the proposition's 'locations'.
      // The presence of a colon (':') indicates the use of an URL.
      delivery_location: string;
    }

  .. ts:def:: Tax

    interface Tax {
      // the name of the tax
      name: string;

      // amount paid in tax
      tax: Amount;
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
