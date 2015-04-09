========================
The Mint JSON API
========================

-------
General
-------

  This section describes how certain types of values are
  represented throughout the API.

  * **Timestamps**:
    Timestamps are represented in JSON as a string literal `"\\/Date(x)\\/"`, where `x` is the decimal representation
    of the number of milliseconds past the Unix Epoch (January 1, 1970).  The escaped slash (`\\/`) is interpreted in JSON simply
    as a normal slash, but distinguishes the timestamp from a normal string literal.
  * **Public key**: Public keys are represented using the Ed25519 standard
    compact format (256 bits), converted to Base32Hex (RFC 4648) for
    transmission.
  * **Signatures**: Signatures are transmitted as a JSON object with the following fields:

    * `purpose`: a unique number to state the context in which the signature is to be used in
    * `size`: the number of bytes that were hashed (using SHA-512) to create the signature; note that signatures are always done over a packed, binary representation of the data and not the JSON representations.
    * `r`: R value of the signature (256 bit, in Base32Hex).
    * `s`: S value of the signature (256 bit, in Base32Hex).

    The specific signature scheme in use (blind signature, EdDSA)
    depends on the context and can be derived from the purpose.

  * **Denominations**: Currency denominations are expressed as a JSON object with the following fields:

    * `currency`: name of the currency using ISO 4217 currency code
    * `value`: unsigned 32 bit value in the currency, note that "1" here would correspond to 1 EUR or 1 USD (depending on `currency`), not 1 cent.
    * `fraction`: unsigned 32 bit fractional value (to be added to `value`) representing an additional currency fraction, in units of 1 in one million (1/1000000) of the base currency value.  For example, a fraction of 50000000 (50 million) would correspond to 50 cents.

  * **Large numbers**: Large numbers (typically 256 bits), such as blinding factors and private keys, are transmitted in Base32Hex encoding.

-------------------
Obtaining Mint Keys
-------------------
.. http:get:: /keys

  Get a list of all denomination keys offered by the bank,
  as well as the bank's current online signing key.

  **Response on Success**

  On success, the mint responds with HTTP status code `200 OK`.
  The body of the response contains a JSON object with the following fields:

  * `denoms`: A JSON list of denomination descriptions.  Described below in detail.
  * `denoms_date`: The date when the denomination keys were last updated.
  * `denoms_sig`: A signature over the list of denomination keys and the date.
  * `signing_key`: The mint's current signing key.  Described below in detail.

  A denomination description is a JSON object with the following fields:

  * `value`: Value of the denomination.  An integer, to be interpreted
    relative to the currency provided by the mint.
  * `stamp_start`: timestamp indicating when the denomination key becomes valid.
  * `stamp_expire_withdraw`: timestamp indicating when the denomination key can't
    be used anymore to withdraw new coins.
  * `stamp_expire_deposit`: timestamp indicating when coins of this
    denomination become invalid.
  * `key`: Public key for the denomination.
  * `kappa`: Security parameter for refreshing.
  * `sig`: Signature over the expiration dates, value and the key, created
    with the mint's master key.

  The `signing_key` field contains a JSON object with the following fields:

  * `key`: The actual mint's signing public key.
  * `stamp_expire`: Expiration date for the signing key.
  * `sig`:  Signature over the `key` and `stamp_expire` by the mint master key.

  .. note::

    Both the individual denominations *and* the denomination list is signed,
    allowing customers to prove that they received an inconsistent list.


------------------
Withdrawal
------------------

When transfering money to the mint via SEPA, the mint records
a *purse*, which stores the remaining money from the transaction and the
customer's withdrawal key for the purse.


.. http:get:: /withdraw/status

  Request information about a purse, including the blinding key that is necessary to
  withdraw a coin.

  :query withdraw_pub: Withdrawal key identifying the purse.

  **Success Response**

  The mint responds with a JSON object containing the following fields:

  * `balance`: Money left in this purse. A list of denominations (in case multiple currencies happen to be in the same purse).
  * `expiration`: Expiration date of the purse.
  * `sig`: Signature of the mint.

  **Error Responses**

  :status 400 Bad Request: The `withdraw_pub` parameter is missing or malformed.

  :status 404 Not Found: The withdrawal key does not belong to a purse known to the mint.


