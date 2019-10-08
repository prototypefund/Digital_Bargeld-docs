..
  This file is part of GNU TALER.
  Copyright (C) 2019 Taler Systems SA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Christian Grothoff
  @author Dominik Meister
  @author Dennis Neufeld

==============================
The Anastasis RESTful JSON API
==============================

**Anastasis** is a service that allows the user to securely deposit a master
secret with an open set of escrow providers and recover it if it is lost.  To
uniquely identify users, an "unforgettable" **identifier** is used.  This
identifier should be difficult to guess for anybody but the user, but is not
expected to have sufficient entropy or secrecy to be cryptographically
secure. Examples for such identifier would be a concatenation of the full name
of the user and their social security or passport number(s).  For Swiss
citizens, the AHV number could also be used.  Some key material, but not the
master secret, is then derived from this **identifier** using different HKDFs.
These HKDFs are salted using the respective escrow provider's **server salt**,
which ensures that the accounts for the same user cannot be easily correlated
across the various Anastasis servers.

The Anastasis service uses an EdDSA **account key** to identify the account of
the user.  The account private key is derived from the user's identifier using
a computationally expensive cryptographic hash function H_1.  Using an
expensive hash algorithm is supposed to make it difficult for an adversary to
determine account keys by brute force without knowing the user's identifier.
However, it is assumed that an adversary performing a targeted attack can
compute the account key pair.

The public account key is Crockford base32-encoded in the URI to identify the
account, and used to sign requests.  These signatures are provided in base32
encoding using the HTTP header "Anastasis-Account-Signature".

Payloads are encrypted using AES-GCM with a symmetric key and IV derived from
the identifier and a nonce.  The nonce and the GCM tag are then pre-pended to
the resulting ciphertext and uploaded to the Anastasis server.  This is done
whenever encrypted data is stored with the server.

The **core secret** of the user is encrypted using a symmetric **master key**.
Recovering the master key requires the user to satisfy a particular
**policy**.  Policies specify a set of **escrow methods**, each of
which leads the user to a **key share**. Combining those key shares then
ultimately allows the user to obtain a **policy key**, which can be used to
decrypt the **master key**.  There can be many policies, satisfying any of
these will allow the user to recover the master key.  A **recovery document**
contains the encrypted core secret, a set of escrow methods and a set
of policies.

An escrow method specifies an Anastasis provider and how the user should
authorize themself. The **truth** API allows the user to provide the
(encrypted) key share to the respective escrow provider, as well as auxiliary
data required for the respective authorization method.


.. _salt:

-----------
Obtain salt
-----------

.. http:get:: /salt

  Obtain the salt used by the escrow provider.  Different providers
  will use different high-entropy salt values. The resulting
  **provider salt** is then used in various operations to ensure
  cryptographic operations differ by provider.  A provider must
  never change its salt value.


  **Response:**

  Returns a `SaltResponse`_.

  .. _SaltResponse:
  .. _tsref-type-SaltResponse:
  .. code-block:: tsref

    interface SaltResponse {
      // salt value, at least 128 bits of entropy
      server_salt: string;
    }

.. _terms:

--------------------------
Receiving Terms of Service
--------------------------

.. http:get:: /terms

  Obtain the terms of service provided by the escrow provider.

  **Response:**

  Returns a `SyncTermsOfServiceResponse`_.

  .. _SyncTermsOfServiceResponse:
  .. _tsref-type-SyncTermsOfServiceResponse:
  .. code-block:: tsref

    interface SyncTermsOfServiceResponse {
      // maximum key database backup size supported
      storage_limit_in_megabytes: number;

      // maximum number of sync requests per day (per account)
      daily_sync_limit: number;

      // minimum supported protocol version
      min_version: number;

      // maximum supported protocol version
      max_version: number;

      // supported authentication methods
      auth_methods: string[];

      // how long the service expire the deposited truth?
      truth_expiration: relative-time;

      // Fee per transaction.
      transaction_fee: Amount;

    }

.. _escrow:

-------------
Manage policy
-------------

