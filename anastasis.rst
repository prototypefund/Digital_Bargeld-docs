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

=========
Anastasis
=========

Anastasis is a service that allows the user to securely deposit a
**core secret** with an open set of escrow providers and recover it if the secret is
lost.  The **core secret** itself is protected from the escrow providers by
encrypting it with a **master key**.  The main objective of Anastasis is to
ensure that the user can reliably recover the **core secret**, while making
this difficult for everyone else.  Furthermore, it is assumed that the user is
unable to reliably remember any secret with sufficiently high entropy, so we
cannot simply encrypt using some other key material in posession of the user.

To uniquely identify users, an "unforgettable" **identifier** is used.  This
identifier should be difficult to guess for anybody but the user. However, the
**identifier** is not expected to have sufficient entropy or secrecy to be
cryptographically secure. Examples for such identifier would be a
concatenation of the full name of the user and their social security or
passport number(s).  For Swiss citizens, the AHV number could also be used.

The adversary model of Anastasis has two types of adversaries: weak
adversaries which do not know the user's **identifier**, and strong
adversaries which somehow do know a user's **identifier**.  For weak
adversaries the system guarantees full confidentiality.  For strong
adversaries, breaking confidentiality additionally requires that Anastasis
escrow providers must have colluded.  The user is able to specify a set of
**policies** which determine which Anastasis escrow providers would need to
collude to break confidentiality. These policies also set the bar for the user
to recover their core secret.

A **recovery document** includes all of the information a user needs to
recover access to their core secret.  It specifies a set of **escrow
methods**, which specify how the user should convince the Anastasis server
that they are "real".  Escrow methods can for example include SMS-based
verification, Video-identfication or a security question.  For each escrow
method, the Anastasis server is provided with **truth**, that is data the
Anastasis operator may learn during the recovery process to authenticate the
user.  Examples for truth would be a phone number (for SMS), a picture of the
user (for video identification), or the (hash of) a security answer.  A strong
adversary is assumed to be able to learn the truth, while weak adversaries
must not.  In addition to a set of escrow methods and associated Anastasis
server operators, the **recovery document** also specifies **policies**, which
describe the combination(s) of the escrow methods that suffice to obtain
access to the core secret.  For example, a **policy** could say that the
escrow methods (A and B) suffice, and a second policy may permit (A and C).  A
different user may choose to use the policy that (A and B and C) are all
required.  Anastasis imposes no limit on the number of policies in a
**recovery document**, or the set of providers or escrow methods involved in
guarding a user's secret.  Weak adversaries must not be able to deduce
information about a user's **recovery document** (except for its length, which
may be exposed to an adversary which monitors the user's network traffic).


----------------------
Anastasis Cryptography
----------------------

When a user needs to interact with Anastasis, the system first derives some key
material, but not the master secret, from the user's **identifier** using
different HKDFs.  These HKDFs are salted using the respective escrow
provider's **server salt**, which ensures that the accounts for the same user
cannot be easily correlated across the various Anastasis servers.

Each Anastasis server uses an EdDSA **account key** to identify the account of
the user.  The account private key is derived from the user's **identifier** using
a computationally expensive cryptographic hash function.  Using an
expensive hash algorithm is assumed to make it infeasible for a weak adversary to
determine account keys by brute force (without knowing the user's identifier).
However, it is assumed that a strong adversary performing a targeted attack can
compute the account key pair.

The public account key is Crockford base32-encoded in the URI to identify the
account, and used to sign requests.  These signatures are also provided in
base32-encoding and transmitted using the HTTP header
"Anastasis-Account-Signature".

When confidential data is uploaded to an Anastasis server, the respective
payload is encrypted using AES-GCM with a symmetric key and initialization
vector derived from the **identifier** and a high-entropy **nonce**.  The
nonce and the GCM tag are prepended to the ciphertext before being uploaded to
the Anastasis server.  This is done whenever confidential data is stored with
the server.

The **core secret** of the user is (AES) encrypted using a symmetric **master
key**.  Recovering this master key requires the user to satisfy a particular
**policy**.  Policies specify a set of **escrow methods**, each of which leads
the user to a **key share**. Combining those key shares (by hashing) allows
the user to obtain a **policy key**, which can be used to decrypt the **master
key**.  There can be many policies, satisfying any of these will allow the
user to recover the master key.  A **recovery document** contains the
encrypted **core secret**, a set of escrow methods and a set of policies.




---------------
Key derivations
---------------

EdDSA and ECDHE public keys are always points on Curve25519 and represented
using the standard 256 bit Ed25519 compact format.  The binary representation
is converted to Crockford Base32 when transmitted inside JSON or as part of
URLs.

To start, a user provides their private, unique and unforgettable
**identifier** as a seed to identify their account.  For example, this could
be a social security number together with their full name.  Specifics may
depend on the cultural context, in this document we will simply refer to this
information as the **identifier**.

This identifier will be first hashed with SCrypt, to provide a **kdf_id**
which will be used to derive other keys later. The Hash must also include the
respective **server_salt**. This also ensures that the **kdf_id** is different
on each server. The use of SCrypt and the respective server_salt is intended
to make it difficult to brute-force **kdf_id** values and help protect user's
privacy. Also this ensures that the kdf_ids on every server differs. However,
we do not assume that the **identifier** or the **kdf_id** cannot be
determined by an adversary performing a targeted attack, as a user's
**identifier** is likely to always be known to state actors and may
likely also be available to other actors.


.. code-block:: tsref

    kdf_id := SCrypt( identifier, server_salt, keysize )

**identifier**: The secret defined from the user beforehand.

**server_salt**: The salt from the Server

**keysize**: The desired output size of the KDF, here 32 bytes.


Verification
^^^^^^^^^^^^

For users to authorize "policy" operations we need an EdDSA key pair.  As we
cannot assure that the corresponding private key is truly secret, such policy
operations must never be destructive: Should an adversary learn the private
key, they could access (and with the kdf_id decrypt) the user's policy (but
not the core secret), or upload a new version of the
**encrypted recovery document** (but not delete an existing version).

