========================
The Mint JSON API
========================

-------
General
-------

++++++++++++++++
Common encodings
++++++++++++++++

This section describes how certain types of values are represented throughout the API.

  .. _Base32:

  * **Binary data**:
    Binary data is generally encoded using Crockford's variant of Base32 (http://www.crockford.com/wrmg/base32.html), except that "U" is not excluded but also decodes to "V" to make OCR easy.  We will still simply use the JSON type "base32" and the term "Crockford Base32" in the text to refer to the resulting encoding.

  * **Large numbers**: Large numbers (typically 256 bits), such as blinding factors and private keys, are transmitted as other binary data in Crockford Base32 encoding.

  .. _Timestamp:

  * **Timestamps**:
    Timestamps are represented in JSON as a string literal `"\\/Date(x)\\/"`, where `x` is the decimal representation of the number of milliseconds past the Unix Epoch (January 1, 1970).  The escaped slash (`\\/`) is interpreted in JSON simply as a normal slash, but distinguishes the timestamp from a normal string literal.  We use the type "date" in the documentation below.

  .. _public\ key:

  * **Public key**: ECDSA, EdDSA and ECDHE public keys are always points on Curve25519 and represented using the Ed25519 standard compact format (256 bits), converted to Crockford Base32_.

  .. _Signature:

  * **Signatures**: EdDSA and ECDSA signatures are be transmitted in two forms in the protocol.  As 64-byte base32_ binary-encoded objects with just the R and S values (base32_ binary-only), or as JSON objects with following fields (replace `eddsa` with `ecdsa` for ECDSA signatures):

    * `purpose`: a unique number to state the context in which the signature is to be used in
    * `size`: the number of bytes that were hashed (using SHA-512) to create the signature; note that signatures are always done over a packed, binary representation of the data and not the JSON representations.
    * `eddsa_sig`: 64-byte base32_ binary encoding of the R and S values
    * `eddsa_val`: base32_ binary encoding of the full signed data (including again `purpose` and `size`)

    RSA signatures are always simply base32_ encoded. The specific signature scheme in use (blind signature, ECDSA, EdDSA) depends on the context.

  .. _Amount:

  * **Amounts**: Amounts of currency are expressed as a JSON object with the following fields:

    * `currency`: name of the currency using either a three-character ISO 4217 currency code, or a regional currency identifier starting with a "*" followed by at most 10 characters; ISO 4217 exponents in the name are not supported (for this, the "fraction" is used, corresponding to an ISO 4217 exponent of 6).
    * `value`: unsigned 32 bit value in the currency, note that "1" here would correspond to 1 EUR or 1 USD (depending on `currency`), not 1 cent.
    * `fraction`: unsigned 32 bit fractional value (to be added to `value`) representing an additional currency fraction, in units of 1 in one million (1/1000000) of the base currency value.  For example, a fraction of 500000 (500 thousand) would correspond to 50 cents.


++++++++++++++
General errors
++++++++++++++

Certain response formats are common for all requests. They are documented here instead of with each individual request.

