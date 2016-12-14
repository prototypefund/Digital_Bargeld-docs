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

.. _merchant-arch:
------
Design
------

In order for a merchant to be Taler-compatible, they need to run two distinct Web
services: a *frontend* and a *backend*.  The former is typically the Web site where
the merchant exposes their goods, whereas the latter is a C program in charge of
making all the Taler-related cryptography.

In details, the frontend gathers all the information from customers about sales,
and forwards it to the backend via its RESTful API.  Typically, the backend will either
cryptographically process this data or just forward it to the exchange.

That saves the frontend developers from dealing with cryptography in scripting
languages and from commmunicating at all with any exchange.

Additionally, the backend RESTful API is such that a frontend might be run completely
database-less.
