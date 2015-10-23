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
frontend to facilitate two JSON-based interactions between the
wallet and the `backend`, and one of those is trivial.

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

  :>json object amount: an :ref:`amount <Amount>` indicating the total price for the transaction. Note that, in the act of paying, the mint will subtract from this amount the deposit fees due to the choice of coins made by wallets, and finally transfer the remaining amount to the merchant's bank account.
  :>json object max_fee: :ref:`amount <Amount>` indicating the maximum deposit fee accepted by the merchant for this transaction.
  :>json int trans_id: a 53-bit number chosen by the merchant to uniquely identify the contract.
  :>json array products: a collection of `product` objects (described below), for each different item purchased within this transaction.
  :>json `date` timestamp: this contract's generation time
  :>json `date` refund: the maximum time until which the merchant can refund the wallet in case of a problem, or some request
  :>json base32 merchant_pub: merchant's EdDSA key used to sign this contract; this information is typically added by the `backend`
  :>json object merchant: the set of values describing this `merchant`, defined below
  :>json base32 H_wire: the hash of the merchant's :ref:`wire details <wireformats>`; this information is typically added by the `backend`
  :>json array mints: a JSON array of `mint` objects, specifying to the wallet which mints the merchant is willing to deal with; this information is typically added by the `backend`
  :>json object locations: maps labels for locations to detailed geographical location data (details for the format of locations are specified below). The label strings must not contain a colon (`:`).  These locations can then be references by their respective labels throughout the contract.

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

  :>json string county: blah
  :>json string city: blah
  :>json string state: blah
  :>json string region: blah
  :>json string province: blah
  :>json int zip_code: blah
  :>json string street: blah
  :>json string street_number: blah

  Additional fields may be present depending on the country.

  The `mint` object:

  :>json string address: label for a location with the business address of the mint
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
we define two interactions.  One is initiated by the HTML page inquiring
about the Taler wallet extension being available, the other by the wallet
extension inquiring about page supporting Taler as a payment option.

The HTML page implements all interactions using JavaScript signals
dispatched on the HTML element `body`.

When the merchant wants to notify the availability of a Taler-style payment
option (for example on a "checkout" page), it sends the following event:

  .. js:data:: taler-checkout-probe

This event must be sent from a callback for the `onload` event of the
`body` element, otherwise the extension would have not time to
register a listener for this event.  It also needs to be sent when
the Taler extension is dynamically loaded (if the user activates
the extension while he is on the checkout page).  This is done by
listening for the

  .. js:data:: taler-load

event.  If the Taler extension is present, it will respond with a

  .. js:data:: taler-wallet-present

event.  The handler should then activate the Taler payment option,
for example by updating the DOM to enable the respective button.

The following events are needed when one of the two parties leaves the
scenario.

First, if the Taler extension is unloaded while the user is
visiting a checkout page, the page should listen for the

  .. js:data:: taler-unload

event to hide the Taler payment option.

Secondly, when the Taler extension is active and the user closes (or navigates
away from) the checkout page, the page should listen to a 

  .. js:data:: taler-navigating-away

event, and reply with a

  .. js:data:: taler-checkout-away

event, in order to notify the extension that the user is leaving a checkout
page, so that the extension can change its color back to its default.

The following source code highlights the key steps for adding
the Taler signaling to a checkout page:

.. sourcecode:: javascript

    function has_taler_wallet_callback(aEvent){
       // This function is called if a Taler wallet is available.
       // suppose the radio button for the Taler option has
       // the DOM ID attribute 'taler-radio-button-id'
      var tbutton = document.getElementById("taler-radio-button-id");
      tbutton.removeAttribute("disabled");
    };

    function taler_wallet_load_callback(aEvent){
      // let the Taler wallet know that this is a Checkout page
      // which supports Taler (the extension will have
      // missed our initial 'taler-checkout-probe' from onload())
      document.body.dispatchEvent(new Event('taler-checkout-probe'));
    };

    function taler_wallet_unload_callback(aEvent){
       // suppose the radio button for the Taler option has
       // the DOM ID attribute 'taler-radio-button-id'
       var tbutton = document.getElementById("taler-radio-button-id");
       tbutton.setAttribute("disabled", "true");
    };


