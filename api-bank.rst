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

This is `local` API, meant to make the bank communicate with trusted entities,
namely exchanges.

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

    // JSON 'amount' object. The amount the caller wants to transfer
    // to the recipient's count
    amount: Amount;

    // The id of this wire transfer
    wtid: base32;

    // The sender's account identificator
    debit_account: number;

    // The recipient's account identificator
    credit_account: number;

  }

.. _BankIncomingError:
.. code-block:: tsref

  interface BankIncomingError {

    // Human readable explanation of the failure.
    reason: string

  }

--------
Util API
--------

Whenever the user wants to know the bank account number of a public account,
the following path returns a human readable HTML containing this information

  `/public-accounts/details?account=accountName`
