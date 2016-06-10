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

============
Merchant API
============

Before reading the API reference documentation, it is suggested to read the :ref:`merchant-arch`

------------------------------
The Frontent HTTP API
------------------------------

.. http:get:: contract_url

  Triggers the contract generation. Note that the URL may differ between
  merchants.

  **Request:**

  The request depends entirely on the merchant implementation.

  **Response**

  :status 200 OK: The request was successful.  The body contains an :ref:`Offer <contract>`.
  :status 400 Bad Request: Request not understood.
  :status 500 Internal Server Error:
    In most cases, some error occurred while the backend was generating the
    contract. For example, it failed to store it into its database.

.. _pay:
.. http:post:: pay_url


  Send the deposit permission to the merchant. The client should POST a `deposit-permission`_
  object. Note that ``pay_url`` is make known by the frontent to the wallet via the DOM event
  ``taler-execute-payment``, documented in :ref:`byoffer`.

  .. _deposit-permission:
  .. code-block:: tsref

    interface DepositPermission {
      // the hashed :ref:`wire details <wireformats>` of this merchant. The wallet takes this value as-is from the contract
      H_wire: HashCode;

      // the base32 encoding of the field `h_contract` of the contract `blob <contract-blob>`. The wallet can choose whether to take this value obtained from the field `h_contract`, or regenerating one starting from the values it gets within the contract
      H_contract: HashCode;

      // a 53-bit number corresponding to the contract being agreed on
      transaction_id: number;

      // total amount being paid as per the contract (the sum of the amounts from the `coins` may be larger to cover deposit fees not covered by the merchant)
      total_amount: Amount;

      // maximum fees merchant agreed to cover as per the contract
      max_fee: Amount;

      // signature by the merchant over the contract, must match signed data of purpose TALER_SIGNATURE_MERCHANT_CONTRACT
      merchant_sig: EddsaSignature;

      // a timestamp of this deposit permission. It equals just the contract's timestamp
      timestamp: Timestamp;

      // same value held in the contract's `refund` field
      refund_deadline: Timestamp;

      // the chosen exchange's base URL
      exchange: string;

      // the coins used to sign the contract
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

      // exchange's signature over this coin's public key
      ub_sig: RsaSignature;

      // the signature made by the coin's private key on a `struct TALER_DepositRequestPS`. See section `Signatures` on the exchange's API page.
      coin_sig: EddsaSignature;
  }

  **Success Response:**

  :status 301 Redirection: the merchant should redirect the client to his fullfillment page, where the good outcome of the purchase must be shown to the user.

  **Failure Responses:**

  The error codes and data sent to the wallet are a mere copy of those gotten from the exchange when attempting to pay. The section about :ref:`deposit <deposit>` explains them in detail.


.. http:post:: fulfillment_url

  Returns a cooperative merchant page (called the execution page) that will
  send the ``taler-execute-payment`` to the wallet and react to failure or
  success of the actual payment. ``fulfillment_url`` is included in the `contract`_.
  Furthermore, :ref:`payprot` documents the payment protocol between wallets and
  merchants.

  The wallet will inject an ``XMLHttpRequest`` request to the merchant's
  ``$pay_url`` in the context of the execution page.  This mechanism is
  necessary since the request to ``$pay_url`` must be made from the merchant's
  origin domain in order to preserve information (e.g. cookies, origin header).

------------------------------
The Merchant Backend HTTP API
------------------------------

The following API are made available by the merchant's `backend` to the merchant's `frontend`.

.. http:post:: /contract

  Ask the backend to add some missing (mostly related to cryptography) information to the contract.

  **Request:**

  The `proposition` that is to be sent from the frontend is a `contract` object without the fields

  * `exchanges`
  * `auditors`
  * `H_wire`
  * `merchant_pub`

  The `backend` then completes this information based on its configuration.

  **Response**

  :status 200 OK:
    The backend has successfully created the contract.  It responds with an :ref:`offer <offer>`. This request should virtually always be successful.
  On success, the `frontend` should pass this response verbatim to the wallet.

  :status 403 Forbidden:
    The frontend used the same transaction ID twice.  This is only allowed if the response from the backend was lost ("instant" replay), but to assure that frontends usually create fresh transaction IDs this is forbidden if the contract was already paid.  So attempting to have the backend sign a contract for a contract that was already paid by a wallet (and thus was generated by the frontend a "long" time ago), is forbidden and results in this error.  Frontends must make sure that they increment the transaction ID properly and persist the largest value used so far.

.. http:post:: /pay

  Asks the `backend` to execute the transaction with the exchange and deposit the coins.

  **Request:**

  The `frontend` passes the :ref:`deposit permission <deposit-permission>`
  received from the wallet, and optionally adding a field named `pay_deadline`,
  indicating a deadline by which he would expect to receive the bank transfer
  for this deal.  Note that the `pay_deadline` must be after the `refund_deadline`.
  The backend calculates the `pay_deadline` by adding the `wire_transfer_delay`
  value found in the configuration to the current time.

  **Response:**

  :status 200 OK:
    The exchange accepted all of the coins. The `frontend` should now fullfill the
    contract.  This response has no meaningful body, the frontend needs to
    generate the fullfillment page.
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



.. http:get:: /track/transfer

  Provides deposits associated with a given wire transfer.

  **Request:**

  :query wtid: raw wire transfer identifier identifying the wire transfer (a base32-encoded value)
  :query exchange_uri: base URI of the exchange that made the wire transfer

  **Response:**

  :status 200 OK:
    The wire transfer is known to the exchange, details about it follow in the body.
    The body of the response is a `TrackTransferResponse`_.  Note that
    the similarity to the response given by the exchange for a /track/transfer
    is completely intended.

  :status 404 Not Found:
    The wire transfer identifier is unknown to the exchange.

