..
  This file is part of GNU TALER.
  Copyright (C) 2018, 2019 Taler Systems SA

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

======================================
Backup and Synchronization Service API
======================================

The backup and synchronization service uses an EdDSA key
to identify the "account" of the user.  The key is Crockford
Base32-encoded in the URI to access the data and used to sign requests
as well as to encrypt the contents (see below).  These signatures are
provided in detached from as HTTP headers.

Once the user activates backup or synchronization, the client should
display the key as a QR code as well as in text format together
with the synchronization service's URL and ask the user to print this
key material and keep it safe.

The actual format of the backup is not relevant for the
backup and synchronization service, as the service must only ever see
a padded and encrypted version of the data.

However, there are a few general rules that will apply to
any version of the backup.  Still, except for the
32 byte minimum upload size, the synchronization service
itself cannot not enforce these rules.

*  First, the database should be compressed (i.e. gzip), then
   padded to a power of 2 in kilobytes or a multiple of
   megabytes, then encrypted and finally protected with
   an HDKF.
*  The encryption should use an SHA-512 nonce which
   is prefixed to the actual database, and combined with
   the master key to create the encryption symmetric secret.
   With every revision of the backup (but only real
   revisions or merge operations), a fresh nonce must be
   used to ensure that the symmetric secret differs every
   time.  HKDFs are used to derive symmetric key material
   for authenticated encryption (encrypt-then-mac or a
   modern AEAD-cipher like Keccak).  Given that AES is more
   easily available and will likey increase the code of
   the wallet less, AES plus a SHA-512 HMAC should suffice
   for now.
*  The client must enable merging databases in a way that is
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
   deletion operations supported by the client.  Deletion operations
   themselves are associated with an expiration time reflecting the
   expiration of the longest lasting record that they explicitly
   deleted.
   Purchases do not have an expiration time, thus they create
   a challenge if an indivdiual purchase is deleted. Thus, when
   an individual purchase is deleted, the client is to keep track
   of the deletion with a deletion record. The deletion record
   still includes the purchase amount and purchase date.  Thus,
   when purchases are deleted "in bulk" in a way that would have
   covered the individual deletion, such deletion records may
   still be subsumed by a more general deletion clause.  In addition
   to the date and amount, the deletion record should only contain
   a salted hash of the original purchase record's primary key,
   so as to minimize information leakage.
*  The database should contain a "last modified" timestamp to ensure
   we do not go backwards in time if the synchronization service is
   malicious.  Merging two databases means taking the max of the
   "last modified" timestamps, not setting it to the current time.
   The client should reject a "fast forward" database update if the
   result would imply going back in time.  If the client receives a
   database with a timestamp into the future, it must still
   increment it by the smallest possible amount when uploading an
   update.

It is assumed that the synchronization service is only ever accessed
over TLS, and that the synchronization service is trusted to not build
user's location profiles by linking client IP addresses and client
keys.


--------------------------
Receiving Terms of Service
--------------------------

.. http:get:: /terms

  Obtain the terms of service provided by the storage service.

  **Response:**

  Returns a `SyncTermsOfServiceResponse`.

  .. ts:def:: SyncTermsOfServiceResponse

    interface SyncTermsOfServiceResponse {
      // maximum backup size supported
      storage_limit_in_megabytes: number;

      // Fee for an account, per year.
      annual_fee: Amount;

    }


.. _sync:

.. http:get:: /$ACCOUNT-KEY

  Download latest version of the backup.
  The returned headers must include "Etags" based on
  the hash of the (encrypted) database. The server must
  check the client's caching headers and only return the
  full database if it has changed since the last request
  of the client.

  This method is generally only performed once per device
  when the private key and URL of a synchronization service are
  first given to the client on the respective device.  Once a
  client has made a backup, it should always use the POST method.

  A signature is not required, as (1) the account-key should
  be reasonably private and thus unauthorized users should not
  know how to produce the correct request, and (2) the
  information returned is encrypted to the private key anyway
  and thus virtually useless even to an attacker who somehow
  managed to obtain the public key.

  **Response**

  :status 200 OK:
    The body contains the current version of the backup
    as known to the server.

  :status 204 No content:
    This is a fresh account, no previous backup data exists at
    the server.

  :status 304 Not modified:
    The version available at the server is identical to that
    specified in the "If-None-Match" header.

  :status 404 Not found:
    The backup service is unaware of a matching account.

  :status 410 Gone:
    The backup service has closed operations.  The body will
    contain the latest version still available at the server.
    The body may be empty if no version is available.
    The user should be urged to find another provider.

  :status 429 Too many requests:
    This account has exceeded thresholds for the number of
    requests.  The client should try again later, and may want
    to decrease its synchronization frequency.

  .. note::

    "200 OK" responses include an HTTP header
    "Sync-Signature" with the signature of the
    client from the orginal upload, and an
    "Sync-Previous" with the version that was
    being updated (unless this is the first revision).
    "Sync-Previous" is only given to enable
    signature validation.


