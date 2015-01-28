The Merchant JSON API
=====================

The Merchant API serves as a protocol interface for the interactions between a
customer and a merchant.  The protocol allows the customer and the merchant to
agree upon a contract and for the customer to spend coins according to the
contract at the merchant.  It should be noted that the interactions are strictly
one way: The customer *always* initiates the requests by contacting the
merchant.  It is also assumed that the customer knows the merchant's public
key.  Futhermore, it is assumed that the merchant's server is cooperating *i.e*
does not repudiate on received requests.

The protocol allows for three different type of interactions.  In the first type
of interaction, which we refer to as *direct deposit*, an interested customer
asks the merchant to provide a ``contract`` for the merchant's services or
products.  Details about the services or products and the merchant's payment
information are provided in the contract.  The customer can either agree or
disagree with the contract.  If there is a disagreement between the merchant and
the customer, the customer can choose to abort the protocol by not participating
int the furthur steps.  If the customer chooses to agree, the aggrement is sent
to the merchant as a ``deposit permission`` which effectively is also a
confirmation made by the customer to pay the merchant the sum mentioned in the
contract.  The merchant then submits this deposit permission at the mint to
verify its validity.  Upon successful verification, the merchant delivers the
promised services or products.

The second type of interaction, *incremental deposit*, allows the merchant to
charge the customer incrementally.  This is useful for subscription based
e-commerce systems.  Examples for such systems are app stores and news websites.
The idea here is that the merchant will be assured that he will receive a
certain amount of money from the transaction, and then he can charge small
amounts over the assured amount without contacting the mint.  In these
interactions, the customer asks merchant to make an ``offer`` for the
subscription by specifying the maximum amount the merchant may charge during the
interaction.  The customer conveys his acceptance of the offer by sending a
``lock permission`` to the merchant.  The merchant asks the mint to verify the
lock permission and if verified successfully, the customer then obtains a
contract from the merchant and the first type interaction follows.  The customer
can then obtain further contracts until the maximum amount made in the offer is
reached.

The thrid type of interactions allows probablistic spending.  `To be done.`

Contract retraction/returns/refunds: It is common for merchants to provide a
retraction period where the customer can evaluate the products and return them
for a refund.  To facilitate such interactions, our protocol allows merchants to
provide a retraction period in the contract.  During the retraction period a
customer can retract a previously made contract with the merchant and obtain a
``retract permission`` from the merchant.  The customer, before the end of the
retraction period, can submit the retract permission to the mint to obtain a
refund.

The following are the API made available by the merchant:

.. http:GET:: /offer
.. http:POST:: /offer

   Ask the merchant to prepare a contract.  The request parameters are specific
   to the merchant's implementation, however, they are recommended to contain
   information required for the merchant to identify which product or service
   the customer is interested int.

   **Success Response**

   :status 200 OK: The request was successful.

   The merchant responds with a JSON object containing the following fields:

   :>json string transaction_id: A string representing the transaction identifier.
   :>json integer expiry: The timestamp after which this contract expires.
   :>json object amount: Price of the contract as a Denomination object.
   :>json integer retraction_period: The period of time expressed in seconds
     during which the customer can retract this contract and thus can claim the
     coins spent for this contract by refreshing them at the mint.  The
     retraction period starts from the moment the customer has signed the
     contract.  During the retraction period, the mint withholds the contract's
     money from being transferred to the merchant.
   :>json string description: The contract description as string.
   :>json string H_wire: The hash of a JSON object containing the merchant's payment
     information.  See :ref:`wireformats`.
   :>json string msig: Signature of the merchant over the fields `transaction_id`,
     `expiry`, `amount`, `retraction_period`, `description`, `H_wire`.

   **Failure response**

   :status 400: Request not understood.
   :status 404: No products or services given in the request were found.

   It is also possible to receive other error status codes depending on the
   merchant's implementation.

.. http:POST:: /pay

   Agree with the previously obtained contract and pay the merchant by signing
   the contract with a coin.  The request is a JSON object containing the
   following fields.

   :<json string coin_pub: The coin's public key.
   :<json string mint_pub: The public key of the mint from where the coin is obtained.
   :<json string denom_pub: Denomination key with which the coin is signed
   :<json string ubsig: Mint's unblinded signature of the coin
   :<json string type: the string constant `"DIRECT_DEPOSIT"` or `"INCREMENTAL_DEPOSIT"`
     respectively for direct deposit or incremental deposit type of interaction.
   :<json string transaction_id: The transaction identifier obtained from the contract.
   :<json object amount: The amount to be deposited as a Denomination object.  Its value should
     be less than or equal to the coin's face value.  Additionally, for direct
     deposit type of interactions, this should be equal to the amount stated in
     the contract.
   :<json string merchant_pub: The public key of the merchant.
   :<json integer retract_until: The timestamp until which the customer can retract the
     contract and claim for a refund.  This should be generated by the customer
     by adding the retraction period mentioned in the contract to the present
     UTC time in seconds.
   :<json string H_a: The hash of the contract.
   :<json string H_wire: The hash of the merchant's payment information.
   :<json string csig: The signature with the coin's private key over the parameters
     `type`, `transaction_id`, `amount`, `merchant_pub`, `retract_until`,
     `H_a` and, `H_wire`.

   **Success Response**

   :status 200 OK: The deposit permission is successful.

   It is left upto the merchant's implementation to carry over the process of
   fulfilling the agreed contract `a` from here.  For example, for services or
   products which can be served through HTTP, this response could contain them.

   **Failure Response**

   :status 400: Request not understood.
   :status 404: The merchant does not entertain this type of interaction.  Try
                another one.
   :status 403: The request doesn't comply to the contract provided.  The
                request should not be repeated.
   :status 403: The deposit operation has failed because the coin has previously
                been deposited or it has been already refreshed; the request
                should not be repeated again.  The response body contains the
                failure response objects from the :ref:`Mint
                API:deposit<deposit>`.

.. _retract:
.. http:POST:: /retract

   Retract a previously made contract with the merchant.  The request should
   contain a JSON object with the following fields:

   :<json string status: the string constant `"RETRACT"`
   :<json string transaction_id: The transaction identifier of the contract to
                                 retract.
   :<json string merchant_pub: The public key of the merchant.
   :<json string csig: The signature over the fields `transaction_id` and
                       `merchant_pub` with the private key of the coin used to
                       previously sign the contract.

   **Success Response**

   :status 200 OK: The contract has been successfully retracted.

   The response contains a JSON object with the following fields.  The customer
   then has to send this object as part of the refresh request to claim the
   refund (See: :ref:`Mint API:refresh<refresh>`)

   :>json string status: the string constanst `"RETRACT"`
   :>json string transaction_id: The identifier of the transaction that is
                                 retracted
   :>json string merchant_pub: The public key of the merchant whose contract
                               is retracted
   :>json string csig: The signature of the coin submpitted by the merchant's
                       customer over the fields `transaction_id` and
                       `merchant_pub`
   :>json string msig: The signature of the merchant over the fields `status`
                       and `transaction_id`

   **Failure Response**

   :status 400: Request not understood
   :status 404: Invalid contract
   :status 403: The contract's retraction period has expired

Other interactions tbd..
