..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016 GNUnet e.V. and INRIA
  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.
  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Christian Grothoff
  @author Marcello Stanisci

.. _http-common:

=================================
Common Taler HTTP API Conventions
=================================


-------------------------
HTTP Request and Response
-------------------------

Certain response formats are common for all requests. They are documented here
instead of with each individual request.  Furthermore, we note that clients may
theoretically fail to receive any response.  In this case, the client should
verify that the Internet connection is working properly, and then proceed to
handle the error as if an internal error (500) had been returned.

.. http:any:: /*


  **Request:**

  Unless specified otherwise, HTTP requests that carry a message body must
  have the content type `application/json`.

  :reqheader Content-Type: application/json

  **Response:**

  :resheader Content-Type: application/json
  :status 200: The request was successful.
  :status 500 Internal server error:
    This always indicates some serious internal operational error of the exchange,
    such as a program bug, database problems, etc., and must not be used for
    client-side problems.  When facing an internal server error, clients should
    retry their request after some delay.  We recommended initially trying after
    1s, twice more at randomized times within 1 minute, then the user should be
    informed and another three retries should be scheduled within the next 24h.
    If the error persists, a report should ultimately be made to the auditor,
    although the auditor API for this is not yet specified.  However, as internal
    server errors are always reported to the exchange operator, a good operator
    should naturally be able to address them in a timely fashion, especially
    within 24h.  When generating an internal server error, the exchange responds with
    a JSON object containing the following fields:
  :status 400 Bad Request: One of the arguments to the request is missing or malformed.

  Unless specified otherwise, all error status codes (4xx and 5xx) have a message
  body with an `ErrorDetail`_ JSON object.

  **Details:**

  .. _ErrorDetail:
  .. _tsref-type-ErrorDetail:
  .. code-block:: tsref

    interface ErrorDetail {

      // Numeric error code unique to the condition. See "taler_error_codes.h".
      code: number;

      // Human-readable description of the error, i.e. "missing parameter", "commitment violation", ...
      // The other arguments are specific to the error value reported here.
      error: string;

      // Hint about error nature
      hint?: string;

      // Name of the parameter that was bogus (if applicable)
      parameter?: string;

      // Path to the argument that was bogus (if applicable)
      path?: string;

      // Offset of the argument that was bogus (if applicable)
      offset?: string;

      // Index of the argument that was bogus (if applicable)
      index?: string;

      // Name of the object that was bogus (if applicable)
      object?: string;

      // Name of the currency thant was problematic (if applicable)
      currency?: string;

      // Expected type (if applicable).
      type_expected?: string;

      // Type that was provided instead (if applicable).
      type_actual?: string;
    }


.. _encodings-ref:

----------------
Common encodings
----------------

This section describes how certain types of values are represented throughout the API.

.. _base32:
.. _tsref-type-Base32:

Binary Data
^^^^^^^^^^^

Binary data is generally encoded using Crockford's variant of Base32
(http://www.crockford.com/wrmg/base32.html), except that "U" is not excluded
but also decodes to "V" to make OCR easy.  We will still simply use the JSON
type "base32" and the term "Crockford Base32" in the text to refer to the
resulting encoding.

.. _tsref-type-HashCode:

Hash codes
^^^^^^^^^^
Hashcodes are strings representing base32 encoding of the respective hashed
data. See `base32`_.

Large numbers
^^^^^^^^^^^^^

Large numbers such as RSA blinding factors and 256 bit  keys, are transmitted
as other binary data in Crockford Base32 encoding.


.. _tsref-type-Timestamp:

Timestamps
^^^^^^^^^^

Timestamps are represented in JSON as a string literal `"\\/Date(x)\\/"`,
where `x` is the decimal representation of the number of seconds past the
Unix Epoch (January 1, 1970).  The escaped slash (`\\/`) is interpreted in
JSON simply as a normal slash, but distinguishes the timestamp from a normal
string literal.  We use the type "date" in the documentation below.
Additionally, the special strings "\\/never\\/" and "\\/forever\\/" are
recognized to represent the end of time.


.. _public\ key:

Keys
^^^^

.. _`tsref-type-EddsaPublicKey`:
.. _`tsref-type-EcdhePublicKey`:
.. _`tsref-type-EcdhePrivateKey`:
.. _`tsref-type-EddsaPrivateKey`:
.. _`tsref-type-CoinPublicKey`:

.. code-block:: tsref

   // EdDSA and ECDHE public keys always point on Curve25519 (FIXME does that hold for private
   // keys as well?) and represented
   // using the standard 256 bits Ed25519 compact format, converted to Crockford
   // `Base32`_.
   type EddsaPublicKey = string;
   type EddsaPrivateKey = string;

.. _`tsref-type-RsaPublicKey`:

.. code-block:: tsref

   // RSA public key converted to Crockford `Base32`_.
   type RsaPublicKey = string;

.. _blinded-coin:

Blinded coin
^^^^^^^^^^^^

.. _`tsref-type-CoinEnvelope`:

.. code-block:: tsref

  // Blinded coin's `public EdDSA key <eddsa-coin-pub>`_, `base32`_ encoded
  type CoinEnvelope = string;

.. _signature:

Signatures
^^^^^^^^^^

.. _`tsref-type-EddsaSignature`:

.. code-block:: tsref
  
  // EdDSA signatures are transmitted as 64-bytes `base32`_
  // binary-encoded objects with just the R and S values (base32_ binary-only)
  type EddsaSignature = string;


.. _`tsref-type-RsaSignature`:

.. code-block:: tsref
  
  // `base32`_ encoded RSA signature
  type RsaSignature = string;

.. _`tsref-type-BlindedRsaSignature`:

.. code-block:: tsref
  
  // `base32`_ encoded RSA blinded signature
  type BlindedRsaSignature = string;

.. _amount:

Amounts
^^^^^^^

Amounts of currency are expressed as a JSON object with the following fields:

.. _`tsref-type-Amount`:

.. code-block:: tsref

  interface Amount {
    // name of the currency using either a three-character ISO 4217 currency
    // code, or a regional currency identifier starting with a "*" followed by
    // at most 10 characters.  ISO 4217 exponents in the name are not supported,
    // although the "fraction" is corresponds to an ISO 4217 exponent of 6.
    currency: string;

    // unsigned 32 bit value in the currency, note that "1" here would
    // correspond to 1 EUR or 1 USD, depending on `currency`, not 1 cent.
    value: number;

    // unsigned 32 bit fractional value to be added to `value` representing
    // an additional currency fraction, in units of one millionth (1e-6)
    // of the base currency value.  For example, a fraction
    // of 500,000 would correspond to 50 cents.
    fraction: number;
  }


--------------
Binary Formats
--------------

  .. note::

     Due to the way of handling `big` numbers by some platforms (such as
     `JavaScript`, for example), wherever the following specification mentions
     a 64-bit value, the actual implementations are strongly advised to rely on
     arithmetic up to 53 bits.

  .. note::
     
     Taler uses `libgnunetutil` for interfacing itself with the operating system,
     doing crypto work, and other "low level" actions, therefore it is strongly
     connected with the `GNUnet project <https://gnunet.org>`_.

This section specifies the binary representation of messages used in Taler's
protocols. The message formats are given in a C-style pseudocode notation.
Padding is always specified explicitly, and numeric values are in network byte
order (big endian).

Amounts
^^^^^^^

Amounts of currency are always expressed in terms of a base value, a fractional
value and the denomination of the currency:

.. sourcecode:: c

  struct TALER_Amount {
    uint64_t value;
    uint32_t fraction;
    uint8_t currency_code[12]; // i.e. "EUR" or "USD"
  };
  struct TALER_AmountNBO {
    uint64_t value;            // in network byte order
    uint32_t fraction;         // in network byte order
    uint8_t currency_code[12];
  };


Time
^^^^

In signed messages, time is represented using 64-bit big-endian values,
denoting microseconds since the UNIX Epoch.  `UINT64_MAX` represents "never".

.. sourcecode:: c

  struct GNUNET_TIME_Absolute {
    uint64_t timestamp_us;
  };
  struct GNUNET_TIME_AbsoluteNBO {
    uint64_t abs_value_us__;       // in network byte order
  };

Cryptographic primitives
^^^^^^^^^^^^^^^^^^^^^^^^

All elliptic curve operations are on Curve25519.  Public and private keys are
thus 32 bytes, and signatures 64 bytes.  For hashing, including HKDFs, Taler
uses 512-bit hash codes (64 bytes).

.. sourcecode:: c

   struct GNUNET_HashCode {
     uint8_t hash[64];      // usually SHA-512
   };

.. _reserve-pub:
.. sourcecode:: c

   struct TALER_ReservePublicKeyP {
     uint8_t eddsa_pub[32];
   };

.. _reserve-priv:
.. sourcecode:: c

   struct TALER_ReservePrivateKeyP {
     uint8_t eddsa_priv[32];
   };

   struct TALER_ReserveSignatureP {
     uint8_t eddsa_signature[64];
   };

.. _merchant-pub:
.. sourcecode:: c

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

.. _sign-key-pub:
.. sourcecode:: c

   struct TALER_ExchangePublicKeyP {
     uint8_t eddsa_pub[32];
   };

.. _sign-key-priv:
.. sourcecode:: c

   struct TALER_ExchangePrivateKeyP {
     uint8_t eddsa_priv[32];
   };

.. _eddsa-sig:
.. sourcecode:: c

   struct TALER_ExchangeSignatureP {
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

.. _eddsa-coin-pub:
.. sourcecode:: c

   union TALER_CoinSpendPublicKeyP {
     uint8_t eddsa_pub[32];
     uint8_t ecdhe_pub[32];
   };

.. _coin-priv:
.. sourcecode:: c

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
     uint8_t key[sizeof (struct GNUNET_HashCode)];
   };

   struct TALER_EncryptedLinkSecretP {
     uint8_t enc[sizeof (struct TALER_LinkSecretP)];
   };

.. _Signatures:

Signatures
^^^^^^^^^^
Any piece of signed data, complies to the abstract data structure given below.

.. sourcecode:: c

  struct Data {
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    type1_t payload1;
    type2_t payload2;
    ...
  };

  /*From gnunet_crypto_lib.h*/
  struct GNUNET_CRYPTO_EccSignaturePurpose {
    /**
     * This field is used to express the context in
     * which the signature is made, ensuring that a
     * signature cannot be lifted from one part of the protocol
     * to another. See `src/include/taler_signatures.h` within the
     * exchange's codebase (git://taler.net/exchange)
     */
    uint32_t purpose;
    /**
     * This field equals the number of bytes being signed,
     * namely 'sizeof (struct Data)'
     */
    uint32_t size;
  };