.. sourcecode:: html

   <body onload="function(){
        // First, we set up the listener to be called if a wallet is present.
        document.body.addEventListener("taler-wallet-present", has_taler_wallet_callback, false);
        // Detect if a wallet is dynamically added (rarely needed)
        document.body.addEventListener("taler-load", taler_wallet_load_callback, false);
        // Detect if a wallet is dynamically removed (rarely needed)
        document.body.addEventListener("taler-unload", taler_wallet_unload_callback, false);
        // Finally, signal the wallet that this is a payment page.
        document.body.dispatchEvent(new Event('taler-checkout-probe'));
      };">
     ...
   </body>


When the user chooses to pay, the page needs to inform the extension
that it should execute the payment process.  This is done by sending
a

  .. js:data:: taler-contract

event to the extension.  The following example code fetches the
contract from the merchant website and passes it to the extension
when the button is clicked:

.. sourcecode:: javascript

   function deliver_contract_to_wallet(jsonContract){
   var cevent = new CustomEvent('taler-contract', { detail: jsonContract, target: '/taler/pay' });
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
  :>json base32 contract: a :ref:`JSON contract <contract>` for this deal.
  :>json base32 sig: the signature of the binary described in :ref:`blob <contract-blob>`.
  :>json base32 h_contract: the base32 encoding of the field `h_contract_details` of the contract's :ref:`blob <contract-blob>`

  **Failure Response**

  In most cases, the response will just be the forwarded response that the `frontend` got from the `backend`.

  :status 400 Bad Request: Request not understood.
  :status 500 Internal Server Error: In most cases, some error occurred while the backend was generating the contract. For example, it failed to store it into its database.


.. http:post:: /taler/pay

  Send the deposit permission to the merchant. Note that the URL may differ between
  merchants.

  :reqheader Content-Type: application/json
  :<json base32 H_wire: the hashed `wire details <wireformats>` of this merchant. The wallet takes this value as-is from the contract
  :<json base32 H_contract: the base32 encoding of the field `h_contract_details` of `contract`_. The wallet can choose whether to take this value from the gotten contract (field `h_contract`), or regenerating one starting from the values it gets within the contract
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

  :status 200 OK: the payment has been received.
  :resheader Content-Type: text/html

  In this case the merchant sends back a `fullfillment` page in HTML, which the wallet will make the new `body` of the merchant's current page. It is just a confirmation of the positive transaction's conclusion.

  **Failure Responses:**

  The error codes and data sent to the wallet are a mere copy of those gotten from the mint when attempting to pay. The section about :ref:`deposit <deposit>` explains them in detail.

----------------
Frontend-Backend
----------------

+++++++++++++++
The RESTful API
+++++++++++++++

The following API are made available by the merchant's `backend` to the merchant's `frontend`.

.. http:post:: /contract

  Ask the backend to add some missing (mostly related to cryptography) information to the contract.

  :reqheader Content-Type: application/json

  The JSON that is to be sent from the frontend is just a `contract` object which misses the fields

  * `merchant_pub`
  * `mints`

  The `backend` then completes this information based on its configuration.

  **Success Response**

  :status 200 OK: The backend has successfully created the contract.
  :resheader Content-Type: application/json

  The `frontend` should pass this response verbatim to the wallet.

  **Failure Responses: Bad contract**

  :status 400 Bad Request: Request not understood. The JSON was invalid. Possibly due to some error in formatting the JSON by the `frontend`.

.. http:post:: /pay

  Asks the `backend` to execute the transaction with the mint and deposit the coins.

  :reqheader Content-Type: application/json

  The `frontend` should just pass the deposit permission information it received from the wallet verbatim.

  **Success Response: OK**

  :status 200 OK: The mint accepted all of the coins. The `frontend` should now fullfill the contract.  This response has no meaningful body, the frontend needs to generate the fullfillment page.

  **Failure Responses:**

  The `backend` will return error codes received from the mint verbatim (see `/deposit` documentation for the mint API for possible errors).  If the wallet made a mistake (for example, by double-spending), the `frontend` should pass the reply verbatim to the browser/wallet. (This is pretty much always the case, as the `frontend` cannot really make mistakes; the only reasonable exception is if the `backend` is unavailable, in which case the customer might appreciate some reassurance that the merchant is working on getting his systems back online.)
