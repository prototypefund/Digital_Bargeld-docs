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


------------------------------
Frontend-Backend communication
------------------------------

To create a contract, the `frontend` needs to generate the body of a
`contract` in JSON format.  This `proposition` is then signed by the
`backend` and then sent to the wallet.  If the customer approves
the `proposition`, the wallet signs the body of the `contract`
using coins in the form of a `deposit permission`.  This signature
using the coins signifies both agreement of the customer and
represents payment at the same time.  The `frontend` passes the
`deposit permission` to the `backend` which immediately verifies it
with the mint and signals the `frontend` the success or failure of
the payment process.  If the payment is successful, the `frontend` is
responsible for generating the fullfillment page.

The contract format is specified in the `contract`_ section.


---------
Encodings
---------

Data such as dates, binary blobs, and other useful formats, are encoded as described in :ref:`encodings-ref`.

.. _contract:

Contract
^^^^^^^^

A `contract` is a JSON object having the following structure, which is returned as a
successful response to the following two calls:

.. note::

  This section holds just a central definition for the `contract`, so refer to each component's
  section for its detailed REST interaction.

.. http:get:: /taler/contract

  Issued by the wallet when the customer wants to see the contract for a certain purchase

.. http:post:: /contract

  Issued by the frontend to the backend when it wants to augment its `proposition` with all the
  cryptographic information. For the sake of precision, the frontend encloses the following JSON inside a `contract`
  field to the actual JSON sent to the backend.

  :>json object amount: an :ref:`amount <Amount>` indicating the total price for the transaction. Note that, in the act of paying, the mint will subtract from this amount the deposit fees due to the choice of coins made by wallets, and finally transfer the remaining amount to the merchant's bank account.
  :>json object max_fee: :ref:`amount <Amount>` indicating the maximum deposit fee accepted by the merchant for this transaction.
  :>json int transaction_id: a 53-bit number chosen by the merchant to uniquely identify the contract.
  :>json array products: a collection of `product` objects (described below), for each different item purchased within this transaction.
  :>json `date` timestamp: this contract's generation time
  :>json `date` refund_deadline: the maximum time until which the merchant can refund the wallet in case of a problem, or some request
  :>json `date` expiry: the maximum time until which the wallet can agree on this contract
  :>json base32 merchant_pub: merchant's EdDSA key used to sign this contract; this information is typically added by the `backend`
  :>json object merchant: the set of values describing this `merchant`, defined below
  :>json base32 H_wire: the hash of the merchant's :ref:`wire details <wireformats>`; this information is typically added by the `backend`
  :>json base32 H_contract: encoding of the `h_contract` field of contract :ref:`blob <contract-blob>`. Tough the wallet gets all required information to regenerate this hash code locally, the merchant sends it anyway to avoid subtle encoding errors, or to allow the wallet to double check its locally generated copy
  :>json array auditors: a JSON array of `auditor` objects.  Any mints audited by these auditors are accepted by the merchant.
  :>json string pay_url: the relative URL where the merchant will receive the deposit permission (i.e. the payment)
  :>json string exec_url: FIXME
  :>json array mints: a JSON array of `mint` objects that the merchant accepts even if it does not accept any auditors that audit them.
  :>json object locations: maps labels for locations to detailed geographical location data (details for the format of locations are specified below). The label strings must not contain a colon (`:`).  These locations can then be references by their respective labels throughout the contract.

  The wallet must select a mint that either the mechant accepts directly by listing it in the mints arry, or for which the merchant accepts an auditor that audits that mint by listing it in the auditors array.

  The `product` object focuses on the product being purchased from the merchant. It has the following structure:

  :>json string description: this object contains a human-readable description of the product
  :>json int quantity: the quantity of the product to deliver to the customer (optional, if applicable)
  :>json object price: the price of the product; this is the total price for the amount specified by `quantity`
  :>json int product_id: merchant's 53-bit internal identification number for the product (optional)
  :>json array taxes: a list of objects indicating a `taxname` and its amount. Again, italics denotes the object field's name.
  :>json string delivery_date: human-readable date indicating when this product should be delivered
  :>json string delivery_location: where to deliver this product. This may be an URI for online delivery (i.e. `http://example.com/download` or `mailto:customer@example.com`), or a location label defined inside the proposition's `locations`.  The presence of a colon (`:`) indicates the use of an URL.

  The `merchant` object:

  :>json string address: label for a location with the business address of the merchant
  :>json string name: the merchant's legal name of business
  :>json object jurisdiction: label for a location that denotes the jurisdiction for disputes. Some of the typical fields for a location (such as a street address) may be absent.

  The `location` object:

  :>json string country: blah
  :>json string city: blah
  :>json string state: blah
  :>json string region: blah
  :>json string province: blah
  :>json int zip_code: blah
  :>json string street: blah
  :>json string street_number: blah

  Depending on the country, some fields may be missing

  The `auditor` object:

  :>json string name: official name
  :>json base32 auditor_pub: public key of the auditor
  :>json string uri: URI of the auditor

  The `mint` object:

  :>json string url: the mint's base URL
  :>json base32 master_pub: master public key of the mint


