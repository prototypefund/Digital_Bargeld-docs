..
  This file is part of GNU TALER.
  Copyright (C) 2018 Taler Systems SA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Christian Grothoff

.. _sync-api:

=============================================
Wallet Backup and Synchronization Service API
=============================================

The wallet backup and synchronization service uses an EdDSA wallet key
to identify the "account" of the user.  The wallet key is Crockford
Base32-encoded in the URI to access the data and used to sign requests
as well as to encrypt the contents (see below).  These signatures are
provided in detached from as HTTP headers.  The wallet key also
identifies the account for the purpose of payment.

Once the user activates backup or synchronization, the wallet should
display the wallet key as a QR code as well as in text format together
with the synchronization service's URL and ask the user to print this
key material and keep it safe.

The actual format of the wallet database is not relevant for the
backup and synchronization service, as the service must only ever see
a padded and encrypted version of the data.

However, there are a few general rules that will apply to
any version of the wallet database.  Still, except for the
32 byte minimum upload size, the synchronization service
itself cannot not enforce these rules.

  *  First, the database should be compressed (i.e. gzip), then
     padded to a power of 2 in kilobytes or a multiple of
     megabytes, then encrypted and finally protected with
     an HDKF.
  *  The encryption should use an ephemeral Curve25519 point that
     is prefixed to the actual database, and combined with
     the wallet key via ECDH to create a symmetric secret.
     With every revision of the wallet (but only real
     revisions or merge operations), a fresh ephemeral must be
     used to ensure that the symmetric secret differs every
     time.  HKDFs are used to derive symmetric key material
     for authenticated encryption (encrypt-then-mac or a
     modern AEAD-cipher like Keccak).  Given that AES is more
     easily available and will likey increase the code of
     the wallet less, AES plus a SHA-512 HMAC should suffice
     for now.
   * The wallet must enable merging databases in a way that is
     associative and commutative.  For most activities, this implies
     merging lists, applying expirations, dropping duplicates and
     sorting the result.  For deletions (operations by which the user
     removed records prior to their scheduled expiration), it means
     keeping a summarizing log of all deletion operations and applying
     the deletions after each merge.  A summarizing log of a deletion
     operation would combine two deletion operations of the form
     "delete all transactions smaller than amount X before time T" and
     "delete all transactions smaller than amount Y before time T"
     into "delete all transactions smaller than amount max(X,Y) before
     time T".  Similar summarizations should be applied to all
     deletion operations supported by the wallet.  Deletion operations
     themselves are associated with an expiration time reflecting the
     expiration of the longest lasting record that they explicitly
     deleted.
     Purchases do not have an expiration time, thus they create
     a challenge if an indivdiual purchase is deleted, as such
     deletions cannot be summarized as above.  On the other hand,
     remembering the deletion of the purchase is itself evidence
     that the user might have wanted to erase.  Thus, we first
     of all only store the hash of the primary key of the deleted
     transaction.  Second, we keep such deletion records only
     for a limited time, like one month.  Finally, when merging
     wallets, transactions older than one month must occur in
     both wallets to be preserved, while otherwise they must
     occur in either wallet to be integrated into the merged
     result.     
   * The database should contain a "last modified" timestamp to ensure
     we do not go backwards in time if the synchronization service is
     malicious.  Merging two databases means taking the max of the
     "last modified" timestamps, not setting it to the current time.
     The wallet should reject a "fast forward" database update if the
     result would imply going back in time.  If the wallet receives a
     database with a timestamp into the future, it must still
     increment it by the smallest possible amount when uploading an
     update.

It is assumed that the synchronization service is only ever accessed
over TLS, and that the synchronization service is trusted to not build
user's location profiles by linking client IP addresses and wallet
keys.

     
-------------------------- 
Receiving Terms of Service
--------------------------

.. http:get:: /terms

  Obtain the terms of service provided by the storage service.


  **Response:**

  Returns a `SyncTermsOfServiceResponse`_.

  .. _SyncTermsOfServiceResponse:
  .. _tsref-type-SyncTermsOfServiceResponse:
  .. code-block:: tsref

    interface SyncTermsOfServiceResponse {
      // maximum wallet database backup size supported
      storage_limit_in_megabytes: number; 

      // maximum number of sync requests per day (per account)
      daily_sync_limit: number;

      // how long after an account (or device) becomes dormant does the
      // service expire the respective records?
      inactive_expiration: relative-time;

      // Fee for an account, per year.
      annual_fee: Amount;

    }


.. _sync:

