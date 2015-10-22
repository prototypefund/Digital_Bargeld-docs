================
The Merchant API
================

This Merchant API defines the
interactions between a browser-based wallet and an HTTP-based RESTful merchant.
The protocol allows the customer and the merchant to agree upon a
contract and for the customer to spend coins according to the contract
proposed by the merchant.

It is assumed that the browser has a secure and possibly
customer-anonymizing channel to the merchant, typically by using the
Tor browser bundle.  Furthermore, it is assumed that the merchant's
server does not repudiate on contractual offers it has made.  If
necessary, the merchant assures this by limiting the time for which
the offer is valid.

Taler also assumes that the wallet and the merchant can agree on the
current time (similar to what is required to connect to Tor or
validate TLS certificates).  The wallet may rely on the timestamp
provided in the HTTP "Date:" header for this purpose, but the customer
is expected to check that the time is approximately correct.


-----------------------
Architecture's Overview
-----------------------

In our settlement, the "merchant" is divided in two independent
compontents, the `frontend` and the `backend`.

The `frontend` is the (usually pre-existing) shopping portal of the
merchant.  The architecture tries to minimize the amount of
modifications necessary to the `frontend` as well as the trust that
needs to be placed into the `frontend` logic.  Taler requires the
frontend to facilitate three JSON-based interactions between the
wallet and the `backend`, and two of those are trivial.

The `backend` is a standalone C application intended to implement all
the cryptographic routines required to interact with the Taler wallet
and a Taler mint.


+++++++++++++++++++++++++++++
Wallet-Frontend communication
+++++++++++++++++++++++++++++

Taler's virtual wallet is designed to notify the user when a certain webpage
is offering Taler as a payment option. It does so by simply changing the color of
the wallet's button in the user's browser. In the other direction, the website
may want to make the Taler payment option visible `only if` the user has the Taler
wallet active in his browser. So the notification is mutual:

* the website notifies the wallet (`s -> w`), so it can change its color
* the wallet notifies the website (`w -> s`), so it can show Taler as a
  suitable payment option

Furthermore, there are two scenarios according to which the mutual signaling would
succeed.  For a page where the merchant wants to show a Taler-style payment
option and, accordingly, the wallet is supposed to change its color, there are
two scenarios we need to handle:

* the customer has the wallet extension active at the moment of visiting the page, or
* the customer activates the wallet extension
  (regardless of whether he installs it or simply enables it)
  `after` downloading the page.

In the first case, the messaging sequence is `s -> w` and `w -> s`. In the
second case, the first attempt (`s -> w`) will get no reply; however, as soon as the
wallet becomes active, it issues a `w -> s`, and it will get a `s -> w` back.

Beyond signaling to indicate the mutual support for Taler, the wallet
and the frontend also have to communicate for finalizing a purchase.
Here, the checkout page needs to generate a checkout event to signal
to the wallet that payment with Taler is desired. The wallet will then
fetch the contract from the `frontend`, allow the user to confirm and
pay.  The wallet will then transmit the payment information to the
`frontend` and redirect the user to the fullfillment page generated
by the `frontend` in response to a successful payment.

A precise specification and sample code for implementing the signalling
is provided in the dedicated :ref:`section <message-passing-ref>`.


++++++++++++++++++++++++++++++
Frontend-Backend communication
++++++++++++++++++++++++++++++

To create a contract, the `frontend` needs to generate the body of a
`contract` in JSON format.  This `proposition` is then signed by the
`backend` and then sent to the wallet.  If the customer approves
the `proposition`, the wallet signs the body of the `contract`
using coins in the form of a `deposit permission`.  This signature
using the coins signifies both agreement of the customer and
represents payment at the same time.  The `frontend` passes the
`deposit permission` to the `backend` which immediately verifies it
with the mint and signals the `frontend` the success (or failure) of
the payment process.  If the payment is successful, the `frontend` is
responsible for generating the fullfillment page.

The contract format is specified in section `contract`_.


+++++++++
Encodings
+++++++++

Data such as dates, binary blobs, and other useful formats, are encoded as described in :ref:`encodings-ref`.

.. _contract:

Contract
--------

A `contract` is a JSON object having the following structure, which is returned as a
successful response to the following two calls:

.. note::

  This section holds just a central definition for the `contract`, so refer to each component's
  section for its detailed REST interaction.

.. http:get:: /taler/contract
  
  Issued by the wallet when the customer wants to see the contract for a certain purchase

