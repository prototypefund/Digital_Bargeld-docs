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

=========
Bank API
=========

.. contents:: Table of Contents


-------
Testing
-------

.. _bank-register:
.. http:post:: /register

  This API provides programmatic user registration at the bank.

  **Request** The body of this request must have the format of a
  `BankRegistrationRequest`.

  **Response**

  :status 200 OK:
    The new user has been correctly registered.
  :status 409 Conflict:
    The username requested by the client is not available anymore.
  :status 406 Not Acceptable:
    Unacceptable characters were given for the username. See
    https://docs.djangoproject.com/en/2.2/ref/contrib/auth/#django.contrib.auth.models.User.username
    for the accepted character set.

**Details**

.. ts:def:: BankRegistrationRequest

  interface BankRegistrationRequest {
  
    // Username to use for registration; max length is 150 chars.
    username: string;

    // Password to associate with the username.  Any characters and
    // any length are valid; next releases will enforce a minimum length
    // and a safer characters choice.
    password: string;
  }

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
  :status 406 Not Acceptable: the user does not have sufficient credit to fulfill their request.
  :status 404 Not Found: The exchange wire details did not point to any valid bank account.

  **Details**

  .. ts:def:: BankTalerWithdrawRequest

    interface BankTalerWithdrawRequest {

      // Authentication method used
      auth: BankAuth;
    
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

---------------------------------
Making and Rejecting Transactions
---------------------------------

.. _bank-deposit:
.. http:post:: /admin/add/incoming

  This API allows one user to send money to another user, within the same "test"
  bank.  The user calling it has to authenticate by including his credentials in the
  request.


  **Request:** The body of this request must have the format of a `BankDepositRequest`.

  **Response:**

  :status 200 OK:
    The request has been correctly handled, so the funds have been transferred to
    the recipient's account.  The body is a `BankDepositDetails`
  :status 400 Bad Request: The bank replies a `BankError` object.
  :status 406 Not Acceptable: The request had wrong currency; the bank replies a `BankError` object.

  **Details:**

  .. ts:def:: BankDepositDetails

    interface BankDepositDetails {

      // Timestamp related to the transaction being made.
      timestamp: Timestamp;

      // Row id number identifying the transaction in the bank's
      // database.
      row_id: number;
    }

  .. ts:def:: BankDepositRequest

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

      // The subject of this wire transfer.
      subject: string;

      // The sender's account identificator.  NOTE, in the current stage
      // of development this field is _ignored_, as it's always the bank account
      // of the logged user that plays as the "debit account".
      // In future releases, a logged user may specify multiple bank accounts
      // of her/his as the debit account.
      debit_account: number;

      // The recipient's account identificator
      credit_account: number;

    }

  .. ts:def:: BankAuth

    interface BankAuth {

      // authentication type.  At this stage of development,
      // only value "basic" is accepted in this field.
      // The credentials must be indicated in the following HTTP
      // headers: "X-Taler-Bank-Username" and "X-Taler-Bank-Password".
      type: string;
    }


  .. ts:def:: BankError

    interface BankError {

      // Human readable explanation of the failure.
      error: string;

      // Numeric Taler error code (`TALER_ErrorCode`)
      ec: number;

    }


.. http:put:: /reject

  Rejects an inbound transaction.  This can be used by the receiver of a wire transfer to
  cancel that transaction, nullifying its effect.  This basically creates a correcting
  entry that voids the original transaction.  Henceforth, the /history must show
  the original transaction as "cancelled+" or "cancelled-" for creditor and debitor respectively.
  This API is used when the exchange receives a wire transfer with an invalid wire
  transfer subject that fails to decode to a public key.

  **Request** The body of this request must have the format of a `BankCancelRequest`.

  :query auth:
    authentication method used.  At this stage of development, only
    value ``"basic"`` is accepted.  Note that username and password need to be
    given as request's headers.
    The dedicated headers are: ``X-Taler-Bank-Username`` and ``X-Taler-Bank-Password``.
  :query row_id: row identifier of the transaction that should be cancelled.
  :query account_number:
    bank account for which the incoming transfer was made and
    for which ``auth`` provides the authentication data.
    **Currently ignored**, as multiple bank accounts per user are not implemented yet.

  .. ts:def:: BankCancelRequest

    interface BankCancelRequest {

      // Authentication method used
      auth: BankAuth;

      // The row id of the wire transfer to cancel
      row_id: number;

      // The recipient's account identificator
      credit_account: number;

    }

  **Response**  In case of an error, the body is a `BankError` object.

  :status 204 No Content: The request has been correctly handled, so the original transaction was voided.  The body is empty.
  :status 400 Bad Request: The bank replies a `BankError` object.
  :status 404 Not Found: The bank does not know this rowid for this account.


---------------------
Querying Transactions
---------------------


.. http:get:: /history-range

  Filters and returns the list of transactions in the time range specified by
  ``start`` and ``end``

  **Request**

  :query auth:
    authentication method used.  At this stage of development, only
    value ``"basic"`` is accepted.  Note that username and password need to be
    given as request's headers.  The dedicated headers are:
    ``X-Taler-Bank-Username`` and ``X-Taler-Bank-Password``.
  :query start:
    unix timestamp indicating the oldest transaction accepted in
    the result.
  :query end:
    unix timestamp indicating the youngest transaction accepted in
    the result.
  :query direction:
    argument taking values ``debit`` or ``credit``, according to
    the caller willing to receive both incoming and outgoing, only outgoing, or
    only incoming records.  Use ``both`` to return both directions.
  :query cancelled:
    argument taking values ``omit`` or ``show`` to filter out rejected
    transactions
  :query account_number:
    bank account whose history is to be returned.  *Currently ignored*, as
    multiple bank accounts per user are not implemented yet.
  :query ordering:
    can be ``descending`` or ``ascending`` and regulates whether
    the row are returned youger-to-older or vice versa.  Defaults to
    ``descending``.


  **Response**

  :status 200 OK: JSON object whose field ``data`` is an array of type `BankTransaction`.
  :status 204 No content: in case no records exist for the targeted user.


