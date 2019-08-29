..
  This file is part of GNU TALER.
  Copyright (C) 2014-2018 Taler Systems SA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Christian Grothoff

=============================
The Exchange RESTful JSON API
=============================

The API specified here follows the :ref:`general conventions <http-common>`
for all details not specified in the individual requests.
The `glossary <https://docs.taler.net/glossary.html#glossary>`
defines all specific terms used in this section.

.. _keys:

-----------------------
Obtaining Exchange Keys
-----------------------

This API is used by wallets and merchants to obtain global information about
the exchange, such as online signing keys, available denominations and the fee
structure.  This is typically the first call any exchange client makes, as it
returns information required to process all of the other interactions with the
exchange.  The returned information is secured by (1) signature(s) from the exchange,
especially the long-term offline signing key of the exchange, which clients should
cache; (2) signature(s) from auditors, and the auditor keys should be
hard-coded into the wallet as they are the trust anchors for Taler; (3)
possibly by using HTTPS.


.. http:get:: /keys

  Get a list of all denomination keys offered by the bank,
  as well as the bank's current online signing key.

  **Request:**

  :query last_issue_date: optional argument specifying the maximum value of any of the "stamp_start" members of the denomination keys of a "/keys" response that is already known to the client. Allows the exchange to only return keys that have changed since that timestamp.  The given value must be an unsigned 64-bit integer representing seconds after 1970.  If the timestamp does not exactly match the "stamp_start" of one of the denomination keys, all keys are returned.

  **Response:**

  :status 200 OK:
    The exchange responds with a `ExchangeKeysResponse`_ object. This request should
    virtually always be successful.

  **Details:**

  .. _ExchangeKeysResponse:
  .. code-block:: tsref

    interface ExchangeKeysResponse {
      // libtool-style representation of the Taler protocol version, see
      // https://www.gnu.org/software/libtool/manual/html_node/Versioning.html#Versioning
      // The format is "current:revision:age".
      version: String;

      // EdDSA master public key of the exchange, used to sign entries in `denoms` and `signkeys`
      master_public_key: EddsaPublicKey;

      // Relative duration until inactive reserves are closed; not signed, expressed as
      // a string in relative time in microseconds, i.e. "/Delay(1000)/" for 1 second.
      reserve_closing_delay: RelativeTime;

      // Denominations offered by this exchange.
      denoms: Denom[];

      // Denominations for which the exchange currently offers/requests payback.
      payback: Payback[];

      // The date when the denomination keys were last updated.
      list_issue_date: Timestamp;

      // Auditors of the exchange.
      auditors: Auditor[];

      // The exchange's signing keys.
      signkeys: SignKey[];

      // compact EdDSA `signature`_ (binary-only) over the SHA-512 hash of the
      // concatenation of all SHA-512 hashes of the RSA denomination public keys
      // in `denoms` in the same order as they were in `denoms`.  Note that for
      // hashing, the binary format of the RSA public keys is used, and not their
      // `base32 encoding <base32>`_.  Wallets cannot do much with this signature by itself;
      // it is only useful when multiple clients need to establish that the exchange
      // is sabotaging end-user anonymity by giving disjoint denomination keys to
      // different users.  If a exchange were to do this, this signature allows the
      // clients to demonstrate to the public that the exchange is dishonest.
      eddsa_sig: EddsaSignature;

      // Public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  It is given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      eddsa_pub: EddsaPublicKey;
    }

  .. _tsref-type-Denom:
  .. code-block:: tsref

    interface Denom {
      // How much are coins of this denomination worth?
      value: Amount;

      // When does the denomination key become valid?
      stamp_start: Timestamp;

      // When is it no longer possible to deposit coins
      // of this denomination?
      stamp_expire_withdraw: Timestamp;

      // Timestamp indicating by when legal disputes relating to these coins must
      // be settled, as the exchange will afterwards destroy its evidence relating to
      // transactions involving this coin.
      stamp_expire_legal: Timestamp;

      // Public (RSA) key for the denomination.
      denom_pub: RsaPublicKey;

      // Fee charged by the exchange for withdrawing a coin of this denomination
      fee_withdraw: Amount;

      // Fee charged by the exchange for depositing a coin of this denomination
      fee_deposit: Amount;

      // Fee charged by the exchange for refreshing a coin of this denomination
      fee_refresh: Amount;

      // Fee charged by the exchange for refunding a coin of this denomination
      fee_refund: Amount;

      // Signature of `TALER_DenominationKeyValidityPS`_
      master_sig: EddsaSignature;
    }

  Fees for any of the operations can be zero, but the fields must still be
  present. The currency of the `fee_deposit`, `fee_refresh` and `fee_refund` must match the
  currency of the `value`.  Theoretically, the `fee_withdraw` could be in a
  different currency, but this is not currently supported by the
  implementation.

  .. _tsref-type-Payback:
  .. code-block:: tsref

    interface Payback {
      // hash of the public key of the denomination that is being revoked under
      // emergency protocol (see /payback).
      h_denom_pub: HashCode;

      // We do not include any signature here, as the primary use-case for
      // this emergency involves the exchange having lost its signing keys,
      // so such a signature here would be pretty worthless.  However, the
      // exchange will not honor /payback requests unless they are for
      // denomination keys listed here.
    }

  A signing key in the `signkeys` list is a JSON object with the following fields:

  .. _tsref-type-SignKey:
  .. code-block:: tsref

    interface SignKey {
      // The actual exchange's EdDSA signing public key.
      key: EddsaPublicKey;

      // Initial validity date for the signing key.
      stamp_start: Timestamp;

      // Date when the exchange will stop using the signing key, allowed to overlap
      // slightly with the next signing key's validity to allow for clock skew.
      stamp_expire: Timestamp;

      // Date when all signatures made by the signing key expire and should
      // henceforth no longer be considered valid in legal disputes.
      stamp_end: Timestamp;

      // Signature over `key` and `stamp_expire` by the exchange master key.
      // Must have purpose TALER_SIGNATURE_MASTER_SIGNING_KEY_VALIDITY.
      master_sig: EddsaSignature;
    }

  An entry in the `auditors` list is a JSON object with the following fields:

  .. _tsref-type-Auditor:
  .. code-block:: tsref

    interface Auditor {
      // The auditor's EdDSA signing public key.
      auditor_pub: EddsaPublicKey;

      // The auditor's URL.
      auditor_url: string;

      // An array of denomination keys the auditor affirms with its signature.
      // Note that the message only includes the hash of the public key, while the
      // signature is actually over the expanded information including expiration
      // times and fees.  The exact format is described below.
      denomination_keys: DenominationKey[];
    }

  .. _tsref-type-DenominationKey:
  .. code-block:: tsref

    interface DenominationKey {
      // hash of the public RSA key used to sign coins of the respective
      // denomination.  Note that the auditor's signature covers more than just
      // the hash, but this other information is already provided in `denoms` and
      // thus not repeated here.
      denom_pub_h: HashCode;

      // Signature of `TALER_ExchangeKeyValidityPS`_
      auditor_sig: EddsaSignature;
    }

  The same auditor may appear multiple times in the array for different subsets
  of denomination keys, and the same denomination key hash may be listed
  multiple times for the same or different auditors.  The wallet or merchant
  just should check that the denomination keys they use are in the set for at
  least one of the auditors that they accept.

  .. note::

    Both the individual denominations *and* the denomination list is signed,
    allowing customers to prove that they received an inconsistent list.