This API is used by the Anastasis client to deposit or request encrypted
recovery documents with the escrow provider.  Generally, a client will deposit
the same encrypted recovery document with each escrow provider, but provide
different truth to each escrow provider.

Operations by the client are identified and authorized by $ACCOUNT_PUB, which
should be kept secret from third parties. $ACCOUNT_PUB should be an account
public key using the Crockford base32-encoding.


.. http:get:: /policy/$ACCOUNT_PUB[?version=$NUMBER]

  Get the customer's policy and encrypted master key share data.  If "version"
  is not specified, returns the latest available version.  If
  "version" is specified, returns the policy with the respective
  "version".  The response must begin with the nonce and
  an AES-GCM tag and continue with the ciphertext.  Once decrypted, the
  plaintext is expected to contain:

  * the escrow policy
  * the separately encrypted master public key

  Note that the key shares required to decrypt the master public key are
  not included, as for this the client needs to obtain authorization.
  The policy does provide sufficient information for the client to determine
  how to authorize requests for **truth**.

  The client MAY provide an "If-not-modified-since" header with an Etag.
  In that case, the server MUST additionally respond with an "304" status
  code in case the resource matches the provided Etag.

  :status 200 OK:
    The escrow provider responds with an `EncryptedRecoveryDocument`_ object.
  :status 304 Not modified:
    The client requested the same ressource he already owns.
  :status 400 Bad request:
    The $ACCOUNT_PUB is not an EdDSA public key.
  :status 402 Payment Required:
    The account's balance is too low for the specified operation.
    See the Taler payment protocol specification for how to pay.
  :status 403 Forbidden:
    The required account signature was invalid.
  :status 404 Not Found:
    The requested resource was not found.

  *Anastasis-Version*: $NUMBER --- The server must return actual version number in header;
  the client specifies version number in the header of the request (if not specified in request, the server returns latest version of EncryptedRecoveryDocument_ ).

  *Etag*: Etag, hash over the body for caching and to prevent redundancies. If status is 200 OK, the server must send the Etag.

  *If-modified-since*: If the client has previously received an Etag from the server, he has to send it with this request (to avoid unnecessary downloads).

  *If-None-Match*: If this is not the very first request of the client, this contains the Etag-Value which the client has reveived before from the server. 
  The client must send this header with every request (except for the very first request).

  *Anastasis-Account-Signature*: The client must provide Base-32 encoded EdDSA signature over hash of body with $ACCOUNT_PRIV, affirming desire to download the requested encrypted recovery document.