When the contract is signed by the merchant or the wallet, the
signature is made over the hash of the JSON text, as the contract may
be confidential between merchant and customer and should not be
exposed to the mint.  The hashcode is generated by hashing the
encoding of the contract's JSON obtained by using the flags
`JSON_COMPACT | JSON_PRESERVE_ORDER`, as described in the `libjansson
documentation
<https://jansson.readthedocs.org/en/2.7/apiref.html?highlight=json_dumps#c.json_dumps>`_.
The following structure is a container for the signature. The purpose
should be set to `TALER_SIGNATURE_MERCHANT_CONTRACT`.

.. _contract-blob:

.. sourcecode:: c

   struct MERCHANT_Contract
   {
     struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
     struct GNUNET_HashCode h_contract;
   }

---------------
Wallet-Frontend
---------------

.. _message-passing-ref:


When the user chooses to pay, the page needs to inform the extension
that it should execute the payment process.  This is done by sending
a

  .. js:data:: taler-contract

event to the extension.  The following example code fetches the
contract from the merchant website and passes it to the extension
when the button is clicked:

.. sourcecode:: javascript

   function deliver_contract_to_wallet(jsonContract){
   var cevent = new CustomEvent('taler-contract', { detail: jsonContract });
     document.body.dispatchEvent(cevent);
   };

   function taler_pay(form){
     var contract_req = new XMLHttpRequest();
     // request contract from merchant website, i.e.:
     contract_req.open("GET", "/taler/contract", true);
     contract_req.onload = function (ev){
       if (contract_req.readyState == 4){ // HTTP request is done
         if (contract_req.status == 200){ // HTTP 200 OK
           deliver_contract_to_wallet(contract_req.responseText);
         }else{
           alert("Merchant failed to generate contract: " + contract_req.status);
         }
       }
     };
     contract_req.onerror = function (ev){
       // HTTP request failed, we didn't even get a status code...
       alert(contract_req.statusText);
     };
     contract_req.send(null); // run the GET request
   };

.. sourcecode:: html

    <input type="button" onclick="taler_pay(this.form)" value="Ok">


In this example, the function `taler_pay` is attached to the
'checkout' button. This function issues the required POST and passes
the contract to the wallet in the the function
`deliver_contract_to_wallet` if the contract was received correctly
(i.e. HTTP response code was 200 OK).

+++++++++++++++
The RESTful API
+++++++++++++++

The merchant's frontend must provide the JavaScript logic with the
ability to fetch the JSON contract.  In the example above, the
JavaScript expected the contract at `/taler/contract` and the payment
to go to '/taler/pay'.  However, it is possible to deliver the
contract from any URL and post the deposit permission to any URL,
as long as the client-side logic knows how to fetch it and pass it to
the extension.  For example, the contract could already be embedded in
the webpage or be at a contract-specific URL to avoid relying on
cookies to identify the shopping session.


.. http:get:: /taler/contract

  Triggers the contract generation. Note that the URL may differ between
  merchants.

  **Success Response**

  :status 200 OK: The request was successful.
  :resheader Content-Type: application/json
  :>json base32 contract: a :ref:`JSON contract <contract>` for this deal deprived of `pay_url` and `exec_url`
  :>json base32 sig: the signature of the binary described in :ref:`blob <contract-blob>`.
  :>json string pay_url: relative URL where the wallet should issue the payment
  :>json string exec_url: FIXME
  :>json base32 H_contract: the base32 encoding of the field `h_contract` of the contract's :ref:`blob <contract-blob>`

  **Failure Response**

  In most cases, the response will just be the forwarded response that the `frontend` got from the `backend`.

  :status 400 Bad Request: Request not understood.
  :status 500 Internal Server Error: In most cases, some error occurred while the backend was generating the contract. For example, it failed to store it into its database.


.. _deposit-permission:

.. http:post:: /taler/pay

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