The following list contains all the data structure that can be signed in
Taler. Their definition is typically found in `src/include/taler_signatures.h`,
within the :ref:`exchange's codebase <exchange-repo>`.

.. _TALER_WithdrawRequestPS:
.. sourcecode:: c

  struct TALER_WithdrawRequestPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_WALLET_RESERVE_WITHDRAW
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct TALER_ReservePublicKeyP reserve_pub;
    struct TALER_AmountNBO amount_with_fee;
    struct TALER_AmountNBO withdraw_fee;
    struct GNUNET_HashCode h_denomination_pub;
    struct GNUNET_HashCode h_coin_envelope;
  };

.. _TALER_DepositRequestPS:
.. sourcecode:: c

  struct TALER_DepositRequestPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_WALLET_COIN_DEPOSIT
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode h_contract;
    struct GNUNET_HashCode h_wire;
    struct GNUNET_TIME_AbsoluteNBO timestamp;
    struct GNUNET_TIME_AbsoluteNBO refund_deadline;
    uint64_t transaction_id;
    struct TALER_AmountNBO amount_with_fee;
    struct TALER_AmountNBO deposit_fee;
    struct TALER_MerchantPublicKeyP merchant;
    union TALER_CoinSpendPublicKeyP coin_pub;
  };

.. _TALER_DepositConfirmationPS:
.. sourcecode:: c

  struct TALER_DepositConfirmationPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_WALLET_CONFIRM_DEPOSIT
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode h_contract;
    struct GNUNET_HashCode h_wire;
    uint64_t transaction_id GNUNET_PACKED;
    struct GNUNET_TIME_AbsoluteNBO timestamp;
    struct GNUNET_TIME_AbsoluteNBO refund_deadline;
    struct TALER_AmountNBO amount_without_fee;
    union TALER_CoinSpendPublicKeyP coin_pub;
    struct TALER_MerchantPublicKeyP merchant;
  };