.. http:get:: /track/transaction

  Provide the wire transfer identifier associated with an (existing) deposit operation.

  **Request:**

  :query id: ID of the transaction we want to trace (an integer)

  **Response:**

  :status 200 OK:
    The deposit has been executed by the exchange and we have a wire transfer identifier.
     The response body is a JSON array of `TransactionWireTransfer`_ objects.


  :status 202 Accepted:
    The deposit request has been accepted for processing, but was not yet
    executed.  Hence the exchange does not yet have a wire transfer identifier.
    The merchant should come back later and ask again.
    The response body is a `TrackTransactionAcceptedResponse`_.  Note that
    the similarity to the response given by the exchange for a /track/transaction
    is completely intended.

  :status 404 Not Found: The transaction is unknown to the backend.


  **Details:**

  .. _tsref-type-TransactionWireTransfer:
  .. _TransactionWireTransfer:
  .. code-block:: tsref

    interface TransactionWireTransfer {
      // 32-byte wire transfer identifier
      wtid: Base32;

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

---------
Encodings
---------

Data such as dates, binary blobs, and other useful formats, are encoded as described in :ref:`encodings-ref`.

.. _contract:

Offer and Contract
^^^^^^^^^^^^^^^^^^

An `offer` is a wrapper around a contract with some additional information
that is legally non-binding:

  .. _tsref-type-Offer:
  .. code-block:: tsref
    :name: offer

    interface Offer {
      // The actual contract
      contract: Contract;

      // The hash of the contract, encoded in base32, provided
      // as a convenience.  All components that do not fully trust
      // the merchant must verify this field.
      H_contract: HashCode ;

      // Signature over the contract made by the merchant.
      // Must confirm to the `Signature specification`_ below.
      merchant_sig: EddsaSignature;
    }

The `contract` must have the following structure:

  .. _tsref-type-Contract:
  .. code-block:: tsref

    interface Contract {
      // Total price for the transaction.
      // The exchange will subtract deposit fees from that amount
      // before transfering it to the merchant.
      amount: Amount;

      // Optional identifier chosen by the merchant,
      // which allows the wallet to detect if it is buying
      // a contract where it already has paid for the same
      // product instance.
      repurchase_correlation_id?: string;

      // URL that the wallet will navigate to after the customer
      // confirmed purchasing the contract.  Responsible for
      // doing the actual payment and making available the product (if digital)
      // or displaying a confirmation.
      // The placeholder ${H_contract} will be replaced
      // with the contract hash by wallets before navigating
      // to the fulfillment URL.
      fulfillment_url: string;

      // Maximum total deposit fee accepted by the merchant for this contract
      max_fee: Amount;

      // 53-bit number chosen by the merchant to uniquely identify the contract.
      transaction_id: number;

      // List of products that are part of the purchase (see `below)
      products: Product[];

      // Time when this contract was generated
      timestamp: number;

      // After this deadline has passed, no refunds will be accepted.
      refund_deadline: number;

      // After this deadline, the merchant won't accept payments for the contact
      expiry: number;

      // Merchant's public key used to sign this contract; this information is typically added by the backend
      // Note that this can be an ephemeral key.
      merchant_pub: EddsaPublicKey;

      // More info about the merchant, see below
      merchant: Merchant;

      // The hash of the merchant's wire details.
      H_wire: HashCode;

      // Any exchanges audited by these auditors are accepted by the merchant.
      auditors: Auditor[];

      // Exchanges that the merchant accepts even if it does not accept any auditors that audit them.
      exchanges: Exchange[];

      // Map from label to a `Location`_.
      // The label strings must not contain a colon (`:`).
      locations: { [label: string]: Location>;
    }

  The wallet must select a exchange that either the mechant accepts directly by listing it in the exchanges arry, or for which the merchant accepts an auditor that audits that exchange by listing it in the auditors array.

  The `product` object describes the product being purchased from the merchant. It has the following structure:

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

      // human-readable date indicating when this product should be delivered
      delivery_date: string;

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


  .. _Location:
  .. _tsref-type-Location:
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

  .. code-block:: ts

    interface Auditor {
      // official name
      name: string;

      auditor_pub: EddsaPublicKey

      // Base URL of the auditor
      url: string;
    }

  .. code-block:: ts

    interface Exchange {
      // the exchange's base URL
      url: string;

      // master public key of the exchange
      master_pub: EddsaPublicKey;
    }


.. _`Signature specification`:

When the contract is signed by the merchant or the wallet, the
signature is made over the hash of the JSON text, as the contract may
be confidential between merchant and customer and should not be
exposed to the exchange.  The hashcode is generated by hashing the
encoding of the contract's JSON obtained by using the flags
``JSON_COMPACT | JSON_PRESERVE_ORDER``, as described in the `libjansson
documentation
<https://jansson.readthedocs.org/en/2.7/apiref.html?highlight=json_dumps#c.json_dumps>`_.
The following structure is a container for the signature. The purpose
should be set to ``TALER_SIGNATURE_MERCHANT_CONTRACT``.

.. _contract-blob:
.. code-block:: c

   struct MERCHANT_Contract
   {
     struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
     /**
      * Transaction ID must match the one in the JSON contract, here given
      * in big endian.
      */
     uint64_t transaction_id;

     /**
      * Total amount to be paid for the contract, must match JSON "amount".
      */
     struct TALER_AmountNBO total_amount;

     /**
      * Total amount to be paid for the contract, must match JSON "max_fee".
      */
     struct TALER_AmountNBO max_fee;

     /**
      * Hash of the overall JSON contract.
      */
     struct GNUNET_HashCode h_contract;
   }
