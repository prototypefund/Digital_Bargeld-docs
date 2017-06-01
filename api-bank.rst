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

:status 200 OK: The request has been correctly handled, so the funds have been transferred to the recipient's account.  The body is a `BankDepositDetails`_.
:status 400 Bad Request: The bank replies a `BankError`_ object.

**Details:**

.. _BankDepositDetails:
.. code-block:: tsref

  interface BankDepositDetails {
    
    // Timestamp related to the transaction being made.
    timestamp: Timestamp;

    // Serial id identifying the transaction into the bank's
    // database.
    serial_id: number;
  }

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

    // The sender's account identificator.  NOTE, in the current stage
    // of development this field is _ignored_, as it's always the bank account
    // of the logged user that plays as the "debit account".
    // In future releases, a logged user may specify multiple bank accounts
    // of her/his as the debit account.
    debit_account: number;

    // The recipient's account identificator
    credit_account: number;

  }

.. _BankAuth:
.. _tsref-type-BankAuth:
.. code-block:: tsref

  interface BankAuth {

    // authentication type.  At this stage of development,
    // only value "basic" is accepted in this field.
    // The credentials must be indicated in the following HTTP
    // headers: "X-Taler-Bank-Username" and "X-Taler-Bank-Password".
    type: string; 
  }


.. _BankError:
.. code-block:: tsref

  interface BankError {

    // Human readable explanation of the failure.
    error: string;

  }

--------
User API
--------

.. http:get:: /history

  Filters and returns the list of transactions of the customer specified in the request.

  **Request**

  :query auth: authentication method used.  At this stage of development, only value `basic` is accepted.  Note that username and password need to be given as request's headers.  The dedicated headers are: `X-Taler-Bank-Username` and `X-Taler-Bank-Password`.
  :query delta: returns the first `N` records younger (older) than `start` if `+N` (`-N`) is specified.
  :query start: according to `delta`, only those records with row id strictly greater (lesser) than `start` will be returned.  This argument is optional; if not given, `delta` youngest records will be returned.
  :query direction: optional argument taking values `debit` or `credit`, according to the caller willing to receive both incoming and outgoing, only outgoing, or only incoming records.
  :query account_number: optional argument indicating the bank account number whose history is to be returned.  If not given, then the history of the calling user will be returned.

  **Response** 

  :status 200 OK: JSON object whose field `data` is an array of type `BankTransaction`_.
  :status 204 No content: in case no records exist for the targeted user.

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

    // Wire transfer subject line.
    wt_subject: string;
  
  }

..
  The counterpart currently only points to the same bank as
  the client using the bank.  A reasonable improvement is to
  specify a bank URI too, so that Taler can run across multiple
  banks.