.. _wire-req:

-----------------------------------
Obtaining wire-transfer information
-----------------------------------

.. http:get:: /wire

  Returns a list of payment methods supported by the exchange.  The idea is that wallets may use this information to instruct users on how to perform wire transfers to top up their wallets.

  **Response:**

  :status 200: The exchange responds with a `WireResponse`_ object. This request should virtually always be successful.

  **Details:**

  .. _WireResponse:
  .. _tsref-type-WireResponse:
  .. code-block:: tsref

    interface WireResponse {

      // Array of wire accounts operated by the exchange for
      // incoming wire transfers.
      accounts: WireAccount[];

      // Object mapping names of wire methods (i.e. "sepa" or "x-taler-bank")
      // to wire fees.
      fees: { method : AggregateTransferFee };
    }

  The specification for the account object is:

  .. _WireAccouunt:
  .. _tsref-type-WireAccount:
  .. code-block:: tsref

    interface WireAccount {
      // payto:// URL identifying the account and wire method
      url: string;

      // Salt value (used when hashing 'url' to verify signature)
      salt: string;

      // Signature using the exchange's offline key
      // with purpose TALER_SIGNATURE_MASTER_WIRE_DETAILS.
      master_sig: EddsaSignature;
    }

  Aggregate wire transfer fees representing the fees the exchange
  charges per wire transfer to a merchant must be specified as an
  array in all wire transfer response objects under `fees`.  The
  respective array contains objects with the following members:

  .. _AggregateTransferFee:
  .. _tsref-type-AggregateTransferFee:
  .. code-block:: tsref

    interface AggregateTransferFee {
      // Per transfer wire transfer fee.
      wire_fee: Amount;

      // Per transfer closing fee.
      closing_fee: Amount;

      // What date (inclusive) does this fee go into effect?
      // The different fees must cover the full time period in which
      // any of the denomination keys are valid without overlap.
      start_date: Timestamp;

      // What date (exclusive) does this fee stop going into effect?
      // The different fees must cover the full time period in which
      // any of the denomination keys are valid without overlap.
      end_date: Timestamp;

      // Signature of `TALER_MasterWireFeePS`_ with purpose TALER_SIGNATURE_MASTER_WIRE_FEES
      sig: EddsaSignature;
    }

----------
Withdrawal
----------

This API is used by the wallet to obtain digital coins.

When transfering money to the exchange such as via SEPA transfers, the exchange creates
a *reserve*, which keeps the money from the customer.  The customer must
specify an EdDSA reserve public key as part of the transfer, and can then
withdraw digital coins using the corresponding private key.  All incoming and
outgoing transactions are recorded under the corresponding public key by the
exchange.

  .. note::

     Eventually the exchange will need to advertise a policy for how long it will keep transaction histories for inactive or even fully drained reserves.  We will therefore need some additional handler similar to `/keys` to advertise those terms of service.


