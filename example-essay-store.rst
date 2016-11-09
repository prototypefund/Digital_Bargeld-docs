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

==================================
Example: Essay Store
==================================

This section shows how to set up a merchant :ref:`frontend <merchant-arch>`, and is
inspired by our demonstration shop running at `https://blog.demo.taler.net/`.

The code we are going to describe is available at
https://git.taler.net/merchant-frontends.git/tree/talerfrontends/blog
and is implemented in Python+Flask.

The desired effect is that the homepage has a list of buyable article, and once the
user clicks on one of them, they will either get the Taler :ref:`contract <contract>`
or a credit card paywall if they have no Taler wallet installed.


The offer URLs trigger the expected interaction with the wallet. In practical terms, the
offer URL returns a HTML page that can either show a pay-form in case Taler is not installed
in the user's browser or download the contract from the merchant.
If the user has Taler installed and wants to pay, the wallet will POST the coins to a URL
of the form:

  `https://blog.demo.taler.net/pay?uuid=${contract_hashcode}`

The URL comes with the contract's hashcode because each contract is an entry in
the merchant's state, so it can mark it as ``payed`` whenever it receives coins.


For the essay store, the fulfillment URL matches the initial part of
an offer URL, but contains the additional parameters needed to
reconstruct the contract, in this case the `tid` (transaction id) and
a `timestamp`. Hence, a fulfillment URL for the essay store looks like:

  `https://blog.demo.taler.net/essay/article_title?tid=3489&timestamp=8374738`

This is sufficient for the simple essay store, as we do not need any further
details to reconstruct the contract.  In particular, the essay store
assumes for simplicity that all the articles have the same price forever.

We note that Taler does not require that offer and fulfillment URL
have this kind of relationship. In fact, it is perfectly acceptable
for the fulfillment URL to be hosted on a different server under a
differnt domain name.