.. http:post:: /policy/$ACCOUNT_PUB

  Upload a new version of the customer's policy and encrypted master key share data.
  If request has been seen before, the server should do nothing, and otherwise store the new version.
  The body must begin with a nonce, an AES-GCM tag and continue with the ciphertext.  The format
  is the same as specified for the response of the GET method. The
  Anastasis server cannot validate the format, but MAY impose
  minimum and maximum size limits.

  :status 204 No Content:
    The policy was accepted and stored.  "Anastasis-Version" and "Anastasis-UUID" headers
    incidate what version and UUID was assigned to this policy upload by the server.
  :status 304 Not modified:
    The same encrypted recovery document was previously accepted and stored.  "Anastasis-Version" header
    incidates what version was previously assigned to this encrypted recovery document.
  :status 400 Bad request:
    The $ACCOUNT_PUB is not an EdDSA public key.  The response body may elaborate on the error.
  :status 402 Payment Required:
    The account's balance is too low for the specified operation.
    See the Taler payment protocol specification for how to pay.
    The response body SHOULD provide various means for payment.
  :status 403 Forbidden:
    The required account signature was invalid.  The response body may elaborate on the error.
  :status 413 Request Entity Too Large:
    The upload is too large *or* too small. The response body may elaborate on the error.

    
  *Anastasis-Version*: $NUMBER --- The server must return the actual version number it determined.
    Only generated if the status is 204 or 304.

  *If-not-modified-since*: The client must provide an Etag with the hash over the body (to avoid unnecessary re-uploads).

  *Anastasis-Policy-Signature*: The client must provide Base-32 encoded EdDSA signature over hash of body with $ACCOUNT_PRIV, affirming desire to upload an encrypted recovery document.

  *Payment-Identifier*: Base-32 encoded 32-byte payment identifier that was included in a previous payment (see 402 status code). Used to allow the server to check that the client paid for the upload (to protect the server against DoS attacks) and that the client knows a real secret of financial value (as the kdf_id might be known to an attacker). If this header is missing in the client's request (or the associated payment has exceeded the upload limit), the server must return a 402 response.  When making payments, the server must include a fresh, randomly-generated payment-identifier in the payment request.

  **Details:**

  .. _EncryptedRecoveryDocument:
  .. code-block:: tsref

    interface EncryptedRecoveryDocument {
      // Nonce used to compute the (iv,key) pair for encryption of the
      // encrypted_compressed_recovery_document.
      nonce: byte[32];

      // Authentication tag
      aes_gcm_tag: byte[16];

      // Variable-size encrypted recovery document. After decryption,
      // this contains a gzip compressed JSON-encoded `RecoveryDocument`_.
      // The salt of the HKDF for this encryption must include the
      // string "EDR".
      encrypted_compressed_recovery_document: byte[]

    }

  .. _RecoveryDocument:
  .. code-block:: tsref

    interface RecoveryDocument {
      // Account identifier at backup provider, AES-encrypted with
      // the (symmetric) master_key, i.e. an URL
      // https://sync.taler.net/$BACKUP_ID and
      // a private key to decrypt the backup.  Anastasis is oblivious
      // to the details of how this is ultimately encoded.
      backup_account: byte[];

      // List of escrow providers and selected authentication method
      methods: EscrowMethod[];

      // List of possible decryption policies
      policy: EscrowPolicy[];

    }

  .. _EscrowMethod:
  .. code-block:: tsref

    interface EscrowMethod {
      // URL of the escrow provider (including possibly this Anastasis server)
      provider_url : string;

      // Name of the escrow method (e.g. security question, SMS etc.)
      escrow_method: string;

      // UUID of the escrow method (see /truth/ API below).
      uuid: uuid;

      // Salt used to encrypt the truth on the Anastasis server.
      truth_salt: byte[32];

      // The challenge to give to the user (i.e. the security question
      // if this is challenge-response).
      // (Q: as string in base32 encoding?)
      // (Q: what is the mime-type of this value?)
      //
      // For some methods, this value may be absent.
      //
      // The plaintext challenge is not revealed to the
      // Anastasis server.
      challenge: byte[];

    }

  .. _EscrowPolicy:
  .. code-block:: tsref

    interface DecryptionPolicy {
      // Salt included to encrypt master key share when
      // using this decryption policy.
      policy_salt: byte[32];

      // Master key, AES-encrypted with key derived from
      // salt and secrets revealed by the following list of
      // escrow methods identified by UUID.
      encrypted_master_key: byte[32];

      // List of escrow methods identified by their uuid
      uuid: uuid[];

    }


.. _truth:

--------------
Managing truth
--------------

This API is used by the Anastasis client to deposit or request **truth** with
the escrow provider.  As with the policy, the user may be identified and
authorized by $ACCOUNT_PUB.  Note that authentification of the user is
optional when uploading truth and depends on the server.  An Anastasis-server
may agree to store truth for free for a certain time period, or charge per
truth without associating the truth with an account.  Hence the "account"
argument and signature may be optional.