For the generation of the private key we use the **kdf_id** as the entropy source,
hash it to derive a base secret which will then be processed to fit the
requirements for EdDSA private keys.  From the private key we can then
generate the corresponding public key.  Here, "ver" is used as a salt for the
HKDF to ensure that the result differs from other cases where we hash
**kdf_id**.

.. code-block:: tsref

    ver_secret:= HKDF(kdf_id, "ver", keysize)
    eddsa_priv := eddsa_d_to_a(ver_secret)
    eddsa_pub := get_EdDSA_Pub(eddsa_priv)


**HKDF()**: The HKDF-function uses to phases: First we use HMAC-SHA512 for the extraction phase, then HMAC-SHA256 is used for expansion phase.

**kdf_id**: Hashed identifier.

**key_size**: Size of the output, here 32 bytes.

**ver_secret**: Derived key from the kdf_id, serves as intermediate step for the generation of the private key

**eddsa_d_to_a()**: Function which converts the ver_key to a valid EdDSA private key. Specifically, assuming the value eddsa_priv is in a 32-byte array "digest", the function clears and sets certain bits as follows:

.. code-block:: tsref

   digest[0] = (digest[0] & 0x7f) | 0x40;
   digest[31] &= 0xf8;

**eddsa_priv**: The generated EdDSA private key.

**eddsa_pub**: The generated EdDSA public key.


Encryption
^^^^^^^^^^

For symmetric encryption of data we use AES256-GCM. For this we need a
symmetric key and an initialization vector (IV).  To ensure that the
symmetric key changes for each encryption operation, we compute the
key material using an HKDF over a nonce and the kdf_id.

.. code-block:: tsref

    (iv,key) := HKDF(kdf_id, nonce, keysize + ivsize)

**HKDF()**: The HKDF-function uses to phases: First we use HMAC-SHA512 for the extraction phase, then HMAC-SHA256 is used for expansion phase.

**kdf_id**: Hashed identifier

**keysize**: Size of the AES symmetric key, here 32 bytes

**ivsize**: Size of the AES GCM IV, here 12 bytes

**prekey**: Original key material.

**nonce**: 32-byte nonce, must never match "ver" (which it cannot as the length is different).

**key**: Symmetric key which is later used to encrypt the documents with AES256-GCM.

**iv**: IV which will be used for AES-GCM


---------
Key Usage
---------

The keys we have generated are then used to encrypt the **recovery document** and
the **key_share** of the user.


Encryption
^^^^^^^^^^

Before every encryption a 32-byte nonce is generated.
From this the symmetric key is computed as described above.
We use AES256-GCM for the encryption of the **recovery document** and
the **key_share**.

.. code-block:: tsref

    (iv0, key0) = HKDF(key_id, nonce0, keysize + ivsize)
    (encrypted_recovery_document, aes_gcm_tag) = AES256_GCM(recovery_document, key0, iv0)
    (iv_i, key_i) = HKDF(key_id, nonce_i, keysize + ivsize)
    (encrypted_key_share_i, aes_gcm_tag_i) = AES256_GCM(key_share_i, key_i, iv_i)