.. http:post:: /contract

  Issued by the frontend to the backend when it wants to augment its `proposition` with all the
  cryptographic information.

  :>json object amount: an :ref:`amount <Amount>` indicating the total price for this deal. Note that, in tha act of paying, the mint will subtract from this amount the total cost of deposit fee due to the choice of coins made by wallets, and finally transfer the remaining amount to the merchant's bank account.
  :>json object max_fee: :ref:`amount <Amount>` indicating the maximum deposit fee accepted by the merchant
  :>json int trans_id: an identification number for this deal
  :>json array details: a collection of `product` objects (described below), for each different item purchased within this deal.
  :>json `date` timestamp: this contract's generation time
  :>json `date` refund: the maximum time until which the merchant can reimburse the wallet in case of a problem, or some request
  :>json base32 merchant_pub: merchant's EdDSA key used to sign this contract; this information is typically added by the `backend`
  :>json base32 H_wire: the hash of the merchant's :ref:`wire details <wireformats>`; this information is typically added by the `backend`
  :>json array mints: a JSON array of `mint` objects, specifying to the wallet which mints the merchant is willing to deal with; this information is typically added by the `backend`

  The `product` object focuses on one buyable good from this merchant. It has the following structure:

  :>json object items: this object contains a human-readable `description` of the good, the `quantity` of goods to deliver to the customer, and the `price` of the single good; the italics denotes the name of this object's fields
  :>json int product_id: some identification number for this good, mainly useful to the merchant but also useful when ambiguities may arise, like in courts
  :>json array taxes: a list of objects indicating a `taxname` and its amount. Again, italics denotes the object field's name.
  :>json string delivery date: human-readable date indicating when this good should be delivered
  :>json string delivery location: where to send this good. This field's value is a label defined inside a a collection of `L-names` provided inside `product`
  :>json object merchant: the set of values describing this `merchant`, defined below
  :>json object L-names: it has a field named `LNAMEx` indicating a human-readable geographical address, for each `LNAMEx` used throughout `product`

  The `merchant` object:

  :>json string address: an LNAME
  :>json string name: the merchant's name, possibly having legal relevance
  :>json object jurisdiction: the minimal set of values that denotes a geographical jurisdiction. That information is strictly dependant on the jusrisdiction's Country, and it can comprehend at most the following fields: `country`, `city`, `state`, `region`, `province`, `ZIP code`. Each field, except `ZIP code` which requires an `int` type, can be represented by the type `string`.





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

   struct Contract
   {
     struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
     struct GNUNET_HashCode h_contract_details;
   }

---------------
Wallet-Frontend
---------------

.. _message-passing-ref:

+++++++++++++++++++
Messagging protocol
+++++++++++++++++++
In order to reach mutual acknowledgement, and to avoid signaling loops,
we define two protocols according to the initiator. The signals are to be
implemented in JavaScript events dispatched on the HTML element `body`.

Thus, when the merchant wants to notify the availability of a Taler-style payment
option (for example on a "checkout" page), it sends the following event:

  .. js:data:: taler-payment-mfirst

.. note::
   this event must be sent from a callback for the `onload` event of the `BODY` element,
   otherwise the extension would have not time to register a listener for this event.
   For example:

.. sourcecode:: html

   <body onload="function(){
     // set up the listener for 'taler-wallet-mfirst'
     // ...
     let eve = new Event('taler-payment-first');
     document.body.dispatchEvent(eve);
     };"> ... </body>

and the wallet will reply with a

  .. js:data:: taler-wallet-mfirst

The other direction, the wallet sends a

  .. js:data:: taler-wallet-wfirst

and the merchant must reply with a

  .. js:data:: taler-payment-wfirst


+++++++++++++++
The RESTful API
+++++++++++++++

The following are the API made available by the merchant's frontend to the wallet:

.. http:get:: /taler/key

   Allows the customer to obtain the merchant's public EdDSA key. Should only be used over a "secure" channel (i.e. at least HTTPS).

   **Success Response**

   :status 200 OK: The request was successful.

   The merchant responds with a JSON object containing the following fields:

   :>json base32 merchant_pub: base32-encoded EdDSA public key of the merchant.

   **Failure response**

   :status 404 Not Found: Taler not supported.

.. http:get:: /taler/contract

  Ask the merchant to send a contract for the current deal

  **Success Response**

  :status 200 OK: The request was successful.
  :resheader Content-Type: application/json
  :>json base32 contract: a :ref:`JSON contract <contract>` for this deal.
  :>json base32 sig: the signature of the binary described in :ref:`blob <contract-blob>`.
  :>json base32 h_contract: the base32 encoding of the field `h_contract_details` of the contract's :ref:`blob <contract-blob>`

  **Failure Response**

  In most cases, the response gotten by the wallet will just be the forwarded response
  that the frontend got from the backend.

  :status 400 Bad Request: Request not understood. Possibly due to some error in formatting the JSON by the frontend.
  :status 500 Internal Server Error: In most cases, some error occurred while the backend was generating the contract. For example, it failed to store it into its database.

It's up to the merchant's implementation to identify which product or service the customer
is interested in.  For example, a common implementation might
use a cookie to identify the customer's shopping cart.  After the customer
has filled the shopping cart and selected "confirm", the merchant might
display a catalog of payment options.  Upon confirming "Taler" as the payment
option, the merchant must send the contract to the Wallet.

So the "button" which allows the user to confirm his payment option has two main
tasks: it request "/taler/contract" to the merchant, and secondly it forwards the
received contract to the wallet.