.. http:post:: /$ACCOUNT-KEY

  Upload a new version of the account's database, or download the
  latest version.  The request must include the "Expect: 100 Continue"
  header.  The client must wait for "100 Continue" before proceeding
  with the upload, regardless of the size of the upload.

  **Request**

  The request must include a "If-Match" header indicating the latest
  version of the account's database known to the client.  If the server
  knows a more recent version, it will respond with a "409 conflict"
  and return the server's version in the response.  The client must
  then merge the two versions before retrying the upload.  Note that
  a "409 Conflict" response will typically be given before the upload,
  (instead of "100 continue"), but may also be given after the upload,
  for example due to concurrent activities from other accounts on the
  same account!

  The request must also include an "Sync-Signature" signing
  the "If-Match" SHA-512 value and the SHA-512 hash of the body with
  the account private key.

  Finally, the SHA-512 hash of the body must also be given in an
  "Etag" header of the request (so that the signature can be verified
  before the upload is allowed to proceed).  We note that the use
  of "ETag" in HTTP requests is non-standard, but in this case
  logical.

  The uploaded body must have at least 32 bytes of payload (see
  suggested upload format beginning with an ephemeral key).

  :query paying:
     Optional argument providing an order identifier.
     The client is promising that it is already paying on a
     related order. This will cause the
     server to delay processing until the respective payment
     has arrived (if the operation requires a payment). Useful
     if the server previously returned a ``402 Payment required``
     and the client wants to proceed as soon as the payment
     went through.
  :query pay:
     Optional argument, any non-empty value will do,
     suggested is ``y`` for ``yes``.
     The client insists on making a payment for the respective
     account, even if this is not yet required. The server
     will respond with a ``402 Payment required``, but only
     if the rest of the request is well-formed (account
     signature must match).  Clients that do not actually
     intend to make a new upload but that only want to pay
     may attempt to upload the latest backup again, as this
     option will be checked before the ``304 Not modified``
     case.



  **Response**

  :status 204 No content:
    The transfer was successful, and the server has registered
    the new version.

  :status 304 Not modified:
    The server is already aware of this version of the client.
    Returned before 100 continue to avoid upload.

  :status 400 Bad request:
    Most likely, the uploaded body is too short (less than 32 bytes).

  :status 401 Unauthorized:
    The signature is invalid or missing (or body does not match).

  :status 402 Payment required:
    The synchronization service requires payment before the
    account can continue to be used.  The fulfillment URL
    should be the /$ACCOUNT-KEY URL, but can be safely ignored
    by the client.  The contract should be shown to the user
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

  :status 413 Request Entity Too Large:
    The requested upload exceeds the quota for the type of
    account.  The client should suggest to the user to
    migrate to another backup and synchronization service
    (like with "410 Gone").

  :status 429 Too many requests:
    This account has exceeded daily thresholds for the number of
    requests.  The client should try again later, and may want
    to decrease its synchronization frequency.

  .. note::

    Responses with a body include an HTTP header
    "Sync-Signature" with the signature of the
    client from the orginal upload, and an
    "If-Match" with the version that is
    being updated (unless this is the first revision).



---------------------------
Special constraints for Tor
---------------------------

We might introduce the notion of a "constraint" into the client's
database that states that the database is a "Tor wallet".  Then,
synchronizing a "Tor-wallet" with a non-Tor wallet should trigger a
stern warning and require user confirmation (as otherwise
cross-browser synchronization may weaken the security of Tor browser
users).


------------------------------------------------
Discovery of backup and synchronization services
------------------------------------------------

The client should keep a list of "default" synchronization services
per currency (by the currency the synchronization service accepts
for payment).  If a synchronization service is entirely free, it
should be kept in a special list that is always available.

Extending (or shortening) the list of synchronization services should
be possible using the same mechanism that is used to add/remove
auditors or exchanges.

The client should urge the user to make use of a synchronization
service upon first withdrawal, suggesting one that is free or
accepts payment in the respective currency. If none is available,
the client should warn the user about the lack of availalable
backups and synchronization and suggest to the user to find a
reasonable service.  Once a synchronization service was selected,
the client should urge the user to print the respective key
material.

When the client starts the first time on a new device, it should
ask the user if he wants to synchronize with an existing client,
and if so, ask the user to enter the respective key and the
(base) URL of the synchronization service.


-------------------------
Synchronization frequency
-------------------------

Generally, the client should attempt to synchronize at a randomized
time interval between 30 and 300 seconds of being started, unless it
already synchronized less than two hours ago already.  Afterwards,
the client should synchronize every two hours, or after purchases
exceed 5 percent of the last bulk amount that the user withdrew.
In all cases the exact time of synchronization should be randomized
between 30 and 300 seconds of the specified event, both to minimize
obvious correlations and to spread the load.

If the two hour frequency would exceed half of the rate budget offered
by the synchronization provider, it should be reduced to remain below
that threshold.


-------------------------------
Synchronization user experience
-------------------------------

The menu should include three entries for synchronization:

* "synchronize" to manually trigger synchronization,
    insensitive if no synchronization provider is available
* "export backup configuration" to re-display (and possibly
   print) the synchronization and backup parameters (URL and
   private key), insensitive if no synchronization
   provider is available, and
* "import backup configuration" to:

  * import another devices' synchronization options
    (by specifying URL and private key, or possibly
    scanning a QR code), or
  * select a synchronization provider from the list,
    including manual specification of a URL; here
    confirmation should only be possible if the provider
    is free or can be paid for; in this case, the
    client should trigger the payment interaction when
    the user presses the "select" button.
  * a special button to "disable synchronization and backup"

One usability issue here is that we are asking users to deal with a
private key.  It is likely better to map private keys to trustwords
(PEP-style).  Also, when putting private keys into a QR code, there is
the danger of the QR code being scanned and interpreted as a "public"
URL.  Thus, the QR code should use the schema
"taler-sync://$SYNC-DOMAIN/$SYNC-PATH#private-key" where
"$SYNC-DOMAIN" is the domainname of the synchronization service and
$SYNC-PATH the (usually empty) path.  By putting the private key after
"#", we may succeed in disclosing the value even to eager Web-ish
interpreters of URLs.  Note that the actual synchronization service
must use the HTTPS protocol, which means we can leave out this prefix.
