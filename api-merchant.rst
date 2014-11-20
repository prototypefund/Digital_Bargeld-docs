The Merchant JSON API
=====================

The Merchant API serves the protocol interactions between a customer and a
merchant.  The protocol allows the customer and the merchant to agree upon a
contract and for the customer to spend coins according to the contract at the
merchant.  It should be noted that the interactions are strictly one way: The
customer *always* initiates the requests by contacting the merchant.  It is also
assumed that the customer knows the merchant's public key.

The protocol allows for three different type of interactions.  In the first type
of interaction, which we refer to as *direct deposit*, an interested customer
asks the merchant to provide a ``contract`` for the merchant's services or
products.  Details about the services or products and the merchant's payment
information are provided in the contract.  The customer then agrees upon one of
these contracts by giving the the merchant a ``deposit permission``.  The
merchant then submits this deposit permission at the mint for verification.
Upon successful verification, the merchant delivers the promised services or
products.

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

The following are the API made available by the merchant:

.. http:GET:: /contract
.. http:POST:: /contract

   Ask the merchant to prepare a contract.  The request parameters are specific
   to the merchant's implementation, however, they are recommended to contain
   information required for the merchant to identify which product or service
   the customer is interested int.

   **Success Response**

   :status 200 OK: The request was successful.

   The merchant responds with a JSON object containing the following fields:

   * `transaction_id`: A string representing the transaction identifier.
   * `expiry`: The timestamp after which this contract expires.
   * `amount`: Price of the contract as a Denomination object.
   * `description`: The contract description as string.
   * `H_wire`: The hash of a JSON object containing the merchant's payment
     information.  See :ref:`wireformats`.
   * `msig`: Signature of the merchant over the fields `m`, `t`, `f`, `a`, `H_wire`.

   **Failure response**

   :status 400: Request not understood.
   :status 404: No products or services given in the request were found.

   It is also possible to receive other error status codes depending on the
   merchant's implementation.

.. http:GET:: /deposit

   Send a ``deposit-permission`` JSON object to the merchant.  The object should
   contain the following fields:

   * `coin_pub`: The coin's public key.
   * `mint_pub`: The public key of the mint from where the coin is obtained.
   * `denom_pub`: Denomination key with which the coin is signed
   * `ubsig`: Mint's unblinded signature of the coin
   * `type`: the string constant `"DIRECT_DEPOSIT"` or `"INCREMENTAL_DEPOSIT"`
     respectively for direct deposit or incremental deposit type of interaction.
   * `transaction_id`: The transaction identifier obtained from the contract.
   * `amount`: The amount to be deposited as a Denomination object.  Its value should
     be less than or equal to the coin's face value.  Additionally, for direct
     deposit type of interactions, this should be equal to the amount stated in
     the contract.
   * `merchant_pub`: The public key of the merchant.
   * `H_a`: The hash of the contract.
   * `H_wire`: The hash of the merchant's payment information.
   * `csig`: The signature with the coin's private key over the parameters
     `type`, `m`, `f`, `M`, `H_a` and, `H_wire`.

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
                failure response objects from the :ref:`Mint API deposit
                request<deposit>`.

Other interactions tbd..
