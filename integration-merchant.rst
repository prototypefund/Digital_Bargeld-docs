..
  This file is part of GNU TALER.

..
  Note that this page is more a protocol-explaination than a guide that teaches
  merchants how to work with Taler wallets

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
  @author Christian Grothoff

==================================
Interaction with merchant websites
==================================

.. _payprot:

+++++++++++++++++++
The payment process
+++++++++++++++++++

By design, the Taler payment process ensures the following three properties:

1. The user must see and accept a contract in a secure context before the payment happens.
2. The payment process must be idempotent, that is at any later time the customer must
   be able to replay the payment and again retrieve the online resource he paid for.
   In case where a physical item was bought, this online resource is the merchant's
   order status page, which may contain tracking information for the customer.
   Note that by `replay the payment` we mean reusing the `same coins` used to pay for
   the product the first time to get the `same product` the user got the first time.
   So the replay will NOT subtract further credit from the user's total budget.

3. The user must be able to *share* the link to both the page with the unpaid offer or
   the order status page. If the links are shared with another user, they should
   typically allow the other user to perform the same purchase (assuming the item
   is still available).

We call an *offer URL* the user-visible URL of the merchant's Web site
that triggers the generation of a contract, and the display of the
contract to the user via the wallet.  The offer URL may include support
for payment systems other than Taler, for example by including a credit
card form in the body.  The interaction with the wallet can be started
over JavaScript or by returning a "402 Payment Required" status code
with Taler-specific headers. Detailed documentation about involved headers
is found in a dedicated article, hosted in the wallet git repository, at
the path `articles/ui/ui.pdf`. It is merchant's choice to initiate the
communication via JavaScript or "402 Payment Required", but they need to
take into account that the user may have JavaScript disabled. As for the
JavaScript tecnique of initiating a communication, please refer to the
page :ref:`integration-general`.

The merchant may have a *contract URL* which generates the contract
in JSON format for Taler.  Alternatively, the contract may be embedded
within the page returned by the offer URL and given to the wallet
via JavaScript or via an HTTP header.

The merchant must also provide a *pay URL* to which the wallet can
transmit the payment, which is HTTP POSTing coins. Again, how this
URL is make known from the merchant to the wallet, it is managed by
the HTTP headers- or JavaScript-based protocol.

The merchant must have a *fulfillment URL* which checks whether the
customer has paid.  When the fulfillment URL is triggered the first
time (which happens when the user accepts the contract), this will not
(yet) be the case.  In this case, the merchant generates another "402
Payment Required" status code which will trigger the actual payment from
the wallet to the *pay URL*.  The wallet will then reload the fulfillment
URL, and this time the merchant should return the online resource the customer
paid for (or the shipping status for physical goods).

-------
Example
-------

For example, suppose Alice wants to pay for a movie.  She will first
select the movie from the catalog, which directs her to the offer URL
*https://merchant/offer?x=8ru42*.  This URL generates a "402 Payment
Required" response, with a contract stating that Alice is about to buy
some movie.  The contract includes a fresh transaction ID, say 62.
Alice's browser detects the response code and displays the contract
for Alice.

Alice then confirms that she wants to buy the movie. Her wallet
associates her confirmation with the details and a hash of the contract.
After Alice confirms, the wallet redirects her to the fulfillment URL, say
*https://merchant/fulfillment?x=8ru42&tid=62* that is specified in the
contract.

The first time Alice visits this URL, the merchant will again
generate a "402 Payment Required" response, this time not including
the full contract but merely the hash of the contract (which includes
Alice's transaction ID 62), as well as the offer URL (which Alice
will ignore) and the pay URL.  Alice's wallet will detect that
Alice already confirmed that she wants to execute this particular
contract.  The wallet will then transmit the payment to the pay URL,
obtain a response from the merchant confirming that the payment was
successful, and then reload the fulfillment URL.

This time (and every time in the future where Alice visits the
fulfillment URL), she receives the movie.  If the browser has lost the
session state, the merchant will again ask her to pay (as it happened the
very first time she visited the fulfillment URK), and she will authenticate
by replaying the payment.

If Alice decides to share the fulfillment URL with Bob and he visits
it, his browser will not have the right session state and furthermore
his wallet will not be able to replay the payment. Instead, his wallet
will automatically redirect Bob to the offer URL and allow him to
purchase the movie himself.

---------------
Making an offer
---------------

The offer URL is a location where the user must pass by in order to get a contract.
Note that this URL is not strictly asked to initiate the interaction with the
wallet. For example, if a Website lets first pick the item to buy and *then* the
payment method in a second page, then we call offer URL only the first page,
although the communication with the wallet will be initialized by the second page.
Note that, whenever a user accepts a contract, the wallet will automatically store
that contract's hash in an internal database. That happens for three reasons:

* to have a cryptographic proof of the user's (and merchant's) activity
* to not show again the same contract to the user when visiting the fulfillment page
* to associate the same set of coins with this contract, in order to replay payments

-------------------------------
Fulfillment interaction details
-------------------------------

A payment process is triggered whenever the user visits a fulfillment
URL and he has no rights in the session state to get the items
accounted in the fulfillment URL. Note that when the user is not
visiting a fulfillment URL he got from someone else, it is the wallet
which points the browser to a fulfillment URL after the user accepts
the contract.

A fulfillment URL must carry all the details necessary to reconstruct
a contract.  For simple contracts, a Web shop should encode the unique
contract details (in particular, the transaction identifier) in the
URL.  This way, the Web shop can generate fulfillment URLs without
actually having to write the full contract proposal to its database.
This allows the merchant to delay disk (write) operations until
customers actually pay.

Once the payment process has been started, the merchant will then
reconstruct the contract and re-hash it, sending back to the client
a "402 Payment required" status code and some HTTP headers which will
help the wallet to manage the payment, they are:

* `X-taler-contract-hash`
* `X-taler-pay-URL`
* `X-taler-offer-URL`

By looking at `X-taler-contract-hash`, the wallet can face two situations:

1. This hashcode is already present in the wallet's database, so the wallet can send the payment to `X-taler-pay-URL`.  During this operation, the wallet associates the data it sent to `X-taler-pay-URL` with the received hashcode, so that it can replay payments whenever it gets this hashcode again.
2. This hashcode is unknown to the wallet, so the wallet can point the browser to `X-taler-offer-URL`, so the user will get the contract and decide to accept it or not.  This happens when the user gets the fulfillment URL from someone else.

FIXME: explain the JavaScript way ..