.. http:get:: /withdraw/sign

  Withdraw a coin with a given denomination key.

  :query denom: denomination key
  :query blank: coin's blinded public key
  :query withdraw_pub: withdraw / purse public key
  :query sig: signature, created with the withdrawal key

  **Success Response**:

  :status 200 OK: The request was succesful.

  The response body of a succesful request contains a JSON object with the following fields:

  * `bcsig`: The blindly signed coin.

  **Error Responses**:

  :status 400 Bad Request: A request parameter is missing or malformed.

  :status 402 Payment Required: The balance of the purse is not sufficient to withdraw a coin of the
    indicated denomination.

  :status 401 Unauthorized: The signature is invalid.

  :status 404 Not Found: The blinding key is not known to the mint.

  :status 409 Conflict: A sign request for the same `big_r` has already been sent,
    but with a different `denom` or `blank`.


------------------
Refreshing
------------------

Refreshing creates `n` new coins from `m` old coins, where the sum
of denominations of the new coins must be smaller than the sum of
the old coins' denominations plus a refreshing fee imposed by the mint.

The new coins are linkable from all old coins.

In order group multipe coins, the customer generates a refreshing session key.

.. _refresh:
.. http:post:: /refresh/melt

  "Melt" coins.  Invalidates the coins and prepares for minting of fresh coins.

  The request body must contain a JSON object with the following fields:

  :<json int kappa: dimension `kappa` for the cut-and-choose protocol
  :<json array new_denoms: List of `n` new denominations to order.
  :<json string session_pub: Session public key
  :<json string session_sig: Signature over the whole commitment
  :<json array coin_evs: For each of the `n` new coin, `kappa` coin blanks.
  :<json array transfer_pubs: List of `m` transfer public keys
  :<json array new_encs: For each of the `n` new coins, a list of encryptions (one for each cnc instance)
  :<json array secret_encs: For each of the `kappa` cut-and-choose instances, the linking encryption for each of the `m` old coins
  :<json array melt_coins: List of `m` coins to melt.

  The `melt_coins` field is a list of JSON objects with the following fields:

  :<json string coin_pub: Coin public key
  :<json string coin_sig: Signature by the coin over the session public key
  :<json string denom_pub: Denomination public key
  :<json string denom_sig: Signature over the coin public key by the denomination
     key
  :<json string value: Amount of the value of the coin that should be melted as part of this refresh operation

  **Success Response**

    :status 200 OK: The request was succesful. The response body contains a JSON object with the following fields:
  * `noreveal_index`: Which of the `kappa` indices does the client not have to reveal.
  * `mint_sig`: Signature of the mint affirming the successful melt and confirming the `noreveal_index`


  **Error Responses**

  :status 400 Bad Request: A request parameter is missing or malformed.

  :status 403 Forbidden: Either a `coin_sig` or the `session_sig` is invalid.

  :status 404 Not Found: The mint does not know one of the denomination keys `denom_pub` given in the request.

  :status 409 Conflict: A coin `coin` has insufficient funds.  Request body contains a JSON object with
  the following fields:

     :<fixme: Details showing that `coin` has insufficient funds to satisfy the request.

  :status 412 Precondition failed: The client's choice of `kappa` is outside of the acceptable range.


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

  :status 400 Bad Request: Request parameters incomplete or malformed.
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

  :status 400 Bad Request: Request parameters incomplete or malformed.
  :status 403 Forbidden: The signature `csig` is invalid.
  :status 404 Not Found: The coin public key is not known to the bank, or was
                         not involved in a refresh.



--------------------
Locking and Deposit
--------------------

Locking and Deposit operations are requested by a merchant during a transaction.
For locking operation, the merchant has to obtain a lock permission for a coin
from the customer.  Similarly, for deposit operation the merchant has to obtain
deposit permission for the coin from the customer.

.. http:GET:: /lock

  Lock the given coin which is identified by the coin's public key.

  :query C: coin's public key
  :query K: denomination key with which the coin is signed
  :query ubsig: mint's unblinded signature of the coin
  :query t: timestamp indicating the lock expire time
  :query m: transaction id for the transaction between merchant and customer
  :query f: the maximum amount for which the coin has to be locked
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
  :>json integer t: timestamp indicating the lock expire time
  :>json string m: transaction id for the transaction between merchant and customer
  :>json object f: the maximum amount for which the coin has to be locked
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
  :>json object f: the amount locked for the coin
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

  :json obj retract_perm: If the coin was claimed as a refund, this
    field should contain the retract permission obtained from the merchant,
    otherwise it should not be present.  For details about the object type, see
     :ref:`Merchant API:retract<retract>`.
  :json string retract_value: Value returned due to the retraction.


