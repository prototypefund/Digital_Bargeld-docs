=====================
The Merchant JSON API
=====================

The Merchant JSON API serves as a protocol interface for the
interactions between a customer and an HTTP-based RESTful merchant.
The protocol allows the customer and the merchant to agree upon a
contract and for the customer to spend coins according to the contract
proposed by the merchant.

It is assumed that the customer has a secure (and possibly
customer-anonymizing) channel to the merchant, and in particular that
the customer knows the merchant's public key.  Futhermore, it is
assumed that the merchant's server does not repudiate on contractual
offers it has made.  If necessary, the merchant should be able to
assure this by limiting the time for which the offer is valid.

--------
Overview
--------

The Merchant HTTP protocol allows for several different types of
interactions with the Wallet (HTTP client), described in more detail
in the following sections.


+++++++++++++++
Direct Deposits
+++++++++++++++

For a direct deposit, an interested customer obtains a *contract* from
the merchant specifying an amount that needs to be paid for the
merchant's services or products.  Details about the services or
products and the merchant's payment details are provided in the
contract, together with other terms such as how long the offer is
valid.

After receiving the contract, the customer can either accept or reject
with the contract.  If the customer rejects the contract, the customer
simply aborts the protocol.  If the customer chooses to accept the
deal, he sends the merchant a ``deposit permission``, which is the
digital payment of the sum mentioned in the contract, tied to the
contract details. Thus, by sending the deposit permission, the
customer both formally accepts the contract and pays at the same time.
This way, the customer has proof tying the payment to the particular
contract, and thus the wallet stores the contract offer (signed by the
merchant) and the deposit permissions as proof for later disputes.

The merchant then submits this deposit permission to the mint to
verify its validity and claim the amount.  The mint may return an
error message proving that the payment is fraudulent, in which case
the merchant aborts the transaction (but may be polite in forwarding
the proof to the customer).  If the mint confirms (with its signature)
that the payment was correct, the merchant files the mint's response
(to have proof in case the mint operator tries to defraud) and
delivers the promised services or products to the customer.  The
merchant also returns a signed message to the customer indicating that
the payment was successful.

++++++++++++++++++++
Incremental Deposits
++++++++++++++++++++

  .. note::

     Incremental deposits are currently not implemented.

Incremental deposits allow the merchant to charge the customer
incrementally without interacting with the mint each time.  This is
useful for metered services, such as cab fares.  The idea here is that
the merchant first gets an exclusive lock on a certain amount of the
customer's coins.  With this lock in place, the merchant can accept
deposit permissions from the customer without checking with the mint
for each payment.  The merchant merely has to "claim" the total coins
he receives before the lock expires.

For incremental deposits, the customer asks merchant to make an
``offer`` for the subscription by specifying the maximum amount the
merchant may charge during the interaction and a desired locking
period.  The customer conveys his acceptance of the offer by sending a
``lock permission`` to the merchant.  The merchant asks the mint to
verify the lock permission, and if verified successfully, the customer
then obtains a subscription from the merchant.  With this in place,
the customer and merchant can interact with the usual deposit
permissions without involving the mint each time.

++++++++++++++
Microdonations
++++++++++++++

  .. note::

     Microdonations are currently not implemented.

+++++++
Refunds
+++++++

  .. note::

     Refunds are currently not implemented.

In some markets, it is common for merchants to provide a retraction
period where the customer can evaluate the products and return them
for a refund.  To facilitate such interactions, Taler allows merchants
to provide a retraction period in the contract.  During the retraction
period a customer can retract a previously made contract with the
merchant and obtain a ``retract permission`` from the merchant.  The
customer, before the end of the retraction period, can submit the
retract permission to the mint to obtain a refund.

---------------
The RESTful API
---------------

The following are the API made available by the merchant:

.. http:GET:: /taler/key

   Allows the customer to obtain the merchant's public EdDSA key. Should only be used over a "secure" channel (i.e. at least HTTPS).

   **Success Response**

   :status 200 OK: The request was successful.

   The merchant responds with a JSON object containing the following fields:

   :>json base32 merchant_pub: base32-encoded EdDSA public key of the merchant.

   **Failure response**

   :status 404 Not Found: Taler not supported.


