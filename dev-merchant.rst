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

========
Merchant
========

------------
Introduction
------------
TBD

.. _merchant-arch:
------
Design
------

TO REVIEW::

  The `frontend` is the existing shopping portal of the merchant.
  The architecture tries to minimize the amount of modifications necessary
  to the `frontend` as well as the trust that needs to be placed into the
  `frontend` logic.  Taler requires the frontend to facilitate two
  JSON-based interactions between the wallet and the `backend`, and
  one of those is trivial.
  
  The `backend` is a standalone C application intended to implement all
  the cryptographic routines required to interact with the Taler wallet
  and a Taler exchange.