.. http:get:: /reserve/status

  Request information about a reserve.

  .. note::
    The client currently does not have to demonstrate knowledge of the private
    key of the reserve to make this request, which makes the reserve's public
    key privileged information known only to the client, their bank, and the
    exchange.  In future, we might wish to revisit this decision to improve
    security, such as by having the client EdDSA-sign an ECDHE key to be used
    to derive a symmetric key to encrypt the response.  This would be useful if
    for example HTTPS were not used for communication with the exchange.

  **Request:**

  :query reserve_pub: EdDSA reserve public key identifying the reserve.

  **Response:**

  :status 200 OK:
    The exchange responds with a `ReserveStatus`_ object;  the reserve was known to the exchange,
  :status 404 Not Found: The reserve key does not belong to a reserve known to the exchange.

  **Details:**

  .. _ReserveStatus:
  .. code-block:: tsref

    interface ReserveStatus {
      // Balance left in the reserve.
      balance: Amount;

      // Transaction history for this reserve
      history: TransactionHistoryItem[];
    }

  Objects in the transaction history have the following format:

  .. _tsref-type-TransactionHistoryItem:
  .. code-block:: tsref

    interface TransactionHistoryItem {
      // Either "WITHDRAW", "DEPOSIT", "PAYBACK", or "CLOSING"
      type: string;

      // The amount that was withdrawn or deposited (incl. fee)
      // or paid back, or the closing amount.
      amount: Amount;

      // Hash of the denomination public key of the coin, if
      // type is "WITHDRAW".
      h_denom_pub?: base32;

      // Hash of the blinded coin to be signed, if
      // type is "WITHDRAW".
      h_coin_envelope?: base32;

      // Signature of `TALER_WithdrawRequestPS`_ created with the `reserves's private key <reserve-priv>`_.  Only present if type is "WITHDRAW".
      reserve_sig?: EddsaSignature;

      // The fee that was charged for "WITHDRAW".
      withdraw_fee?: Amount;

      // The fee that was charged for "CLOSING".
      closing_fee?: Amount;

      // Sender account payto://-URL, only present if type is "DEPOSIT".
      sender_account_url?: String;

      // Receiver account details, only present if type is "PAYBACK".
      receiver_account_details?: any;

      // Wire transfer identifier, only present if type is "PAYBACK".
      wire_transfer?: any;

      // Transfer details uniquely identifying the transfer, only present if type is "DEPOSIT".
      wire_reference?: any;

      // Wire transfer subject, only present if type is "CLOSING".
      wtid?: any;

      // Hash of the wire account into which the funds were
      // returned to, present if type is "CLOSING".
      h_wire?: base32;

      // If `type` is "PAYBACK", this is a signature over a `struct TALER_PaybackConfirmationPS` with purpose TALER_SIGNATURE_EXCHANGE_CONFIRM_PAYBACK.
      // If `type` is "CLOSING", this is a signature over a `struct TALER_ReserveCloseConfirmationPS` with purpose TALER_SIGNATURE_EXCHANGE_RESERVE_CLOSED.
      // Not present for other values of `type`.
      exchange_sig?: EddsaSignature;

      // Public key used to create `exchange_sig`, only present if `exchange_sig` is present.
      exchange_pub?: EddsaPublicKey;

      // Public key of the coin that was paid back; only present if type is "PAYBACK".
      coin_pub?: CoinPublicKey;

      // Timestamp when the exchange received the /payback or executed the wire transfer. Only present if `type` is "DEPOSIT", "PAYBACK" or "CLOSING".
      timestamp?: Timestamp;
   }


.. http:post:: /reserve/withdraw

  Withdraw a coin of the specified denomination.  Note that the client should
  commit all of the request details, including the private key of the coin and
  the blinding factor, to disk *before* issuing this request, so that it can
  recover the information if necessary in case of transient failures, like
  power outage, network outage, etc.

  **Request:** The request body must be a `WithdrawRequest`_ object.

  **Response:**

  :status 200 OK:
    The request was succesful, and the response is a `WithdrawResponse`.  Note that repeating exactly the same request
    will again yield the same response, so if the network goes down during the
    transaction or before the client can commit the coin signature to disk, the
    coin is not lost.
  :status 401 Unauthorized: The signature is invalid.
  :status 404 Not Found:
    The denomination key or the reserve are not known to the exchange.  If the
    denomination key is unknown, this suggests a bug in the wallet as the
    wallet should have used current denomination keys from `/keys`.  If the
    reserve is unknown, the wallet should not report a hard error yet, but
    instead simply wait for up to a day, as the wire transaction might simply
    not yet have completed and might be known to the exchange in the near future.
    In this case, the wallet should repeat the exact same request later again
    using exactly the same blinded coin.
  :status 403 Forbidden:
    The balance of the reserve is not sufficient to withdraw a coin of the indicated denomination.
    The response is `WithdrawError`_ object.


  **Details:**

  .. _WithdrawRequest:
  .. code-block:: tsref

    interface WithdrawRequest {
      // Hash of a denomination public key (RSA), specifying the type of coin the client
      // would like the exchange to create.
      denom_pub_hash: HashCode;

      // coin's blinded public key, should be (blindly) signed by the exchange's
      // denomination private key
      coin_ev: CoinEnvelope;

      // `public (EdDSA) key <reserve-pub>`_ of the reserve from which the coin should be
      // withdrawn.  The total amount deducted will be the coin's value plus the
      // withdrawal fee as specified with the denomination information.
      reserve_pub: EddsaPublicKey;

      // Signature of `TALER_WithdrawRequestPS`_ created with the `reserves's private key <reserve-priv>`_
      reserve_sig: EddsaSignature;
    }


  .. _WithdrawResponse:
  .. code-block:: tsref

    interface WithdrawResponse {
      // The blinded RSA signature over the `coin_ev`, affirms the coin's
      // validity after unblinding.
      ev_sig: BlindedRsaSignature;
    }

  .. _WithdrawError:
  .. code-block:: tsref

    interface WithdrawError {
      // Constant "Insufficient funds"
      error: string;

      // Amount left in the reserve
      balance: Amount;

      // History of the reserve's activity, in the same format as returned by /reserve/status.
      history: TransactionHistoryItem[]
    }

.. _deposit-par:

-------
Deposit
-------

Deposit operations are requested by a merchant during a transaction. For the
deposit operation, the merchant has to obtain the deposit permission for a coin
from their customer who owns the coin.  When depositing a coin, the merchant is
credited an amount specified in the deposit permission, possibly a fraction of
the total coin's value, minus the deposit fee as specified by the coin's
denomination.


.. _deposit:

.. http:POST:: /deposit

  Deposit the given coin and ask the exchange to transfer the given :ref:`amount`
  to the merchants bank account.  This API is used by the merchant to redeem
  the digital coins.  The request should contain a JSON object with the
  following fields:

  **Request:** The request body must be a `DepositRequest`_ object.

  **Response:**

  :status 200 Ok:
    The operation succeeded, the exchange confirms that no double-spending took place.  The response will include a `DepositSuccess`_ object.
  :status 401 Unauthorized:
    One of the signatures is invalid.
  :status 403 Forbidden:
    The deposit operation has failed because the coin has insufficient
    residual value; the request should not be repeated again with this coin.
    In this case, the response is a `DepositDoubleSpendError`_.
  :status 404 Not Found:
    Either the denomination key is not recognized (expired or invalid) or
    the wire type is not recognized.

  **Details:**

  .. _DepositRequest:
  .. code-block:: tsref

    interface DepositRequest {
      // Amount to be deposited, can be a fraction of the
      // coin's total value.
      f: Amount;

      // The merchant's account details. This must be a JSON object whose format
      // must correspond to one of the supported wire transfer formats of the exchange.
      // See `wireformats`_.
      wire: Object;

      // SHA-512 hash of the merchant's payment details from `wire`.  Although
      // strictly speaking redundant, this helps detect inconsistencies.
      // TODO: change to 'h_wire'.
      H_wire: HashCode;

      // SHA-512 hash of the contact of the merchant with the customer.  Further
      // details are never disclosed to the exchange.
      h_contract_terms: HashCode;

      // `coin's public key <eddsa-coin-pub>`_, both ECDHE and EdDSA.
      coin_pub: CoinPublicKey;

      // Hash of denomination RSA key with which the coin is signed
      denom_pub_hash: HashCode;

      // exchange's unblinded RSA signature of the coin
      ub_sig: RsaSignature;

      // timestamp when the contract was finalized, must match approximately the
      // current time of the exchange; if the timestamp is too far off, the
      // exchange returns "400 Bad Request" with an error code of
      // "TALER_EC_DEPOSIT_INVALID_TIMESTAMP".
      timestamp: Timestamp;

      // indicative time by which the exchange undertakes to transfer the funds to
      // the merchant, in case of successful payment.
      wire_deadline: Timestamp;

      // EdDSA `public key of the merchant <merchant-pub>`_, so that the client can identify the
      // merchant for refund requests.
      merchant_pub: EddsaPublicKey;

      // date until which the merchant can issue a refund to the customer via the
      // exchange, possibly zero if refunds are not allowed.
      refund_deadline: Timestamp;

      // Signature of `TALER_DepositRequestPS`_, made by the customer with the `coin's private key <coin-priv>`_
      coin_sig: EddsaSignature;
    }

  The deposit operation succeeds if the coin is valid for making a deposit and
  has enough residual value that has not already been deposited or melted.


  .. _`tsref-type-DepositSuccess`:
  .. _DepositSuccess:
  .. code-block:: tsref

     interface DepositSuccess {
      // The string constant "DEPOSIT_OK"
      status: string;

      // the EdDSA signature of `TALER_DepositConfirmationPS`_ using a current
      // `signing key of the exchange <sign-key-priv>`_ affirming the successful
      // deposit and that the exchange will transfer the funds after the refund
      // deadline, or as soon as possible if the refund deadline is zero.
      sig: EddsaSignature;

      // `public EdDSA key of the exchange <sign-key-pub>`_ that was used to
      // generate the signature.
      // Should match one of the exchange's signing keys from /keys.  It is given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      pub: EddsaPublicKey;
    }

  .. _DepositDoubleSpendError:
  .. code-block:: tsref

    interface DepositDoubleSpendError {
      // The string constant "insufficient funds"
      error: string;

      // Transaction history for the coin that is
      // being double-spended
      history: CoinSpendHistoryItem[];
    }

  .. _`tsref-type-CoinSpendHistoryItem`:
  .. _CoinSpendHistoryItem:
  .. code-block:: tsref

    interface CoinSpendHistoryItem {
      // Either "DEPOSIT", "MELT", "REFUND", "PAYBACK",
      // "OLD-COIN-PAYBACK" or "PAYBACK-REFRESH"
      type: string;

      // The total amount of the coin's value absorbed (or restored in the case of a refund) by this transaction.
      // Note that for deposit and melt this means the amount given includes
      // the transaction fee, while for refunds the amount given excludes
      // the transaction fee. The current coin value can thus be computed by
      // subtracting deposit and melt amounts and adding refund amounts from
      // the coin's denomination value.
      amount: Amount;

      // Deposit fee in case of type "DEPOSIT".
      deposit_fee: Amount;

      // public key of the merchant, for "DEPOSIT" operations.
      merchant_pub?: EddsaPublicKey;

      // date when the operation was made.
      // Only for "DEPOSIT", "PAYBACK", "OLD-COIN-PAYBACK" and
      // "PAYBACK-REFRESH" operations.
      timestamp?: Timestamp;

      // date until which the merchant can issue a refund to the customer via the
      // exchange, possibly zero if refunds are not allowed. Only for "DEPOSIT" operations.
      refund_deadline?: Timestamp;

      // Signature by the coin, only present if `type` is "DEPOSIT" or "MELT"
      coin_sig?: EddsaSignature;

      // Deposit fee in case of type "MELT".
      melt_fee: Amount;

      // Commitment from the melt operation, only for "MELT".
      rc?: TALER_RefreshCommitmentP;

      // Hash of the bank account from where we received the funds,
      // only present if `type` is "DEPOSIT"
      h_wire?: HashCode;

      // Deposit fee in case of type "REFUND".
      refund_fee?: Amount;

      // Hash over the proposal data of the contract that
      // is being paid (if type is "DEPOSIT") or refunded (if
      // `type` is "REFUND"); otherwise absent.
      h_contract_terms?: HashCode;

      // Refund transaction ID.  Only present if `type` is
      // "REFUND"
      rtransaction_id?: integer;

      // `EdDSA Signature <eddsa-sig>`_ authorizing the REFUND. Made with
      // the `public key of the merchant <merchant-pub>`_.
      // Only present if `type` is "REFUND"
      merchant_sig?: EddsaSignature;

      // public key of the reserve that will receive the funds, for "PAYBACK" operations.
      reserve_pub?: EddsaPublicKey;

      // Signature by the exchange, only present if `type` is "PAYBACK",
      // "OLD-COIN-PAYBACK" or "PAYBACK-REFRESH".  Signature is
      // of type TALER_SIGNATURE_EXCHANGE_CONFIRM_PAYBACK for "PAYBACK",
      // and of type TALER_SIGNATURE_EXCHANGE_CONFIRM_PAYBACK_REFRESH otherwise.
      exchange_sig?: EddsaSignature;

      // public key used to sign `exchange_sig`, only present if `exchange_sig` present.
      exchange_pub?: EddsaPublicKey;

      // Blinding factor of the revoked new coin,
      // only present if `type` is "REFRESH_PAYBACK".
      new_coin_blinding_secret: RsaBlindingKeySecret;

      // Blinded public key of the revoked new coin,
      // only present if `type` is "REFRESH_PAYBACK".
      new_coin_ev: RsaBlindingKeySecret;
    }

