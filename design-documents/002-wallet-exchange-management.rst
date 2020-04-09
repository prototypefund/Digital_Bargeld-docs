Design Doc 002: Wallet Exchange Management
##########################################

.. note::

  This design document is currently a draft, it
  does not reflect any implementation decisions yet.

Summary
=======

This document presents the requirements and proposed interface for an API that
wallet-core exposes (to clients such as the CLI, WebExtension, Android Wallet)
to manage exchanges known to and used by the wallet.


Motivation
==========

There currently is no documented API for this functionality.  The API that the
WebExtension API uses doesn't support all required functionality and exposes
the internal DB storage format.


Background and Requirements
===========================

The wallet maintains a list of known exchanges.  For each exchange in this
list, the wallet regularly makes network queries to fetch updated information
about the exchange's cryptographic key material and fee structure.

Additionally, the wallet maintains a list of *trusted auditors*.  Auditors
certify that they audit a (sub)set of denominations offered by the exchange.

When an exchange is marked as *directly trusted*, the wallet can use it
for withdrawals independent of how the exchange is audited.  Otherwise,
a withdrawal can only proceed if an adequate set of denominations is
audited by a trusted auditor.

An exchange might only be known the wallet temporarily.  For example,
the wallet UI may allow the user to review the fee structure of an
exchange before the wallet is permanently added to the wallet.
Once a an exchange is either (a) marked as trusted or (b) used for a
withdrawal operation, it is marked as permanent.

Exchanges that are not permanent will be automatically be removed
("garbage-collected") by the wallet after some time.

Exchanges also expose their terms of service (ToS) document.
Before withdrawing, the wallet must ensure that the user
has reviewed and accepted the current version of this ToS document.

Exchange Management During Withdrawal
-------------------------------------

The functions to list / view exchanges can either be used in the context of
some exchange management activity or in the context of a withdrawal.  In the
context of a withdrawal, additional filtering must be applied, as not every
exchange is compatible with every withdrawal process.  Additionally, the list
of exchanges might contain additional details pertaining to this particular
withdrawal process.

An exchange is considered *compatible* if it accepts wire transfers with a wire
method that matches the one of the withdrawal *and* the current exchange
protocol version of the exchange is compatible with the exchange protocol
version of the wallet.

During the withdrawal process, the bank can also suggest an exchange.  Unless
the exchange is already known to the wallet, this exchange will be added
non-permanently to the wallet.  The bank-suggested will only be selected by
default if no other trusted exchange compatible with the withdrawal process is
known to the wallet.

Otherwise, the exchange selected by default will be the exchange that has most
recently been used for a withdrawal and is compatible with the current withdrawal.


Open Questions
--------------

If the user reviews a **new** exchange during withdrawal
but then does not decide to use it, will this exchange be permanent?

Pro:

* Staying permanently in the list might help when comparing multiple exchanges

Con:

* It clutters the list of exchanges, especially as we're not planning
  to have a mechanism to remove exchanges.

=> Maybe non-permanent exchanges can be "sticky" to some particular
withdrawal session?


Proposed Solution
=================

We will add the following functions (invoked over IPC with wallet-core).

queryExchangeInfo
-----------------

This function will query information about an exchange based on the base URL
of the exchange.  If the exchange is not known yet to the wallet, it will be
added non-permanently.

Request:

.. code:: ts

  interface QueryExchangeInfoRequest {
    // If given, return error description if the exchange is
    // not compatible with this withdrawal operation.
    talerWithdrawUri?: string;

    // Exchange base URL to use for the query.
    exchangeBaseUrl: string;

    // If true, the query already returns a result even if
    // /wire and denomination signatures weren't processed yet
    partial: boolean;
  }

Response:

