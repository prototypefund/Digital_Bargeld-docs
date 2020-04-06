..
  This file is part of GNU TALER.
  Copyright (C) 2019-2020 Taler Systems SA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

===========================
Taler Wire Gateway HTTP API
===========================

This section describes the API offered by the Taler wire gateway. The API is
used by the exchange to trigger transactions and query incoming transactions, as
well as by the auditor to query incoming and outgoing transactions.

This API is currently implemented by the Taler Demo Bank, as well as by
LibEuFin (work in progress).


--------------
Authentication
--------------

The bank library authenticates requests to the wire gatway via
`HTTP basic auth <https://tools.ietf.org/html/rfc7617>`_.

-------------------
Making Transactions
-------------------

.. http:post:: ${BASE_URL}/transfer

  This API allows the exchange to make a transaction, typically to a merchant.  The bank account
  of the exchange is not included in the request, but instead derived from the user name in the
  authentication header and/or the request base URL.

  To make the API idempotent, the client must include a nonce.  Requests with the same nonce
  are rejected unless the request is the same.

  **Request:** The body of this request must have the format of a `TransactionRequest`.

  **Response:**

  :status 200 OK:
    The request has been correctly handled, so the funds have been transferred to
    the recipient's account.  The body is a `TransferResponse`
  :status 400 Bad Request: Request malformed. The bank replies with an `ErrorDetail` object.
  :status 401 Unauthorized: Authentication failed, likely the credentials are wrong.
  :status 404 Not found: The endpoint is wrong or the user name is unknown. The bank replies with an `ErrorDetail` object.
  :status 409 Conflict:
    A transaction with the same ``transaction_uid`` but different transaction details
    has been submitted before.

  **Details:**

  .. ts:def:: TransferResponse

    interface TransferResponse {

      // Timestamp that indicates when the wire transfer will be executed.
      // In cases where the wire transfer gateway is unable to know when
      // the wire transfer will be executed, the time at which the request
      // has been received and stored will be returned.
      // The purpose of this field is for debugging (humans trying to find
      // the transaction) as well as for taxation (determining which
      // time period a transaction belongs to).
      timestamp: Timestamp;

      // Opaque of the transaction that the bank has made.
      row_id: SafeUint64;
    }


  .. ts:def:: TransactionRequest

    interface TransactionRequest {
      // Nonce to make the request idempotent.  Requests with the same
      // transaction_uid that differ in any of the other fields
      // are rejected.
      request_uid: HashCode;

      // Amount to transfer.
      amount: Amount;

      // Base URL of the exchange.  Shall be included by the bank gateway
      // in the approriate section of the wire transfer details.
      exchange_base_url: string;

      // Wire transfer identifier chosen by the exchange,
      // used by the merchant to identify the Taler order(s)
      // associated with this wire transfer.
      wtid: ShortHashCode;

      // The recipient's account identifier as a payto URI
      credit_account: string;
    }


--------------------------------
Querying the transaction history
--------------------------------