----------
Refreshing
----------

Refreshing creates `n` new coins from `m` old coins, where the sum of
denominations of the new coins must be smaller than the sum of the old coins'
denominations plus melting (refresh) and withdrawal fees charged by the exchange.
The refreshing API can be used by wallets to melt partially spent coins, making
transactions with the freshly exchangeed coins unlinkabe to previous transactions
by anyone except the wallet itself.

However, the new coins are linkable from the private keys of all old coins
using the /refresh/link request.  While /refresh/link must be implemented by
the exchange to achieve taxability, wallets do not really ever need that part of
the API during normal operation.

.. _refresh:
.. http:post:: /refresh/melt

  "Melts" coins.  Invalidates the coins and prepares for exchangeing of fresh
  coins.  Taler uses a global parameter `kappa` for the cut-and-choose
  component of the protocol, for which this request is the commitment.  Thus,
  various arguments are given `kappa`-times in this step.  At present `kappa`
  is always 3.


  :status 401 Unauthorized:
    One of the signatures is invalid.
  :status 200 OK:
    The request was succesful.  The response body is `MeltResponse`_ in this case.
  :status 403 Forbidden:
    The operation is not allowed as at least one of the coins has insufficient funds.  The response
    is `MeltForbiddenResponse`_ in this case.
  :status 404:
    the exchange does not recognize the denomination key as belonging to the exchange,
    or it has expired

  **Details:**


  .. code-block:: tsref

    interface MeltRequest {

      // `Coin public key <eddsa-coin-pub>`_, uniquely identifies the coin to be melted
      coin_pub: string;

      // Hash of the denomination public key, to determine total coin value.
      denom_pub_hash: HashCode;

      // Signature over the `coin public key <eddsa-coin-pub>`_ by the denomination.
      denom_sig: RsaSignature;

      // Signature by the `coin <coin-priv>`_ over the melt commitment.
      confirm_sig: EddsaSignature;

      // Amount of the value of the coin that should be melted as part of
      // this refresh operation, including melting fee.
      value_with_fee: Amount;

      // Melt commitment.  Hash over the various coins to be withdrawn.
      // See also `TALER_refresh_get_commitment()`
      rc: TALER_RefreshCommitmentP;

    }

  For details about the HKDF used to derive the new coin private keys and
  the blinding factors from ECDHE between the transfer public keys and
  the private key of the melted coin, please refer to the
  implementation in `libtalerutil`.

  .. _tsref-type-MeltResponse:
  .. _MeltResponse:
  .. code-block:: tsref

    interface MeltResponse {
      // Which of the `kappa` indices does the client not have to reveal.
      noreveal_index: number;

      // Signature of `TALER_RefreshMeltConfirmationPS`_ whereby the exchange
      // affirms the successful melt and confirming the `noreveal_index`
      exchange_sig: EddsaSignature;

      // `public EdDSA key <sign-key-pub>`_ of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  Again given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      exchange_pub: EddsaPublicKey;
    }


  .. _tsref-type-MeltForbiddenResponse:
  .. _MeltForbiddenResponse:
  .. code-block:: tsref

    interface MeltForbiddenResponse {
      // Always "insufficient funds"
      error: string;

      // public key of a melted coin that had insufficient funds
      coin_pub: EddsaPublicKey;

      // original total value of the coin
      original_value: Amount;

      // remaining value of the coin
      residual_value: Amount;

      // amount of the coin's value that was to be melted
      requested_value: Amount;

      // The transaction list of the respective coin that failed to have sufficient funds left.
      // Note that only the transaction history for one bogus coin is given,
      // even if multiple coins would have failed the check.
      history: CoinSpendHistoryItem[];
    }


.. http:post:: /refresh/reveal

  Reveal previously commited values to the exchange, except for the values
  corresponding to the `noreveal_index` returned by the /exchange/melt step.

  Errors such as failing to do proper arithmetic when it comes to calculating
  the total of the coin values and fees are simply reported as bad requests.
  This includes issues such as melting the same coin twice in the same session,
  which is simply not allowed.  However, theoretically it is possible to melt a
  coin twice, as long as the `value_with_fee` of the two melting operations is
  not larger than the total remaining value of the coin before the melting
  operations. Nevertheless, this is not really useful.

  :status 200 OK:
    The transfer private keys matched the commitment and the original request was well-formed.
    The response body is a `RevealResponse`_
  :status 409 Conflict:
    There is a problem between the original commitment and the revealed private
    keys.  The returned information is proof of the missmatch, and therefore
    rather verbose, as it includes most of the original /refresh/melt request,
    but of course expected to be primarily used for diagnostics.
    The response body is a `RevealConflictResponse`_.

  **Details:**

  Request body contains a JSON object with the following fields:

  .. code-block:: tsref

    interface RevealRequest {

      // Array of `n` new hash codes of denomination public keys to order.
      new_denoms_h: HashCode[];

      // Array of `n` entries with blinded coins,
      // matching the respective entries in `new_denoms`.
      coin_evs: CoinEnvelope[];

      // `kappa - 1` transfer private keys (ephemeral ECDHE keys)
      transfer_privs: EddsaPrivateKey[];

      // transfer public key at the `noreveal_index`.
      transfer_pub: EddsaPublicKey;

      // Array of `n` signatures made by the wallet using the old coin's private key,
      // used later to verify the /refresh/link response from the exchange.
      // Signs over a `TALER_CoinLinkSignaturePS`_
      link_sigs: EddsaSignature[];

      // The original commitment, used to match the /refresh/reveal
      // to the corresponding /refresh/melt operation.
      rc: HashCode;
    }


  .. _RevealResponse:
  .. code-block:: tsref

    interface RevealResponse {
      // List of the exchange's blinded RSA signatures on the new coins.  Each
      // element in the array is another JSON object which contains the signature
      // in the "ev_sig" field.
      ev_sigs: BlindedRsaSignature[];
    }


  .. _RevealConflictResponse:
  .. code-block:: tsref

    interface RevealConflictResponse {
      // Constant "commitment violation"
      error: string;

      // Detailed error code
      code: integer;

      // Commitment as calculated by the exchange from the revealed data.
      rc_expected: HashCode;

    }