**encrypted_recovery_document**: The encrypted **recovery document** which contains the escrow methods, policies and the encrypted **core secret**.

**encrypted_key_share_i**: The encrypted **key_share** which the escrow provider must release upon successful authentication.  Here, **i** must a positive number used to iterate over the various **key shares** used for the various **escrow methods** at the various providers.


Signatures
^^^^^^^^^^

The EdDSA keys are used to sign the data sent from the client to the
server. Everything the client sends to server is signed. The following
algorithm is equivalent for **Anastasis-Policy-Signature**.

.. code-block:: tsref

    (anastasis-account-signature) = eddsa_sign(h_body, eddsa_priv)
    ver_res = eddsa_verifiy(h_body, anastasis-account-signature, eddsa_pub)

**anastasis-account-signature**: Signature over the SHA-512 hash of the body using the purpose code TALER_SIGNATURE_ANASTASIS_POLICY_UPLOAD (1400) (see GNUnet EdDSA signature API for the use of purpose)

**h_body**: The hashed body.

**ver_res**: A boolean value. True: Signature verification passed, False: Signature verification failed.


When requesting policy downloads, the client must also provide a signature:

.. code-block:: tsref
    (anastasis-account-signature) = eddsa_sign(version, eddsa_priv)
    ver_res = eddsa_verifiy(version, anastasis-account-signature, eddsa_pub)

**anastasis-account-signature**: Signature over the SHA-512 hash of the body using the purpose code TALER_SIGNATURE_ANASTASIS_POLICY_DOWNLOAD (1401) (see GNUnet EdDSA signature API for the use of purpose)

**version**: The version requested as a 64-bit integer, 2^64-1 for the "latest version".

**ver_res**: A boolean value. True: Signature verification passed, False: Signature verification failed.



-------------------
Encryption of Truth
-------------------

FIXME: missing crypto! (See "EKS" below!)
In particular, underspecified for the security answer ("may additionally include"...).


---------------------------
Availability Considerations
---------------------------

Anastasis considers two main threats against availability. First, the
Anastasis server operators must be protected against denial-of-service attacks
where an adversary attempts to exhaust operator's resources.  The API protects
against these attacks by allowing operators to set fees for all
operations. Furthermore, all data stored comes with an expiration logic, so an
attacker cannot force servers to store data indefinitively.

A second availability issue arises from strong adversaries that may be able to
compute the account keys of some user.  While we assume that such an adversary
cannot successfully authenticate against the truth, the account key does
inherently enable these adversaries to upload a new policy for the account.
This cannot be prevented, as the legitimate user must be able to set or change
a policy using only the account key.  To ensure that an adversary cannot
exploit this, policy uploads first of all never delete existing policies, but
merely create another version.  This way, even if an adversary uploads a
malicious policy, a user can still retrieve an older version of the policy to
recover access to their data.  This append-only storage for policies still
leaves a strong adversary with the option of uploading many policies to
exhaust the Anastasis server's capacity.  We limit this attack by requiring a
policy upload to include a reference to a **payment secret** from a payment
made by the user.  Thus, a policy upload requires both knowledge of the
**identity** and making a payment.  This effectively prevents and adversary
from using the append-only policy storage from exhausting Anastasis server
capacity.



-------------
Anastasis API
-------------

.. _salt:


Obtain salt
^^^^^^^^^^^

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


Receiving Terms of Service
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. http:get:: /terms

  Obtain the terms of service provided by the escrow provider.

  **Response:**

  Returns a `EscrowTermsOfServiceResponse`_.

  .. _EscrowTermsOfServiceResponse:
  .. _tsref-type-EscrowTermsOfServiceResponse:
  .. code-block:: tsref

    interface EscrowTermsOfServiceResponse {

      // minimum supported protocol version
      min_version: number;

      // maximum supported protocol version
      max_version: number;

      // supported authentication methods
      auth_methods: AuthenticationMethod[];

      // Payment required to maintain an account to store policy documents for a month.
      // Users can pay more, in which case the storage time will go up proportionally.
      monthly_account_fee: Amount;

      // Amount required per policy upload. Note that the amount is NOT charged additionally
      // to the monthly_storage_fee. Instead, when a payment is made, the amount is
      // divided by the policy_upload_fee (and rounded down) to determine how many
      // uploads can be made under the associated **payment secret**.
      policy_upload_ratio: Amount;

      // maximum policy upload size supported
      policy_size_limit_in_bytes: number;

      // maximum truth upload size supported
      truth_size_limit_in_bytes: number;

      // how long until the service expires deposited truth
      // (unless refreshed via another POST)?
      truth_expiration: relative-time;

      // Payment required to upload truth.  To be paid per upload.
      truth_upload_fee: Amount;

      // Limit on the liability that the provider is offering with
      // respect to the services provided.
      liability_limit: Amount;

      // HTML text describing the terms of service in legalese.
      // May include placeholders like "${truth_upload_fee}" to
      // reference entries in this response.
      tos: string;

    }

    interface AuthenticationMethod {
      // name of the authentication method
      name: string;

      // Fee for accessing truth using this method
      usage_fee: Amount;

    }

