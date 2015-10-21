================
The Merchant API
================

The Merchant API serves as a protocol interface for the
interactions between a customer and an HTTP-based RESTful merchant.
The protocol allows the customer and the merchant to agree upon a
contract and for the customer to spend coins according to the contract
proposed by the merchant.

It is assumed that the customer has a secure (and possibly
customer-anonymizing) channel to the merchant.  Futhermore, it is
assumed that the merchant's server does not repudiate on contractual
offers it has made.  If necessary, the merchant should be able to
assure this by limiting the time for which the offer is valid.

-----------------------
Architecture's Overview
-----------------------

In our settlement, the "merchant" is divided in two independent applications
having different objectives. We consider a `frontend` and a `backend`. Please
note, that for any existing merchant, which is presumed to have its
own web portal (which represents the `frontent`, in our terminology), this
architecture will only require for him to comply with not more than three JSON based
communications with the `backend`.
This design choice was dictated by the need of allowing cooperation between a
dynamic frontend, more suited for serving interactive web content, and a standalone
C application intended to implement all the cryptographic routines.
That way, a merchant willing to integrate Taler-style payments in his business,
can completely reuse his website in cooperation with the backend provided by Taler.

+++++++++++++++++++++++++++++
Wallet-Frontend communication
+++++++++++++++++++++++++++++

The Taler's virtual wallet is designed to notify the user when a certain webpage
is offering Taler as a payment option. It does so by simply changing the color of
the wallet's button in the user's browser. In the other direction, the website
may want to make the Taler payment option visible `only if` the user has the Taler
wallet active in his browser. So the notification is mutual:

* the website notifies the wallet (`s -> w`), so it can change its color
* the wallet notifies the website (`w -> s`), so it can show Taler as a
  suitable payment mean

Furthermore, there are two scenarios according to which the mutual signaling would
succeed; let `p` be the page where the merchant wants to show a Taler-style payment
option and, accordingly, the wallet is supposed to change its color:

* the user has the wallet active at the moment of visiting `p`.
* the user activates its wallet (regardless of whether he installs it or simply
  enables it) `after` it downloads page `p`.

In the first case, the messagging sequence is `s -> w` and `w -> s`. In the
second case, the first attempt (`s -> w`) will get no reply but as soon as the
wallet becomes active, it issues a `w -> s`, and it will get a `s -> w` back.

Besides this messagging issue, the wallet and the frontend have to communicate
also for finalizing a purchase. According to Taler design and terminology, that
communication must ensure the generation of a `contract` by the merchant, whenever
the user wants to buy a good, and the generation of a `deposit permission` by the
wallet in case the user validates the contract and wants to proceed with the actual
payment.

++++++++++++++++++++++++++++++
Frontend-Backend communication
++++++++++++++++++++++++++++++
This cooperation is mainly intended to help the frontend to obtain contracts and deposit permissions.
In particular, it wants to put the cryptographic facility and the bit-level memory management aside
from scripted languages like, for example, PHP. Thus the typical work-cycle of a frontend is to
  
  1. Gather information from the user.
  2. Format this information in JSON accordingly with the operation being served.
  3. Send this JSON to the backend.
  4. Forward the response to the user.

.. note::

  the fact that wallets never reach the backends directly allows the
  merchants to place their backends in areas with security configurations
  particularly addressed to them. Again, the merchant can demand the backend
  management to some other body of his trust.

+++++++++
Encodings
+++++++++

The used encodings are the same described in :ref:`encodings-ref`.

Contract
--------
The following structure is a container for the hashcode coming from the encoding of
the contract's JSON obtained by using the flags JSON_COMPACT | JSON_PRESERVE_ORDER,
as described in
the `libjansson documentation <https://jansson.readthedocs.org/en/2.7/apiref.html?highlight=json_dumps#c.json_dumps>`_.
The signature's purpose is set to TALER_SIGNATURE_MERCHANT_CONTRACT.