.. code:: ts

  interface QueryExchangeInfoResponse {
    exchangeBaseUrl: string;

    // Master public key
    exchangePub: string;

    trustedDirectly: boolean;

    // The "reasonable-ness" of the exchange's fees.
    feeStructureSummary: FeeStructureSummary | undefined;

    // Detailled info for each individual denomination
    denominations: ExchangeDenomination[];

    // Currency of the exchange.
    currency: string;

    // Last observed protocol version range of the exchange
    protocolVersionRange: string;

    // Is this exchange either trusted directly or in use?
    permanent: boolean;

    // Only present if the last exchange information update
    // failed.  Same error as the corresponding pending operation.
    lastError?: OperationError;

    wireInfo: ExchangeWireInfo;

    // Auditing state for each auditor.
    auditingState: ExchangeAuditingState[];

    // Do we trust an auditor that sufficiently audits
    // this exchange's denominations?
    trustedViaAuditor: boolean;

    currentTosVersion: string;
    acceptedTosVersion: string;

    withdrawalRelatedInfo?: {
      // Can the user accept the withdrawal directly?
      // This field is redundant and derivable from other fields.
      acceptable: boolean;

      recommendedByBank: boolean;

      // Is this exchange the default exchange for this withdrawal?
      isDefault: boolean;

      // The "reasonable-ness" of the exchange's fees, in context
      // of the withdrawn amount.
      feeStructureSummaryForAmount: FeeStructureSummaryForAmount;
    };
  }

  export interface ExchangeWireInfo {
    feesForType: { [wireMethod: string]: WireFee[] };
    accounts: { paytoUri: string }[];
  }

  interface ExchangeAuditingState {
    auditorName: string;
    auditorBaseUrl: string;
    auditorPub: string;

    // Is the auditor already trusted by the wallet?
    trustedByWallet: boolean;

    // Does the auditor audit some reasonable set of
    // denominations of the exchange?
    // If this is false, at least some warning should be shown.
    auditedDenominationsReasonable: boolean;
  }


  interface FeeStructureSummary {
    // Does the fee structure fulfill our basic reasonableness
    // requirements?
    reasonable: boolean;

    // Lower range of amounts that this exchange can
    // deal with efficiently.
    smallAmount: Amount;

    // Upper range of amounts that this exchange can deal
    // with efficiently.
    bigAmount: Amount;

    // Rest to be specified later
    // [ ... ]
  }


getExchangeTos
--------------

Request:

.. code:: ts

  interface GetExchangeTosRequest {
    exchangeBaseUrl: string;
  }


Response:

.. code:: ts

  interface GetTosResponse {
    // Version of the exchange ToS (corresponds to tos ETag)
    version: string;

    // Text of the exchange ToS, with (optional) markdown markup.
    tosMarkdownText: string;
  }

listExchanges
-------------

List exchanges known to the wallet.  Either lists all exchanges, or exchanges
related to a withdrawal process.

Request:

.. code:: ts

  interface ExchangeListRequest {
    // If given, only return exchanges that
    // match the currency of this withdrawal
    // process.
    talerWithdrawUri?: string;
  }

Response:

.. code:: ts

  interface ExchangeListRespose {
    // Only returned in the context of withdrawals.
    // The base URL of the exchange that should
    // be considered the default for the withdrawal.
    withdrawalDefaultExchangeBaseUrl?: string;

    exchanges: {
      exchangeBaseUrl: string;

      // Incompatible exchanges are also returned,
      // as otherwise users might wonder why their expected
      // exchange is not there.
      compatibility: "compatible" |
        "incompatible-version" | "incompatible-wire";

      // Currency of the exchange.
      currency: string;

      // Does the wallet directly trust this exchange?
      trustedDirectly: boolean;

      // Is this exchange either trusted directly or in use?
      permanent: boolean;

      // This information is only returned if it's
      // already available to us, as the list query
      // must be fast!
      trustedViaAuditor: boolean | undefined;

      // The "reasonable-ness" of the exchange's fees.
      // Only provided if available (if we've already queried
      // and checked this exchange before).
      feeStructureSummary: FeeStructureSummary | undefined;

      // Did the user accept the current version of the exchange's ToS?
      currentTosAccepted: boolean;

      withdrawalRelatedInfo?: {
        // Can the user accept the withdrawal directly?
        // This field is redundant and derivable from other fields.
        acceptable: boolean;

        recommendedByBank: boolean;

        // Is this exchange the default exchange for this withdrawal?
        isDefault: boolean;

        // The "reasonable-ness" of the exchange's fees, in context
        // of the withdrawn amount.
        // Only provided if available (if we've already queried
        // and checked this exchange before).
        feeStructureSummaryForAmount: FeeStructureSummaryForAmount | undefined;
      };
    }[];
  }


setExchangeTrust
----------------

Request:

.. code:: ts

  interface SetExchangeTrustRequest {
    exchangeBaseUrl: string;

    trusted: boolean;
  }

The response is an empty object or an error response.

setExchangeTosAccepted
----------------------

Request:

.. code:: ts

  interface SetExchangeTosAccepted {
    exchangeBaseUrl: string;
  }

The response is an empty object or an error response.


Alternatives
============

* The UI could directly access the wallet's DB for more flexible access to the
  required data.  But this would make the UI less robust against changes in wallet-core.

