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

Refreshing creates `n` new coins from `m` old coins, where the sum of denominations of the new coins must be smaller than the sum of the old coins' denominations plus melting (refresh) and withdrawl fees charged by the mint.  The refreshing API can be used by wallets to ensure that partially spent coins are refreshed, making transactions with the refreshed coins unlinkabe to previous transactions (by anyone except the wallet itself).

However, the new coins are linkable from the private keys of all old coins using the /refresh/link request.  While /refresh/link must be implemented by the mint to achieve certain security properties, wallets do not really ever need it during normal operation.

  .. note::

     This section still needs to be updated to reflect the latest implementation (where two requests were combined into one).

.. _refresh:
.. http:post:: /refresh/melt

  "Melt" coins.  Invalidates the coins and prepares for minting of fresh coins.

  The request body must contain a JSON object with the following fields:

  :<json array new_denoms: List of `n` new denominations to order.
  :<json string session_pub: Session public key
  :<json string session_sig: Signature_ over the whole commitment
  :<json array coin_evs: For each of the `n` new coin, `kappa` coin blanks.
  :<json array transfer_pubs: List of `m` transfer public keys
  :<json array new_encs: For each of the `n` new coins, a list of encryptions (one for each cnc instance)
  :<json array secret_encs: For each of the `kappa` cut-and-choose instances, the linking encryption for each of the `m` old coins
  :<json array melt_coins: List of `m` coins to melt.

  The `melt_coins` field is a list of JSON objects with the following fields:

  :<json string coin_pub: Coin public key
  :<json string coin_sig: Signature_ by the coin over the session public key
  :<json string denom_pub: Denomination public key
  :<json string denom_sig: Signature over the coin public key by the denomination
     key
  :<json object value: Amount_ of the value of the coin that should be melted as part of this refresh operation

  **Success Response**

  :status 200 OK: The request was succesful. The response body contains a JSON object with the following fields:
  :<json int noreveal_index: Which of the `kappa` indices does the client not have to reveal.
  :<json base32 mint_sig: Signature_ of the mint affirming the successful melt and confirming the `noreveal_index`


  **Error Responses**

  :status 401 Gone: The coin has insufficient value remaining.

  :<json fixme fixme: Details showing that `coin` has insufficient funds to satisfy the request.

  :status 403 Forbidden: Either a `coin_sig` or the `session_sig` is invalid.

  :status 404 Not Found: The mint does not know one of the denomination keys `denom_pub` given in the request.


     .. http:post:: /refresh/reveal

.. http:post:: /refresh/commit

  Commit values for the cut-and-choose in the refreshing protocol.
  The request body must be a JSON object with the following fields:


  **Success Response**

  :status 202 Accepted: The mint accepted the commitment, but still needs more commitments.

  The response body contains a JSON object with the following fields:
  TODO..

  **Error Response**

  :status 403 Forbidden: The signature `sig` is invalid.
  :status 404 Not Found: The mint does not know the blind key `blindkey` given
    in the request.

.. http:post:: /refresh/reveal

  Reveal previously commited values to the bank.  Request body contains a JSON object with
  the following fields:

  :<json string session_pub: The session public key
  :<json array transfer_privs: Revealed transfer private keys

  **Success Response**

  :status 200 OK: All commitments were revealed successfully.  The mint responds
                  with a JSON of the following type

  :>json array bcsig_list: List of the mint's blind signatures on the ordered
                           new coins.

  :status 403 Forbidden: The signature `ssig` is invalid.
  :status 404 Not Found: The blinding key is not known to the mint.
  :status 409 Conflict: The revealed value was inconsistent with the commitment.

     * `original_info`: signed information from /refresh/melt that conflicts with the current /refresh/reveal request.

  :status 410 Gone: A conflict occured, the money is gone.

     * `conflict_info`: proof of previous attempt by the client to cheat


.. http:get:: /refresh/link

  Link an old key to the refreshed coin.

  :query coin: coin public key
  :query csig: signature by the coin

  **Success Response**

  :status 200 OK: All commitments were revealed successfully.

  The mint responds with a JSON object containing the following fields:

  :>json string `link_secret_enc`: ...
  :>json array enc_list: List of encrypted values for the result coins.
  :>json array tpk_list: List of transfer public keys for the new coins.
  :>json array bscoin_list: List of blind signatures on the new coins.

  **Error Responses**

  :status 403 Forbidden: The signature `csig` is invalid.
  :status 404 Not Found: The coin public key is not known to the bank, or was
                         not involved in a refresh.



--------------------
Locking
--------------------

