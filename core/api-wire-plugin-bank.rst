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

==========================
Taler Bank Wire Plugin API
==========================

This section describes the API that the ``taler-bank`` wire plugin expects.
This API is currently implemented by the Taler Demo Bank, as well as by
LibEuFin (work in progress).


--------------
Authentication
--------------

The wire plugin authenticates requests to the bank service via
`HTTP basic auth <https://tools.ietf.org/html/rfc7617>`.

-------------------
Making Transactions
-------------------


.. http:post:: /taler/transaction

  This API allows the exchange to make a transaction, typically to a merchant.  The bank account
  of the exchange is not included in the request, but instead derived from the user name in the
  authentication header.

  To make the API idempotent, the client must include a nonce.  Requests with the same nonce
  are rejected unless the request is the same.

  **Request:** The body of this request must have the format of a `TransactionRequest`.

  **Response:**

  :status 200 OK:
    The request has been correctly handled, so the funds have been transferred to
    the recipient's account.  The body is a `TransactionResponse`
  :status 400 Bad Request: The bank replies a `BankError` object.
  :status 406 Not Acceptable: The request had wrong currency; the bank replies a `BankError` object.

  **Details:**

  .. ts:def:: TransactionResponse

    interface TransactionResponse {

      // Timestamp related to the transaction being made.
      timestamp: Timestamp;

      // Opaque of the transaction that the bank has made.
      row_id: string;
    }

  .. ts:def:: TransactionRequest

    interface TransactionRequest {
      // Nonce to make the request idempotent.  Requests with the same
      // transaction_uid that differ in any of the other fields
      // are rejected.
      transaction_uid: HashCode;

      // Amount to transfer.
      amount: Amount;

      // Reserve public key, will be included in the details
      // of the wire transfer.
      reserve_pub: string;

      // The recipient's account identifier as a payto URI
      credit_account: string;
    }


  .. ts:def:: BankError

    interface BankError {

      // Human readable explanation of the failure.
      error: string;

      // Numeric Taler error code (`TALER_ErrorCode`)
      ec: number;
    }


--------------------------------
Querying the transaction history
--------------------------------

.. http:get:: /taler/history

  Return a list of transactions made to the exchange.  The transaction
  list shall be filtered to only include transactions that include a valid
  reserve public key.

  The bank account of the exchange is determined via the user name in the ``Authorization`` header.
  In fact the transaction history might come from a "virtual" account, where multiple real bank accounts
  are merged into one history.

  Transactions are identified by an opaque string identifier, referred to here
  as "row ID".  The semantics of the row ID (including its sorting order) are
  determined by the bank server and completely opaque to the client.

  The list of returned transactions is determined by a row ID *starting point*
  and a signed non-zero integer *delta*:

  * If *delta* is positive, return a list of up to *delta* transactions (all matching
    the filter criteria) strictly **after** the starting point.  The transactions are sorted
    in **ascending** order of the row ID.
  * If *delta* is negative, return a list of up to *-delta* transactions (allmatching
    the filter criteria) strictly **before** the starting point.  The transactions are sorted
    in **descending** order of the row ID.

  If *starting point* is not explicitly given, it defaults to:

  * A value that is **smaller** than all other row IDs if *delta* is **positive**.
  * A value that is **larger** than all other row IDs if *delta* is **negative**.

  **Request**

  :query start: *Optional.*
    Row identifier to explicitly set the *starting point* of the query.
  :query delta:
    The *delta* value that determines the range of the query.
  :query long_poll_ms: *Optional.*  If this parameter is specified and the
    result of the query would be empty, the bank will wait up to ``long_poll_ms``
    milliseconds for new transactions that match the query to arrive and only
    then send the HTTP response.  A client must never rely on this behavior, as
    the bank may return a response immediately or after waiting only a fraction
    of ``long_poll_ms``.

  **Response**

  :status 200 OK: JSON object whose field ``transactions`` is an array of type `BankTransaction`.
  :status 204 No content: in case no records exist for the targeted user.

  .. ts:def:: BankTransaction

    interface BankTransaction {

      // Opaque identifier of the returned record
      row_id: string;

      // Date of the transaction
      date: Timestamp;

      // Amount transferred
      amount: Amount;

      // Payto URI to identify the sender of funds
      debit_account: string;

      // The reserve public key extracted from the transaction details
      reserve_pub: string;
    }