.. http:get:: /history

  Filters and returns the list of transactions for the bank account of the
  customer specified in the request.  Clients must provide authentication
  information via the ``X-Taler-Bank-Username`` and ``Taler-Bank-Password``
  headers.

  Transactions are identified by an opaque string identifier, referred to here
  as "row ID".  The semantics of the row ID (including its sorting order) are
  up to the bank server to determine completely opaque to the client.

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
  :query direction:
    Filter transactions by type.  Can be ``debit`` to return only
    transactions that debit this account, ``credit`` to return only transactions
    that credit this account, or ``both`` for both types.
  :query cancelled:
    Filter transactions by their cancellation state.
    Can be ``omit`` to omit rejected transactions or ``show`` to keep rejected transaction.
  :query account_number:
    Bank account whose history is to be returned.
    *Currently ignored*, as multiple bank accounts per user are not implemented
    yet.
  :query long_poll_ms: *Optional.*  If this parameter is specified and the
    result of the query would be empty, the bank will wait up to ``long_poll_ms``
    milliseconds for new transactions that match the query to arrive and only
    then send the HTTP response.  A client must never rely on this behavior, as
    the bank may return a response immediately or after waiting only a fraction
    of ``long_poll_ms``.

  **Response**

  :status 200 OK: JSON object whose field ``data`` is an array of type `BankTransaction`.
  :status 204 No content: in case no records exist for the targeted user.

  .. ts:def:: BankTransaction

    interface BankTransaction {

      // identification number of the record
      row_id: number;

      // Date of the transaction
      date: Timestamp;

      // Amount transferred
      amount: Amount;

      // "-" if the transfer was outgoing, "+" if it was
      // incoming; "cancel+" or "cancel-" if the transfer
      // was /reject-ed by the receiver.
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
    specify a bank URL too, so that Taler can run across multiple
    banks.

------------------------
Interactions with wallet
------------------------

.. warning::

  This section is completely outdated.

A bank and a wallet need to communicate for (1) make some elements visible
only if the wallet is installed, (2) exchange information when the user withdraws
coins.

Make elements visible.
^^^^^^^^^^^^^^^^^^^^^^

This feature works via CSS injection from the wallet.  To enable it, the
page must contain the ``<html data-taler-nojs="true">`` element, so that
the wallet will do the injection.

Whenever a element ``<x>`` needs to be visualized (hidden) if the wallet is
installed, the special class ``taler-installed-show`` (``taler-installed-hide``)
must be added to ``x``, as follows:

* ``<x class="taler-installed-show">y</x>`` will make ``y`` visible.
* ``<x class="taler-installed-hide">y</x>`` will make ``y`` visible.

Clearly, a fallback page must be provided, which will be useful if the
wallet is *not* installed.  This special page will hide any element of
the class ``taler-install-show``; it can be downloaded at the following
URL: ``git://taler.net/web-common/taler-fallback.css``.

Withdrawing coins
^^^^^^^^^^^^^^^^^

After the user confirms the withdrawal, the bank must return a ``202 Accepted`` response,
along with the following HTTP headers:

* ``X-Taler-Operation: create-reserve``
* ``X-Taler-Callback-Url: <callback_url>``; this URL will be automatically visited by the wallet after the user confirms the exchange.
* ``X-Taler-Wt-Types: '["test"]'``; stringified JSON list of supported wire transfer types (only 'test' supported so far).
* ``X-Taler-Amount: <amount_string>``; stringified Taler-style JSON :ref:`amount <amount>`.
* ``X-Taler-Sender-Wire: <wire_details>``; stringified `WireDetails`.
* ``X-Taler-Suggested-Exchange: <URL>``; this header is optional, and ``<URL>`` is the suggested exchange URL as given in the ``SUGGESTED_EXCHANGE`` configuration option.

.. ts:def:: WireDetails

  interface WireDetails {
    // Only 'test' value admitted so far.
    type: string;

    // URL of the bank.
    bank_uri: string;

    // bank account number of the user attempting to withdraw.
    account_number: number;
  }

After the user confirms the exchange to withdraw coins from, the wallet will
visit the callback URL, in order to let the user answer some security questions
and provide all relevant data to create a reserve.

.. note::
  Currently, the bank is in charge of creating the reserve at the chosen
  exchange.  In future, the exchange will "poll" its bank account and automatically
  creating a reserve whenever it receives any funds, without any bank's
  intervention.

The callback URL implements the following API.

.. http:get:: <callback_url>

  **Request**

  :query amount_value: integer part of the amount to be withdrawn.
  :query amount_fraction: fractional part of the amount to be withdrawn.
  :query amount_currency: currency of the amount to be withdrawn.
  :query exchange: base URL of the exchange where the reserve is to be created.
  :query reserve_pub: public key of the reserve to create.
  :query exchange_wire_details: stringification of the chosen exchange's `WireDetails`.

  **Response**

  Because the wallet is not supposed to take action according to this response,
  the bank implementers are not required to return any particular status code here.

  For example, our demonstrator bank always redirects the browser to the user's
  profile page and let them know the outcome via a informational bar.
