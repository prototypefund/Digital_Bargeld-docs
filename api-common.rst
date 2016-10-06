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

      // Numeric error code. See "taler_error_codes.h".
      error_code: number;

      // Human-readable description of the error, i.e. "missing parameter", "commitment violation", ...
      // The other arguments are specific to the error value reported here.
      error: string;

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

Public Keys
^^^^^^^^^^^

.. _`tsref-type-EddsaPublicKey`:
.. _`tsref-type-EddsaPrivateKey`:

.. code-block:: tsref

   // EdDSA public keys are always points on Curve25519 (FIXME does that hold for private keys as well?) and represented
   // using the standard 256 bits Ed25519 compact format, converted to Crockford
   // `Base32`_.
   type EddsaPublicKey = string;
   type EddsaPrivateKey = string;

.. _`tsref-type-RsaPublicKey`:

.. code-block:: tsref

   // RSA public key converted to Crockford `Base32`_.
   type RsaPublicKey = string;


.. _signature:

Signatures
^^^^^^^^^^

.. _`tsref-type-EddsaSignature`:

.. code-block:: tsref
  
  // EdDSA signatures are transmitted as 64-byte `base32`_
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

   struct TALER_ExchangePublicKeyP {
     uint8_t eddsa_pub[32];
   };

   struct TALER_ExchangePrivateKeyP {
     uint8_t eddsa_priv[32];
   };

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

  struct TALER_ContractPS {
      /**
       * purpose.purpose = TALER_SIGNATURE_MERCHANT_CONTRACT
       */
      struct GNUNET_CRYPTO_EccSignaturePurpose purpose;
      uint64_t transaction_id;
      struct TALER_AmountNBO total_amount;
      struct TALER_AmountNBO max_fee;
      struct GNUNET_HashCode h_contract;
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
