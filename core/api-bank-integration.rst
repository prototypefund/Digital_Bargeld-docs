..
  This file is part of GNU TALER.

  Copyright (C) 2014-2020 Taler Systems SA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Marcello Stanisci
  @author Christian Grothoff

==========================
Taler Bank Integration API
==========================

This chapter describe the APIs that banks need to offer towards Taler wallets
to tightly integrate with GNU Taler.

.. contents:: Table of Contents

.. http:get:: /config

  Get a configuration information about the bank.

  **Request:**

  **Response:**

  :status 200 OK:
    The exchange responds with a `BankVersion` object. This request should
    virtually always be successful.

  **Details:**

  .. ts:def:: BankVersion

    interface BankVersion {
      // libtool-style representation of the Bank protocol version, see
      // https://www.gnu.org/software/libtool/manual/html_node/Versioning.html#Versioning
      // The format is "current:revision:age".
      version: string;

      // currency used by this bank
      currency: string;

    }


-----------
Withdrawing
-----------

Withdrawals with a Taler-integrated bank are based on withdrawal operations.
Some user interaction (on the Bank's website or a Taler-enabled ATM) creates a
withdrawal operation record in the Bank's database.  The wallet can use a unique identifier
for the withdrawal operation (the ``wopid``) to interact with the withdrawal operation.

.. http:get:: ${BANK_API_BASE_URL}/withdrawal-operation/${wopid}

  Query information about a withdrawal operation, identified by the ``wopid``.

  **Request**

  :query long_poll_ms:
    *Optional.*  If specified, the bank will wait up to ``long_poll_ms``
    milliseconds for completion of the transfer before sending the HTTP
    response.  A client must never rely on this behavior, as the bank may
    return a response immediately.

  **Response**

  :status 200 OK:
    The withdrawal operation is known to the bank, and details are given
    in the `BankWithdrawalOperationStatus` response body.


  .. ts:def:: BankWithdrawalOperationStatus

    export class BankWithdrawalOperationStatus {
      // has the wallet selected parameters for the withdrawal operation
      // (exchange and reserve public key) and successfully sent it
      // to the bank?
      selection_done: boolean;

      // The transfer has been confirmed and registered by the bank.
      // Does not guarantee that the funds have arrived at the exchange already.
      transfer_done: boolean;

      // Amount that will be withdrawn with this operation
      // (raw amount without fee considerations).
      amount: Amount;

      // Bank account of the customer that is withdrawing, as a
      // payto URI.
      sender_wire?: string;

      // Suggestion for an exchange given by the bank.
      suggested_exchange?: string;

      // URL that the user needs to navigate to in order to
      // complete some final confirmation (e.g. 2FA).
      confirm_transfer_url?: string;

      // Wire transfer types supported by the bank.
      wire_types: string[];
    }

.. http:post:: ${BANK_API_BASE_URL}/withdrawal-operation/${wopid}

  **Request** The body of this request must have the format of a `BankWithdrawalOperationPostRequest`.

  **Response**

  :status 200 OK:
    The bank has accepted the withdrawal operation parameters chosen by the wallet.
    The response is a `BankWithdrawalOperationPostResponse`.
  :status 404 Not Found:
    The bank does not know about a withdrawal operation with the specified ``wopid``.

  **Details**

  .. ts:def:: BankWithdrawalOperationPostRequest

    interface BankWithdrawalOperationPostRequest {

      // Reserve public key.
      reserve_pub: string;

      // Exchange bank details specified in the 'payto'
      // format.  NOTE: this field is optional, therefore
      // the bank will initiate the withdrawal with the
      // default exchange, if not given.
      exchange_wire_details: string;
    }

  .. ts:def:: BankWithdrawalOperationPostResponse

    interface BankWithdrawalOperationPostResponse {

      // The transfer has been confirmed and registered by the bank.
      // Does not guarantee that the funds have arrived at the exchange already.
      transfer_done: boolean;

      // URL that the user needs to navigate to in order to
      // complete some final confirmation (e.g. 2FA).
      //
      // Only applicable when 'transfer_done' is false.
      confirm_transfer_url?: string;
    }