.. http:get:: /refresh/link

  Link the old public key of a melted coin to the coin(s) that were exchangeed during the refresh operation.

  **Request:**

  :query coin_pub: melted coin's public key

  **Response:**

  :status 200 OK:
    All commitments were revealed successfully.  The exchange returns an array,
    typically consisting of only one element, in which each each element contains
    information about a melting session that the coin was used in.
  :status 404 Not Found:
    The exchange has no linkage data for the given public key, as the coin has not
    yet been involved in a refresh operation.

  **Details:**

  .. _tsref-type-LinkResponse:
  .. code-block:: tsref

    interface LinkResponse {
      // transfer ECDHE public key corresponding to the `coin_pub`, used to
      // compute the blinding factor and private key of the fresh coins.
      transfer_pub: EcdhePublicKey;

      // array with (encrypted/blinded) information for each of the coins
      // exchangeed in the refresh operation.
      new_coins: NewCoinInfo[];
    }

  .. _tsref-type-NewCoinInfo:
  .. code-block:: tsref

    interface NewCoinInfo {
      // RSA public key of the exchangeed coin.
      denom_pub: RsaPublicKey;

      // Exchange's blinded signature over the exchangeed coin.
      ev_sig: BlindedRsaSignature;

      // Blinded coin, to be verified by the wallet to protect against
      // a malicious exchange.
      coin_ev: CoinEnvelope;

      // Signature made by the old coin over the refresh request.
      // Signs over a `TALER_CoinLinkSignaturePS`_
      link_sig: EddsaSignature;
    }


-------------------
Emergency Cash-Back
-------------------

This API is only used if the exchange is either about to go out of
business or has had its private signing keys compromised (so in
either case, the protocol is only used in **abnormal**
situations).  In the above cases, the exchange signals to the
wallets that the emergency cash back protocol has been activated
by putting the affected denomination keys into the cash-back
part of the /keys response.  If and only if this has happened,
coins that were signed with those denomination keys can be cashed
in using this API.

   .. note::

      This is a proposed API, we are implementing it as bug #3887.

.. http:post:: /payback

  Demand that a coin be refunded via wire transfer to the original owner.

  **Request:** The request body must be a `PaybackRequest`_ object.

  **Response:**
  :status 200 OK:
  The request was succesful, and the response is a `PaybackConfirmation`.
  Note that repeating exactly the same request
  will again yield the same response, so if the network goes down during the
  transaction or before the client can commit the coin signature to disk, the
  coin is not lost.
  :status 401 Unauthorized: The coin's signature is invalid.
  :status 403 Forbidden: The coin was already used for payment.
  The response is a `DepositDoubleSpendError`_.
  :status 404 Not Found:
  The denomination key is not in the set of denomination
  keys where emergency pay back is enabled, or the blinded
  coin is not known to have been withdrawn.

  **Details:**

  .. _PaybackRequest:
  .. code-block:: tsref

    interface PaybackRequest {
      // Hash of denomination public key (RSA), specifying the type of coin the client
      // would like the exchange to pay back.
      denom_pub_hash: HashCode;

      // Signature over the `coin public key <eddsa-coin-pub>`_ by the denomination.
      denom_sig: RsaSignature;

      // coin's public key
      coin_pub: CoinPublicKey;

      // coin's blinding factor
      coin_blind_key_secret: RsaBlindingKeySecret;

      // Signature of `TALER_PaybackRequestPS`_ created with the `coin's private key <coin-priv>`_
      coin_sig: EddsaSignature;

      // Was the coin refreshed (and thus the payback should go to the old coin)?
      // Optional (for backwards compatibility); if absent, "false" is assumed
      refreshed?: boolean;
    }


  .. _PaybackConfirmation:
  .. code-block:: tsref

    interface PaybackConfirmation {
      // public key of the reserve that will receive the payback,
      // provided if refreshed was false.
      reserve_pub?: EddsaPublicKey;

      // public key of the old coin that will receive the payback,
      // provided if refreshed was true.
      old_coin_pub?: EddsaPublicKey;

      // How much will the exchange pay back (needed by wallet in
      // case coin was partially spent and wallet got restored from backup)
      amount: Amount;

      // Time by which the exchange received the /payback request.
      timestamp: Timestamp;

      // the EdDSA signature of `TALER_PaybackConfirmationPS`_ (refreshed false)
      // or `TALER_PaybackRefreshConfirmationPS_` (refreshed true) using a current
      // `signing key of the exchange <sign-key-priv>`_ affirming the successful
      // payback request, and that the exchange promises to transfer the funds
      // by the date specified (this allows the exchange delaying the transfer
      // a bit to aggregate additional payback requests into a larger one).
      exchange_sig: EddsaSignature;

      // Public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  It is given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      exchange_pub: EddsaPublicKey;
    }