.. http:GET:: /taler/contract
.. http:POST:: /taler/contract

   Ask the merchant to prepare a contract.  The request parameters are specific
   to the merchant's implementation, however, they are recommended to contain
   information required for the merchant to identify which product or service
   the customer is interested in.  For example, a common implementation might
   use a cookie to identify the customer's shopping cart.  After the customer
   has filled the shopping cart and selected "confirm", the merchant might
   display a catalog of payment options.  Upon selecting "Taler", the system
   would trigger the interaction with the Wallet by loading "/taler/contract",
   providing the necessary contract details to the Wallet as a JSON object.

   **Success Response**

   :status 200 OK: The request was successful.

   The merchant responds with a JSON object containing the following fields:

   :>json integer transaction_id: A string representing the transaction identifier.
   :>json timestamp expiry: The timestamp after which this contract expires.
   :>json string legal_system: String describing the legal system under which the contract is made.
   :>json string tos_url: Link to the terms of service of the merchant in UTF-8 text.
   :>json base32 H_tos: Hash of the terms of service as provided at `tos_url`.
   :>json object total_amount: Price of the offer.
   :>json object retract_fee: Fee the merchant will retain if the customer retracts from the contract (optional, assumed to be zero if absent).
   :>json object TAX_amount: Amount of taxes of type "TAX" included in the offer.  "TAX" is specified by the tax regime, i.e. "vat" or "sales".  If multiple types of taxes are applicable, multiple fields may be present.  If no taxes are applicable, the fields may be omitted.
   :>json array mints: List of master (EdDSA) public keys of mints accepted by the merchant for payment.
   :>json array auditors: List of auditor (EdDSA) public keys accepted by the merchant as acceptable to accredit *additional* mints.
   :>json timestamp retraction_period: Until when the customer can retract from this contract, and thus get a refund on the coins spent.  Note that until the retraction period is over, the mint may withhold the contract's money from being transferred to the merchant.
   :>json array terms: An array with the deliverables from the contract.
   :>json base32 H_wire: The hash of a JSON object containing the merchant's payment information.  See :ref:`wireformats`.
   :>json base32 m_pub: Public EdDSA key of the merchant.
   :>json base32 H_contract: Hash over all preceeding fields (FIXME: need to specify details).
   :>json base32 m_sig: Signature of the merchant over `H_contract`.

   The `terms` must contain at least the following fields:
   :>jsonarr string description-LANG: Human-readable description of the item in language LANG.  Must be present in at least one language.
   :>jsonarr integer quantity: Number of items to be delivered (can be omitted if quantity is one).
   :>jsonarr object total_amount: Total price for these items (optional if contract does not allow disclosure of prices for individual items).
   :>jsonarr object TAX_amount: Amount of tax of type "TAX" included in `total_amount` (optional, multiple possible).
   :>jsonarr string link: Link to further information about the item.  Optional and not formally part of the contract, but might be used by the customer to find the product's purchasing address again easily in the future.

   Additional fields may be provided, but are never officially part of the contract and may be ignored by the Wallet.

   **Failure response**

   :status 400 Bad Request: Request not understood.
   :status 404 Not Found: No products or services given in the request were found.

   It is also possible to receive other error status codes depending on the merchant's implementation.

.. http:POST:: /taler/pay

   Agree with a previously obtained contract and pay the merchant by signing the contract with coins.

   :<json base32 H_contract: The hash of the contract.
   :<json integer transaction_id: The transaction identifier obtained from the contract.
   :<json array coins: Array of coins used for the payment.

   The `coins` are a JSON array where each object contains the following fields:

   :<jsonarr base32 coin_pub: The coin's public key.
   :<jsonarr base32 mint_pub: The public key of the mint from where the coin is obtained.
   :<jsonarr base32 denom_pub: Denomination key with which the coin is signed.
   :<jsonarr base32 ub_sig: Mint's unblinded signature of the coin
   :<jsonarr string type: the string constant `"DIRECT_DEPOSIT"` or `"INCREMENTAL_DEPOSIT"` respectively for direct deposit or incremental deposit type of interaction.
   :<jsonarr object amount: The amount to be deposited as a Denomination object.  Its value should be less than or equal to the coin's face value.  Additionally, for direct deposit type of interactions, the total amount of all coins must be equal to the amount stated in the contract.
   :<jsonarr base32 coin_sig: The signature with the coin's private key over the parameters `type`, `transaction_id`, `amount`, `H_contract` and, `H_wire`.

   **Success Response**

   :status 200 OK: The deposit permission is successful.
   :status 302 Found: The deposit permission is successful, the interaction continues elsewhere.

   :resheader X-Taler-Merchant-Confirmation: Base32-encoded EdDSA Signature of the merchant confirming the successful deposit operation.

   Other details depend on the merchant's Web portal organization, the browser will simply render the data returned for the user as usual.

   **Failure Response**

   :status 400 Bad Request: Request not understood.
   :status 403 Forbidden: The request does not match the contract that was provided.  The request should not be repeated.
   :status 499 TBD: The deposit operation has failed because the coin has previously been deposited or it has been already refreshed; the request should not be repeated again.  The response body contains the failure response objects from the :ref:`Mint API:deposit<deposit>`.
   :status 404 Not Found: The merchant does not entertain this type of interaction.  Try another one.


.. _retract:
.. http:POST:: /taler/retract

   Retract a previously made contract with the merchant.  This API may not be supported by merchants that do not offer refunds.  The request should contain a JSON object with the following fields:

   :<json integer transaction_id: The transaction identifier of the contract to retract.
   :<json base32 merchant_pub: The public key of the merchant.
   :<json array coin_sigs: Signature over the fields `transaction_id` and `merchant_pub` with the private key of the coins used to previously sign the contract.

   The merchant may require additional information to be provided for the retraction, as per its terms of service.

   **Success Response**

   :status 200 OK: The contract has been successfully retracted.

   The response contains a JSON object with the following fields:

   :>json base32 merchant_sig: The EdDSA signature of the merchant over its public key and the transaction ID. (FIXME: Specify exact purpose.)

   The customer then has to send this object as part of the refresh request to claim the refund (See: :ref:`Mint API:refresh<refresh>`)

   **Failure Response**

   :status 400 Bad Request: Request not understood or incomplete
   :status 403 Forbidden: The contract's retraction period has expired
   :status 404 Not Found: Invalid / unknown contract