.. http:any:: /*

  **Error Response: Internal error**

  When encountering an internal error, the mint may respond to any request with an internal server error.

  :status 500 Internal server error: This always indicates some serious internal operational error of the mint (i.e. a program bug, database problems, etc.) and must not be used for client-side problems.  When facing an internal server error, clients should retry their request after some delay (say after 5, 15 and 60 minutes) and if the error persists report the details to the user.  However, as internal server errors are always reported to the mint operator, a good operator should naturally be able to address them in a timely fashion.  When generating an internal server error, the mint responds with a JSON object containing the following fields:

  :resheader Content-Type: application/json
  :>json error: a string with the value "internal error"
  :>json hint: a string with problem-specific human-readable diagnostic text (typically useful for the mint operator)


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


.. http:get:: /keys

  Get a list of all denomination keys offered by the bank,
  as well as the bank's current online signing key.

  **Success Response: OK**

  :status 200 OK: This request should virtually always be successful.
  :resheader Content-Type: application/json
  :>json object keys: JSON object described in more detail below (might be inlined once we resolve #3739)
  :>json base32 eddsa_sig: EdDSA signature_ (binary-only) over the JSON object using the current signing key (which is part of `keys`).  FIXME: What is exactly signed here is currently a hack (#3739) and will change in the future.

  The `keys` JSON object consists of:

  :>json base32 master_public_key: EdDSA master public key of the mint, used to sign entries in `denoms` and `signkeys`
  :>json list denoms: A JSON list of denomination descriptions.  Described below in detail.
  :>json date list_issue_date: The date when the denomination keys were last updated.
  :>json list signkeys: A JSON list of the mint's signing keys.  Described below in detail.

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

  .. note::

    Both the individual denominations *and* the denomination list is signed,
    allowing customers to prove that they received an inconsistent list.


------------------
Withdrawal
------------------

This API is used by the wallet to obtain digital coins.

When transfering money to the mint (for example, via SEPA transfers), the mint creates a *reserve*, which keeps the money from the customer.  The customer must specify an EdDSA reserve public key as part of the transfer, and can then withdraw digital coins using the corresponding private key.  All incoming and outgoing transactions are recorded under the corresponding public key by the mint.

  .. note::

     Eventually the mint will need to advertise a policy for how long it will keep transaction histories for inactive or even fully drained reserves.  So we will need some additional handler (similar to `/keys`) to advertise those terms of service.


.. http:get:: /withdraw/status

  Request information about a reserve, including the blinding key that is necessary to withdraw a coin.

  :query reserve_pub: EdDSA reserve public key identifying the reserve.

  .. note::
    The client currently does not have to demonstrate knowledge of the private key of the reserve to make this request.  This should be OK, as the only entities that learn about the reserves' public key (the client, the bank and the mint) should already know most of the information returned (in particular, the `wire` details), and everything else is not really sensitive information.  However, we might want to revisit this decision for maximum security in the future; for example, the client could EdDSA-sign an ECDHE key to be used to derive a symmetric key to encrypt the response.  This might be useful, especially if HTTPS is not used for communication with the mint.

  **Success Response: OK**

  :status 200 OK: The reserve was known to the mint, details about it follow in the body.
  :resheader Content-Type: application/json
  :>json object balance: Total amount_ left in this reserve, an amount_ expressed as a JSON object.
  :>json object history: JSON list with the history of transactions involving the reserve.

  Objects in the transaction history have the following format:

  :>jsonarr string type: either the string "WITHDRAW" or the string "DEPOSIT"
  :>jsonarr object amount: the amount_ that was withdrawn or deposited
  :>jsonarr object wire: a JSON object with the wiring details (specific to the banking system in use), present in case the `type` was "DEPOSIT"
  :>jsonarr base32 signature: signature_ (binary-only) made with purpose `TALER_SIGNATURE_WALLET_RESERVE_WITHDRAW` made with the reserve's public key over the original "WITHDRAW" request, present if the `type` was "WITHDRAW"

  **Error Response: Unknown reserve**

  :status 404 Not Found: The withdrawal key does not belong to a reserve known to the mint.
  :resheader Content-Type: application/json
  :>json string error: the value is always "Reserve not found"
  :>json string parameter: the value is always "withdraw_pub"


.. http:post:: /withdraw/sign

  Withdraw a coin of the specified denomination.  Note that the client should commit all of the request details (including the private key of the coin and the blinding factor) to disk before (!) issuing this request, so that it can recover the information if necessary in case of transient failures (power outage, network outage, etc.).

  :reqheader Content-Type: application/json
  :<json base32 denom_pub: denomination public key (RSA), specifying the type of coin the client would like the mint to create.
  :<json base32 coin_ev: coin's blinded public key, should be (blindly) signed by the mint's denomination private key
  :<json base32 reserve_pub: public (EdDSA) key of the reserve that the coin should be withdrawn from (the total amount deducted will be the coin's value plus the withdrawl fee as specified with the denomination information)
  :<json object reserve_sig: EdDSA signature_ (binary-only) of purpose `TALER_SIGNATURE_WALLET_RESERVE_WITHDRAW` created with the reserves's public key

  **Success Response: OK**:

  :status 200 OK: The request was succesful.  Note that repeating exactly the same request will again yield the same response, so if the network goes down during the transaction or before the client can commit the coin signature_ to disk, the coin is not lost.
  :resheader Content-Type: application/json
  :>json base32 ev_sig: The RSA signature_ over the `coin_ev`, affirms the coin's validity after unblinding.

  **Error Response: Insufficient funds**:

  :status 402 Payment Required: The balance of the reserve is not sufficient to withdraw a coin of the indicated denomination.
  :resheader Content-Type: application/json
  :>json string error: the value is "Insufficient funds"
  :>json object balance: a JSON object with the current amount_ left in the reserve
  :>json array history: a JSON list with the history of the reserve's activity, in the same format as returned by /withdraw/status.

  **Error Response: Invalid signature**:

  :status 401 Unauthorized: The signature is invalid.
  :resheader Content-Type: application/json
  :>json string error: the value is "invalid signature"
  :>json string paramter: the value is "reserve_sig"

  **Error Response: Unknown key**:

  :status 404 Not Found: The denomination key or the reserve are not known to the mint.  If the denomination key is unknown, this suggests a bug in the wallet as the wallet should have used current denomination keys from /keys.  If the reserve is unknown, the wallet should not report a hard error (yet) but instead simply wait (for like a day!) as the wire transaction might simply not yet have completed and might be known to the mint in the near future.  In this case, the wallet should repeat the exact same request later again (using exactly the same blinded coin).
  :resheader Content-Type: application/json
  :>json string error: "unknown entity referenced"
  :>json string parameter: either "denom_pub" or "reserve_pub"


--------------------
Deposit
--------------------

Deposit operations are requested by a merchant during a transaction. For the deposit operation, the merchant has to obtain the deposit permission for the coin from the owner of the coin (the merchant's customer).  When depositing a coin, the merchant is credited an amount specified in the deposit permission (which may be a fraction of the total coin's value) minus the deposit fee as specified by the coin's denomination.


.. _deposit:
.. http:POST:: /deposit

  Deposit the given coin and ask the mint to transfer the given amount to the merchants bank account.  This API is used by the merchant to redeem the digital coins.  The request should contain a JSON object with the following fields:

  :reqheader Content-Type: application/json
  :<json object f: the amount_ to be deposited, can be a fraction of the coin's total value
  :<json object `wire`: the merchant's account details. This must be a JSON object whose format must correspond to one of the supported wire transfer formats of the mint.  See :ref:`wireformats`
  :<json base32 H_wire: SHA-512 hash of the merchant's payment details from `wire` (yes, strictly speaking redundant, but useful to detect inconsistencies)
  :<json base32 H_contract: SHA-512 hash of the contact of the merchant with the customer (further details are never disclosed to the mint)
  :<json base32 coin_pub: coin's public key (ECDHE and ECDSA)
  :<json base32 denom_pub: denomination (RSA) key with which the coin is signed
  :<json base32 ub_sig: mint's unblinded RSA signature_ of the coin
  :<json date timestamp: timestamp when the contract was finalized, must match approximately the current time of the mint
  :<json int transaction_id: 64-bit transaction id for the transaction between merchant and customer
  :<json base32 merchant_pub: the EdDSA public key of the merchant (used to identify the merchant for refund requests)
  :<json date refund_deadline: date until which the merchant can issue a refund to the customer via the mint (can be zero if refunds are not allowed)
  :<json base32 coin_sig: the ECDSA signature_ (binary-only) made with purpose `TALER_SIGNATURE_WALLET_COIN_DEPOSIT` made by the customer with the coin's private key.

  The deposit operation succeeds if the coin is valid for making a deposit and has enough residual value that has not already been deposited, refreshed or locked.

  **Success response: OK**

  :status 200: the operation succeeded, the mint confirms that no double-spending took place.
  :resheader Content-Type: application/json
  :>json string status: the string constant `DEPOSIT_OK`
  :>json object sig: signature_ (JSON object) with purpose `TALER_SIGNATURE_MINT_CONFIRM_DEPOSIT` using a current signing key of the mint affirming the successful deposit and that the mint will transfer the funds after the refund deadline (or as soon as possible if the refund deadline is zero).

  **Failure response: Double spending**

  :status 403: the deposit operation has failed because the coin has insufficient (unlocked) residual value; the request should not be repeated again with this coin.
  :resheader Content-Type: application/json
  :>json string error: the string "insufficient funds"
  :>json object history: a JSON array with the transaction history for the coin

  The transaction history contains entries of the following format:

  :>jsonarr string type: either "deposit" or "melt" (in the future, also "lock")
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



------------------
Refreshing
------------------

Refreshing creates `n` new coins from `m` old coins, where the sum of denominations of the new coins must be smaller than the sum of the old coins' denominations plus melting (refresh) and withdrawl fees charged by the mint.  The refreshing API can be used by wallets to melt partially spent coins, making transactions with the freshly minted coins unlinkabe to previous transactions (by anyone except the wallet itself).

However, the new coins are linkable from the private keys of all old coins using the /refresh/link request.  While /refresh/link must be implemented by the mint to achieve certain security properties (taxability), wallets do not really ever need that part of the API during normal operation.

.. _refresh:
.. http:post:: /refresh/melt

  "Melt" coins.  Invalidates the coins and prepares for minting of fresh coins.  Taler uses a global parameter `kappa` (currently always 3) for the cut-and-choose component of the protocol (this request is the commitment for the cut-and-choose).  Thus, various arguments are given `kappa`-times in this step.

  The request body must contain a JSON object with the following fields:

  :<json array new_denoms: List of `n` new denominations to order. Each entry must be a base32_ encoded RSA public key corresponding to the coin to be minted.
  :<json array melt_coins: List of `m` coins to melt.
  :<json array coin_evs: For each of the `n` new coins, `kappa` coin blanks (2D array)
  :<json array transfer_pubs: For each of the `m` old coins, `kappa` transfer public keys (2D-array of ephemeral ECDHE keys)
  :<json array secret_encs: For each of the `m` old coins, `kappa` link encryptions with an ECDHE-encrypted SHA-512 hash code.  The ECDHE encryption is done using the private key of the respective old coin and the corresponding transfer public key.  Note that the SHA-512 hash code must be the same across all coins, but different across all of the `kappa` dimensions.  Given the private key of a single old coin, it is thus possible to decrypt the respective `secret_encs` and obtain the SHA-512 hash that was used to symetrically encrypt the `link_encs` of all of the new coins.
  :<json array link_encs: For each of the `n` new coins, `kappa` (symmetric) encryptions of the ECDSA/ECDHE-private key of the new coins and the corresponding blinding factor, encrypted using the corresponding SHA-512 hash that is encrypted in `secret_encs`.

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
  :<json base32 mint_sig: Signature_ with purpose `TALER_SIGNATURE_MINT_CONFIRM_MELT` whereby the mint affirms the successful melt and confirming the `noreveal_index`

  **Error Response: Invalid signature**:

  :status 401 Unauthorized: One of the signatures is invalid.
  :resheader Content-Type: application/json
  :>json string error: the value is "invalid signature"
  :>json string paramter: the value is "confirm_sig" or "denom_sig", depending on which signature was deemed invalid by the mint

  **Error Response: Precondition failed**:

  :status 403 Forbidden: The operation is not allowed as (at least) one of the coins has insufficient funds.
  :resheader Content-Type: application/json
  :>json string error: the value is "insufficient funds"
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
  :>json array ev_sigs: List of the mint's blind (RSA) signatures on the new coins.

  **Failure Response: Conflict**

  :status 409 Conflict: There is a problem between the original commitment and the revealed private keys.
  :resheader Content-Type: application/json
  :>json string error: the value is "commitment violation"
  :>json int offset: offset of in the array of `kappa` commitments where the error was detected
  :>json int index: index of in the with respect to the melted coin where the error was detected
  :>json string object: name of the entity that failed the check (i.e. "transfer key")

  .. note::

     Further proof of the violation will need to be added to this response in the future. (#3712)

.. http:get:: /refresh/link

  Link the old public key of a melted coin to the coin(s) that were minted during the refresh operation.

  :query coin_pub: melted coin's public key

  **Success Response**

  :status 200 OK: All commitments were revealed successfully.
  :>json base32 transfer_pub: transfer public key corresponding to the `coin_pub`, used to (ECDHE) decrypt the `secret_enc` in combination with the private key of `coin_pub`.
  :>json base32 secret_enc: ECDHE-encrypted link secret that, once decrypted, can be used to decrypt/unblind the `new_coins`.
  :>json array new_coins: array with (encrypted/blinded) information for each of the coins minted in the refresh operation.

  The `new_coins` array contains the following fields:

  :>jsonarr base32 link_enc: Encrypted private key and blinding factor information of the fresh coin
  :>jsonarr base32 denom_pub: Public key of the minted coin (still blind).
  :>jsonarr base32 ev_sig: Mint's signature over the minted coin (still blind).

  **Error Response: Unknown key**:

  :status 404 Not Found: The mint has no linkage data for the given public key, as the coin has not (yet) been involved in a refresh operation.
  :resheader Content-Type: application/json
  :>json string error: "unknown entity referenced"
  :>json string parameter: will be "coin_pub"


--------------------
Locking
--------------------

Locking operations can be used by a merchant to ensure that a coin remains exclusively reserved for the particular merchant (and thus cannot be double-spent) for a certain period of time.  For locking operation, the merchant has to obtain a lock permission for a coin from the coin's owner.

  .. note::

     Locking is currently not implemented (#3625), this documentation is thus rather preliminary and subject to change.

.. http:GET:: /lock

  Lock the given coin which is identified by the coin's public key.

  :query C: coin's public key
  :query K: denomination key with which the coin is signed
  :query ubsig: mint's unblinded signature of the coin
  :query t: timestamp_ indicating the lock expire time
  :query m: transaction id for the transaction between merchant and customer
  :query f: the maximum amount_ for which the coin has to be locked
  :query M: the public key of the merchant
  :query csig: the signature made by the customer with the coin's private key over
               the parameters `t`, `m`, `f`, `M` and the string `"LOCK"`

  The locking operation may succeed if the coin is not already locked or a
  previous lock for the coin has already expired.

  **Success response**

  :status 200: the operation succeeded

  The mint responds with a JSON object containing the following fields:

  :>json string status: The string constant `LOCK_OK`
  :>json string C: the coin's public key
  :>json integer t: timestamp_ indicating the lock expire time
  :>json string m: transaction id for the transaction between merchant and customer
  :>json object f: the maximum amount_ for which the coin has to be locked
  :>json string M: the public key of the merchant
  :>json string sig: the signature made by the mint with the corresponding
           coin's denomination key over the parameters `status`, `C`, `t`, `m`,
           `f`, `M`

  The merchant can then save this JSON object as a proof that the mint has
  agreed to transfer a maximum amount equalling to the locked amount upon a
  successful deposit request (see /deposit).

  **Failure response**

  :status 403: the locking operation has failed because the coin is already
               locked or already refreshed and the same request should not be
               repeated as it will always fail.

  In this case the response contains a proof that the given coin is already
  locked ordeposited.

  If the coin is already locked, then the response contains the existing lock
  object rendered as a JSON object with the following fields:

  :>json string status: the string constant `LOCKED`
  :>json string C: the coin's public key
  :>json integer t: the expiration time of the existing lock
  :>json string m: the transaction ID which locked the coin
  :>json object f: the amount_ locked for the coin
  :>json string M: the public key of the merchant who locked the coin
  :>json string csig: the signature made by the customer with the coin's private
    key over the parameters `t`, `m`, `f` and `M`

  If the coin has already been refreshed then the mint responds with a JSON
  object with the following fields:

  :>json string status: the string constant `REFRESHED`

  * ... TBD

  :status 404: the coin is not minted by this mint, or it has been expired
  :status 501: the request or one of the query parameters are not valid and the
               response body will contain an error string explaining why they are
               invalid
  :status 503: the mint is currently unavailable; the request can be retried after
               the delay indicated in the Retry-After response header

  In these failures, the response contains an error string describing the reason
  why the request has failed.

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



===========================
Binary Blob Specification
===========================

  .. note::

     This section largely corresponds to the definitions in taler_signatures.h.  You may also want to refer to this code, as it offers additional details on each of the members of the structs.

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

All elliptic curve operations are on Curve25519.  Public and private keys are thus 32 bytes, and signatures 64 bytes.  For hashing (including HKDFs), Taler uses 512-bit hash codes (64 bytes).

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
     uint8_t ecdsa_pub[32];
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
     uint8_t ecdsa_pub[32];
     uint8_t ecdhe_pub[32];
   };

   union TALER_CoinSpendPrivateKeyP {
     uint8_t ecdsa_priv[32];
     uint8_t ecdhe_priv[32];
   };

   struct TALER_CoinSpendSignatureP {
     uint8_t ecdsa_signature[64];
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

------------------------
Signatures
------------------------

EdDSA and ECDSA signatures are always made over (the hash of) a block of the same generic format, the `struct SignedData` given below.  In our notation, the type of a field can depend on the value of another field. For the following message, the length of the `payload` array must match the value of the `size` field:

.. sourcecode:: c

  struct SignedData {
    uint32_t size;
    uint32_t purpose;
    uint8_t payload[size - sizeof (struct SignedData)];
  };

The `purpose` field in `struct SignedData` is used to express the context in which the signature is made, ensuring that a signature cannot be lifted from one part of the protocol to another.  The various `purpose` constants are defined in `taler_signatures.h`.  The `size` field prevents padding attacks.

In the subsequent messages, we use the following notation

.. sourcecode:: c

  signed (purpose = SOME_CONSTANT) {
    FIELDS
  } msg;

for signed data (contained in `FIELDS`) with the given purpose.  The `size` field of the corresponding `struct SignedData` is determined by the size of `FIELDS`.

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
    struct TALER_MasterSignatureP signature;
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
      struct GNUNET_HashCode hc; /* FIXME: #3739 */
    }
  };

  struct TALER_DenominationKeyValidityPS {
    struct TALER_MasterSignatureP signature;
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