.. http:get:: /$WALLET-KEY

  Download latest version of the wallet database.
  
  This method is generally only performed once per device
  when the private key and URL of a synchronization service are
  first given to the wallet on the respective device.  Once a
  wallet has a database, it should always use the POST method.

  A signature is not required, as (1) the wallet-key should
  be reasonably private and thus unauthorized users should not
  know how to produce the correct request, and (2) the
  information returned is encrypted to the private key anyway
  and thus virtually useless even to an attacker who somehow
  managed to obtain the public key.
  
  **Response**
  
  :status 200 OK:
    The body contains the current version of the wallet's
    database as known to the server.

  :status 204 No content:
    This is a fresh account, no previous wallet data exists at
    the server.

  :status 402 Payment required:
    The synchronization service requires payment before the
    account can continue to be used.  The fulfillment URL
    should be the /$WALLET-KEY URL, but can be safely ignored
    by the wallet.  The contract should be shown to the user
    in the canonical dialog, possibly in a fresh tab.
    
  :status 410 Gone:
    The backup service has closed operations.  The body will
    contain the latest version still available at the server.
    The body may be empty if no version is available. 
    The user should be urged to find another provider.

  :status 429 Too many requests:
    This account has exceeded daily thresholds for the number of
    requests.  The wallet should try again later, and may want
    to decrease its synchronization frequency.

  .. note::

    "200 OK" responses include an HTTP header
    "X-Taler-Sync-Signature" with the signature of the
    wallet from the orginal upload, and an
    "X-Taler-Sync-Previous" with the version that was
    being updated (unless this is the first revision).
    "X-Taler-Sync-Previous" is only given to enable
    signature validation.
    
    
.. http:post:: /$WALLET-KEY	       

  Upload a new version of the wallet's database, or download the
  latest version.  The request must include the "Expect: 100 Continue"
  header.  The client must wait for "100 Continue" before proceeding
  with the upload, regardless of the size of the upload.

  **Request**

  The request must include a "If-Match" header indicating the latest
  version of the wallet's database known to the client.  If the server
  knows a more recent version, it will respond with a "409 conflict"
  and return the server's version in the response.  The client must
  then merge the two versions before retrying the upload.  Note that
  a "409 Conflict" response will typically be given before the upload,
  (instead of "100 continue"), but may also be given after the upload,
  for example due to concurrent activities from other wallets on the
  same account!

  The request must also include an "X-Taler-Sync-Signature" signing
  the "If-Match" SHA-512 value and the SHA-512 hash of the body with
  the wallet private key.

  Finally, the SHA-512 hash of the body must also be given in an
  "E-tag" header of the request (so that the signature can be verified
  before the upload is allowed to proceed).  We note that the use
  of "E-tag" in HTTP requests is non-standard, but in this case
  logical.

  The uploaded body must have at least 32 bytes of payload (see
  suggested upload format beginning with an ephemeral key).
  

  **Response**

  :status 204 No content:
    The transfer was successful, and the server has registered
    the new version.

  :status 304 Not modified:
    The server is already aware of this version of the wallet.
    Returned before 100 continue to avoid upload.
    
  :status 400 Bad request:
    Most likely, the uploaded body is too short (less than 32 bytes).
    
  :status 401 Unauthorized:
    The signature is invalid or missing (or body does not match).

  :status 402 Payment required:
    The synchronization service requires payment before the
    account can continue to be used.  The fulfillment URL
    should be the /$WALLET-KEY URL, but can be safely ignored
    by the wallet.  The contract should be shown to the user
    in the canonical dialog, possibly in a fresh tab.
    
  :status 409 Conflict:
    The server has a more recent version than what is given
    in "If-Match".  The more recent version is returned. The
    client should merge the two versions and retry using the
    given response's "E-Tag" in the next attempt in "If-Match".

  :status 410 Gone:
    The backup service has closed operations.  The body will
    contain the latest version still available at the server.
    The body may be empty if no version is available. 
    The user should be urged to find another provider.

  :status 411 Length required:
    The client must specify the "Content-length" header before
    attempting upload.  While technically optional by the
    HTTP specification, the synchronization service may require
    the client to provide the length upfront.
    
  :status 413 Payload too large:
    The requested upload exceeds the quota for the type of
    account.  The wallet should suggest to the user to
    migrate to another backup and synchronization service
    (like with "410 Gone").
    
  :status 429 Too many requests:
    This account has exceeded daily thresholds for the number of
    requests.  The wallet should try again later, and may want
    to decrease its synchronization frequency.

  .. note::

    Responses with a body include an HTTP header
    "X-Taler-Sync-Signature" with the signature of the
    wallet from the orginal upload, and an
    "X-Taler-Sync-Previous" with the version that was
    being updated (unless this is the first revision).
    "X-Taler-Sync-Previous" is only given to enable
    signature validation.



---------------------------
Special constraints for Tor
---------------------------

We might introduce the notion of a "constraint" into the wallet's
database that states that the database is a "Tor wallet".  Then,
synchronizing a "Tor-wallet" with a non-Tor wallet should trigger a
stern warning and require user confirmation (as otherwise
cross-browser synchronization may weaken the security of Tor browser
users).
    


