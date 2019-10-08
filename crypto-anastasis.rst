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


==========================================
Specification of Cryptography in Anastasis
==========================================
This document specifies the Crypto used in Anastasis.

-------------------
1. Key derivations
-------------------

EdDSA and ECDHE public keys are always points on Curve25519 and represented
using the standard 256 bit Ed25519 compact format.  The binary representation
is converted to Crockford Base32 when transmitted inside JSON or as part of
URLs.

To start, a user provides their private, unique and unforgettable
**identifier** as a seed to identify their account.  For example, this could
be a social security number together with their full name.  Specifics may
depend on the cultural context, in this document we will simply refer to this
information as the **user_identifier**.

This user_identifier will be first hashed with SCrypt, to provide a **kdf_id**
which will be used to derive other keys later. The Hash must also include the
respective **server_salt**. This also ensures that the **kdf_id** is different
on each server. The use of SCrypt and the respective server_salt is intended
to make it difficult to brute-force **kdf_id** values and help protect user's
privacy. Also this ensures that the kdf_ids on every server differs. However,
we do not assume that the **user_identifier** or the **kdf_id** cannot be
determined by an adversary performing a targeted attack, as a user's
**user_identifier** is likely to always be known to state actors and may
likely also be available to other actors.


.. code-block:: tsref

    kdf_id := SCrypt( user_identifier, server_salt, keysize )

**user_identifier**: The secret defined from the user beforehand.

**server_salt**: The salt from the Server

**keysize**: The desired output size of the KDF, here 32 bytes.


1.1 Verification
^^^^^^^^^^^^^^^^

For users to authorize **policy** operations we need an EdDSA key pair.  As we
cannot assure that the corresponding private key is truly secret, such policy
operations must never be destructive: Should an adversary learn the private
key, they could access (and with the kdf_id decrypt) the user's policy (but
not the core secret), or upload a new version of the policy (but not delete an
existing version).

For the generation of the private key we use the kdf_id as the entropy source,
hash it to derive a base secret which will then be processed to fit the
requirements for EdDSA private keys.  From the private key we can then
generate the corresponding public key.  Here, "ver" is used as a salt for the
HKDF to ensure that the result differs from other cases where we hash
kdf_id.

.. code-block:: tsref

    ver_secret:= HKDF(kdf_id, "ver", keysize)
    eddsa_priv := eddsa_d_to_a(ver_secret)
    eddsa_pub := get_EdDSA_Pub(eddsa_priv)


**HKDF()**: The HKDF-function uses to phases: First we use HMAC-SHA512 for the extraction phase, then HMAC-SHA256 is used for expansion phase.

**kdf_id**: Hashed user_identifier.

**key_size**: Size of the output, here 32 bytes.

**ver_secret**: Derived key from the kdf_id, serves as intermediate step for the generation of the private key

**eddsa_d_to_a()**: Function which converts the ver_key to a valid EdDSA private key. Specifically, assuming the value eddsa_priv is in a 32-byte array "digest", the function clears and sets certain bits as follows:

.. code-block:: tsref

   digest[0] = (digest[0] & 0x7f) | 0x40;
   digest[31] &= 0xf8;

**eddsa_priv**: The generated EdDSA private key.

**eddsa_pub**: The generated EdDSA public key.


1.2 Encryption
^^^^^^^^^^^^^^

For symmetric encryption of data we use AES256-GCM. For this we need a
symmetric key and an initialization vector (IV).  To ensure that the
symmetric key changes for each encryption operation, we compute the
key material using an HKDF over a nonce and the kdf_id.

.. code-block:: tsref

    (iv,key) := HKDF(kdf_id, nonce, keysize + ivsize)

**HKDF()**: The HKDF-function uses to phases: First we use HMAC-SHA512 for the extraction phase, then HMAC-SHA256 is used for expansion phase.

**kdf_id**: Hashed user_identifier

**keysize**: Size of the AES symmetric key, here 32 bytes

**ivsize**: Size of the AES GCM IV, here 12 bytes

**prekey**: Original key material.

**nonce**: 32-byte nonce, must never match "ver" (which it cannot as the length is different).

**key**: Symmetric key which is later used to encrypt the documents with AES256-GCM.
 
**iv**: IV which will be used for AES-GCM

----------------------------
2. Key Usage
----------------------------

The keys we have generated, are now used to encrypt the recovery_document and
the key_share of the user.

2.1 Encryption
^^^^^^^^^^^^^^

Before every encryption a 32-byte nonce is generated.
From this the symmetric key is computed as described above.
We use AES256-GCM for the encryption of the recovery_document and
key_share. 

.. code-block:: tsref

    (encrypted_recovery_document, aes_gcm_tag) = AES256_GCM(recovery_document, key, iv)
    (encrypted_key_share, aes_gcm_tag) = AES256_GCM(key_share, key, iv)

**encrypted_recovery_document**: The encrypted RecoveryDocument (recovery_document) which contains the policies. 

**encrypted_key_share**: The encrypted KeyShare (key_share).

2.2 Signatures
^^^^^^^^^^^^^^

The EdDSA keys are used to sign the data sent from the client to the
server. Everything the client sends to server is signed. The following algorithm is equivalent for **Anastasis-Policy-Signature**.

.. code-block:: tsref

    (anastasis-account-signature) = eddsa_sign(h_body, eddsa_priv)
    ver_res = eddsa_verifiy(h_body, anastasis-account-signature, eddsa_pub)

**anastasis-account-signature**: Signature over the hash of body. 

**h_body**: The hashed body.

**ver_res**: A boolean value. True: Verification passed, False: Verification failed.