.. _TALER_RefreshMeltCoinAffirmationPS:
.. sourcecode:: c

  struct TALER_RefreshMeltCoinAffirmationPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_WALLET_COIN_MELT
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode session_hash;
    struct TALER_AmountNBO amount_with_fee;
    struct TALER_AmountNBO melt_fee;
    union TALER_CoinSpendPublicKeyP coin_pub;
  };

.. _TALER_RefreshMeltConfirmationPS:
.. sourcecode:: c

  struct TALER_RefreshMeltConfirmationPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_EXCHANGE_CONFIRM_MELT
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode session_hash;
    uint16_t noreveal_index;
  };

  struct TALER_ExchangeSigningKeyValidityPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_MASTER_SIGNING_KEY_VALIDITY
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct TALER_MasterPublicKeyP master_public_key;
    struct GNUNET_TIME_AbsoluteNBO start;
    struct GNUNET_TIME_AbsoluteNBO expire;
    struct GNUNET_TIME_AbsoluteNBO end;
    struct TALER_ExchangePublicKeyP signkey_pub;
  };

  struct TALER_ExchangeKeySetPS {
      /**
       * purpose.purpose = TALER_SIGNATURE_EXCHANGE_KEY_SET
       */
      struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
      struct GNUNET_TIME_AbsoluteNBO list_issue_date;
      struct GNUNET_HashCode hc;
  };

.. _TALER_DenominationKeyValidityPS:
.. sourcecode:: c

  struct TALER_DenominationKeyValidityPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_MASTER_DENOMINATION_KEY_VALIDITY
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
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
  };

.. _TALER_MasterWireDetailsPS:
.. sourcecode:: c

  struct TALER_MasterWireDetailsPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_MASTER_SEPA_DETAILS || TALER_SIGNATURE_MASTER_TEST_DETAILS
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode h_sepa_details;
  };

  struct TALER_DepositTrackPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_MASTER_SEPA_DETAILS || TALER_SIGNATURE_MASTER_TEST_DETAILS
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode h_contract;
    struct GNUNET_HashCode h_wire;
    uint64_t transaction_id;
    struct TALER_MerchantPublicKeyP merchant;
    struct TALER_CoinSpendPublicKeyP coin_pub;
  };

  /**
   * Format internally used for packing the detailed information
   * to generate the signature for /track/transfer signatures.
   */
  struct TALER_WireDepositDetailP {
    struct GNUNET_HashCode h_contract;
    struct GNUNET_TIME_AbsoluteNBO execution_time;
    uint64_t transaction_id GNUNET_PACKED;
    struct TALER_CoinSpendPublicKeyP coin_pub;
    struct TALER_AmountNBO deposit_value;
    struct TALER_AmountNBO deposit_fee;
  };


  struct TALER_WireDepositDataPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_EXCHANGE_CONFIRM_WIRE_DEPOSIT 
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct TALER_AmountNBO total;
    struct TALER_MerchantPublicKeyP merchant_pub;
    struct GNUNET_HashCode h_wire;
    struct GNUNET_HashCode h_details;
  };

.. _TALER_ExchangeKeyValidityPS:
.. sourcecode:: c

  struct TALER_ExchangeKeyValidityPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_AUDITOR_EXCHANGE_KEYS
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode auditor_url_hash;
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
  };


.. _TALER_PaymentResponsePS:
.. sourcecode:: c

  struct PaymentResponsePS {
    /**
     * purpose.purpose = TALER_SIGNATURE_MERCHANT_PAYMENT_OK
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode h_contract;
  };


.. _TALER_ContractPS:
.. sourcecode:: c

  struct TALER_ContractPS {
    /**
     * purpose.purpose = TALER_SIGNATURE_MERCHANT_CONTRACT
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    uint64_t transaction_id;
    struct TALER_AmountNBO total_amount;
    struct TALER_AmountNBO max_fee;
    struct GNUNET_HashCode h_contract;
    struct TALER_MerchantPublicKeyP merchant_pub;
  };

  struct TALER_ConfirmWirePS {
    /**
     * purpose.purpose = TALER_SIGNATURE_EXCHANGE_CONFIRM_WIRE
     */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode h_wire;
    struct GNUNET_HashCode h_contract;
    struct TALER_WireTransferIdentifierRawP wtid;
    struct TALER_CoinSpendPublicKeyP coin_pub;
    uint64_t transaction_id;
    struct GNUNET_TIME_AbsoluteNBO execution_time;
    struct TALER_AmountNBO coin_contribution;
  };

.. _TALER_RefundRequestPS:
.. sourcecode:: c

  struct TALER_RefundRequestPS {
    /**
      *  purpose.purpose = TALER_SIGNATURE_MERCHANT_REFUND
      */
    struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
    struct GNUNET_HashCode h_contract GNUNET_PACKED;
    uint64_t transaction_id GNUNET_PACKED;
    struct TALER_CoinSpendPublicKeyP coin_pub;
    struct TALER_MerchantPublicKeyP merchant;
    uint64_t rtransaction_id GNUNET_PACKED;
    struct TALER_AmountNBO refund_amount;
    struct TALER_AmountNBO refund_fee;
  };

    