-----------------------
Tracking wire transfers
-----------------------

This API is used by merchants that need to find out which wire
transfers (from the exchange to the merchant) correspond to which deposit
operations.  Typically, a merchant will receive a wire transfer with a
**wire transfer identifier** and want to know the set of deposit
operations that correspond to this wire transfer.  This is the
preferred query that merchants should make for each wire transfer they
receive.  If a merchant needs to investigate a specific deposit
operation (i.e. because it seems that it was not paid), then the
merchant can also request the wire transfer identifier for a deposit
operation.

Sufficient information is returned to verify that the coin signatures
are correct. This also allows governments to use this API when doing
a tax audit on merchants.

Naturally, the returned information may be sensitive for the merchant.
We do not require the merchant to sign the request, as the same requests
may also be performed by the government auditing a merchant.
However, wire transfer identifiers should have sufficient entropy to
ensure that obtaining a successful reply by brute-force is not practical.
Nevertheless, the merchant should protect the wire transfer identifiers
from his bank statements against unauthorized access, least his income
situation is revealed to an adversary. (This is not a major issue, as
an adversary that has access to the line-items of bank statements can
typically also view the balance.)


.. http:get:: /track/transfer

  Provides deposits associated with a given wire transfer.

  **Request:**

  :query wtid: raw wire transfer identifier identifying the wire transfer (a base32-encoded value)

  **Response:**

  :status 200 OK:
    The wire transfer is known to the exchange, details about it follow in the body.
    The body of the response is a `TrackTransferResponse`_.
  :status 404 Not Found:
    The wire transfer identifier is unknown to the exchange.

  .. _TrackTransferResponse:
  .. _tsref-type-TrackTransferResponse:
  .. code-block:: tsref

    interface TrackTransferResponse {
      // Total amount transferred
      total: Amount;

      // Applicable wire fee that was charged
      wire_fee: Amount;

      // public key of the merchant (identical for all deposits)
      merchant_pub: EddsaPublicKey;

      // hash of the wire details (identical for all deposits)
      H_wire: HashCode;

      // Time of the execution of the wire transfer by the exchange
      execution_time: Timestamp;

      // details about the deposits
      deposits: TrackTransferDetail[];

      // signature from the exchange made with purpose
      // `TALER_SIGNATURE_EXCHANGE_CONFIRM_WIRE_DEPOSIT`
      exchange_sig: EddsaSignature;

      // public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  Again given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      exchange_pub: EddsaSignature;
    }

  .. _tsref-type-TrackTransferDetail:
  .. code-block:: tsref

    interface TrackTransferDetail {
      // SHA-512 hash of the contact of the merchant with the customer.
      h_contract_terms: HashCode;

      // coin's public key, both ECDHE and EdDSA.
      coin_pub: CoinPublicKey;

      // The total amount the original deposit was worth.
      deposit_value: Amount;

      // applicable fees for the deposit
      deposit_fee: Amount;

    }

.. http:post:: /track/transaction

  Provide the wire transfer identifier associated with an (existing) deposit operation.

  **Request:** The request body must be a `TrackTransactionRequest`_ JSON object.

  **Response:**

  :status 200 OK:
    The deposit has been executed by the exchange and we have a wire transfer identifier.
    The response body is a `TrackTransactionResponse`_ object.
  :status 202 Accepted:
    The deposit request has been accepted for processing, but was not yet
    executed.  Hence the exchange does not yet have a wire transfer identifier.  The
    merchant should come back later and ask again.
    The response body is a `TrackTransactionAcceptedResponse`_.
  :status 401 Unauthorized: The signature is invalid.
  :status 404 Not Found: The deposit operation is unknown to the exchange

  **Details:**

  .. _tsref-type-TrackTransactionRequest:
  .. _TrackTransactionRequest:
  .. code-block:: tsref

    interface TrackTransactionRequest {
      // SHA-512 hash of the merchant's payment details.
      H_wire: HashCode;

      // SHA-512 hash of the contact of the merchant with the customer.
      h_contract_terms: HashCode;

      // coin's public key, both ECDHE and EdDSA.
      coin_pub: CoinPublicKey;

      // the EdDSA public key of the merchant, so that the client can identify
      // the merchant for refund requests.
      merchant_pub: EddsaPublicKey;

      // the EdDSA signature of the merchant made with purpose
      // `TALER_SIGNATURE_MERCHANT_TRACK_TRANSACTION` , affirming that it is really the
      // merchant who requires obtaining the wire transfer identifier.
      merchant_sig: EddsaSignature;
    }


  .. _tsref-type-TrackTransactionResponse:
  .. _TrackTransactionResponse:
  .. code-block:: tsref

    interface TrackTransactionResponse {
      // raw wire transfer identifier of the deposit.
      wtid: Base32;

      // when was the wire transfer given to the bank.
      execution_time: Timestamp;

      // The contribution of this coin to the total (without fees)
      coin_contribution: Amount;

      // Total amount transferred
      total_amount: Amount;

      // binary-only Signature_ for purpose `TALER_SIGNATURE_EXCHANGE_CONFIRM_WIRE`
      // whereby the exchange affirms the successful wire transfer.
      exchange_sig: EddsaSignature;

      // public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  Again given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      exchange_pub: EddsaPublicKey;
    }

  .. _tsref-type-TrackTransactionAcceptedResponse:
  .. _TrackTransactionAcceptedResponse:
  .. code-block:: tsref

    interface TrackTransactionAcceptedResponse {
      // time by which the exchange currently thinks the deposit will be executed.
      execution_time: Timestamp;
    }


-------
Refunds
-------

