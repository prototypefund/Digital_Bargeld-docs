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
with Taler-specific headers.

The merchant may have a *contract URL* which generates the contract
in JSON format for Taler.  Alternatively, the contract may be embedded
within the page returned by the offer URL and given to the wallet
via JavaScript or via an HTTP header.

The merchant must have a *fulfillment URL* which checks whether the
customer has paid.  When the fulfillment URL is triggered the first
time, this will not (yet) be the case.  In this case, the merchant
generates another "402 Payment Required" status code which will trigger
the actual payment from the wallet to the *pay URL*.  The wallet will
then reload the fulfillment URL, and this time the merchant should
return the online resource the customer paid for (or the shipping
status for physical goods).

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
associates her confirmation with the details of the contract.  After
Alice confirms, the wallet redirects her to the fulfillment URL, say
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
session state, the merchant will again ask her to pay, and she will
authenticate by replaying the payment.

If Alice decides to share the fulfillment URL with Bob and he visits
it, his browser will not have the right session state and furthermore
his wallet will not be able to replay the payment. Instead, his wallet
will automatically redirect Bob to the offer URL and allow him to
purchase the movie himself.


---------------
Making an offer
---------------

The offer URL is a location where the user must pass by in order to
get a contract.

FIXME: Add more details.


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


FIXME: This is outdated! Describe 402 vs. JavaScript interactions
as in paper!

This event is listened to by the wallet which can take two decisions based on the `H_contract`
field: if `H_contract` is known to the wallet, then the user has already accepted the contract
for this purchase and the wallet will send a deposit permission to `pay_url`. If that is not the
case, then the wallet will visit the `offering_url` and the user will decide whether or not to
accept the contract. Once `pay_url` receives and approves the deposit permission, it sets the session
state for the claimed item(s) to ``payed`` and now the wallet can point again the browser to the
fulfillment URL and finally get the claimed item(s). It's worth noting that each deposit permission
is associated with a contract and the wallet can reuse the same deposit permission to get the item(s)
mentioned in the contract without spending new coins.
