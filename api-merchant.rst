=====================
The Merchant HTTP API
=====================

This chapter defines the HTTP-based protocol between the Taler wallet and the
merchant.

It is assumed that the browser has a secure and possibly customer-anonymizing
channel to the merchant, typically by using the Tor browser bundle.
Furthermore, it is assumed that the merchant's server does not repudiate on
contractual offers it has made.  If necessary, the merchant assures this by
limiting the time for which the offer is valid.

Taler also assumes that the wallet and the merchant can agree on the
current time; similar to what is required to connect to Tor or
validate TLS certificates.  The wallet may rely on the timestamp
provided in the HTTP "Date:" header for this purpose, but the customer
is expected to check that the time of his machine is approximately
correct.

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

      // The hash of the contract, provided as a convenience.
      // All components that do not fully trust the
      // merchant must verify this field.
      H_contract: HashCode;

      // Signature over the contract made by the merchant.
      // Must confirm to the `Signature specification`_ below.
      sig: EddsaSignature;
    }

The contract must have the following structure:

  .. _tsref-type-Contract:
  .. code-block:: tsref

    interface Contract {
      // Total price for the transaction.
      // The mint will subtract deposit fees from that amount
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

      // Any mints audited by these auditors are accepted by the merchant.
      auditors: Auditor[];

      // Mints that the merchant accepts even if it does not accept any auditors that audit them.
      mints: Mint[];

      // Map from label to a `Location`_.
      // The label strings must not contain a colon (`:`).
      locations: { [label: string]: Location>;
    }

  The wallet must select a mint that either the mechant accepts directly by listing it in the mints arry, or for which the merchant accepts an auditor that audits that mint by listing it in the auditors array.

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

    interface Mint {
      // the mint's base URL
      url: string;

      // master public key of the mint
      master_pub: EddsaPublicKey;
    }


.. _`Signature specification`:

When the contract is signed by the merchant or the wallet, the
signature is made over the hash of the JSON text, as the contract may
be confidential between merchant and customer and should not be
exposed to the mint.  The hashcode is generated by hashing the
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

---------------------
The Merchant HTTP API
---------------------

In the following requests, ``$``-variables refer to the variables in the
merchant's offer.

.. http:post:: $pay_url

  Send the deposit permission to the merchant. Note that the URL may differ between
  merchants.

  :reqheader Content-Type: application/json
  :<json base32 H_wire: the hashed :ref:`wire details <wireformats>` of this merchant. The wallet takes this value as-is from the contract
  :<json base32 H_contract: the base32 encoding of the field `h_contract` of the contract `blob <contract-blob>`. The wallet can choose whether to take this value obtained from the field `h_contract`, or regenerating one starting from the values it gets within the contract
  :<json int transaction_id: a 53-bit number corresponding to the contract being agreed on
  :<json date timestamp: a timestamp of this deposit permission. It equals just the contract's timestamp
  :<json date refund_deadline: same value held in the contract's `refund` field
  :<json string mint: the chosen mint's base URL
  :<json array coins: the coins used to sign the contract

  For each coin, the array contains the following information:

  :<json amount f: the :ref:`amount <Amount>` this coin is paying, including this coin's deposit fee
  :<json base32 coin_pub: the coin's public key
  :<json base32 denom_pub: the denomination's (RSA public) key
  :<json base32 ub_sig: the mint's signature over this coin's public key
  :<json base32 coin_sig: the signature made by the coin's private key on a `struct TALER_DepositRequestPS`. See the :ref:`dedicated section <Signatures>` on the mint's specifications.

  **Success Response:**

  :status 301 Redirection: the merchant should redirect the client to his fullfillment page, where the good outcome of the purchase must be shown to the user.

  **Failure Responses:**

  The error codes and data sent to the wallet are a mere copy of those gotten from the mint when attempting to pay. The section about :ref:`deposit <deposit>` explains them in detail.


.. http:post:: $exec_url

  Returns a cooperative merchant page (called the execution page) that will
  send the ``taler-execute-payment`` to the wallet and react to failure or
  success of the actual payment.

  The wallet will inject an ``XMLHttpRequest`` request to the merchant's
  ``$pay_url`` in the context of the execution page.  This mechanism is
  necessary since the request to ``$pay_url`` must be made from the merchant's
  origin domain in order to preserve information (e.g. cookies, origin header).