.. _refund:
.. http:POST:: /refund

  Undo deposit of the given coin, restoring its value.

  **Request:** The request body must be a `RefundRequest`_ object.

  **Response:**

  :status 200 Ok:
    The operation succeeded, the exchange confirms that the coin can now be refreshed.  The response will include a `RefundSuccess`_ object.
  :status 401 Unauthorized:
    Merchant signature is invalid.
  :status 404 Not found:
    The refund operation failed as we could not find a matching deposit operation (coin, contract, transaction ID and merchant public key must all match).
  :status 410 Gone:
    It is too late for a refund by the exchange, the money was already sent to the merchant.

  **Details:**

  .. _RefundRequest:
  .. code-block:: tsref

     interface RefundRequest {

      // Amount to be refunded, can be a fraction of the
      // coin's total deposit value (including deposit fee);
      // must be larger than the refund fee.
      refund_amount: Amount;

      // Refund fee associated with the given coin.
      // must be smaller than the refund amount.
      refund_fee: Amount;

      // SHA-512 hash of the contact of the merchant with the customer.
      h_contract_terms: HashCode;

      // coin's public key, both ECDHE and EdDSA.
      coin_pub: CoinPublicKey;

      // 64-bit transaction id of the refund transaction between merchant and customer
      rtransaction_id: number;

      // EdDSA public key of the merchant.
      merchant_pub: EddsaPublicKey;

      // EdDSA signature of the merchant affirming the refund.
      merchant_sig: EddsaPublicKey;

    }

  .. _RefundSuccess:
  .. code-block:: tsref

    interface RefundSuccess {
      // The string constant "REFUND_OK"
      status: string;

      // the EdDSA :ref:`signature` (binary-only) with purpose
      // `TALER_SIGNATURE_EXCHANGE_CONFIRM_REFUND` using a current signing key of the
      // exchange affirming the successful refund
      sig: EddsaSignature;

      // public EdDSA key of the exchange that was used to generate the signature.
      // Should match one of the exchange's signing keys from /keys.  It is given
      // explicitly as the client might otherwise be confused by clock skew as to
      // which signing key was used.
      pub: EddsaPublicKey;
   }


------------
The Test API
------------

The test API is not there to test the exchange, but to allow
clients of the exchange (merchant and wallet implementations)
to test if their implemenation of the cryptography is
binary-compatible with the implementation of the exchange.

.. http:POST:: /test/base32

  Test hashing and Crockford :ref:`base32` encoding.

  **Request:**

  .. code-block:: tsref

    {
      // some base32-encoded value
      input: Base32;
    }

  **Response:**

  .. code-block:: tsref

    {
      // the base32_-encoded hash of the input value
      output: Base32;
    }

.. http:POST:: /test/encrypt

  Test symmetric encryption.

  **Request:**

  .. code-block:: tsref

    {
      // Some `base32`_-encoded value
      input: Base32;

      // some `base32`_-encoded hash that is used to derive the symmetric key and
      // initialization vector for the encryption using the HKDF with "skey" and
      // "iv" as the salt.
      key_hash: Base32;
    }

  **Response:**


  .. code-block:: tsref

    {
      // the encrypted value
      output: Base32;
    }

.. http:POST:: /test/hkdf

  Test Hash Key Deriviation Function.

  **Request:**


  .. code-block:: tsref

    {
      // Some `base32`_-encoded value
      input: Base32;
    }

  **Response:**


  .. code-block:: tsref

    {
      // the HKDF of the input using "salty" as salt
      output: Base32;
    }

.. http:POST:: /test/ecdhe

  Test ECDHE.

  **Request:**

  .. code-block:: tsref

    {
      ecdhe_pub: EcdhePublicKey;
      ecdhe_priv: EcdhePrivateKey;
    }

  **Response:**

  .. code-block:: tsref

    {
      // ECDH result from the two keys
      ecdhe_hash: HashCode;
    }


.. http:POST:: /test/eddsa

  Test EdDSA.

  **Request:**

  .. code-block:: tsref

    {
      eddsa_pub: EddsaPublicKey;

      // EdDSA signature using purpose TALER_SIGNATURE_CLIENT_TEST_EDDSA. Note:
      // the signed payload must be empty, we sign just the purpose here.
      eddsa_sig: EddsaSignature;
    }

  **Response:**

  :status 200: the signature was valid
  :status 401 Unauthorized: the signature was invalid

  The exchange responds with another valid signature, which gives the
  client the opportunity to test its signature verification implementation.

  .. code-block:: tsref

    {
      // Another EdDSA public key
      eddsa_pub: EddsaPublicKey;

      // EdDSA signature using purpose TALER_SIGNATURE_EXCHANGE_TEST_EDDSA
      eddsa_sig: EddsaSignature;
    }


.. http:GET:: /test/rsa/get

  Obtain the RSA public key used for signing in /test/rsa/sign.

  **Response:**

  .. code-block:: tsref

    {
      // The RSA public key the client should use when blinding a value for the /test/rsa/sign API.
      rsa_pub: RsaPublicKey;
    }

.. http:POST:: /test/rsa/sign

  Test RSA blind signatures.

  **Request:**

  .. code-block:: tsref

    {
      // Blinded value to sign.
      blind_ev: BlindedRsaSignature;
    }

  **Response:**


  .. code-block:: tsref

    {
      // Blind RSA signature over the `blind_ev` using the private key
      // corresponding to the RSA public key returned by /test/rsa/get.
      rsa_blind_sig: BlindedRsaSignature;
    }

.. http:POST:: /test/transfer

  Test Transfer decryption.

  **Request:**

  .. code-block:: tsref

    {
      // Private transfer key
      trans_priv: string;

      // `Coin public key <eddsa-coin-pub>`_
      coin_pub: EddsaPublicKey;
    }

  **Response:**

  :status 200: the operation succeeded

  .. code-block:: tsref

    {
      // Decrypted transfer secret
      secret: string;
    }