.. http:post:: /truth/$UUID[?account=$ACCOUNT_PUB]

  :status 204 No content:
    Truth stored successfully.
  :status 304 Not modified:
    The same truth was previously accepted and stored under this UUID.
  :status 400 Bad request:
    The $ACCOUNT_PUB is not an EdDSA public key.  The response body may elaborate on the error.
  :status 402 Payment Required:
    The account's balance is too low for the specified operation (or the server
    requires payment to store truth per item).
    See the Taler payment protocol specification for how to pay.
    The response body SHOULD provide various means for payment.
  :status 403 Forbidden:
    The required account signature was invalid.  The response body may elaborate on the error.
  :status 409 Conflict:
    The server already has some truth stored under this UUID. The client should check that it
    is generating UUIDs with enough entropy.
  :status 412 Precondition Failed:
    The selected authentication method is not supported on this provider.

  *Anastasis-Account-Signature*: The client must provide Base-32 encoded EdDSA signature over hash of body with $ACCOUNT_PRIV, affirming the desire to upload the truth; only present if "account" is specified in the URL.

  **Details:**

  .. _Truth:
  .. code-block:: tsref

    interface Truth {
      // Key share method, i.e. "security question", "SMS", "e-mail", ...
      method: String;

      // The explicit key material to reveal (Q: as string in base32 encoding?)
      // Contains a KeyShare_, but in compact binary encoding.
      //
      // The salt of the HKDF for the encryption of this
      // value must include the string "EKS".   Depending
      // on the method, the HKDF may additionally include
      // bits from the response (i.e. some hash over the
      // answer to the security question)
      encrypted_key_share: byte[];

      // Nonce used to generate the (iv,key) from kdf_id to AES-GCM encrypt the truth.
      nonce: byte[32];

      // Authentication tag over the encrypted_key_share
      key_share_aes_gcm_tag: byte[32];
      
      // ground truth, i.e. H(challenge answer),
      // phone number, e-mail address, picture, fingerprint, ...
      // base32 encoded
      //
      // The truth MUST NOT be revealed to the user, even
      // after successful authentication (of course the user
      // was originally aware when establishing the truth).
      truth: string;

      // mime type of truth, i.e. text/ascii, image/jpeg, etc.
      truth_mime: string;

    }


.. http:get:: /truth/$UUID[?response=$RESPONSE]

  :status 200 OK:
    EncryptedKeyShare_ is returned in body (in binary).
  :status 202 Accepted:
    The escrow provider will respond out-of-band (i.e. SMS).
    The body may contain human-readable instructions on next steps.
  :status 303 See Other:
    The provider redirects for authentication (i.e. video identification/WebRTC).
    If the client is not a browser, it should launch a browser at the URL
    given in the "Location" header and allow the user to re-try the operation
    after successful authorization.
  :status 402 Payment Required:
    The account's balance is too low for the specified operation (or the server
    requires payment to store truth per item).
    See the Taler payment protocol specification for how to pay.
    The response body SHOULD provide various means for payment.
  :status 403 Forbidden:
    The server requires a valid "response" to the challenge associated with the UUID.
  :status 404 Not Found:
    The server does not know any truth under the given UUID.
  :status 412 Precondition Failed:
    The escrow provider responds with an EscrowChallenge_ object containing
    details on the challenge the user has to satisfy (see below).
  :status 503 Service Unavailable:
    Server is out of Service.

  **Details:**

  .. _EncryptedKeyShare:
  .. code-block:: tsref

    interface EncryptedKeyShare {
      // Nonce used to compute the decryption (iv,key) pair.
      nonce: byte[32];

      // Authentication tag
      aes_gcm_tag: byte[32];

      // Encrypted key-share in base32 encoding.
      // After decryption, this yields a KeyShare_.  Note that
      // the KeyShare_ MUST be encoded as a fixed-size binary
      // block (instead of in JSON encoding).
      //
      // The salt of the HKDF for the encryption of this
      // value must include the string "EKS".   Depending
      // on the method, the HKDF may additionally include
      // bits from the response (i.e. some hash over the
      // answer to the security question)
      encrypted_key_share: byte[]; 

    }

  .. _KeyShare:
  .. code-block:: tsref

    interface KeyShare {
      // Key material to concatenate with policy_salt and KDF to derive
      // the key to decrypt the master key.
      key_share: byte[32];

      // Signature over method, uuid, and key_share.
      account_sig: EdDSA-Signature;

    }

  .. _EscrowChallenge:
  .. code-block:: tsref

    interface EscrowChallenge {
      // ground truth, i.e. challenge question,
      // phone number, e-mail address, picture, fingerprint, ...
      truth: byte[];

      // mime type of truth, i.e. text/ascii, image/jpeg, etc.
      truth_mime: string;

    }
