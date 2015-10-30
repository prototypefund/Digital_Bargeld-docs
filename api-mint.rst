=========================
The Mint RESTful JSON API
=========================

-------
General
-------

.. _encodings-ref:

++++++++++++++++
Common encodings
++++++++++++++++

This section describes how certain types of values are represented throughout the API.

  .. _Base32:

  * **Binary data**:
    Binary data is generally encoded using Crockford's variant of Base32 (http://www.crockford.com/wrmg/base32.html), except that "U" is not excluded but also decodes to "V" to make OCR easy.  We will still simply use the JSON type "base32" and the term "Crockford Base32" in the text to refer to the resulting encoding.

  * **Large numbers**: Large numbers such as RSA blinding factors and 256 bit  keys, are transmitted as other binary data in Crockford Base32 encoding.

  .. _Timestamp:

  * **Timestamps**:
    Timestamps are represented in JSON as a string literal `"\\/Date(x)\\/"`, where `x` is the decimal representation of the number of seconds past the Unix Epoch (January 1, 1970).  The escaped slash (`\\/`) is interpreted in JSON simply as a normal slash, but distinguishes the timestamp from a normal string literal.  We use the type "date" in the documentation below.  Additionally, the special strings "\\/never\\/" and "\\/forever\\/" are recognized to represent the end of time.

  .. _public\ key:

  * **Public key**: EdDSA and ECDHE public keys are always points on Curve25519 and represented using the standard 256 bits Ed25519 compact format, converted to Crockford Base32_.

  .. _Signature:

  * **Signatures**: The specific signature scheme in use, like RSA blind signatures or EdDSA, depends on the context.  RSA blind signatures are only used for coins and always simply base32_ encoded. 

EdDSA signatures are transmitted as 64-byte base32_ binary-encoded objects with just the R and S values (base32_ binary-only). 
These signed objects always contain a purpose number unique to the context in which the signature is used, but frequently the actual binary-object must be reconstructed locally from information available only in context, such as recent messages or account detals.
These objects are described in detail in :ref:`Signatures`.

  .. _Amount:

  * **Amounts**: Amounts of currency are expressed as a JSON object with the following fields:

    * `currency`: name of the currency using either a three-character ISO 4217 currency code, or a regional currency identifier starting with a "*" followed by at most 10 characters.  ISO 4217 exponents in the name are not supported, although the "fraction" is corresponds to an ISO 4217 exponent of 6.
    * `value`: unsigned 32 bit value in the currency, note that "1" here would correspond to 1 EUR or 1 USD, depending on `currency`, not 1 cent.
    * `fraction`: unsigned 32 bit fractional value to be added to `value` representing an additional currency fraction, in units of one millionth (10\ :superscript:`-6`) of the base currency value.  For example, a fraction of 500,000 would correspond to 50 cents.


++++++++++++++
General errors
++++++++++++++

Certain response formats are common for all requests. They are documented here instead of with each individual request.  Furthermore, we note that clients may theoretically fail to receive any response.  In this case, the client should verify that the Internet connection is working properly, and then proceed to handle the error as if an internal error (500) had been returned.

