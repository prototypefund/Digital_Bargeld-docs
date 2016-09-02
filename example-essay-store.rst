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

To properly understand this example, the reader should be familiar with Taler's terminology;
in particular, definitions like `contract`, `fulfillment URL`, `offering URL`, and `deposit permission`,
are assumed to be known.  Refer to :ref:`contract`, :ref:`payprot` and :ref:`deposit-par` in order to get
some general insight on terms and interactions between components.

This section describes how the demonstrator essay store interacts with the Taler system.  As for Taler's
terminology, the demonstrator essay store is an example of `frontend`.
This demonstrator's code is hosted at `git://taler.net/merchant-frontends/talerfrontends/blog/` and is
implemented in Python.

The essay store, available at https://blog.demo.taler.net, is such that its homepage
is a list of titles from buyable articles and each title links to an `offer URL`.
In particular, the offer URLs have the following format:

  `https://blog.demo.taler.net/essay/article_title`

The offer URLs trigger the expected interaction with the wallet.
  FIXME: describe where the contract is generated!
  FIXME: give the pay URL.

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
