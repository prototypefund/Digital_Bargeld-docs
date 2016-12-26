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

By design, the Taler payment process ensures the following properties:

1. The user must see and accept a contract in a secure context before the payment happens.
   That contract accounts for all the items which are supposed to be bought.

2. The payment process must be idempotent, that is at any later time the customer must
   be able to replay the payment and retrieve the resource he paid for.
   In case where a physical item was bought, this online resource is the merchant's
   order status page, which may contain tracking information for the customer.
   Note that by `replaying the payment` we mean reusing the `same coins` used to pay for
   the product the first time to get the `same product` the user got the first time.
   So the replay does NOT subtract further credit from the user's total budget.

3. Purchases are shareable: any purchase is given a URL that allows other users to
   buy the same item(s).

We call an *offer URL* any URL at the merchant's Web site that notifies the
wallet that the user needs to pay for something. The offer URL must take into
account that the user has no wallet installed, and manage the situation accordingly
(for example, by showing a credit card paywall).  The notification can happen either
via JavaScript or via HTTP headers.

The merchant needs to have a *contract URL* which generates the JSON
contract for Taler.  Alternatively, the contract may be embedded
within the page returned by the offer URL and given to the wallet
via JavaScript or via an HTTP header.

The merchant must also provide a *pay URL* to which the wallet can
transmit the payment. Again, how this URL is made known from the merchant
to the wallet, it is managed by the HTTP headers- or JavaScript-based protocol.

The merchant must also have a *fulfillment URL*, that addresses points 2 and 3 above.
In particular, fulfillment URL is responsible for:

* Deliver the final product to the user after the payment
* Instruct the wallet to send the payment to the pay URL
* Redirect the user to the offer URL in case they hit a shared fulfillment URL.

Again, Taler provides two ways of doing that: JavaScript- and HTTP headers-based.

Taler helps merchants on the JavaScript-based interaction by providing the
``taler-wallet-lib``.  See https://git.taler.net/web-common.git/tree/taler-wallet-lib.ts

-------
Example
-------

For example, suppose Alice wants to pay for a movie.  She will first
select the movie from the catalog, which directs her to the offer URL
*https://merchant/offer?x=8ru42*.  This URL generates a "402 Payment
Required" response, and will instruct the wallet about the contract's
URL. Then the wallet downloads the contract that states that Alice is
about to buy a movie.  The contract includes a fresh transaction ID, say 62.
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
very first time she visited the fulfillment URL), and she will authenticate
by replaying the payment.

If Alice decides to share the fulfillment URL with Bob and he visits
it, his browser will not have the right session state and furthermore
his wallet will not be able to replay the payment. Instead, his wallet
will automatically redirect Bob to the offer URL and allow him to
purchase the movie himself.

.. _offer:

---------------
Making an offer
---------------

When a user visits a offer URL, the merchant returns a page that can interact
with the wallet either via JavaScript or by returning a "402 Payment Required".
This page's main objective is to inform the wallet on where it should get the
contract.  In case of JavaScript interaction, the merchant should just return
a page whose javascript contains an invocation to ``offerContractFrom(<CONTRACT-URL>)``
from ``taler-wallet-lib``.  This function will download the contract from
`<CONTRACT-URL>` and hand it to the wallet.

In case of HTTP headers-based protocol, the merchant needs to set the header
`X-Taler-contract-url` to the contract URL.  Once this information reaches the
browser, the wallet will takes action by reading that header and downloading
the contract.

Either way, the contract gets to the wallet which then renders it to the user.

.. _fulfillment:

-------------------------------
Fulfillment interaction details
-------------------------------

A payment process is triggered whenever the user visits a fulfillment
URL and he has no rights in the session state to get the items
accounted in the fulfillment URL. Note that after the user accepts a
contract, the wallet will automatically point the browser to the
fulfillment URL.

Becasue fulfillment URLs implements replayable and shareable payments
(see points 2,3 above), fulfillment URL parameter must encompass all the
details necessary to reconstruct a contract.

That saves the merchant from writing contracts to disk upon every contract
generation, and defer this operation until customers actually pay.