.. http:get:: ${BASE_URL}/history/incoming

  Return a list of transactions made from or to the exchange.

  Incoming transactions must contain a valid reserve public key.  If a bank
  transaction does not confirm to the right syntax, the wire gatway must not
  report it to the exchange, and sent funds back to the sender if possible.

  The bank account of the exchange is determined via the base URL and/or the
  user name in the ``Authorization`` header.  In fact the transaction history
  might come from a "virtual" account, where multiple real bank accounts are
  merged into one history.

  Transactions are identified by an opaque numeric identifier, referred to here
  as "row ID".  The semantics of the row ID (including its sorting order) are
  determined by the bank server and completely opaque to the client.

  The list of returned transactions is determined by a row ID *starting point*
  and a signed non-zero integer *delta*:

  * If *delta* is positive, return a list of up to *delta* transactions (all matching
    the filter criteria) strictly **after** the starting point.  The transactions are sorted
    in **ascending** order of the row ID.
  * If *delta* is negative, return a list of up to *-delta* transactions (all matching
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

  :status 200 OK: JSON object of type `IncomingHistory`.
  :status 400 Bad Request: Request malformed. The bank replies with an `ErrorDetail` object.
  :status 401 Unauthorized: Authentication failed, likely the credentials are wrong.
  :status 404 Not found: The endpoint is wrong or the user name is unknown. The bank replies with an `ErrorDetail` object.

  .. ts:def:: IncomingHistory

    interface IncomingHistory {

      // Array of incoming transactions
      incoming_transactions : IncomingBankTransaction[];

    }

  .. ts:def:: IncomingBankTransaction

    interface IncomingBankTransaction {

      // Opaque identifier of the returned record
      row_id: SafeUint64;

      // Date of the transaction
      date: Timestamp;

      // Amount transferred
      amount: Amount;

      // Payto URI to identify the receiver of funds.
      // This must be one of the exchange's bank accounts.
      credit_account: string;

      // Payto URI to identify the sender of funds
      debit_account: string;

      // The reserve public key extracted from the transaction details.
      reserve_pub: EddsaPublicKey;
    }


.. http:get:: ${BASE_URL}/history/outgoing

  Return a list of transactions made by the exchange, typically to a merchant.

  The bank account of the exchange is determined via the base URL and/or the
  user name in the ``Authorization`` header.  In fact the transaction history
  might come from a "virtual" account, where multiple real bank accounts are
  merged into one history.

  Transactions are identified by an opaque integer, referred to here as "row
  ID".  The semantics of the row ID (including its sorting order) are
  determined by the bank server and completely opaque to the client.

  The list of returned transactions is determined by a row ID *starting point*
  and a signed non-zero integer *delta*:

  * If *delta* is positive, return a list of up to *delta* transactions (all matching
    the filter criteria) strictly **after** the starting point.  The transactions are sorted
    in **ascending** order of the row ID.
  * If *delta* is negative, return a list of up to *-delta* transactions (all matching
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

  :status 200 OK: JSON object of type `OutgoingHistory`.
  :status 400 Bad Request: Request malformed. The bank replies with an `ErrorDetail` object.
  :status 401 Unauthorized: Authentication failed, likely the credentials are wrong.
  :status 404 Not found: The endpoint is wrong or the user name is unknown. The bank replies with an `ErrorDetail` object.

  .. ts:def:: OutgoingHistory

    interface OutgoingHistory {

      // Array of outgoing transactions
      outgoing_transactions : OutgoingBankTransaction[];

    }

  .. ts:def:: OutgoingBankTransaction

    interface OutgoingBankTransaction {

      // Opaque identifier of the returned record
      row_id: SafeUint64;

      // Date of the transaction
      date: Timestamp;

      // Amount transferred
      amount: Amount;

      // Payto URI to identify the receiver of funds.
      credit_account: string;

      // Payto URI to identify the sender of funds
      // This must be one of the exchange's bank accounts.
      debit_account: string;

      // The wire transfer ID in the outgoing transaction.
      wtid: ShortHashCode;

      // Base URL of the exchange.
      exchange_base_url: string;
    }


-----------------------
Wire Transfer Test APIs
-----------------------

Endpoints in this section are only used for integration tests and never
exposed by bank gateways in production.

.. http:post:: ${BASE_URL}/admin/add-incoming

  Simulate a transfer from a customer to the exchange.  This API is *not*
  idempotent since it's only used in testing.

  **Request:** The body of this request must have the format of a `AddIncomingRequest`.

  **Response:**

  :status 200 OK:
    The request has been correctly handled, so the funds have been transferred to
    the recipient's account.  The body is a `AddIncomingResponse`
  :status 400 Bad Request: The request is malformed. The bank replies with an `ErrorDetail` object.
  :status 401 Unauthorized: Authentication failed, likely the credentials are wrong.
  :status 404 Not found: The endpoint is wrong or the user name is unknown. The bank replies with an `ErrorDetail` object.

  .. ts:def:: AddIncomingRequest

    interface AddIncomingRequest {
      // Amount to transfer.
      amount: Amount;

      // Reserve public key that is included in the wire transfer details
      // to identify the reserve that is being topped up.
      reserve_pub: EddsaPublicKey

      // Account (as payto URI) that makes the wire transfer to the exchange.
      // Usually this account must be created by the test harness before this API is
      // used.  An exception is the "exchange-fakebank", where any debit account can be
      // specified, as it is automatically created.
      debit_account: string;
    }


  .. ts:def:: AddIncomingResponse

    interface AddIncomingResponse {

      // Timestamp that indicates when the wire transfer will be executed.
      // In cases where the wire transfer gateway is unable to know when
      // the wire transfer will be executed, the time at which the request
      // has been received and stored will be returned.
      // The purpose of this field is for debugging (humans trying to find
      // the transaction) as well as for taxation (determining which
      // time period a transaction belongs to).
      timestamp: Timestamp;

      // Opaque of the transaction that the bank has made.
      row_id: SafeUint64;
    }
