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

The used encoding are the same described in :ref:`encodings-ref`, with the addition
of the `contract`'s and `deposit permission`'s blobs

  .. _contract:

  * **contract**:
The following structure is mainly addressed to the wallet, that is
in charge of verifying and dissecting it. It is not of any interest
to the frontend developer, except that forwarding the JSON that encloses
it. However, refer to the `gnunet <https://gnunet.org>`_'s documentation
for those fields prepended with `GNUNET_`.

.. sourcecode:: c
 
 struct Contract
 {
   struct GNUNET_CRYPTO_EddsaSignature sig; // signature of the contract itself: from 'purpose' field down below.
   struct GNUNET_CRYPTO_EccSignaturePurpose purpose; // contract's purpose, indicating TALER_SIGNATURE_MERCHANT_CONTRACT.
   char m[13]; // contract's id.
   struct GNUNET_TIME_AbsoluteNBO t; // the contract's generation time.
   struct TALER_AmountNBO amount; // the good's price.
   struct GNUNET_HashCode h_wire; // merchant's bank account details hashed with a nounce.
   char a[]; // a human-readable description of this deal, or product.
 }

 .. _deposit\ permission:

.. sourcecode:: c

 struct DepositPermission
 {
  struct TALER_CoinPublicInfo; // Crafted by the wallet, contains all the information needed by the mint to validate the deposit. Again, not directly in the interest of the frontend.
 char m[13]; // contract's id.
 struct TALER_Amount amount; // the good's price.
 GNUNET_HashCode a; // hash code of Contract.a.
 struct GNUNET_HashCode h_wire; // merchant's bank account details hashed with a nounce.
 GNUNET_CRYPTO_EddsaPublicKey merch_pub; // merchant's public key. 
 }

---------------
Wallet-Frontend
---------------

+++++++++++++++++++
Messagging protocol
+++++++++++++++++++
Due to that dual mean of reaching acknowledgement, and to avoid signaling loops,
we define two protocols according to the initiator. The signals are to be
implemented in JavaScript events dispatched on the HTML element `body`.

Thus, when the merchant wants to notify the availability of a Taler-style payment
option (for example on a "checkout" page), it sends the following event:

  .. js:data:: taler-payment-mfirst

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

.. http:GET:: /taler/key

   Allows the customer to obtain the merchant's public EdDSA key. Should only be used over a "secure" channel (i.e. at least HTTPS).

   **Success Response**

   :status 200 OK: The request was successful.

   The merchant responds with a JSON object containing the following fields:

   :>json base32 merchant_pub: base32-encoded EdDSA public key of the merchant.

   **Failure response**

   :status 404 Not Found: Taler not supported.

.. http:GET:: /taler/contract

   Ask the merchant to prepare a contract.  It takes no parameter and is up to
   the merchant's implementation to identify which product or service the customer
   is interested in.  For example, a common implementation might
   use a cookie to identify the customer's shopping cart.  After the customer
   has filled the shopping cart and selected "confirm", the merchant might
   display a catalog of payment options.  Upon selecting "Taler", the system
   would trigger the interaction with the Wallet by loading "/taler/contract",
   providing the necessary contract details to the Wallet as a JSON object.

   **Success Response**

   :status 200 OK: The request was successful.

   The merchant responds with a JSON object containing the following fields:

   :>json base32 contract: the encoding of the contract_'s blob.
   :>json base32 sig: the contract as signed by the merchant.
   :>json base32 eddsa_pub: merchant's public EdDSA key.
   
.. note::

The contract is sent as a unique blob since it costs one operation to encrypt it,
and one to decrypt and verify respectively. As of now, the encryption is not part
of the protocol.

   **Failure Response**

.. note::

In most cases, the response gotten by the wallet will be the forwarded response that the
frontend got from the backend.

   :status 400 Bad Request: Request not understood. Possibly due to some error in formatting
   the JSON by the frontend.
   :status 500 Internal Server Error. In most cases, some error occurred while the backend was
   generating the contract. For example, it failed to store it into its database.

.. http:post:: /taler/pay

   Send the deposit permission to the merchant.

   :reqheader Content-Type: application/json
   :<json base32 dep_perm: the signed deposit permission (link to the blob above)
   :<json base32 eddsa_pub: the public key of the customer.


  **Success Response: OK**
  :status 200 OK: the payment has been received.

  **Failure Response: TBD **

 **Error Response: Invalid signature**:

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
   
   Ask the backend to generate a certificate on the basis of the given JSON.

   :reqheader Content-Type: application/json

   :<json string desc: a human readable description of this deal.
   :<json unsigned\ 32 product: the identification number of this product, dependent on the
   frontend implementation.
   :<json unsigned\ 32 cid: the identification number of this contract, dependent on the
   frontend implementation.
   :<json object price: the amount (crosslink to amount's definition on mint's page) representing the price of this item.
 
  **Success Response: OK**:

  :status 200 OK: The backend has successfully created the certificate
  :resheader Content-Type: application/json
  :<json base32 contract: the encoding of the blob (which blob? link above.) representing the contract.
  :<json base32 sig: signature of this contract with purpose TALER_SIGNATURE_MERCHANT_CONTRACT. 
  :<json base32 eddsa_pub: EdDSA key of the merchant.

   **Failure Response**

  :status 400 Bad Request: Request not understood.
     the JSON by the frontend.
     :status 500 Internal Server Error. In most cases, some error occurred while the backend was
     generating the contract. For example, it failed to store it into its database.

.. http:post:: /pay

   :reqheader Content-Type: application/json
   :<json base32 dep_perm: the signed deposit permission (link to the blob above)
   :<json base32 eddsa_pub: the public key of the customer.