Locking operations can be used by a merchant to ensure that a coin
remains exclusively reserved for the particular merchant (and thus
cannot be double-spent) for a certain period of time.  For locking
operation, the merchant has to obtain a lock permission for a coin
from the coin's owner.

  .. note::

     Locking is currently not implemented (#3625), this documentation is thus rather preliminary.

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

.. _restract:
.. http:POST:: /retract

  Undo deposit of the given coin, restoring its value.  The request
  should contain a JSON object with the following fields:

  :>json obj retract_perm: If the coin was claimed as a refund, this field should contain the retract permission obtained from the merchant, otherwise it should not be present.  For details about the object type, see :ref:`Merchant API:retract<retract>`.
  :>json string retract_value: Value returned due to the retraction.



===========================
Binary Blob Specification
===========================

  .. note::

     This section still needs to be updated to reflect the latest implementation.  See "taler_signatures.h" instead in the meantime.

This section specifies the binary representation of messages used in Taler's protocols. The message formats are given in a C-style pseudocode notation.  In contrast to real C structs, padding is always specified explicitly, and numeric values are in network byte order (big endian).

.. sourcecode:: c

  struct PublicKey {
    uint8_t v[32];
  };

  struct PrivateKey {
    uint8_t d[32];
  };

  struct Timestamp {
    uint64_t val_us;
  };

  struct Signature {
    uint8_t rs[64];
  };

In our notation, the type of a field can depend on the value of another field.
For the following message, the length of the `payload` array must match the value
of the `size` field.

.. sourcecode:: c

  struct SignedData {
    uint32_t size;
    uint32_t purpose;
    uint8_t payload[size];
  };

  struct Denomination {
    uint32_t value;
    uint32_t fraction;
    uint8_t currency_code[4];
  };


In the subsequent messages, we use the following notation

.. sourcecode:: c

  signed (purpose = SOME_CONSTANT) {
    FIELDS
  } msg;

for signed data (contained in `FIELDS`) with the given purpose.  The `size` field of the
corresponding `struct SignedData` is determined by the size of `FIELDS`.

.. sourcecode:: c

  struct CoinIssue {
    // signed by the master key
    signed (purpose = COIN_ISSUE) {
      struct PublicKey key;
      struct Timestamp stamp_expire_withdraw;
      struct Timestamp stamp_expire_deposit;
      struct Timestamp stamp_start;
      uint32_t kappa;
      uint32_t padding;
      struct Denomination denom;
    };
  };

  struct CoinIssueList {
    // signed by the master key
    signed (purpose = COIN_ISSUE_LIST) {
      uint32_t n;
      struct Timestamp stamp_issue;
      struct CoinIssue coins[n];
      struct PublicKey mint_signing_key;
    };
  };

  struct ReserveInformation {
    // signed with the mint signing key
    signed (purpose = PURSE_INFO) {
      struct PublicKey big_r;
      struct Timestamp stamp_expire_purse;
      struct Denomination balance;
      struct Timestamp purse_expiration;
    };
  };

  struct BlindBlankCoin {
    TODO todo;
  };

  struct BlindSignedCoin {
    TODO todo;
  };

  struct SignedCoin {
    TODO todo;
  };

  struct WithdrawRequest {
    // signed with the withdrawal key
    signed (purpose = WITHDRAW_REQUEST) {
      struct PublicKey denom_key;
      struct PublicKey big_r;
      struct BlindBlankCoin blank;
    };
  };

  struct MeltRequest {
    // signed with the coin key
    signed (purpose = MELT_COIN) {
      // signed with the session key
      signed (purpose = MELT_SESSION) {
        SignedCoin coin;
        PublicKey session;
      };
    };
  };

  struct OrderRequest {
    // signed with the session key
    signed (purpose = REFRESH_REQUEST) {
      struct PublicKey denom_key;
      struct PublicKey session;
    };
  };


In the following message, `n` is the number of coins
melted by the customer, and `KAPPA` is a security parameter determined
by the new coin's denomination.

.. sourcecode:: c

  struct OrderResponse {
    signed (purpose = ORDER_RESPONSE) {
      Denomination rest_balance;
      struct {
        PublicKey big_r;
        PublicKey old_coin;
      } challenges[KAPPA * n];
    };
  };

  struct BlindFactor {
    TODO todo;
  };

The `encrypted` block denotes an encrypted message.

.. sourcecode:: c

  struct RefreshEnc {
    encrypted {
      struct BlindFactor bf;
      struct PrivateKey tsk;
      struct PrivateKey csk;
    };
  };

  struct CommitRequest {
    signed (purpose = REFRESH_COMMIT) {
      struct PublicKey tpk;
      struct BlindBlankCoin blank;
      struct RefreshEnc enc;
    };
  };

  struct RevealRequest {
    // FIXME: does this need to be signed?
    struct PublicKey big_r;
    struct BlindFactor bf;
    struct PrivateKey csk;
  };

  struct LinkRequest {
    signed (purpose = REFRESH_LINK) {
      struct PublicKey coin;
    };
  };

  struct LinkResponse {
    uint16_t n;
    struct BlindSignedCoin coins[n];
    struct PublicKey tpks[n];
    struct RefreshEnc encs[n];
  };
