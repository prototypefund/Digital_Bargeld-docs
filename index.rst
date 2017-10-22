..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016, 2017 GNUnet e.V.

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Florian Dold
  @author Benedikt Muller
  @author Sree Harsha Totakura
  @author Marcello Stanisci

GNU Taler Documentation
=======================

We are building an anonymous, taxable payment system using modern
cryptography.  Customers will use traditional money transfers to send
money to a digital Exchange and in return receive (anonymized) digital
cash.  Customers can use this digital cash to anonymously pay
Merchants.  Merchants can redeem the digital cash for traditional
money at the digital Exchange.  As Merchants are not anonymous, they can
be taxed, enabling income or sales taxes to be withheld by the state
while providing anonymity for Customers.

Cryptography is used to ensure that none of the participants can
defraud the others without being detected immediately; however, in
practice a fradulent Exchange might go bankrupt instead of paying the
Merchants and thus the Exchange will need to be audited regularly like
any other banking institution.

The system will be based on free software and open protocols.

In this document, we describe the REST-based APIs between the various
components, internal architecture of key components, and how to get them
installed.

--------------------------------------
Taler HTTP Core Protocol Specification
--------------------------------------

The *Protocol Specification* defines the HTTP-based, predominantly RESTful
interfaces between the core components of Taler.

.. toctree::
  :maxdepth: 2

  api-common
  api-error
  api-exchange
  api-merchant
  api-bank
  wireformats

---------
Licensing
---------

.. toctree::
  :maxdepth: 2

  global-licensing