.. _escrow:


Manage policy
^^^^^^^^^^^^^

This API is used by the Anastasis client to deposit or request encrypted
recovery documents with the escrow provider.  Generally, a client will deposit
the same encrypted recovery document with each escrow provider, but provide
different truth to each escrow provider.

Operations by the client are identified and authorized by $ACCOUNT_PUB, which
should be kept secret from third parties. $ACCOUNT_PUB should be an account
public key using the Crockford base32-encoding.


.. http:get:: /policy/$ACCOUNT_PUB[?version=$NUMBER]

  Get the customer's encrypted recovery document.  If "version"
  is not specified, the server returns the latest available version.  If
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

  The client MAY provide an "If-None-Match" header with an Etag.
  In that case, the server MUST additionally respond with an "304" status
  code in case the resource matches the provided Etag.

  :status 200 OK:
    The escrow provider responds with an `EncryptedRecoveryDocument`_ object.
  :status 304 Not modified:
    The client requested the same ressource it already knows.
  :status 400 Bad request:
    The $ACCOUNT_PUB is not an EdDSA public key.
  :status 402 Payment Required:
    The account's balance is too low for the specified operation.
    See the Taler payment protocol specification for how to pay.
  :status 403 Forbidden:
    The required account signature was invalid.
  :status 404 Not Found:
    The requested resource was not found.

  *Anastasis-Version*: $NUMBER --- The server must return actual version of the encrypted recovery document via this header.
  If the client specified a version number in the header of the request, the server must return that version. If the client
  did not specify a version in the request, the server returns latest version of the EncryptedRecoveryDocument_.

  *Etag*: Set by the server to the Base32-encoded SHA512 hash of the body. Used for caching and to prevent redundancies. The server MUST send the Etag if the status code is 200 OK.

  *If-None-Match*: If this is not the very first request of the client, this contains the Etag-value which the client has reveived before from the server.
  The client SHOULD send this header with every request (except for the first request) to avoid unnecessary downloads.

  *Anastasis-Account-Signature*: The client must provide Base-32 encoded EdDSA signature over hash of body with $ACCOUNT_PRIV, affirming desire to download the requested encrypted recovery document.  The purpose used MUST be TALER_SIGNATURE_ANASTASIS_POLICY_DOWNLOAD (1401).

.. http:post:: /policy/$ACCOUNT_PUB

  Upload a new version of the customer's encrypted recovery document.
  If request has been seen before, the server should do nothing, and otherwise store the new version.
  The body must begin with a nonce, an AES-GCM tag and continue with the ciphertext.  The format
  is the same as specified for the response of the GET method. The
  Anastasis server cannot fully validate the format, but MAY impose
  minimum and maximum size limits.

  :status 204 No Content:
    The encrypted recovery document was accepted and stored.  "Anastasis-Version" and "Anastasis-UUID" headers
    incidate what version and UUID was assigned to this encrypted recovery document upload by the server.
  :status 304 Not modified:
    The same encrypted recovery document was previously accepted and stored.  "Anastasis-Version" header
    incidates what version was previously assigned to this encrypted recovery document.
  :status 400 Bad request:
    The $ACCOUNT_PUB is not an EdDSA public key or mandatory headers are missing.
    The response body MUST elaborate on the error using a Taler error code in the typical JSON encoding.
  :status 402 Payment Required:
    The account's balance is too low for the specified operation.
    See the Taler payment protocol specification for how to pay.
    The response body MAY provide alternative means for payment.
  :status 403 Forbidden:
    The required account signature was invalid.  The response body may elaborate on the error.
  :status 409 Conflict:
    The *If-Match* Etag does not match the latest prior version known to the server.
  :status 413 Request Entity Too Large:
    The upload is too large *or* too small. The response body may elaborate on the error.


  *If-Match*: Unless the client expects to upload the first encrypted recovery document to this account, the client
    SHOULD provide an Etag matching the latest version already known to the server.  If this
    header is present, the server MUST refuse the upload if the latest known version prior to
    this upload does not match the given Etag.

  *If-None-Match*: This header MUST be present and set to the SHA512 hash (Etag) of the body by the client.
    The client SHOULD also set the "Expect: 100-Continue" header and wait for "100 continue"
    before uploading the body.  The server MUST
    use the Etag to check whether it already knows the encrypted recovery document that is about to be uploaded.
    The server MUST refuse the upload with a "304" status code if the Etag matches
    the latest version already known to the server.

  *Anastasis-Policy-Signature*: The client must provide Base-32 encoded EdDSA signature over hash of body with $ACCOUNT_PRIV, affirming desire to upload an encrypted recovery document.

  *Payment-Identifier*: Base-32 encoded 32-byte payment identifier that was included in a previous payment (see 402 status code). Used to allow the server to check that the client paid for the upload (to protect the server against DoS attacks) and that the client knows a real secret of financial value (as the **kdf_id** might be known to an attacker). If this header is missing in the client's request (or the associated payment has exceeded the upload limit), the server must return a 402 response.  When making payments, the server must include a fresh, randomly-generated payment-identifier in the payment request.

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