.. http:any:: /*

  **Error Response: Internal error**

  When encountering an internal error, the mint may respond to any request with an internal server error.

  :status 500 Internal server error: This always indicates some serious internal operational error of the mint, such as a program bug, database problems, etc., and must not be used for client-side problems.  When facing an internal server error, clients should retry their request after some delay.  We recommended initially trying after 1s, twice more at randomized times within 1 minute, then the user should be informed and another three retries should be scheduled within the next 24h.  If the error persists, a report should ultimately be made to the auditor, although the auditor API for this is not yet specified.  However, as internal server errors are always reported to the mint operator, a good operator should naturally be able to address them in a timely fashion, especially within 24h.  When generating an internal server error, the mint responds with a JSON object containing the following fields:

  :resheader Content-Type: application/json
  :>json error: a string with the value "internal error"
  :>json hint: a string with problem-specific human-readable diagnostic text and typically useful for the mint operator


  **Error Response: Bad Request**

  When the client issues a malformed request with missing parameters or where the parameters fail to comply with the specification, the mint generates this type of response.  The error should be shown to the user, while the other details are mostly intended as optional diagnostics for developers.

  :status 400 Bad Request: One of the arguments to the request is missing or malformed.
  :resheader Content-Type: application/json
  :>json string error: description of the error, i.e. missing parameter, malformed parameter, commitment violation, etc.  The other arguments are specific to the error value reported here.
  :>json string parameter: name of the parameter that was bogus (if applicable)
  :>json string path: path to the argument that was bogus (if applicable)
  :>json string offset: offset of the argument that was bogus (if applicable)
  :>json string index: index of the argument that was bogus (if applicable)
  :>json string object: name of the component of the object that was bogus (if applicable)
  :>json string currency: currency that was problematic (if applicable)
  :>json string type_expected: expected type (if applicable)
  :>json string type_actual: type that was provided instead (if applicable)



-------------------
Obtaining Mint Keys
-------------------

This API is used by wallets and merchants to obtain global information about the mint, such as online signing keys, available denominations and the fee structure.
This is typically the first call any mint client makes, as it returns information required to process all of the other interactions with the mint.  The returned
information is secured by (1) signature(s) from the mint, especially the long-term offline signing key of the mint, which clients should cache; (2) signature(s)
from auditors, and the auditor keys should be hard-coded into the wallet as they are the trust anchors for Taler; (3) possibly by using HTTPS.


.. http:get:: /keys

  Get a list of all denomination keys offered by the bank,
  as well as the bank's current online signing key.

  **Success Response: OK**

  :status 200 OK: This request should virtually always be successful.
  :resheader Content-Type: application/json
  :>json base32 master_public_key: EdDSA master public key of the mint, used to sign entries in `denoms` and `signkeys`
  :>json list denoms: A JSON list of denomination descriptions.  Described below in detail.
  :>json date list_issue_date: The date when the denomination keys were last updated.
  :>json list auditors: A JSON list of the auditors of the mint. Described below in detail.
  :>json list signkeys: A JSON list of the mint's signing keys.  Described below in detail.
  :>json base32 eddsa_sig: compact EdDSA signature_ (binary-only) over the SHA-512 hash of the concatenation of all SHA-512 hashes of the RSA denomination public keys in `denoms` in the same order as they were in `denoms`.  Note that for hashing, the binary format of the RSA public keys is used, and not their base32_ encoding.  Wallets cannot do much with this signature by itself; it is only useful when multiple clients need to establish that the mint is sabotaging end-user anonymity by giving disjoint denomination keys to different users.  If a mint were to do this, this signature allows the clients to demonstrate to the public that the mint is dishonest.
  :>json base32 eddsa_pub: public EdDSA key of the mint that was used to generate the signature.  Should match one of the mint's signing keys from /keys.  It is given explicitly as the client might otherwise be confused by clock skew as to which signing key was used.

  A denomination description in the `denoms` list is a JSON object with the following fields:

  :>jsonarr object value: Amount_ of the denomination.  A JSON object specifying an amount_.
  :>jsonarr date stamp_start: timestamp_ indicating when the denomination key becomes valid.
  :>jsonarr date stamp_expire_withdraw: timestamp_ indicating when the denomination key can no longer be used to withdraw fresh coins.
  :>jsonarr date stamp_expire_deposit: timestamp_ indicating when coins of this denomination become invalid for depositing.
  :>jsonarr date stamp_expire_legal: timestamp_ indicating by when legal disputes relating to these coins must be settled, as the mint will afterwards destroy its evidence relating to transactions involving this coin.
  :>jsonarr base32 denom_pub: Public (RSA) key for the denomination in base32_ encoding.
  :>jsonarr object fee_withdraw: Fee charged by the mint for withdrawing a coin of this type, encoded as a JSON object specifying an amount_.
  :>jsonarr object fee_deposit: Fee charged by the mint for depositing a coin of this type, encoded as a JSON object specifying an amount_.
  :>jsonarr object fee_refresh: Fee charged by the mint for melting a coin of this type during a refresh operation, encoded as a JSON object specifying an amount_.  Note that the total refreshing charges will be the sum of the refresh fees for all of the melted coins and the sum of the withdraw fees for all "new" coins.
  :>jsonarr base32 master_sig: Signature_ (binary-only) with purpose `TALER_SIGNATURE_MASTER_DENOMINATION_KEY_VALIDITY` over the expiration dates, value and the key, created with the mint's master key.

  Fees for any of the operations can be zero, but the fields must still be present. The currency of the `fee_deposit` and `fee_refresh` must match the currency of the `value`.  Theoretically, the `fee_withdraw` could be in a different currency, but this is not currently supported by the implementation.

  A signing key in the `signkeys` list is a JSON object with the following fields:

  :>jsonarr base32 key: The actual mint's EdDSA signing public key.
  :>jsonarr date stamp_start: Initial validity date for the signing key.
  :>jsonarr date stamp_expire: Date when the mint will stop using the signing key, allowed to overlap slightly with the next signing key's validity to allow for clock skew.
  :>jsonarr date stamp_end: Date when all signatures made by the signing key expire and should henceforth no longer be considered valid in legal disputes.
  :>jsonarr date stamp_expire: Expiration date for the signing key.
  :>jsonarr base32 master_sig:  A signature_ (binary-only) with purpose `TALER_SIGNATURE_MASTER_SIGNING_KEY_VALIDITY` over the `key` and `stamp_expire` by the mint master key.

  An entry in the `auditors` list is a JSON object with the following fields:

  :>jsonarr base32 auditor_pub: The auditor's EdDSA signing public key.
  :>jsonarr array denomination_keys: An array of denomination keys the auditor affirms with its signature. Note that the message only includes the hash of the public key, while the signature is actually over the expanded information including expiration times and fees.  The exact format is described below.

  An entry in the `denomination_keys` list is a JSON object with the following field:

  :>jsonarr base32 denom_pub_h: hash of the public RSA key used to sign coins of the respective denomination.  Note that the auditor's signature covers more than just the hash, but this other information is already provided in `denoms` and thus not repeated here.
  :>jsonarr base32 auditor_sig: A signature_ (binary-only) with purpose `TALER_SIGNATURE_AUDITOR_MINT_KEYS` over the mint's public key and the denomination key information. To verify the signature, the `denom_pub_h` must be resolved with the information from `denoms`.

  The same auditor may appear multiple times in the array for different subsets of denomination keys, and the same denomination key hash may be listed multiple times for the same or different auditors.  The wallet or merchant just should check that the denomination keys they use are in the set for at least one of the auditors that they accept.

  .. note::

    Both the individual denominations *and* the denomination list is signed,
    allowing customers to prove that they received an inconsistent list.

-----------------------------------
Obtaining wire-transfer information
-----------------------------------

.. http:get:: /wire

  Returns a list of payment methods supported by the mint.  The idea is that wallets may use this information to instruct users on how to perform wire transfers to top up their wallets.

  **Success response: OK**

  :status 200: This request should virtually always be successful.
  :resheader Content-Type: application/json
  :>json array methods: a JSON array of strings with supported payment methods, i.e. "sepa". Further information about the respective payment method is then available under /wire/METHOD, i.e. /wire/sepa if the payment method was "sepa".
  :>json base32 sig: the EdDSA signature_ (binary-only) with purpose `TALER_SIGNATURE_MINT_PAYMENT_METHODS` signing over the hash over the 0-terminated strings representing the payment methods in the same order as given in methods.
  :>json base32 pub: public EdDSA key of the mint that was used to generate the signature.  Should match one of the mint's signing keys from /keys.  It is given explicitly as the client might otherwise be confused by clock skew as to which signing key was used.

.. http:get:: /wire/test

  The "test" payment method is for testing the system without using
  real-world currencies or actual wire transfers.  If the mint operates
  in "test" mode, this request provides a redirect to an address where
  the user can initiate a fake wire transfer for testing.

  **Success Response: OK**

  :status 302: Redirect to the webpage where fake wire transfers can be made.

  **Failure Response: Not implemented**

  :status 501: This wire transfer method is not supported by this mint.

.. http:get:: /wire/sepa

  Provides instructions for how to transfer funds to the mint using the SEPA transfers.  Always signed using the mint's long-term offline master public key.

  **Success Response: OK**

  :status 200: This request should virtually always be successful.
  :resheader Content-Type: application/json
  :>json string receiver_name: Legal name of the mint operator who is receiving the funds
  :>json string iban: IBAN account number for the mint
  :>json string bic: BIC of the bank of the mint
  :>json base32 sig: the EdDSA signature_ (binary-only) with purpose `TALER_SIGNATURE_MINT_PAYMENT_METHOD_SEPA` signing over the hash over the 0-terminated strings representing the receiver's name, IBAN and the BIC.

  **Failure Response: Not implemented**

  :status 501: This wire transfer method is not supported by this mint.


------------------
Withdrawal
------------------

This API is used by the wallet to obtain digital coins.

When transfering money to the mint such as via SEPA transfers, the mint creates a *reserve*, which keeps the money from the customer.  The customer must specify an EdDSA reserve public key as part of the transfer, and can then withdraw digital coins using the corresponding private key.  All incoming and outgoing transactions are recorded under the corresponding public key by the mint.

  .. note::

     Eventually the mint will need to advertise a policy for how long it will keep transaction histories for inactive or even fully drained reserves.  We will therefore need some additional handler similar to `/keys` to advertise those terms of service.


.. http:get:: /reserve/status

  Request information about a reserve, including the blinding key that is necessary to withdraw a coin.

  :query reserve_pub: EdDSA reserve public key identifying the reserve.

  .. note::
    The client currently does not have to demonstrate knowledge of the private key of the reserve to make this request, which makes the reserve's public key privliged information known only to the client, their bank, and the mint.  In future, we might wish to revisit this decision to improve security, such as by having the client EdDSA-sign an ECDHE key to be used to derive a symmetric key to encrypt the response.  This would be useful if for example HTTPS were not used for communication with the mint.

  **Success Response: OK**

  :status 200 OK: The reserve was known to the mint, details about it follow in the body.
  :resheader Content-Type: application/json
  :>json object balance: Total amount_ left in this reserve, an amount_ expressed as a JSON object.
  :>json object history: JSON list with the history of transactions involving the reserve.

  Objects in the transaction history have the following format:

  :>jsonarr string type: either the string "WITHDRAW" or the string "DEPOSIT"
  :>jsonarr object amount: the amount_ that was withdrawn or deposited
  :>jsonarr object wire: a JSON object with the wiring details needed by the banking system in use, present in case the `type` was "DEPOSIT"
  :>jsonarr object signature: signature_ (full object with all details) made with purpose `TALER_SIGNATURE_WALLET_RESERVE_WITHDRAW` made with the reserve's public key over the original "WITHDRAW" request, present if the `type` was "WITHDRAW"

  **Error Response: Unknown reserve**

  :status 404 Not Found: The withdrawal key does not belong to a reserve known to the mint.
  :resheader Content-Type: application/json
  :>json string error: the value is always "Reserve not found"
  :>json string parameter: the value is always "withdraw_pub"


.. http:post:: /reserve/withdraw

  Withdraw a coin of the specified denomination.  Note that the client should commit all of the request details, including the private key of the coin and the blinding factor, to disk *before* issuing this request, so that it can recover the information if necessary in case of transient failures, like power outage, network outage, etc.

  :reqheader Content-Type: application/json
  :<json base32 denom_pub: denomination public key (RSA), specifying the type of coin the client would like the mint to create.
  :<json base32 coin_ev: coin's blinded public key, should be (blindly) signed by the mint's denomination private key
  :<json base32 reserve_pub: public (EdDSA) key of the reserve from which the coin should be withdrawn.  The total amount deducted will be the coin's value plus the withdrawal fee as specified with the denomination information.
  :<json object reserve_sig: EdDSA signature_ (binary-only) of purpose `TALER_SIGNATURE_WALLET_RESERVE_WITHDRAW` created with the reserves's private key

  **Success Response: OK**:

  :status 200 OK: The request was succesful.  Note that repeating exactly the same request will again yield the same response, so if the network goes down during the transaction or before the client can commit the coin signature_ to disk, the coin is not lost.
  :resheader Content-Type: application/json
  :>json base32 ev_sig: The RSA signature_ over the `coin_ev`, affirms the coin's validity after unblinding.

  **Error Response: Insufficient funds**:

  :status 402 Payment Required: The balance of the reserve is not sufficient to withdraw a coin of the indicated denomination.
  :resheader Content-Type: application/json
  :>json string error: the value is "Insufficient funds"
  :>json object balance: a JSON object with the current amount_ left in the reserve
  :>json array history: a JSON list with the history of the reserve's activity, in the same format as returned by /reserve/status.

  **Error Response: Invalid signature**:

  :status 401 Unauthorized: The signature is invalid.
  :resheader Content-Type: application/json
  :>json string error: the value is "invalid signature"
  :>json string paramter: the value is "reserve_sig"

  **Error Response: Unknown key**:

  :status 404 Not Found: The denomination key or the reserve are not known to the mint.  If the denomination key is unknown, this suggests a bug in the wallet as the wallet should have used current denomination keys from /keys.  If the reserve is unknown, the wallet should not report a hard error yet, but instead simply wait for up to a day, as the wire transaction might simply not yet have completed and might be known to the mint in the near future.  In this case, the wallet should repeat the exact same request later again using exactly the same blinded coin.
  :resheader Content-Type: application/json
  :>json string error: "unknown entity referenced"
  :>json string parameter: either "denom_pub" or "reserve_pub"


--------------------
Deposit
--------------------

Deposit operations are requested by a merchant during a transaction. For the deposit operation, the merchant has to obtain the deposit permission for a coin from their customer who owns the coin.  When depositing a coin, the merchant is credited an amount specified in the deposit permission, possibly a fraction of the total coin's value, minus the deposit fee as specified by the coin's denomination.


.. _deposit:
.. http:POST:: /deposit

  Deposit the given coin and ask the mint to transfer the given amount to the merchants bank account.  This API is used by the merchant to redeem the digital coins.  The request should contain a JSON object with the following fields:

  :reqheader Content-Type: application/json
  :<json object f: the amount_ to be deposited, can be a fraction of the coin's total value
  :<json object `wire`: the merchant's account details. This must be a JSON object whose format must correspond to one of the supported wire transfer formats of the mint.  See :ref:`wireformats`
  :<json base32 H_wire: SHA-512 hash of the merchant's payment details from `wire`.  Although strictly speaking redundant, this helps detect inconsistencies.
  :<json base32 H_contract: SHA-512 hash of the contact of the merchant with the customer.  Further details are never disclosed to the mint.
  :<json base32 coin_pub: coin's public key, both ECDHE and EdDSA.
  :<json base32 denom_pub: denomination RSA key with which the coin is signed
  :<json base32 ub_sig: mint's unblinded RSA signature_ of the coin
  :<json date timestamp: timestamp when the contract was finalized, must match approximately the current time of the mint
  :<json date edate: indicative time by which the mint undertakes to transfer the funds to the merchant, in case of successful payment.
  :<json int transaction_id: 64-bit transaction id for the transaction between merchant and customer
  :<json base32 merchant_pub: the EdDSA public key of the merchant, so that the client can identify the merchant for refund requests.
  :<json date refund_deadline: date until which the merchant can issue a refund to the customer via the mint, possibly zero if refunds are not allowed.
  :<json base32 coin_sig: the EdDSA signature_ (binary-only) made with purpose `TALER_SIGNATURE_WALLET_COIN_DEPOSIT` made by the customer with the coin's private key.

  The deposit operation succeeds if the coin is valid for making a deposit and has enough residual value that has not already been deposited or melted.

  **Success response: OK**

  :status 200: the operation succeeded, the mint confirms that no double-spending took place.
  :resheader Content-Type: application/json
  :>json string status: the string constant `DEPOSIT_OK`
  :>json base32 sig: the EdDSA signature_ (binary-only) with purpose `TALER_SIGNATURE_MINT_CONFIRM_DEPOSIT` using a current signing key of the mint affirming the successful deposit and that the mint will transfer the funds after the refund deadline, or as soon as possible if the refund deadline is zero.
  :>json base32 pub: public EdDSA key of the mint that was used to generate the signature.  Should match one of the mint's signing keys from /keys.  It is given explicitly as the client might otherwise be confused by clock skew as to which signing key was used.

  **Failure response: Double spending**

  :status 403: the deposit operation has failed because the coin has insufficient residual value; the request should not be repeated again with this coin.
  :resheader Content-Type: application/json
  :>json string error: the string "insufficient funds"
  :>json object history: a JSON array with the transaction history for the coin

  The transaction history contains entries of the following format:

  :>jsonarr string type: either "deposit" or "melt"
  :>jsonarr object amount: the total amount_ of the coin's value absorbed by this transaction
  :>jsonarr object signature: the signature_ (JSON object) of purpose `TALER_SIGNATURE_WALLET_COIN_DEPOSIT` or `TALER_SIGNATURE_WALLET_COIN_MELT` with the details of the transaction that drained the coin's value

  **Error Response: Invalid signature**:

  :status 401 Unauthorized: One of the signatures is invalid.
  :resheader Content-Type: application/json
  :>json string error: the value is "invalid signature"
  :>json string paramter: the value is "coin_sig" or "ub_sig", depending on which signature was deemed invalid by the mint

  **Failure response: Unknown denomination key**

  :status 404: the mint does not recognize the denomination key as belonging to the mint, or it has expired
  :resheader Content-Type: application/json
  :>json string error: the value is "unknown entity referenced"
  :>json string paramter: the value is "denom_pub"

  **Failure response: Unsupported or invalid wire format**

  :status 404: the mint does not recognize the wire format (unknown type or format check fails)
  :resheader Content-Type: application/json
  :>json string error: the value is "unknown entity referenced"
  :>json string paramter: the value is "wire"



------------------
Refreshing
------------------

Refreshing creates `n` new coins from `m` old coins, where the sum of denominations of the new coins must be smaller than the sum of the old coins' denominations plus melting (refresh) and withdrawal fees charged by the mint.  The refreshing API can be used by wallets to melt partially spent coins, making transactions with the freshly minted coins unlinkabe to previous transactions by anyone except the wallet itself.

However, the new coins are linkable from the private keys of all old coins using the /refresh/link request.  While /refresh/link must be implemented by the mint to achieve taxability, wallets do not really ever need that part of the API during normal operation.

.. _refresh:
.. http:post:: /refresh/melt

  "Melts" coins.  Invalidates the coins and prepares for minting of fresh coins.  Taler uses a global parameter `kappa` for the cut-and-choose component of the protocol, for which this request is the commitment.  Thus, various arguments are given `kappa`-times in this step.  At present `kappa` is always 3.

  The request body must contain a JSON object with the following fields:

  :<json array new_denoms: List of `n` new denominations to order. Each entry must be a base32_ encoded RSA public key corresponding to the coin to be minted.
  :<json array melt_coins: List of `m` coins to melt.
  :<json array coin_evs: For each of the `n` new coins, `kappa` coin blanks (2D array)
  :<json array transfer_pubs: For each of the `m` old coins, `kappa` transfer public keys (2D-array of ephemeral ECDHE keys)
  :<json array secret_encs: For each of the `m` old coins, `kappa` link encryptions with an ECDHE-encrypted SHA-512 hash code.  The ECDHE encryption is done using the private key of the respective old coin and the corresponding transfer public key.  Note that the SHA-512 hash code must be the same across all coins, but different across all of the `kappa` dimensions.  Given the private key of a single old coin, it is thus possible to decrypt the respective `secret_encs` and obtain the SHA-512 hash that was used to symetrically encrypt the `link_encs` of all of the new coins.
  :<json array link_encs: For each of the `n` new coins, `kappa` symmetricly encrypted tuples consisting of the EdDSA/ECDHE-private key of the new coin and the corresponding blinding factor, encrypted using the corresponding SHA-512 hash that is encrypted in `secret_encs`.

  For details about the HKDF used to derive the symmetric encryption keys from ECDHE and the symmetric encryption (AES+Twofish) used, please refer to the implementation in `libtalerutil`. The `melt_coins` field is a list of JSON objects with the following fields:

  :<jsonarr string coin_pub: Coin public key (uniquely identifies the coin)
  :<jsonarr string denom_pub: Denomination public key (allows the mint to determine total coin value)
  :<jsonarr string denom_sig: Signature_ over the coin public key by the denomination
  :<jsonarr string confirm_sig: Signature_ by the coin over the session public key
     key
  :<jsonarr object value_with_fee: Amount_ of the value of the coin that should be melted as part of this refresh operation, including melting fee.

  Errors such as failing to do proper arithmetic when it comes to calculating the total of the coin values and fees are simply reported as bad requests.  This includes issues such as melting the same coin twice in the same session, which is simply not allowed.  However, theoretically it is possible to melt a coin twice, as long as the `value_with_fee` of the two melting operations is not larger than the total remaining value of the coin before the melting operations. Nevertheless, this is not really useful.

  **Success Response: OK**

  :status 200 OK: The request was succesful. The response body contains a JSON object with the following fields:
  :resheader Content-Type: application/json
  :<json int noreveal_index: Which of the `kappa` indices does the client not have to reveal.
  :<json base32 mint_sig: binary-only Signature_ for purpose `TALER_SIGNATURE_MINT_CONFIRM_MELT` whereby the mint affirms the successful melt and confirming the `noreveal_index`
  :<json base32 mint_pub: public EdDSA key of the mint that was used to generate the signature.  Should match one of the mint's signing keys from /keys.  Again given explicitly as the client might otherwise be confused by clock skew as to which signing key was used.

  **Error Response: Invalid signature**:

  :status 401 Unauthorized: One of the signatures is invalid.
  :resheader Content-Type: application/json
  :>json string error: the value is "invalid signature"
  :>json string paramter: the value is "confirm_sig" or "denom_sig", depending on which signature was deemed invalid by the mint

  **Error Response: Precondition failed**:

  :status 403 Forbidden: The operation is not allowed as at least one of the coins has insufficient funds.
  :resheader Content-Type: application/json
  :>json string error: the value is "insufficient funds"
  :>json base32 coin_pub: public key of a melted coin that had insufficient funds
  :>json amount original_value: original total value of the coin
  :>json amount residual_value: remaining value of the coin
  :>json amount requested_value: amount of the coin's value that was to be melted
  :>json array history: the transaction list of the respective coin that failed to have sufficient funds left.  The format is the same as for insufficient fund reports during /deposit.  Note that only the transaction history for one bogus coin is given, even if multiple coins would have failed the check.

  **Failure response: Unknown denomination key**

  :status 404: the mint does not recognize the denomination key as belonging to the mint, or it has expired
  :resheader Content-Type: application/json
  :>json string error: the value is "unknown entity referenced"
  :>json string paramter: the value is "denom_pub"

.. http:post:: /refresh/reveal

  Reveal previously commited values to the mint, except for the values corresponding to the `noreveal_index` returned by the /mint/melt step.  Request body contains a JSON object with the following fields:

  :<json base32 session_hash: Hash over most of the arguments to the /mint/melt step.  Used to identify the corresponding melt operation.  For details on which elements must be hashed in which order, please consult the mint code itself.
  :<json array transfer_privs: 2D array of `kappa - 1` times number of melted coins ECDHE transfer private keys.  The mint will use those to decrypt the transfer secrets, check that they match across all coins, and then decrypt the private keys of the coins to be generated and check all this against the commitments.

  **Success Response: OK**

  :status 200 OK: The transfer private keys matched the commitment and the original request was well-formed.  The mint responds with a JSON of the following type:
  :resheader Content-Type: application/json
  :>json array ev_sigs: List of the mint's blinded RSA signatures on the new coins.  Each element in the array is another JSON object which contains the signature in the "ev_sig" field.

  **Failure Response: Conflict**

  :status 409 Conflict: There is a problem between the original commitment and the revealed private keys.  The returned information is proof of the missmatch, and therefore rather verbose, as it includes most of the original /refresh/melt request, but of course expected to be primarily used for diagnostics.
  :resheader Content-Type: application/json
  :>json string error: the value is "commitment violation"
  :>json int offset: offset of in the array of `kappa` commitments where the error was detected
  :>json int index: index of in the with respect to the melted coin where the error was detected
  :>json string object: name of the entity that failed the check (i.e. "transfer key")
  :>json array oldcoin_infos: array with information for each melted coin
  :>json array newcoin_infos: array with RSA denomination public keys of the coins the original refresh request asked to be minted
  :>json array link_infos: 2D array with `kappa` entries in the first dimension and the same length as the `oldcoin_infos` in the 2nd dimension containing as elements objects with the linkage information
  :>json array commit_infos: 2D array with `kappa` entries in the first dimension and the same length as `newcoin_infos` in the 2nd dimension containing as elements objects with the commitment information

  The linkage information from `link_infos` consists of:

  :>jsonarr base32 transfer_pub: the transfer ECDHE public key
  :>jsonarr base32 shared_secret_enc: the encrypted shared secret

  The commit information from `commit_infos` consists of:

  :>jsonarr base32 coin_ev: the coin envelope (information to sign blindly)
  :>jsonarr base32 coin_priv_enc: the encrypted private key of the coin
  :>jsonarr base32 blinding_key_enc: the encrypted blinding key

.. http:get:: /refresh/link

  Link the old public key of a melted coin to the coin(s) that were minted during the refresh operation.

  :query coin_pub: melted coin's public key

  **Success Response**

  :status 200 OK: All commitments were revealed successfully.  The mint returns an array, typically consisting of only one element, in which each each element contains information about a melting session that the coin was used in.

  :>jsonarr base32 transfer_pub: transfer ECDHE public key corresponding to the `coin_pub`, used to decrypt the `secret_enc` in combination with the private key of `coin_pub`.
  :>jsonarr base32 secret_enc: ECDHE-encrypted link secret that, once decrypted, can be used to decrypt/unblind the `new_coins`.
  :>jsonarr array new_coins: array with (encrypted/blinded) information for each of the coins minted in the refresh operation.

  The `new_coins` array contains the following fields for each element:

  :>jsonarr base32 link_enc: Encrypted private key and blinding factor information of the fresh coin
  :>jsonarr base32 denom_pub: RSA public key of the minted coin.
  :>jsonarr base32 ev_sig: Mint's blinded signature over the minted coin.

  **Error Response: Unknown key**:

  :status 404 Not Found: The mint has no linkage data for the given public key, as the coin has not yet been involved in a refresh operation.
  :resheader Content-Type: application/json
  :>json string error: "unknown entity referenced"
  :>json string parameter: will be "coin_pub"


--------------------
Refunds
--------------------

  .. note::

     Refunds are currently not implemented (#3641), this documentation is thus rather preliminary and subject to change.

.. _refund:
.. http:POST:: /refund

  Undo deposit of the given coin, restoring its value.  The request
  should contain a JSON object with the following fields:

  :>json obj retract_perm: If the coin was claimed as a refund, this field should contain the retract permission obtained from the merchant, otherwise it should not be present.  For details about the object type, see :ref:`Merchant API:retract<retract>`.
  :>json string retract_value: Value returned due to the retraction.



------------------------------
Administrative API: Key update
------------------------------

  .. note::

     This is not yet implemented (no bug number yet, as we are not sure we will implement this; for now, adding new files to the directory and sending a signal to the mint process seems to work fine).

New denomination and signing keys can be uploaded to the mint via the
HTTP interface.  It is, of course, only possible to upload keys signed
by the mint's master key.  Furthermore, this API should probably only
be used via loopback, as we want to protect the private keys from
interception.

.. http:POST:: /admin/add/denomination_key

  Upload a new denomination key.

  :>json object denom_info: Public part of the denomination key
  :>json base32 denom_priv: Private RSA key

.. http:POST:: /admin/add/sign_key

  Upload a new signing key.

  :>json object sign_info: Public part of the signing key
  :>json base32 sign_priv: Private EdDSA key


-------------------------------------
Administrative API: Bank transactions
-------------------------------------

.. http:POST:: /admin/add/incoming

  Notify mint of an incoming transaction to fill a reserve.

  :>json base32 reserve_pub: Reserve public key
  :>json object amount: Amount transferred to the reserve
  :>json date execution_date: When was the transaction executed
  :>json object wire: Wire details

  **Success response**

  :status 200: the operation succeeded

  The mint responds with a JSON object containing the following fields:

  :>json string status: The string constant `NEW` or `DUP` to indicate
     whether the transaction was truly added to the DB
     or whether it already existed in the DB

  **Failure response**

  :status 403: the client is not permitted to add incoming transactions. The request may be disallowed by the configuration in general or restricted to certain IP addresses (i.e. loopback-only).

  The mint responds with a JSON object containing the following fields:

  :>json string error: the error message, such as `permission denied`
  :>json string hint: hint as to why permission was denied


.. http:POST:: /admin/add/outgoing

  Notify mint about the completion of an outgoing transaction satisfying a /deposit request.  In the future, this will allow merchants to obtain details about the /deposit requests they send to the mint.

  .. note::

     This is not yet implemented (no bug number yet either).

  :>json base32 coin_pub: Coin public key
  :>json object amount: Amount transferred to the merchant
  :>json string transaction: Transaction identifier in the wire details
  :>json base32 wire: Wire transaction details, as originally specified by the merchant


  **Success response**

  :status 200: the operation succeeded

  The mint responds with a JSON object containing the following fields:

  :>json string status: The string constant `NEW` or `DUP` to indicate
     whether the transaction was truly added to the DB
     or whether it already existed in the DB

  **Failure response**

  :status 403: the client is not permitted to add outgoing transactions

  The mint responds with a JSON object containing the following fields:

  :>json string error: the error message (`permission denied`)
  :>json string hint: hint as to why permission was denied


------------
The Test API
------------

The test API is not there to test the mint, but to allow
clients of the mint (merchant and wallet implementations)
to test if their implemenation of the cryptography is
binary-compatible with the implementation of the mint.

.. http:POST:: /test/base32

  Test hashing and Crockford base32_ encoding.

  :reqheader Content-Type: application/json
  :<json base32 input: some base32_-encoded value
  :status 200: the operation succeeded
  :resheader Content-Type: application/json
  :>json base32 output: the base32_-encoded hash of the input value

.. http:POST:: /test/encrypt

  Test symmetric encryption.

  :reqheader Content-Type: application/json
  :<json base32 input: some base32_-encoded value
  :<json base32 key_hash: some base32_-encoded hash that is used to derive the symmetric key and initialization vector for the encryption using the HKDF with "skey" and "iv" as the salt.
  :status 200: the operation succeeded
  :resheader Content-Type: application/json
  :>json base32 output: the encrypted value

.. http:POST:: /test/hkdf

  Test Hash Key Deriviation Function.

  :reqheader Content-Type: application/json
  :<json base32 input: some base32_-encoded value
  :status 200: the operation succeeded
  :resheader Content-Type: application/json
  :>json base32 output: the HKDF of the input using "salty" as salt

.. http:POST:: /test/ecdhe

  Test ECDHE.

  :reqheader Content-Type: application/json
  :<json base32 ecdhe_pub: ECDHE public key
  :<json base32 ecdhe_priv: ECDHE private key
  :status 200: the operation succeeded
  :resheader Content-Type: application/json
  :>json base32 ecdh_hash: ECDH result from the two keys

.. http:POST:: /test/eddsa

  Test EdDSA.

  :reqheader Content-Type: application/json
  :<json base32 eddsa_pub: EdDSA public key
  :<json base32 eddsa_sig: EdDSA signature using purpose TALER_SIGNATURE_CLIENT_TEST_EDDSA. Note: the signed payload must be empty, we sign just the purpose here.
  :status 200: the signature was valid
  :resheader Content-Type: application/json
  :>json base32 eddsa_pub: Another EdDSA public key
  :>json base32 eddsa_sig: EdDSA signature using purpose TALER_SIGNATURE_MINT_TEST_EDDSA

.. http:GET:: /test/rsa/get

  Obtain the RSA public key used for signing in /test/rsa/sign.

  :status 200: operation was successful
  :resheader Content-Type: application/json
  :>json base32 rsa_pub: The RSA public key the client should use when blinding a value for the /test/rsa/sign API.

.. http:POST:: /test/rsa/sign

  Test RSA blind signatures.

  :reqheader Content-Type: application/json
  :<json base32 blind_ev: Blinded value to sign.
  :status 200: operation was successful
  :resheader Content-Type: application/json
  :>json base32 rsa_blind_sig: Blind RSA signature over the `blind_ev` using the private key corresponding to the RSA public key returned by /test/rsa/get.


.. http:POST:: /test/transfer

  Test Transfer decryption.

  :reqheader Content-Type: application/json
  :<json base32 secret_enc: Encrypted transfer secret
  :<json base32 trans_priv: Private transfer key
  :<json base32 coin_pub: Public key of a coin
  :status 200: the operation succeeded
  :resheader Content-Type: application/json
  :>json base32 secret: Decrypted transfer secret


===========================
Binary Blob Specification
===========================

  .. note::

     This section largely corresponds to the definitions in taler_signatures.h.  You may also want to refer to this code, as it offers additional details on each of the members of the structs.

  .. note::

     Due to the way of handling `big` numbers by some platforms (such as `JavaScript`, for example), wherever the following specification mentions a 64-bit value, the actual implementations
     are strongly advised to rely on arithmetic up to 53 bits.

This section specifies the binary representation of messages used in Taler's protocols. The message formats are given in a C-style pseudocode notation.  Padding is always specified explicitly, and numeric values are in network byte order (big endian).

------------------------
Amounts
------------------------

Amounts of currency are always expressed in terms of a base value, a fractional value and the denomination of the currency:

.. sourcecode:: c

  struct TALER_AmountNBO {
    uint64_t value;
    uint32_t fraction;
    uint8_t currency_code[12];
  };


------------------------
Time
------------------------

In signed messages, time is represented using 64-bit big-endian values, denoting microseconds since the UNIX Epoch.  `UINT64_MAX` represents "never" (distant future, eternity).

.. sourcecode:: c

  struct GNUNET_TIME_AbsoluteNBO {
    uint64_t timestamp_us;
  };

------------------------
Cryptographic primitives
------------------------

All elliptic curve operations are on Curve25519.  Public and private keys are thus 32 bytes, and signatures 64 bytes.  For hashing, including HKDFs, Taler uses 512-bit hash codes (64 bytes).

.. sourcecode:: c

   struct GNUNET_HashCode {
     uint8_t hash[64];
   };

   struct TALER_ReservePublicKeyP {
     uint8_t eddsa_pub[32];
   };

   struct TALER_ReservePrivateKeyP {
     uint8_t eddsa_priv[32];
   };

   struct TALER_ReserveSignatureP {
     uint8_t eddsa_signature[64];
   };

   struct TALER_MerchantPublicKeyP {
     uint8_t eddsa_pub[32];
   };

   struct TALER_MerchantPrivateKeyP {
     uint8_t eddsa_priv[32];
   };

   struct TALER_TransferPublicKeyP {
     uint8_t ecdhe_pub[32];
   };

   struct TALER_TransferPrivateKeyP {
     uint8_t ecdhe_priv[32];
   };

   struct TALER_MintPublicKeyP {
     uint8_t eddsa_pub[32];
   };

   struct TALER_MintPrivateKeyP {
     uint8_t eddsa_priv[32];
   };

   struct TALER_MintSignatureP {
     uint8_t eddsa_signature[64];
   };

   struct TALER_MasterPublicKeyP {
     uint8_t eddsa_pub[32];
   };

   struct TALER_MasterPrivateKeyP {
     uint8_t eddsa_priv[32];
   };

   struct TALER_MasterSignatureP {
     uint8_t eddsa_signature[64];
   };

   union TALER_CoinSpendPublicKeyP {
     uint8_t eddsa_pub[32];
     uint8_t ecdhe_pub[32];
   };

   union TALER_CoinSpendPrivateKeyP {
     uint8_t eddsa_priv[32];
     uint8_t ecdhe_priv[32];
   };

   struct TALER_CoinSpendSignatureP {
     uint8_t eddsa_signature[64];
   };

   struct TALER_TransferSecretP {
     uint8_t key[sizeof (struct GNUNET_HashCode)];
   };

   struct TALER_LinkSecretP {
     uint8_t key[sizeof (struct GNUNET_HashCode)];
   };

   struct TALER_EncryptedLinkSecretP {
     uint8_t enc[sizeof (struct TALER_LinkSecretP)];
   };

.. _Signatures:

------------------------
Signatures
------------------------

Please note that any RSA signature is processed by a function called `GNUNET_CRYPTO_rsa_signature_encode (..)` **before** being sent over the network, so the receiving party must run `GNUNET_CRYPTO_rsa_signature_decode (..)` before verifying it. See their implementation in `src/util/crypto_rsa.c`, in GNUNET's code base. Finally, they are defined in `gnunet/gnunet_crypto_lib.h`.

EdDSA signatures are always made on the hash of a block of the same generic format, the `struct SignedData` given below.  In our notation, the type of a field can depend on the value of another field. For the following message, the length of the `payload` array must match the value of the `size` field:

.. sourcecode:: c

  struct SignedData {
    uint32_t size;
    uint32_t purpose;
    uint8_t payload[size - sizeof (struct SignedData)];
  };

The `purpose` field in `struct SignedData` is used to express the context in which the signature is made, ensuring that a signature cannot be lifted from one part of the protocol to another.  The various `purpose` constants are defined in `taler_signatures.h`.  The `size` field prevents padding attacks.

In the subsequent messages, we use the following notation for signed data described in `FIELDS` with the given purpose.

.. sourcecode:: c

  signed (purpose = SOME_CONSTANT) {
    FIELDS
  } msg;

The `size` field of the corresponding `struct SignedData` is determined by the size of `FIELDS`.

.. sourcecode:: c

  struct TALER_WithdrawRequestPS {
    signed (purpose = TALER_SIGNATURE_WALLET_RESERVE_WITHDRAW) {
      struct TALER_ReservePublicKeyP reserve_pub;
      struct TALER_AmountNBO amount_with_fee;
      struct TALER_AmountNBO withdraw_fee;
      struct GNUNET_HashCode h_denomination_pub;
      struct GNUNET_HashCode h_coin_envelope;
    }
  };

  struct TALER_DepositRequestPS {
    signed (purpose = TALER_SIGNATURE_WALLET_COIN_DEPOSIT) {
      struct GNUNET_HashCode h_contract;
      struct GNUNET_HashCode h_wire;
      struct GNUNET_TIME_AbsoluteNBO timestamp;
      struct GNUNET_TIME_AbsoluteNBO refund_deadline;
      uint64_t transaction_id;
      struct TALER_AmountNBO amount_with_fee;
      struct TALER_AmountNBO deposit_fee;
      struct TALER_MerchantPublicKeyP merchant;
      union TALER_CoinSpendPublicKeyP coin_pub;
    }
  };

  struct TALER_DepositConfirmationPS {
    signed (purpose = TALER_SIGNATURE_MINT_CONFIRM_DEPOSIT) {
      struct GNUNET_HashCode h_contract;
      struct GNUNET_HashCode h_wire;
      uint64_t transaction_id GNUNET_PACKED;
      struct GNUNET_TIME_AbsoluteNBO timestamp;
      struct GNUNET_TIME_AbsoluteNBO refund_deadline;
      struct TALER_AmountNBO amount_without_fee;
      union TALER_CoinSpendPublicKeyP coin_pub;
      struct TALER_MerchantPublicKeyP merchant;
    }
  };

  struct TALER_RefreshMeltCoinAffirmationPS {
    signed (purpose = TALER_SIGNATURE_WALLET_COIN_MELT) {
      struct GNUNET_HashCode session_hash;
      struct TALER_AmountNBO amount_with_fee;
      struct TALER_AmountNBO melt_fee;
      union TALER_CoinSpendPublicKeyP coin_pub;
    }
  };

  struct TALER_RefreshMeltConfirmationPS {
    signed (purpose = TALER_SIGNATURE_MINT_CONFIRM_MELT) {
      struct GNUNET_HashCode session_hash;
      uint16_t noreveal_index;
    }
  };

  struct TALER_MintSigningKeyValidityPS {
    signed (purpose = TALER_SIGNATURE_MASTER_SIGNING_KEY_VALIDITY) {
      struct TALER_MasterPublicKeyP master_public_key;
      struct GNUNET_TIME_AbsoluteNBO start;
      struct GNUNET_TIME_AbsoluteNBO expire;
      struct GNUNET_TIME_AbsoluteNBO end;
      struct TALER_MintPublicKeyP signkey_pub;
    }
  };

  struct TALER_MintKeySetPS {
    signed (purpose=TALER_SIGNATURE_MINT_KEY_SET) {
      struct GNUNET_TIME_AbsoluteNBO list_issue_date;
      struct GNUNET_HashCode hc;
    }
  };

  struct TALER_DenominationKeyValidityPS {
    signed (purpose = TALER_SIGNATURE_MASTER_DENOMINATION_KEY_VALIDITY) {
      struct TALER_MasterPublicKeyP master;
      struct GNUNET_TIME_AbsoluteNBO start;
      struct GNUNET_TIME_AbsoluteNBO expire_withdraw;
      struct GNUNET_TIME_AbsoluteNBO expire_spend;
      struct GNUNET_TIME_AbsoluteNBO expire_legal;
      struct TALER_AmountNBO value;
      struct TALER_AmountNBO fee_withdraw;
      struct TALER_AmountNBO fee_deposit;
      struct TALER_AmountNBO fee_refresh;
      struct GNUNET_HashCode denom_hash;
    }
  };

  struct TALER_MasterWireSepaDetailsPS {
    signed (purpose = TALER_SIGNATURE_MASTER_SEPA_DETAILS) {
      struct GNUNET_HashCode h_sepa_details;
    }
  };

  struct TALER_MintWireSupportMethodsPS {
    signed (purpose = TALER_SIGNATURE_MINT_WIRE_TYPES) {
      struct GNUNET_HashCode h_wire_types;
    }
  };
