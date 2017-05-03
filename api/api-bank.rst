..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016 INRIA
  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.
  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Marcello Stanisci

=========
Bank API
=========

The following APIs are served from banks, in order to allow exchanges to
deposit funds to money recipients.  A typical scenario for calling this
APIs is after a merchant has deposited coins to the exchange, and the exchange
needs to give real money to the merchant.

------------------
Administrative API
------------------

This API allows one user to send money to another user, withing the same "test"
bank.  The user calling it has to authenticate by including his credentials in the
request.

.. _bank-deposit:
.. http:post:: /admin/add/incoming

**Request:** The body of this request must have the format of a `BankDepositRequest`_.

**Response:**

:status 200 OK: The request has been correctly handled, so the funds have been transferred to the recipient's account

:status 400 Bad Request: The bank replies a `BankIncomingError`_ object

**Details:**

.. _BankDepositRequest:
.. code-block:: tsref

  interface BankDepositRequest {

    // Authentication method used
    auth: BankAuth;

    // JSON 'amount' object. The amount the caller wants to transfer
    // to the recipient's count
    amount: Amount;

    // Exchange base URL, used to perform tracking requests against the
    // wire transfer ID.  Note that in the actual bank wire transfer,
    // the schema may have to be encoded differently, i.e.
    // "https://exchange.com/" may become "https exchange.com" due to
    // character set restrictions.  It is the responsibility of the
    // wire transfer adapter to properly encode/decode the URL.
    // Payment service providers must ensure that their URL is short
    // enough to fit together with the wire transfer identifier into
    // the wire transfer subject of their respective banking system.
    exchange_url: string;

    // The id of this wire transfer, a `TALER_WireTransferIdentifierRawP`.
    // Should be encoded together with a checksum in actual wire transfers.
    // (See `TALER_WireTransferIdentifierP`_ for an encoding with CRC8.).
    wtid: base32;

    // The sender's account identificator
    debit_account: number;

    // The recipient's account identificator
    credit_account: number;

  }


.. _BankAuth:
.. code-block:: tsref

  interface BankAuth {

    // authentication type.  Accepted values are:
    // "basic", "digest", "token".
    type: string; 
    
    // Optional object containing data consistent with the
    // used authentication type.
    data: Object;

  }



.. _BankIncomingError:
.. code-block:: tsref

  interface BankIncomingError {

    // Human readable explanation of the failure.
    reason: string;

  }

--------
User API
--------

This API returns a list of his transactions, optionally limiting
the number of results.

.. http:post:: /history

  **Request**
  :query direction: Optional parameter that lets the caller specify
  only incoming, outgoing, or both types of records.  If not given,
  then the API will return both types; if set to `credit` (`debit`),
  only incoming (outgoing) records are returned.


  **Response** JSON array of type `BankTransaction`_.



.. _BankTransaction:
.. code-block:: tsref

  interface BankTransaction {
  
    // identification number of the record
    row_id: number;

    // Date of the transaction
    date: Timestamp;

    // Amount transferred
    amount: Amount;

    // "-" if the transfer was outgoing, "+" if it was
    // incoming.  This field is only present if the
    // argument `direction` was NOT given.
    sign: string;

    // Bank account number of the other party involved in the
    // transaction.
    counterpart: number; 
  
  }

..
  The counterpart currently only points to the same bank as
  the client using the bank.  A reasonable improvement is to
  specify a bank URI too, so that Taler can run across multiple
  banks.

.. _HistoryRequest:
.. code-block:: tsref

  interface HistoryRequest {
  
    // Authentication method used
    auth: BankAuth;

    // Only records with row id LESSER than `start' will
    // be returned.  NOTE, smaller row ids denote older db
    // records.  If this value equals zero, then the youngest
    // `delta' rows are returned.
    start: number;

    // Optional value denoting how many rows we want receive.
    // If not given, then it defaults to 10.
    delta: number;
  }