Managing truth
^^^^^^^^^^^^^^

This API is used by the Anastasis client to deposit or request **truth** with
the escrow provider.

An **escrow method** specifies an Anastasis provider and how the user should
authorize themself.  The **truth** API allows the user to provide the
(encrypted) key share to the respective escrow provider, as well as auxiliary
data required for such an respective escrow method.

An Anastasis-server may store truth for free for a certain time period, or
charge per truth operation using GNU Taler.

.. http:post:: /truth/$UUID

  Upload a Truth-Object according to the policy the client created before (see RecoveryDocument_).
  If request has been seen before, the server should do nothing, and otherwise store the new object.
  The body must begin with a nonce, an AES-GCM tag and continue with the ciphertext.  In addition, 
  the name of the chosen key share method, the Base32-encoded ground truth and the MIME type of 
  Truth must be included in the body. 
  The Anastasis server cannot fully validate the format, but MAY impose
  minimum and maximum size limits.

  :status 204 No content:
    Truth stored successfully.
  :status 304 Not modified:
    The same truth was previously accepted and stored under this UUID.  The
    Anastasis server must still update the expiration time for the truth when returning
    this response code.
  :status 402 Payment Required:
    This server requires payment to store truth per item.
    See the Taler payment protocol specification for how to pay.
    The response body MAY provide alternative means for payment.
  :status 403 Forbidden:
    The required account signature was invalid.  The response body may elaborate on the error.
  :status 409 Conflict:
    The server already has some truth stored under this UUID. The client should check that it
    is generating UUIDs with enough entropy.
  :status 412 Precondition Failed:
    The selected authentication method is not supported on this provider.


  **Details:**

  .. _Truth:
  .. code-block:: tsref

    interface Truth {
      // Nonce used to generate the (iv,key) from kdf_id to AES-GCM encrypt the truth.
      nonce: byte[32];

      // Authentication tag over the encrypted_key_share
      key_share_aes_gcm_tag: byte[32];

      // The encrypted key material to reveal, in base32 encoding.
      // Contains a KeyShare_.
      //
      // The salt of the HKDF for the encryption of this
      // value must include the string "EKS".   Depending
      // on the method, the HKDF may additionally include
      // bits from the response (i.e. some hash over the
      // answer to the security question)
      encrypted_key_share: byte[];

      // Key share method, i.e. "security question", "SMS", "e-mail", ...
      method: String;

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

  Get the stored encrypted key share. If $RESPONSE is specified by the client, the server checks
  if $RESPONSE matches the expected response according to the challenge sent to the client before.
  If $RESPONSE is not specified, the server will response with a challenge according to the key share 
  method (e.g. ask the security question or send a SMS with a code) and await the answer within $RESPONSE. 
  When $RESPONSE is correct, the server responses with the encrypted key share.

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
    The service requires payment for access to truth.
    See the Taler payment protocol specification for how to pay.
    The response body MAY provide alternative means for payment.
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


----------------------
Authentication Methods
----------------------

This section describes the supported authentication methods in
detail.


SMS (sms)
^^^^^^^^^

Sends an SMS with a code to the users phone.
FIXME: details!

Video identification (vid)
^^^^^^^^^^^^^^^^^^^^^^^^^^

Requires the user to identify via video-call.
FIXME: details!


Security question (qa)
^^^^^^^^^^^^^^^^^^^^^^

Asks the user a security question.
FIXME: details!


Post-Indent (post)
^^^^^^^^^^^^^^^^^^

Physical address verification via snail mail.
FIXME: details!