.. sourcecode:: c
 
   struct Contract
   {
     struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
     struct GNUNET_HashCode h_contract_details;
   }

---------------
Wallet-Frontend
---------------

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
  :>json base32 contract: a JSON object being the contract for this deal, descibed below.
  :>json base32 sig: the signature of the binary described in :ref:`contract`.
  :>json base32 h_contract: the base32 encoding of the field `h_contract_details` of `contract`_

  A `contract` is a JSON object having the following structure:

  :>json object amount: an `Amount` indicating the total price for this deal. Note that, in tha act of paying, the mint will subtract from this amount the total cost of deposit fee due to the choice of coins made by wallets, and finally transfer the remaining amount to the merchant's bank account.
  :>json object max fee: `Amount` indicating the maximum deposit fee accepted by the merchant
  :>json int trans_id: an identification number for this deal
  :>json array details: a collection of `product` objects (described below), for each different item purchased within this deal.
  :>json base32 H_wire: the hash of the merchant's wire details, see :ref:`wireformats`
  :>json base32 merchant_pub: merchant's EdDSA key used to sign this contract
  :>json `date` timestamp: this contract's generation time
  :>json `date` refund: the maximum time until which the merchant can reimburse the wallet in case of a problem, or some request
  :>json array mints: a JSON array of `mint` objects, specifying to the wallet which mints the merchant is willing to deal with

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

  Send the deposit permission to the merchant.

  :reqheader Content-Type: application/json
  :<json base32 dep_perm: the signed deposit permission (link to the blob above)
  :<json base32 eddsa_pub: the public key of the customer.


  **Success Response: OK**
  :status 200 OK: the payment has been received.

  **Failure Response: TBD**

  **Error Response: Invalid signature**

  :status 401 Unauthorized: One of the signatures is invalid.
  :resheader Content-Type: application/json
  :>json string error: the value is "invalid signature"
  :>json string paramter: the value is "coin_sig", "ub_sig" (TODO define this) or "wallet_sig", depending on which signature was deemed invalid by the mint


----------------
Frontend-Backend
----------------

+++++++++++++++
The RESTful API
+++++++++++++++

The following API are made available by the merchant's backend to the merchant's frontend.


.. http:post:: /contract
   
  Ask the backend to generate a contract on the basis of the given JSON.

  :reqheader Content-Type: application/json
  :<json string desc: a human readable description of this deal.
  :<json unsigned\ 32 product: the identification number of this product, dependent on the frontend implementation.
  :<json unsigned\ 32 cid: the identification number of this contract, dependent on the frontend implementation.
  :<json object price: the amount (crosslink to amount's definition on mint's page) representing the price of this item.
 
  **Success Response**

  :status 200 OK: The backend has successfully created the contract
  :resheader Content-Type: application/json
  :<json base32 contract: the encoding of the blob (which blob? link above.) representing the contract.
  :<json base32 sig: signature of this contract with purpose TALER_SIGNATURE_MERCHANT_CONTRACT. 
  :<json base32 eddsa_pub: EdDSA key of the merchant.

  **Failure Response**

  :status 400 Bad Request: Request not understood. The JSON was invalid.
  :status 500 Internal Server Error: In most cases, some error occurred while the backend was generating the contract. For example, it failed to store it into its database.

.. http:post:: /pay

  :reqheader Content-Type: application/json
  :<json base32 dep_perm: the signed deposit permission (link to the blob above)
  :<json base32 eddsa_pub: the public key of the customer.

  **Failure Response: TBD**

  **Error Response: Invalid signature**:

  :status 401 Unauthorized: One of the signatures is invalid.
  :resheader Content-Type: application/json
  :>json string error: the value is "invalid signature"
  :>json string paramter: the value is "coin_sig", "ub_sig" (TODO define this) or "wallet_sig", depending on which signature was deemed invalid by the mint