.. _deposit:
.. http:POST:: /deposit

  Deposit the given coin and ask the mint to transfer the given amount to the
  merchants bank account.  The request should contain a JSON object with the
  following fields:

  :<json string C: coin's public key
  :<json string K: denomination key with which the coin is signed
  :<json string ubsig: mint's unblinded signature of the coin
  :<json string type: the string constant `"DIRECT_DEPOSIT"` or `"INCREMENTAL_DEPOSIT"`
     respectively for direct deposit or incremental deposit type of interaction
     chosen by the customer and the merchant.
  :<json string m: transaction id for the transaction between merchant and customer
  :<json object f: the maximum amount for which the coin has to be locked
  :<json string M: the public key of the merchant
  :<json string H_a: the hash of the contract made between merchant and customer
  :<json string H_wire: the hash of the merchant's payment information `wire`
  :<json string csig: the signature made by the customer with the coin's private key over
     the parameters `type`, `m`, `f`, `M`, `H_a` and, `H_wire`
  :<json object `wire`: this should be a JSON object whose format should comply to one of the
     supported wire transfer formats.  See :ref:`wireformats`

  The deposit operation succeeds if the coin is valid for making a deposit and
  is not already deposited or refreshed.

  **Success response**

  :status 200: the operation succeeded

  The mint responds with a JSON object containing the following fields:

  :>json string status: the string constant `DEPOSIT_OK`
  :>json integer t: the current timestamp
  :>json string deposit_tx: the transaction identifier of the transfer transaction made by the
     mint to deposit money into the merchant's account
  :>json string sig: signature of the mint made over the parameters `status`, `t` and
     `deposit_tx`

  :status 202: the operation is accepted but will take a while to complete;
               check back later for its reponse

  This happens when the mint cannot immediately execute the SEPA transaction.
  The response contains the following fields as part of a JSON object:

  :>json string status: the string contant `DEPOSIT_QUEUED`
  :>json integer t: the current timestamp
  :>json integer retry: timestamp indicating when the result of the request will
             be made available
  :>json string sig: the signature of the mint made over the parameters
           `status`, `t`, and `retry`

  **Failure response**

  :status 403: the deposit operation has failed because the coin has previously
               been deposited or it has been already refreshed; the request
               should not be repeated again

  In case of failure due to the coin being already deposity, the response
  contains a JSON object with the following fields:

  :>json string status: the string constant `DEPOSITED`
  :>json string C: the coin's public key
  :>json string m: ID of the past transaction which corresponding to this deposit
  :>json object f: the amount that has been deposited from this coin
  :>json string M: the public key of the merchant to whom the deposit was earlier made
  :>json string H: the hash of the contract made between the merchant identified by `M`
         and the customer
  :>json string csig: the signature made by the owner of the coin with the coin's private
            key over the parameters `m`, `f`, `M`, `H` and the string `"DEPOSIT"`
  :>json integer t: the timestamp when the deposit was made
  :>json string deposit_tx: the transaction identifier of the SEPA transaction made by the
    mint to deposit money into the merchant's account

  In case if the coin has been already refreshed, the response contains a JSON
  object with the following fields:

  :>json string status: the string constant `REFRESHED`

  * ... TBD

  :status 404: the coin is not minted by this mint, or it has been expired
  :status 501: the request or one of the query parameters are not valid and the
               response body will contain an error string explaining why they are
               invalid
  :status 503: the mint is currently unavailable; the request can be retried after
               the delay indicated in the Retry-After response header

  In these failures the response contains an error string describing the reason
  why the request has failed.

===========================
Binary Blob Specification
===========================
This section specifies the binary representation of messages used in Taler's protocols.
The message formats are given in a C-style pseudocode notation.  In contrast to real C structs,
padding is always specified explicitly, and numeric values are little endian.

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

  struct PurseInformation {
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
