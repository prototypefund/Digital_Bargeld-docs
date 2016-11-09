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

We call an *offer URL* any URL at the merchant's Web site that notifies the
wallet that the user needs to pay for something. The offer URL must take into
account that the user has no wallet installed, and manage the situation accordingly
(for example, by showing a credit card paywall).

The merchant needs to have a *contract URL* which generates the JSON
contract for Taler.  Alternatively, the contract may be embedded
within the page returned by the offer URL and given to the wallet
via JavaScript or via an HTTP header.

The merchant must also provide a *pay URL* to which the wallet can
transmit the payment. Again, how this URL is made known from the merchant
to the wallet, it is managed by the HTTP headers- or JavaScript-based protocol.

The merchant must have a *fulfillment URL* which is in charge of doing
two thigs: give to the user what he paid for, or redirect the user
to the offer URL in case he did not pay.

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
contract. In case of JavaScript interaction, this is done by _FIXME_, whereas
in case of "402 Payment Required", a `X-Taler-contract-url` HTTP header will
be set to the contract's location. (_FIXME_: is that right?).

.. _fulfillment:

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

FIXME: explain the JavaScript way

--------------------
Example: Essay Store
--------------------

This section is a high-level description of a merchant :ref:`frontend <merchant-arch>`,
and is inspired by our demonstration essay store running at `https://blog.demo.taler.net/`.
Basically, it tells how the frontend reacts to clients visiting `offer` and `fulfillment`
URLs.

The website is implemented in Python+Flask, and is available at
https://git.taler.net/merchant-frontends.git/tree/talerfrontends/blog.

The desired effect is that the homepage has a list of buyable articles, and once the
user clicks on one of them, they will either get the Taler :ref:`contract <contract>`
or a credit card paywall if they have no Taler wallet installed.

In particular, any buyable article on the homepage links to an `offer URL`:

.. sourcecode:: html

  <html>
    ...
    <h3><a href="/essay/How_to_write_a_frontend">How to write a frontend</a></h3>
    ...
  </html>

whence the offer URL design is as follows::

  https://<BASEURL>/essay/<ARTICLE-NAME>

`<ARTICLE-NAME>` is just a token that uniquely identifies the article within the shop.

The server-side handler for the offer URL will return a special page to the client that
will either HTTP GET the contract from the frontend, or show the credit card paywall. 
See `above <offer>`_ how this special page works.

It is interesting to note that the fulfillment URL is just the offer URL plus
two additional parameters. It looks as follows::

  https://<BASEURL>/essay/<ARTICLE-NAME>?tid=<TRANSACTION-ID>&timestamp=<TIMESTAMP>

.. note::

  Taler does not require that offer and fulfillment URL have this kind of relationship.
  In fact, it is perfectly acceptable for the fulfillment URL to be hosted on a different
  server under a different domain name.

The fulfillment URL server-side handler implements the following logic: it checks the state
to see if `<ARTICLE-NAME>` has been payed, and if so, returns the article to the user.
If the user didn't pay, then it `executes` the contract by returning a special page to the
browser. The contract execution is the order to pay that the frontend gives to the wallet.

Basically, the frontend points the wallet to the hashcode of the contract which is to be paid
and the wallet responds by giving coins to the frontend. Because the frontend doesn't perform
any cryptographic work by design, it forwards `<ARTICLE-NAME>`, `<TRANSACTION-ID>` and
`<TIMESTAMP>` to the frontend in order to get the contract's hashcode.

See `above <fulfillment>`_ for a detailed description of how the frontend triggers the
payment in the wallet.

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