In terms of JavaScript, that translates to defining a JavaScript function hooked to
that button, that will "POST /taler/contract" and send the result back to the wallet
through an event called `taler-contract`. Upon receiving that event, the wallet
will manage the contract visualization.

It is worth showing a simple code sample.

.. sourcecode:: js

   function checkout(form){
     for(var cnt=0; cnt < form.group1.length; cnt++){
       var choice = form.group1[cnt];
         if(choice.checked){
           if(choice.value == "Taler"){
             var cert = new XMLHttpRequest();
             // request contract
             cert.open("POST", "/taler/contract", true);
             cert.onload = function (e) {
               if (cert.readyState == 4) {
                 if (cert.status == 200){
                 // display contract (i.e. it sends the JSON string to the (XUL) extension)
                   sendContract(cert.responseText);
                 }
               else alert("No contract gotten, status " + cert.status);
             }
           };
           cert.onerror = function (e){
             alert(cert.statusText);
           };
           cert.send(null);
         }
         else alert(choice.value + ": NOT available ");
       }
     }
   };
   function sendContract(jsonContract){
     var cevent = new CustomEvent('taler-contract', { 'detail' : jsonContract });
     document.body.dispatchEvent(cevent);
   };

In this example, the function `checkout` is the one attached to the
'checkout' button (or some merchant-dependent triggering
mechanism). This function issues the required POST and hooks the
function `sendContract` as the handler of the successful case
(i.e. response code is 200).  The hook then simply dispatches on the
page's `body` element the 'taler-contract' event, by passing the
gotten JSON as a further argument, which the wallet is waiting for.

.. note::

   Merchants should remind their customers to enable cookies acceptance while
   browsing on the shop, otherwise it could get difficult to associate purchase's
   metadata to its intended certificate.

.. http:post:: /taler/pay

  Send the deposit permission to the merchant. It is worth noting that the deposit permission
  accounts for only `one` coin.

  :reqheader Content-Type: application/json
  :<json amount f: the :ref:`amount <Amount>` this coin is paying, including this coin's deposit fee
  :<json base32 H_wire: the hashed `wire details <wireformats>` of this merchant. The wallet takes this value as-is from the contract
  :<json base32 H_contract: the base32 encoding of the field `h_contract_details` of `contract`_. The wallet can choose whether to take this value from the gotten contract (field `h_contract`), or regenerating one starting from the values it gets within the contract
  :<json base32 coin_pub: the coin's public key
  :<json base32 denom_pub: the denomination's (RSA public) key
  :<json base32 ub_sig: the mint's signature over this coin's public key
  :<json date timestamp: a timestamp of this deposit permission. It equals just the contract's timestamp
  :<json date refund_deadline: same value held in the contract's `refund` field
  :<json base32 coin_sig: the signature made by the coin's private key on a `struct TALER_DepositRequestPS`. See the :ref:`dedicated section <Signatures>` on the mint's specifications.
  :<json string mint: the chosen mint's base URL

  **Success Response:**

  :status 200 OK: the payment has been received.
  :resheader Content-Type: text/html

  In this case the merchant sends back a `fullfillment` page in HTML, which the wallet will make the new `BODY` of the merchant's current page. It is just a confirmation of the positive deal's conclusion

  **Failure Responses:**

  The error codes and data sent to the wallet are a mere copy of those gotten from the mint when attempting to pay. The section about :ref:`deposit <deposit>` explains them in detail.

----------------
Frontend-Backend
----------------

+++++++++++++++
The RESTful API
+++++++++++++++

The following API are made available by the merchant's backend to the merchant's frontend.

.. http:get:: /key

   Issued by the frontend to satisfy the request of the merchant's key coming from the wallet

   **Success Response**

   :status 200 OK: The request was successful.

   The merchant responds with a JSON object containing the following fields:

   :>json base32 merchant_pub: base32-encoded EdDSA public key of the merchant.

   **Failure response**

   :status 404 Not Found: Taler not supported.

.. http:post:: /contract

  Ask the backend to add some missing (mostly related to cryptography) information to the contract.

  :reqheader Content-Type: application/json

  The JSON that is to be sent from the frontend is just a `contract` object which misses the fields

  * `merchant_pub`
  * `timestamp`
  * `refund`
  * `mints`

  **Success Response**

  :status 200 OK: The backend has successfully created the contract

  :resheader Content-Type: application/json

  The backend will reply the same JSON as the one sent back to the wallet by the frontend as response to the "/taler/contract" call.

  **Failure Responses: Bad contract**

  :status 400 Bad Request: Request not understood. The JSON was invalid.

.. http:post:: /pay

  Ask the backend to start the communication with the mint to spend this coin

  :reqheader Content-Type: application/json

  The frontend will just forward the deposit permission it got from the wallet, without making any modification

  **Success Response: OK**

  :status 200 OK: the mint accepted this coin

  **Failure Responses:**

  Again, the backend will route to the frontend any status code, as well as any JSON, that it got from the mint.
