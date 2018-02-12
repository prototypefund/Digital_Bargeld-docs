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

      // Maximum liability the service assumes for lost wallet data
      liability: Amount;
    }


.. _sync:

.. http:get:: /$WALLET-KEY

  Download latest version of the wallet database.  Note that this
  operation should only be used the first time. Later, the wallet
  should always use POST.

  **Response**
  
  :status 200 OK:
    The body contains the current version of the wallet's
    database as known to the server.

  :status 204 No content:
    This is a fresh account, no previous wallet data exists at
    the server.

  :status 429 Too many requests:
    This account has exceeded daily thresholds for the number of
    requests.  Try again later.
    

  .. note::

    200 OK responses include an HTTP header
    "X-Taler-Sync-Signature" with the signature of the
    wallet from the orginal upload, and an
    "X-Taler-Sync-Previous" with the version that was
    being updated (unless this is the first revision).
    
.. http:post:: /$WALLET-KEY	       

  Upload a new version of the wallet's database, or download the
  latest version.  The request must include the "Expect: 100 Continue"
  header.  The client must wait for "100 Continue" before proceeding
  with the upload, regardless of the size of the upload.

  **Request**

  The request must include a "If-Match" (FIXME: correct?)
  header indicating the latest version of the wallet's database
  known to the client.  If the server knows a more recent version,
  it will respond with a 409 conflict and return the server's
  version in the response.  The client must then merge the two
  versions before retrying the upload.

  The request must also include an "X-Taler-Sync-Signature"
  signing the "If-Match" SHA-512 value and the SHA-512 hash
  of the body with the wallet private key.  The SHA-512 hash
  of the body must also be given in an "E-tag" header of the
  request (so that the signature can be verified before the
  upload is allowed to proceed).

  The uploaded body must have at least 32 bytes of payload.

  **Response**

  :status 204 No content:
    The transfer was successful, and the server has registered
    the new version.

  :status 304 Not modified:
    The server is already aware of this version of the wallet.
    Returned before 100 continue to avoid upload.
    
  :status 402 Payment required:
    The synchronization service requires payment before the
    account can continue to be used.
    
  :status 401 Not authorized:
    The signature is invalid or missing (or body does not match).

  :status 409 Conflict:
    The server has a more recent version than what is given
    in "If-Match".  The more recent version is returned. The
    client should merge the two versions and retry using the
    given response's "E-Tag" in the next attempt in "If-Match".

  :status 410 Gone:
    The backup service has closed operations.  The body will
    contain the latest version still available at the server.
    The user should be urged to find another provider.

  :status 411 Length required:
    The client must specify the content-length before
    attempting upload.
    
  :status 413 Payload too large:
    The requested upload exceeds the quota for the account.
    
  :status 429 Too many requests:
    This account has exceeded daily thresholds for the number of
    requests.  Try again later.

  .. note::

    Responses with a body include an HTTP header
    "X-Taler-Sync-Signature" with the signature of the
    wallet from the orginal upload, and an
    "X-Taler-Sync-Previous" with the version that was
    being updated (unless this is the first revision).


    


