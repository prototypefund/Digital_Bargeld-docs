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

This API allows one user to send money to another user, within the same "test"
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

    // Row id number identifying the transaction in the bank's
    // database.
    row_id: number;
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

    // Numeric Taler error code (`enum TALER_ErrorCode`)
    ec: number;

  }


.. http:put:: /reject

  Rejects an inbound transaction.  This can be used by the receiver of a wire transfer to
  cancel that transaction, nullifying its effect.  This basically creates a correcting
  entry that voids the original transaction.  Henceforth, the /history must show
  the original transaction as "cancelled+" or "cancelled-" for creditor and debitor respectively.
  This API is used when the exchange receives a wire transfer with an invalid wire
  transfer subject that fails to decode to a public key.

  **Request** The body of this request must have the format of a `BankCancelRequest`_.

  :query auth: authentication method used.  At this stage of development, only value `basic` is accepted.  Note that username and password need to be given as request's headers.  The dedicated headers are: `X-Taler-Bank-Username` and `X-Taler-Bank-Password`.
  :query row_id: row identifier of the transaction that should be cancelled.
  :query account_number: bank account for which the incoming transfer was made and for which `auth` provides the authentication data.  *Currently ignored*, as multiple bank accounts per user are not implemented yet.

  .. _BankCancelRequest:
  .. code-block:: tsref

    interface BankCancelRequest {

      // Authentication method used
      auth: BankAuth;

      // The row id of the wire transfer to cancel
      row_id: number;

      // The recipient's account identificator
      credit_account: number;

    }

  **Response**  In case of an error, the body is a `BankError`_ object.

  :status 204 No Content: The request has been correctly handled, so the original transaction was voided.  The body is empty.
  :status 400 Bad Request: The bank replies a `BankError`_ object.
  :status 404 Not Found: The bank does not know this rowid for this account.


.. http:get:: /history

  Filters and returns the list of transactions of the customer specified in the request.

  **Request**

  :query auth: authentication method used.  At this stage of development, only value `basic` is accepted.  Note that username and password need to be given as request's headers.  The dedicated headers are: `X-Taler-Bank-Username` and `X-Taler-Bank-Password`.
  :query delta: returns the first `N` records younger (older) than `start` if `+N` (`-N`) is specified.
  :query start: according to `delta`, only those records with row id strictly greater (lesser) than `start` will be returned.  This argument is optional; if not given, `delta` youngest records will be returned.
  :query direction: argument taking values `debit` or `credit`, according to the caller willing to receive both incoming and outgoing, only outgoing, or only incoming records.  Use `both` to return both directions.
  :query cancelled: argument taking values `omit` or `show` to filter out rejected transactions
  :query account_number: bank account whose history is to be returned.  *Currently ignored*, as multiple bank accounts per user are not implemented yet.


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
  specify a bank URI too, so that Taler can run across multiple
  banks.

------------------------
Interactions with wallet
------------------------

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
URI: ``git://taler.net/web-common/taler-fallback.css``.

Withdrawing coins.
^^^^^^^^^^^^^^^^^^

After the user confirms the withdrawal, the bank must return a `202 Accepted` response,
along with the following HTTP headers:

* ``X-Taler-Operation: create-reserve``
* ``X-Taler-Callback-Url: <callback_url>``; this URL will be automatically visited by the wallet after the user confirms the exchange.
* ``X-Taler-Wt-Types: '["test"]'``; stringified JSON list of supported wire transfer types (only 'test' supported so far).
* ``X-Taler-Amount: <amount_string>``; stringified Taler-style JSON :ref:`amount <amount>`.
* ``X-Taler-Sender-Wire: <wire_details>``; stringified WireDetails_.
* ``X-Taler-Suggested-Exchange: <URL>``; this header is optional, and ``<URL>`` is the suggested exchange URL as given in the `SUGGESTED_EXCHANGE` configuration option.

.. _WireDetails:
.. code-block:: tsref

  interface WireDetails {
    type: string; // Only 'test' value admitted so far.
    bank_uri: URI of the bank.
    account_number: bank account number of the user attempting to withdraw.
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
  :query wire_details: stringification of the chosen exchange's WireDetails_.

  **Response**

  Because the wallet is not supposed to take action according to this response,
  the bank implementers are not required to return any particular status code here.

  For example, our demonstrator bank always redirects the browser to the user's
  profile page and let them know the outcome via a informational bar.
