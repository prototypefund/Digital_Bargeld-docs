..
  This file is part of GNU TALER.

  Copyright (C) 2014, 2015, 2016, 2017 Taler Systems SA

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

==============
Taler Bank API
==============

This chapter describe the APIs that banks need to offer towards Taler wallets
to tightly integrate with GNU Taler.

.. contents:: Table of Contents


-----------
Withdrawing
-----------


.. _bank-withdraw:
.. http:post:: /taler/withdraw

  This API provides programmatic withdrawal of cash via Taler to all the
  users registered at the bank.  It triggers a wire transfer from the client
  bank account to the exchange's.

  **Request** The body of this request must have the format of a `BankTalerWithdrawRequest`.

  **Response**

  :status 200 OK:
    The withdrawal was correctly initiated, therefore the exchange received the
    payment.  A `BankTalerWithdrawResponse` object is returned.
  :status 409 Conflict: the user does not have sufficient credit to fulfill their request.
  :status 404 Not Found: The exchange wire details did not point to any valid bank account.

  **Details**

  .. ts:def:: BankTalerWithdrawRequest

    interface BankTalerWithdrawRequest {

      // Amount to withdraw.
      amount: Amount;

      // Reserve public key.
      reserve_pub: string;

      // Exchange bank details specified in the 'payto'
      // format.  NOTE: this field is optional, therefore
      // the bank will initiate the withdrawal with the
      // default exchange, if not given.
      exchange_wire_details: string;
    }

  .. ts:def:: BankTalerWithdrawResponse

    interface BankTalerWithdrawResponse {

      // Sender account details in 'payto' format.
      sender_wire_details: string;

      // Exchange base URL.  Optional: only returned
      // if the user used the default exchange.
      exchange_url: string;
    }
