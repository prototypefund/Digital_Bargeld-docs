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
in particular, definitions like `contract`, `fulfillment URL`, `offering URL`, `IIG` and `deposit permission`,
are assumed to be known.  Refer to :ref:`contract`, :ref:`payprot` and :ref:`deposit-par` in order to get
some general insight on terms and interactions between components.

This section describes how the demonstrator essay store interacts with the Taler system.  As for Taler's
terminology, the demonstrator essay store is an example of `frontend`.
This demonstrator's code is hosted at `git://taler.net/merchant-frontends/talerfrontends/blog/` and is
implemented in Python.

The essay store, available at https://blog.demo.taler.net, is such that its homepage
is a list of titles from buyable articles and each title links to an `offering URL`. 
In particular, the offering URL has the following format:

  `https://blog.demo.taler.net/essay/article_title`

As for the fulfillment URL, it matches the initial part of an offering URL, but contains also
those parameters needed to reconstruct the contract, which are `tid` (transaction id) and `timestamp`.
So a fulfillment URL looks like:

  `https://blog.demo.taler.net/essay/article_title?tid=3489&timestamp=8374738`

We did not need to include any further details in the fulfillment URL because most of them
do not change in the time, and for simplicity all the articles have the same price.
