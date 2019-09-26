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

============================
The Auditor RESTful JSON API
============================

The API specified here follows the :ref:`general conventions <http-common>`
for all details not specified in the individual requests.
The `glossary <https://docs.taler.net/glossary.html#glossary>`_
defines all specific terms used in this section.

.. _auditor-version:

-------------------------
Obtaining Auditor Version
-------------------------

This API is used by merchants to obtain a list of all exchanges audited by
this auditor.  This may be required for the merchant to perform the required
know-your-customer (KYC) registration before issuing contracts.

.. http:get:: /version

  Get the protocol version and some meta data about the auditor.

  **Response:**

  :status 200 OK:
    The auditor responds with a `AuditorVersion`_ object. This request should
    virtually always be successful.

  **Details:**

  .. _AuditorVersion:
  .. code-block:: tsref

    interface AuditorVersion {
      // libtool-style representation of the Taler protocol version, see
      // https://www.gnu.org/software/libtool/manual/html_node/Versioning.html#Versioning
      // The format is "current:revision:age".  Note that the auditor
      // protocol is versioned independently of the exchange's protocol.
      version: string;

      // Return which currency this auditor is auditing for.
      currency: string;

      // EdDSA master public key of the auditor
      auditor_public_key: EddsaPublicKey;
    }

  .. note::

    This API is still experimental (and is not yet implemented at the
    time of this writing).


.. _exchange-list:

-----------------------
Obtaining Exchange List
-----------------------

This API is used by merchants to obtain a list of all exchanges audited by
this auditor.  This may be required for the merchant to perform the required
know-your-customer (KYC) registration before issuing contracts.

.. http:get:: /exchanges

  Get a list of all exchanges audited by the auditor.

  **Response:**

  :status 200 OK:
    The auditor responds with a :ts:type:`ExchangeList` object. This request should
    virtually always be successful.

  **Details:**

  .. ts:def:: ExchangeList

    interface ExchangeList {
      // Exchanges audited by this auditor
      exchanges: ExchangeEntry[];
    }

  .. ts:def:: ExchangeEntry

    interface ExchangeEntry {

      // Master public key of the exchange
      master_pub: EddsaPublicKey;

      // Base URL of the exchange
      exchange_url: string;
    }

  .. note::

    This API is still experimental (and is not yet implemented at the
    time of this writing). A key open question is whether the auditor
    should sign the information. We might also want to support more
    delta downloads in the future.

.. _deposit-confirmation:

--------------------------------
Submitting deposit confirmations
--------------------------------

Merchants should probabilistically submit some of the deposit
confirmations they receive from the exchange to auditors to ensure
that the exchange does not lie about recording deposit confirmations
with the exchange. Participating in this scheme ensures that in case
an exchange runs into financial trouble to pay its obligations, the
merchants that did participate in detecting the bad behavior can be
paid out first.

.. http:put:: /deposit-confirmation

   Submits a `DepositConfirmation` to the exchange. Should succeed
   unless the signature provided is invalid or the exchange is not
   audited by this auditor.

  **Response:**

  :status 200: The auditor responds with a `DepositAudited` object.
               This request should virtually always be successful.

  **Details:**

  .. ts:def:: DepositAudited

    interface DepositAudited {
      // TODO: do we care for the auditor to sign this?
    }

  .. ts:def:: DepositConfirmation

    interface DepositConfirmation {

      // Hash over the contract for which this deposit is made.
      h_contract_terms: HashCode;

      // Hash over the wiring information of the merchant.
      h_wire: HashCode;

      // Time when the deposit confirmation confirmation was generated.
      timestamp: Timestamp;

      // How much time does the merchant have to issue a refund
      // request?  Zero if refunds are not allowed.
      refund_deadline : Timestamp;

      // Amount to be deposited, excluding fee.  Calculated from the
      // amount with fee and the fee from the deposit request.
      amount_without_fee: Amount;

      // The coin's public key.  This is the value that must have been
      // signed (blindly) by the Exchange.  The deposit request is to be
      // signed by the corresponding private key (using EdDSA).
      coin_pub: CoinPublicKey;

      // The Merchant's public key.  Allows the merchant to later refund
      // the transaction or to inquire about the wire transfer identifier.
      merchant_pub: EddsaPublicKey;

      // Signature from the exchange of type
      // TALER_SIGNATURE_EXCHANGE_CONFIRM_DEPOSIT.
      exchange_sig: EddsaSignature;

      // Public signing key from the exchange matching @e exchange_sig.
      exchange_pub: EddsaPublicKey;

      // Master public key of the exchange corresponding to @e master_sig.
      // Identifies the exchange this is about.
      master_pub: EddsaPublicKey;

      // When does the validity of the exchange_pub end?
      ep_start: Timestamp;

      // When will the exchange stop using the signing key?
      ep_expire: Timestamp;

      // When does the validity of the exchange_pub end?
      ep_end: Timestamp;

      // Exchange master signature over @e exchange_sig.
      master_sig: EddsaSignature;
    }

  .. note::

    This API is still experimental (and is not yet implemented at the
    time of this writing). A key open question is whether the auditor
    should sign the response information.


----------
Complaints
----------

This API is used by the wallet or merchants to submit proof of
misbehavior of an exchange to the auditor.

  .. note::

     To be designed and implemented.

  .. http:put:: /complain

  Complain about missbehavior to the auditor.