Error Codes
^^^^^^^^^^^
.. _error-codes:
.. code-block:: c

  /**
   * Enumeration with all possible Taler error codes.
   */
  enum TALER_ErrorCode {
    
    /**
     * Special code to indicate no error (or no "code" present).
     */
    TALER_EC_NONE = 0,
  
    /**
     * Special code to indicate that a non-integer error code was
     * returned in the JSON response.
     */
    TALER_EC_INVALID = 1,
  
    /**
     * The response we got from the server was not even in JSON format.
     */
    TALER_EC_INVALID_RESPONSE = 2,
  
    /**
     * Generic implementation error: this function was not yet implemented.
     */
    TALER_EC_NOT_IMPLEMENTED = 3,
    
    /* ********** generic error codes ************* */
  
    /**
     * The exchange failed to even just initialize its connection to the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_DB_SETUP_FAILED = 1001,
  
    /**
     * The exchange encountered an error event to just start
     * the database transaction.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_DB_START_FAILED = 1002,
  
    /**
     * The exchange encountered an error event to commit
     * the database transaction (hard, unrecoverable error).
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_DB_COMMIT_FAILED_HARD = 1003,
  
    /**
     * The exchange encountered an error event to commit
     * the database transaction, even after repeatedly
     * retrying it there was always a conflicting transaction.
     * (This indicates a repeated serialization error; should
     * only happen if some client maliciously tries to create
     * conflicting concurrent transactions.)
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_DB_COMMIT_FAILED_ON_RETRY = 1004,
  
      /**
     * The exchange had insufficient memory to parse the request. This
     * response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_PARSER_OUT_OF_MEMORY = 1005,
  
    /**
     * The JSON in the client's request to the exchange was malformed.
     * (Generic parse error).
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_JSON_INVALID = 1006,
  
    /**
     * The JSON in the client's request to the exchange was malformed.
     * Details about the location of the parse error are provided.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_JSON_INVALID_WITH_DETAILS = 1007,
  
    /**
     * A required parameter in the request to the exchange was missing.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PARAMETER_MISSING = 1008,
  
    /**
     * A parameter in the request to the exchange was malformed.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PARAMETER_MALFORMED = 1009,
  
    /* ********** request-specific error codes ************* */
  
    /**
     * The given reserve does not have sufficient funds to admit the
     * requested withdraw operation at this time.  The response includes
     * the current "balance" of the reserve as well as the transaction
     * "history" that lead to this balance.  This response is provided
     * with HTTP status code MHD_HTTP_FORBIDDEN.
     */
    TALER_EC_WITHDRAW_INSUFFICIENT_FUNDS = 1100,
  
    /**
     * The exchange has no information about the "reserve_pub" that
     * was given.
     * This response is provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_WITHDRAW_RESERVE_UNKNOWN = 1101,
  
    /**
     * The amount to withdraw together with the fee exceeds the
     * numeric range for Taler amounts.  This is not a client
     * failure, as the coin value and fees come from the exchange's
     * configuration.
     * This response is provided with HTTP status code MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_WITHDRAW_AMOUNT_FEE_OVERFLOW = 1102,
  
    /**
     * All of the deposited amounts into this reserve total up to a
     * value that is too big for the numeric range for Taler amounts.
     * This is not a client failure, as the transaction history comes
     * from the exchange's configuration.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_WITHDRAW_AMOUNT_DEPOSITS_OVERFLOW = 1103,
  
    /**
     * For one of the historic withdrawals from this reserve, the
     * exchange could not find the denomination key.
     * This is not a client failure, as the transaction history comes
     * from the exchange's configuration.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_WITHDRAW_HISTORIC_DENOMINATION_KEY_NOT_FOUND = 1104,
  
    /**
     * All of the withdrawals from reserve total up to a
     * value that is too big for the numeric range for Taler amounts.
     * This is not a client failure, as the transaction history comes
     * from the exchange's configuration.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_WITHDRAW_AMOUNT_WITHDRAWALS_OVERFLOW = 1105,
  
    /**
     * The exchange somehow knows about this reserve, but there seem to
     * have been no wire transfers made.  This is not a client failure,
     * as this is a database consistency issue of the exchange.  This
     * response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_WITHDRAW_RESERVE_WITHOUT_WIRE_TRANSFER = 1106,
  
    /**
     * The exchange failed to create the signature using the
     * denomination key.  This response is provided with HTTP status
     * code MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_WITHDRAW_SIGNATURE_FAILED = 1107,
  
    /**
     * The exchange failed to store the withdraw operation in its
     * database.  This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_WITHDRAW_DB_STORE_ERROR = 1108,
  
    /**
     * The exchange failed to check against historic withdraw data from
     * database (as part of ensuring the idempotency of the operation).
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_WITHDRAW_DB_FETCH_ERROR = 1109,
  
    /**
     * The exchange is not aware of the denomination key
     * the wallet requested for the withdrawal.
     * This response is provided
     * with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_WITHDRAW_DENOMINATION_KEY_NOT_FOUND = 1110,
  
    /**
     * The signature of the reserve is not valid.  This response is
     * provided with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_WITHDRAW_RESERVE_SIGNATURE_INVALID = 1111,
  
    /**
     * The exchange failed to obtain the transaction history of the
     * given reserve from the database while generating an insufficient
     * funds errors.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_WITHDRAW_HISTORY_DB_ERROR_INSUFFICIENT_FUNDS = 1112,
  
    /**
     * When computing the reserve history, we ended up with a negative
     * overall balance, which should be impossible.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_WITHDRAW_RESERVE_HISTORY_IMPOSSIBLE = 1113,
  
    /**
     * The exchange failed to obtain the transaction history of the
     * given reserve from the database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_RESERVE_STATUS_DB_ERROR = 1150,
  
  
    /**
     * The respective coin did not have sufficient residual value
     * for the /deposit operation (i.e. due to double spending).
     * The "history" in the respose provides the transaction history
     * of the coin proving this fact.  This response is provided
     * with HTTP status code MHD_HTTP_FORBIDDEN.
     */
    TALER_EC_DEPOSIT_INSUFFICIENT_FUNDS = 1200,
  
    /**
     * The exchange failed to obtain the transaction history of the
     * given coin from the database (this does not happen merely because
     * the coin is seen by the exchange for the first time).
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_DEPOSIT_HISTORY_DB_ERROR = 1201,
  
    /**
     * The exchange failed to store the /depost information in the
     * database.  This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_DEPOSIT_STORE_DB_ERROR = 1202,
  
    /**
     * The exchange database is unaware of the denomination key that
     * signed the coin (however, the exchange process is; this is not
     * supposed to happen; it can happen if someone decides to purge the
     * DB behind the back of the exchange process).  Hence the deposit
     * is being refused.  This response is provided with HTTP status
     * code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_DEPOSIT_DB_DENOMINATION_KEY_UNKNOWN = 1203,
  
    /**
     * The exchange database is unaware of the denomination key that
     * signed the coin (however, the exchange process is; this is not
     * supposed to happen; it can happen if someone decides to purge the
     * DB behind the back of the exchange process).  Hence the deposit
     * is being refused.  This response is provided with HTTP status
     * code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_DEPOSIT_DENOMINATION_KEY_UNKNOWN = 1204,
  
    /**
     * The signature of the coin is not valid.  This response is
     * provided with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_COIN_SIGNATURE_INVALID = 1205,
  
    /**
     * The signature of the denomination key over the coin is not valid.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_DENOMINATION_SIGNATURE_INVALID = 1206,
  
    /**
     * The stated value of the coin after the deposit fee is subtracted
     * would be negative.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_NEGATIVE_VALUE_AFTER_FEE = 1207,
  
    /**
     * The stated refund deadline is after the wire deadline.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_REFUND_DEADLINE_AFTER_WIRE_DEADLINE = 1208,
  
    /**
     * The exchange does not recognize the validity of or support the
     * given wire format type.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_INVALID_WIRE_FORMAT_TYPE = 1209,
  
    /**
     * The exchange failed to canonicalize and hash the given wire format.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_INVALID_WIRE_FORMAT_JSON = 1210,
  
    /**
     * The hash of the given wire address does not match the hash
     * specified in the contract.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_INVALID_WIRE_FORMAT_CONTRACT_HASH_CONFLICT = 1211,
  
    /**
     * The exchange failed to obtain the transaction history of the
     * given coin from the database while generating an insufficient
     * funds errors.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_DEPOSIT_HISTORY_DB_ERROR_INSUFFICIENT_FUNDS = 1212,
  
    /**
     * The exchange detected that the given account number
     * is invalid for the selected wire format type.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_INVALID_WIRE_FORMAT_ACCOUNT_NUMBER = 1213,
  
    /**
     * The signature over the given wire details is invalid.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_INVALID_WIRE_FORMAT_SIGNATURE = 1214,
  
    /**
     * The bank specified in the wire transfer format is not supported
     * by this exchange.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_INVALID_WIRE_FORMAT_BANK = 1215,
  
    /**
     * No wire format type was specified in the JSON wire format
     * details.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_INVALID_WIRE_FORMAT_TYPE_MISSING = 1216,
  
    /**
     * The given wire format type is not supported by this
     * exchange.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_DEPOSIT_INVALID_WIRE_FORMAT_TYPE_UNSUPPORTED = 1217,
  
  
    /**
     * The respective coin did not have sufficient residual value
     * for the /refresh/melt operation.  The "history" in this
     * response provdes the "residual_value" of the coin, which may
     * be less than its "original_value".  This response is provided
     * with HTTP status code MHD_HTTP_FORBIDDEN.
     */
    TALER_EC_REFRESH_MELT_INSUFFICIENT_FUNDS = 1300,
  
    /**
     * The exchange is unaware of the denomination key that was
     * used to sign the melted coin.  This response is provided
     * with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_REFRESH_MELT_DENOMINATION_KEY_NOT_FOUND = 1301,
  
    /**
     * The exchange had an internal error reconstructing the
     * transaction history of the coin that was being melted.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_REFRESH_MELT_COIN_HISTORY_COMPUTATION_FAILED = 1302,
  
    /**
     * The exchange failed to check against historic melt data from
     * database (as part of ensuring the idempotency of the operation).
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_MELT_DB_FETCH_ERROR = 1303,
  
    /**
     * The exchange failed to store session data in the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_MELT_DB_STORE_SESSION_ERROR = 1304,
  
    /**
     * The exchange failed to store refresh order data in the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_MELT_DB_STORE_ORDER_ERROR = 1305,
  
    /**
     * The exchange failed to store commit data in the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_MELT_DB_STORE_COMMIT_ERROR = 1306,
  
    /**
     * The exchange failed to store transfer keys in the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_MELT_DB_STORE_TRANSFER_ERROR = 1307,
  
    /**
     * The exchange is unaware of the denomination key that was
     * requested for one of the fresh coins.  This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_MELT_FRESH_DENOMINATION_KEY_NOT_FOUND = 1308,
  
    /**
     * The exchange encountered a numeric overflow totaling up
     * the cost for the refresh operation.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_REFRESH_MELT_COST_CALCULATION_OVERFLOW = 1309,
  
    /**
     * During the transaction phase, the exchange could suddenly
     * no longer find the denomination key that was
     * used to sign the melted coin.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_REFRESH_MELT_DB_DENOMINATION_KEY_NOT_FOUND = 1310,
  
    /**
     * The exchange encountered melt fees exceeding the melted
     * coin's contribution.  This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_MELT_FEES_EXCEED_CONTRIBUTION = 1311,
  
    /**
     * The exchange's cost calculation does not add up to the
     * melt fees specified in the request.  This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_MELT_FEES_MISSMATCH = 1312,
  
    /**
     * The denomination key signature on the melted coin is invalid.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_MELT_DENOMINATION_SIGNATURE_INVALID = 1313,
  
    /**
     * The exchange's cost calculation shows that the melt amount
     * is below the costs of the transaction.  This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_MELT_AMOUNT_INSUFFICIENT = 1314,
  
    /**
     * The signature made with the coin to be melted is invalid.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_MELT_COIN_SIGNATURE_INVALID = 1315,
  
    /**
     * The size of the cut-and-choose dimension of the
     * blinded coins request does not match #TALER_CNC_KAPPA.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_MELT_CNC_COIN_ARRAY_SIZE_INVALID = 1316,
  
    /**
     * The size of the cut-and-choose dimension of the
     * transfer keys request does not match #TALER_CNC_KAPPA.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_MELT_CNC_TRANSFER_ARRAY_SIZE_INVALID = 1317,
  
    /**
     * The exchange failed to obtain the transaction history of the
     * given coin from the database while generating an insufficient
     * funds errors.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_REFRESH_MELT_HISTORY_DB_ERROR_INSUFFICIENT_FUNDS = 1318,
  
    /**
     * The provided transfer keys do not match up with the
     * original commitment.  Information about the original
     * commitment is included in the response.  This response is
     * provided with HTTP status code MHD_HTTP_CONFLICT.
     */
    TALER_EC_REFRESH_REVEAL_COMMITMENT_VIOLATION = 1350,
  
    /**
     * Failed to blind the envelope to reconstruct the blinded
     * coins for revealation checks.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_REVEAL_BLINDING_ERROR = 1351,
  
    /**
     * Failed to produce the blinded signatures over the coins
     * to be returned.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_REVEAL_SIGNING_ERROR = 1352,
  
    /**
     * The exchange is unaware of the refresh sessino specified in
     * the request.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_REVEAL_SESSION_UNKNOWN = 1353,
  
    /**
     * The exchange failed to retrieve valid session data from the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_REVEAL_DB_FETCH_SESSION_ERROR = 1354,
  
    /**
     * The exchange failed to retrieve order data from the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_REVEAL_DB_FETCH_ORDER_ERROR = 1355,
  
    /**
     * The exchange failed to retrieve transfer keys from the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_REVEAL_DB_FETCH_TRANSFER_ERROR = 1356,
  
    /**
     * The exchange failed to retrieve commitment data from the
     * database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_ERROR.
     */
    TALER_EC_REFRESH_REVEAL_DB_FETCH_COMMIT_ERROR = 1357,
  
    /**
     * The size of the cut-and-choose dimension of the
     * private transfer keys request does not match #TALER_CNC_KAPPA - 1.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFRESH_REVEAL_CNC_TRANSFER_ARRAY_SIZE_INVALID = 1358,
  
  
    /**
     * The coin specified in the link request is unknown to the exchange.
     * This response is provided with HTTP status code
     * MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_REFRESH_LINK_COIN_UNKNOWN = 1400,
  
  
    /**
     * The exchange knows literally nothing about the coin we were asked
     * to refund. But without a transaction history, we cannot issue a
     * refund.  This is kind-of OK, the owner should just refresh it
     * directly without executing the refund.  This response is provided
     * with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_REFUND_COIN_NOT_FOUND = 1500,
  
    /**
     * We could not process the refund request as the coin's transaction
     * history does not permit the requested refund at this time.  The
     * "history" in the response proves this.  This response is provided
     * with HTTP status code MHD_HTTP_CONFLICT.
     */
    TALER_EC_REFUND_CONFLICT = 1501,
  
    /**
     * The exchange knows about the coin we were asked to refund, but
     * not about the specific /deposit operation.  Hence, we cannot
     * issue a refund (as we do not know if this merchant public key is
     * authorized to do a refund).  This response is provided with HTTP
     * status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_REFUND_DEPOSIT_NOT_FOUND = 1503,
  
    /**
     * The currency specified for the refund is different from
     * the currency of the coin.  This response is provided with HTTP
     * status code MHD_HTTP_PRECONDITION_FAILED.
     */
    TALER_EC_REFUND_CURRENCY_MISSMATCH = 1504,
  
    /**
     * When we tried to check if we already paid out the coin, the
     * exchange's database suddenly disagreed with data it previously
     * provided (internal inconsistency).
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_REFUND_DB_INCONSISTENT = 1505,
  
    /**
     * The exchange can no longer refund the customer/coin as the
     * money was already transferred (paid out) to the merchant.
     * (It should be past the refund deadline.)
     * This response is provided with HTTP status code
     * MHD_HTTP_GONE.
     */
    TALER_EC_REFUND_MERCHANT_ALREADY_PAID = 1506,
  
    /**
     * The amount the exchange was asked to refund exceeds
     * (with fees) the total amount of the deposit (including fees).
     * This response is provided with HTTP status code
     * MHD_HTTP_PRECONDITION_FAILED.
     */
    TALER_EC_REFUND_INSUFFICIENT_FUNDS = 1507,
  
    /**
     * The exchange failed to recover information about the
     * denomination key of the refunded coin (even though it
     * recognizes the key).  Hence it could not check the fee
     * strucutre.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_REFUND_DENOMINATION_KEY_NOT_FOUND = 1508,
  
    /**
     * The refund fee specified for the request is lower than
     * the refund fee charged by the exchange for the given
     * denomination key of the refunded coin.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFUND_FEE_TOO_LOW = 1509,
  
    /**
     * The exchange failed to store the refund information to
     * its database.
     * This response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_REFUND_STORE_DB_ERROR = 1510,
  
    /**
     * The refund fee is specified in a different currency
     * than the refund amount.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFUND_FEE_CURRENCY_MISSMATCH = 1511,
  
    /**
     * The refunded amount is smaller than the refund fee,
     * which would result in a negative refund.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFUND_FEE_ABOVE_AMOUNT = 1512,
  
    /**
     * The signature of the merchant is invalid.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_REFUND_MERCHANT_SIGNATURE_INVALID = 1513,
  
  
    /**
     * The wire format specified in the "sender_account_details"
     * is not understood or not supported by this exchange.
     * Returned with an HTTP status code of MHD_HTTP_NOT_FOUND.
     * (As we did not find an interpretation of the wire format.)
     */
    TALER_EC_ADMIN_ADD_INCOMING_WIREFORMAT_UNSUPPORTED = 1600,
  
    /**
     * The currency specified in the "amount" parameter is not
     * supported by this exhange.  Returned with an HTTP status
     * code of MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_ADMIN_ADD_INCOMING_CURRENCY_UNSUPPORTED = 1601,
  
    /**
     * The exchange failed to store information about the incoming
     * transfer in its database.  This response is provided with HTTP
     * status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_ADMIN_ADD_INCOMING_DB_STORE = 1602,
  
    /**
     * The exchange encountered an error (that is not about not finding
     * the wire transfer) trying to lookup a wire transfer identifier
     * in the database.  This response is provided with HTTP
     * status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSFER_DB_FETCH_FAILED = 1700,
  
    /**
     * The exchange found internally inconsistent data when resolving a
     * wire transfer identifier in the database.  This response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSFER_DB_INCONSISTENT = 1701,
  
    /**
     * The exchange did not find information about the specified
     * wire transfer identifier in the database.  This response is
     * provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_TRACK_TRANSFER_WTID_NOT_FOUND = 1702,
  
  
    /**
     * The exchange found internally inconsistent fee data when
     * resolving a transaction in the database.  This
     * response is provided with HTTP status code
     * MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSACTION_DB_FEE_INCONSISTENT = 1800,
  
    /**
     * The exchange encountered an error (that is not about not finding
     * the transaction) trying to lookup a transaction
     * in the database.  This response is provided with HTTP
     * status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSACTION_DB_FETCH_FAILED = 1801,
  
    /**
     * The exchange did not find information about the specified
     * transaction in the database.  This response is
     * provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_TRACK_TRANSACTION_NOT_FOUND = 1802,
  
    /**
     * The exchange failed to identify the wire transfer of the
     * transaction (or information about the plan that it was supposed
     * to still happen in the future).  This response is provided with
     * HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSACTION_WTID_RESOLUTION_ERROR = 1803,
  
    /**
     * The signature of the merchant is invalid.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_TRACK_TRANSACTION_MERCHANT_SIGNATURE_INVALID = 1804,
  
  
    /* *********** Merchant backend error codes ********* */
  
    /**
     * The backend could not find the merchant instance specified
     * in the request.   This response is
     * provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_CONTRACT_INSTANCE_UNKNOWN = 2000,
  
    /**
     * The exchange failed to provide a meaningful response
     * to a /deposit request.  This response is provided
     * with HTTP status code MHD_HTTP_SERVICE_UNAVAILABLE.
     */
    TALER_EC_PAY_EXCHANGE_FAILED = 2101,
  
    /**
     * The merchant failed to commit the exchanges' response to
     * a /deposit request to its database.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_PAY_DB_STORE_PAY_ERROR = 2102,
  
    /**
     * The specified exchange is not supported/trusted by
     * this merchant.  This response is provided
     * with HTTP status code MHD_HTTP_PRECONDITION_FAILED.
     */
    TALER_EC_PAY_EXCHANGE_REJECTED = 2103,
  
    /**
     * The denomination key used for payment is not listed among the
     * denomination keys of the exchange.  This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_DENOMINATION_KEY_NOT_FOUND = 2104,
  
    /**
     * The denomination key used for payment is not audited by an
     * auditor approved by the merchant.  This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_DENOMINATION_KEY_AUDITOR_FAILURE = 2105,
  
    /**
     * There was an integer overflow totaling up the amounts or
     * deposit fees in the payment.  This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_AMOUNT_OVERFLOW = 2106,
  
    /**
     * The deposit fees exceed the total value of the payment.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_FEES_EXCEED_PAYMENT = 2107,
  
    /**
     * After considering deposit fees, the payment is insufficient
     * to satisfy the required amount for the contract.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_PAYMENT_INSUFFICIENT_DUE_TO_FEES = 2108,
  
    /**
     * While the merchant is happy to cover all applicable deposit fees,
     * the payment is insufficient to satisfy the required amount for
     * the contract.  This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_PAYMENT_INSUFFICIENT = 2109,
  
    /**
     * The signature over the contract of one of the coins
     * was invalid. This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_COIN_SIGNATURE_INVALID = 2110,
  
    /**
     * We failed to contact the exchange for the /pay request.
     * This response is provided
     * with HTTP status code MHD_HTTP_SERVICE_UNAVAILABLE.
     */
    TALER_EC_PAY_EXCHANGE_TIMEOUT = 2111,
  
    /**
     * The backend could not find the merchant instance specified
     * in the request.   This response is
     * provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_PAY_INSTANCE_UNKNOWN = 2112,
  
    /**
     * The signature over the contract of the merchant
     * was invalid. This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_MERCHANT_SIGNATURE_INVALID = 2113,
  
    /**
     * The refund deadline was after the transfer deadline.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_REFUND_DEADLINE_PAST_WIRE_TRANSFER_DEADLINE = 2114,
  
    /**
     * The request fails to provide coins for the payment.
     * This response is provided with HTTP status code
     * MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_COINS_ARRAY_EMPTY = 2115,
  
    /**
     * The merchant failed to fetch the merchant's previous state with
     * respect to a /pay request from its database.  This response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_PAY_DB_FETCH_PAY_ERROR = 2116,
  
    /**
     * The merchant failed to fetch the merchant's previous state with
     * respect to transactions from its database.  This response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_PAY_DB_FETCH_TRANSACTION_ERROR = 2117,
  
    /**
     * The transaction ID was used for a conflicing transaction before.
     * This response is
     * provided with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_DB_TRANSACTION_ID_CONFLICT = 2118,
  
    /**
     * The merchant failed to store the merchant's state with
     * respect to the transaction in its database.  This response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_PAY_DB_STORE_TRANSACTION_ERROR = 2119,
  
    /**
     * The exchange failed to provide a valid response to
     * the merchant's /keys request.
     * This response is provided
     * with HTTP status code MHD_HTTP_SERVICE_UNAVAILABLE.
     */
    TALER_EC_PAY_EXCHANGE_KEYS_FAILURE = 2120,
  
    /**
     * The payment is too late, the offer has expired.
     * This response is
     * provided with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_PAY_OFFER_EXPIRED = 2121,
  
  
    /**
     * Integer overflow with sepcified timestamp argument detected.
     * This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_HISTORY_TIMESTAMP_OVERFLOW = 2200,
  
    /**
     * Failed to retrieve history from merchant database.
     * This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_HISTORY_DB_FETCH_ERROR = 2201,
  
    /**
     * We failed to contact the exchange for the /track/transaction
     * request.  This response is provided with HTTP status code
     * MHD_HTTP_SERVICE_UNAVAILABLE.
     */
    TALER_EC_TRACK_TRANSACTION_EXCHANGE_TIMEOUT = 2300,
  
    /**
     * The backend could not find the merchant instance specified
     * in the request.   This response is
     * provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_TRACK_TRANSACTION_INSTANCE_UNKNOWN = 2301,
  
    /**
     * The backend could not find the transaction specified
     * in the request.   This response is
     * provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_TRACK_TRANSACTION_TRANSACTION_UNKNOWN = 2302,
  
    /**
     * The backend had a database access error trying to
     * retrieve transaction data from its database.
     * The response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSACTION_DB_FETCH_TRANSACTION_ERROR = 2303,
  
    /**
     * The backend had a database access error trying to
     * retrieve payment data from its database.
     * The response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSACTION_DB_FETCH_PAYMENT_ERROR = 2304,
  
    /**
     * The backend found no applicable deposits in the database.
     * This is odd, as we know about the transaction, but not
     * about deposits we made for the transaction.  The response is
     * provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_TRACK_TRANSACTION_DB_NO_DEPOSITS_ERROR = 2305,
  
    /**
     * We failed to obtain a wire transfer identifier for one
     * of the coins in the transaction.  The response is
     * provided with HTTP status code MHD_HTTP_FAILED_DEPENDENCY if
     * the exchange had a hard error, or MHD_HTTP_ACCEPTED if the
     * exchange signaled that the transfer was in progress.
     */
    TALER_EC_TRACK_TRANSACTION_COIN_TRACE_ERROR = 2306,
  
    /**
     * We failed to obtain the full wire transfer identifier for the
     * transfer one of the coins was aggregated into.
     * The response is
     * provided with HTTP status code MHD_HTTP_FAILED_DEPENDENCY.
     */
    TALER_EC_TRACK_TRANSACTION_WIRE_TRANSFER_TRACE_ERROR = 2307,
  
    /**
     * We got conflicting reports from the exhange with
     * respect to which transfers are included in which
     * aggregate.
     * The response is
     * provided with HTTP status code MHD_HTTP_FAILED_DEPENDENCY.
     */
    TALER_EC_TRACK_TRANSACTION_CONFLICTING_REPORTS = 2308,
  
  
    /**
     * We failed to contact the exchange for the /track/transfer
     * request.  This response is provided with HTTP status code
     * MHD_HTTP_SERVICE_UNAVAILABLE.
     */
    TALER_EC_TRACK_TRANSFER_EXCHANGE_TIMEOUT = 2400,
  
    /**
     * The backend could not find the merchant instance specified
     * in the request.   This response is
     * provided with HTTP status code MHD_HTTP_NOT_FOUND.
     */
    TALER_EC_TRACK_TRANSFER_INSTANCE_UNKNOWN = 2401,
  
    /**
     * We failed to persist coin wire transfer information in
     * our merchant database.
     * The response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSFER_DB_STORE_COIN_ERROR = 2402,
  
    /**
     * We internally failed to execute the /track/transfer request.
     * The response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSFER_REQUEST_ERROR = 2403,
  
    /**
     * We failed to persist wire transfer information in
     * our merchant database.
     * The response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSFER_DB_STORE_TRANSFER_ERROR = 2404,
  
    /**
     * The exchange returned an error from /track/transfer.
     * The response is
     * provided with HTTP status code MHD_HTTP_FAILED_DEPENDENCY.
     */
    TALER_EC_TRACK_TRANSFER_EXCHANGE_ERROR = 2405,
  
    /**
     * We failed to fetch deposit information from
     * our merchant database.
     * The response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSFER_DB_FETCH_DEPOSIT_ERROR = 2406,
  
    /**
     * We encountered an internal logic error.
     * The response is
     * provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSFER_DB_INTERNAL_LOGIC_ERROR = 2407,
  
    /**
     * The exchange gave conflicting information about a coin which has
     * been wire transferred.
     * The response is provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TRACK_TRANSFER_CONFLICTING_REPORTS = 2408,
  
    /**
     * The hash provided in the request of /map/in does not match
     * the contract sent alongside in the same request.
     */
    TALER_EC_MAP_IN_UNMATCHED_HASH = 2500,
  
    /**
     * The backend encountered an error while trying to store the
     * pair <contract, h_contract> into the database. 
     * The response is provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_MAP_IN_STORE_DB_ERROR = 2501,
  
    /**
     * The backend encountered an error while trying to retrieve the
     * contract from database.  Likely to be an internal error.
     */
    TALER_EC_MAP_OUT_GET_FROM_DB_ERROR = 2502,
  
  
    /**
     * The backend encountered an error while trying to retrieve the
     * contract from database.  Likely to be an internal error.
     */
    TALER_EC_MAP_OUT_CONTRACT_UNKNOWN = 2503,
  
    /* ********** /test API error codes ************* */
  
    /**
     * The exchange failed to compute ECDH.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TEST_ECDH_ERROR = 4000,
  
    /**
     * The EdDSA test signature is invalid.  This response is provided
     * with HTTP status code MHD_HTTP_BAD_REQUEST.
     */
    TALER_EC_TEST_EDDSA_INVALID = 4001,
  
    /**
     * The exchange failed to compute the EdDSA test signature.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TEST_EDDSA_ERROR = 4002,
  
    /**
     * The exchange failed to generate an RSA key.  This response is provided
     * with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TEST_RSA_GEN_ERROR = 4003,
  
    /**
     * The exchange failed to compute the public RSA key.  This response
     * is provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TEST_RSA_PUB_ERROR = 4004,
  
    /**
     * The exchange failed to compute the RSA signature.  This response
     * is provided with HTTP status code MHD_HTTP_INTERNAL_SERVER_ERROR.
     */
    TALER_EC_TEST_RSA_SIGN_ERROR = 4005,
  
  
    /**
     * End of error code range.
     */
    TALER_EC_END = 9999
  };