..................
HTTP headers based
..................

Once the fulfillment URL gets visited, deliver the final product if the user has
paid, otherwise: the merchant will reconstruct the contract and re-hash it, sending
back to the client a "402 Payment required" status code and some HTTP headers which
will help the wallet to manage the payment.  Namely:

* `X-taler-contract-hash`
* `X-taler-pay-URL`
* `X-taler-offer-URL`

The wallet then looks at `X-taler-contract-hash`, and can face two situations:

1. This hashcode is already present in the wallet's database (meaning that the user did accept the related contract), so the wallet can send the payment to `X-taler-pay-URL`.  During this operation, the wallet associates the coins it sent to `X-taler-pay-URL` with this hashcode, so that it can replay payments whenever it gets this hashcode again.

2. This hashcode is unknown to the wallet (meaning that the user visited a shared fulfillment URL). The wallet then points the browser to `X-taler-offer-URL`, which is in charge of generating a contract referring to the same items accounted in the fulfillment URL.  Of course, the user is then able to accept or not the contract.

................
JavaScript based
................

Once the fulfillment URL gets visited, deliver the final product if the user has paid, otherwise:
the merchant will reconstruct the contract and re-hash it. Then it will return a page whose JavaScript
needs to include a call to ``taler.executeContract(..)``. See the following example:

.. sourcecode:: html

  <html>
    <head>
      <script src="path/to/taler-wallet-lib.js"></script>
      <script type="application/javascript">
        // Imported from taler-wallet-lib.js
        taler.executePayment(<CONTRACT-HASHCODE>, <PAY-URL>, <OFFERING-URL>);
      </script>
    </head>
    ..
    
  </html>

The logic which will take place is the same as in the HTTP header based protocol.
Once ``executePayment(..)`` gets executed in the browser, it will hand its three
parameters to the wallet, which will:

1. Send the payment to `<PAY-URL>` if `<CONTRACT-HASH>` is found in its database (meaning that the user accepted it).
2. Redirect the browser to `<OFFER-URL>`, if `<CONTRACT-HASH>` is NOT found in its database, meaning that the user visited a shared fulfillment URL.

..
  ..................
  State and security
  ..................
  
  The server-side state gets updated in two situations, (1) when an article is
  "about" to be bought, which means when the user visits the fulfillment URL,
  and (2) when the user actually pays.  For (1), we use the contract hascode to
  access the state, whereas in (2) we just define a list of payed articles.
  For example:
  
  .. sourcecode:: python
  
    session[<HASHCODE>] = {'article_name': 'How_to_write_a_frontend'} # (1)
    session['payed_articles'] = ['How_to_write_a_frontend', 'How_to_install_a_backend'] # (2)
  
  The list of payed articles is used by the frontend to deliver the article to the user:
  if the article name is among ``session['payed_articles']``, then the user gets what they
  paid for.
  
  The reason for using `<HASHCODE>` as the key is to prevent the wallet to send bogus
  parameters along the fulfillment URL.  `<HASHCODE>` is the contract hashcode that
  the fulfillment handler gets from the backend using the fulfillment URL parameters.
  
  In fact, when the wallet sends the payment to the frontend pay handler, it has to provide
  both coins and contract hashcode.  That hascode is (1) verified by the backend when it
  receives the coins, (2) used by the frontend to update the list of payed articles.
  
  See below an example of pay handler:
  
  .. sourcecode:: python
  
    ...
  
    # 'deposit_permission' is the JSON object sent by the wallet
    # which contains coins and the contract hashcode.
    response = send_payment_to_backend(deposit_permission)
  
    # The backend accepted the payment
    if 200 == response.status_code:
        # Here we pick the article name from the state defined at
        # fulfillment time.
        # deposit_permission['H_contract'] is the contract hashcode
        payed_article = session[deposit_permission['H_contract']]['article_name']
        session['payed_articles'].append(payed_article)
        
  
  So the wallet is forced to send a valid contract hashcode along the payment,
  and since that hashcode is then used to update the list of payed articles,
  the wallet is forced to send fulfillment URL parameters that match that hashcode,
  therefore being valid parameters.
