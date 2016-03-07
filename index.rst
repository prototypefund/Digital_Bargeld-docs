..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015 GNUnet e.V. and INRIA
  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU Lesser General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.
  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

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
Merchants and thus the Exchange will need to be audited regularly like any
other banking institution.

The system will be based on free software and open protocols.
In this document, we describe the REST-based API of the Exchange,
which is at the heart of the system.


-----------------
Operator Handbook
-----------------

The *Operator Handbook* is for people who want to run a exchange or a merchant.
It focuses on how to install, configure and run the required software.

.. toctree::
  :maxdepth: 2

  impl-exchange
  impl-merchant


------------------------
Web Integration Handbook
------------------------

The *Web Integration Handbook* is for those who want to interact with Taler
wallets on their own website.  Integrators will also have to be familiar with
the material covered in the *Operator Handbook*.


.. toctree::
  :maxdepth: 2

  integration-general
  integration-bank
  integration-merchant
  example-essay-store


--------------------------------------
Taler HTTP Core Protocol Specification
--------------------------------------

The *Protocol Specification* defines the HTTP-based, predominantly RESTful
interfaces between the core components of Taler.

.. toctree::
  :maxdepth: 2

  api-common
  api-exchange
  api-merchant
  api-bank

  wireformats


------------------
Developer Handbook
------------------

The *Developer Handbook* brings developers up to speed who want to hack on the
core components of the Taler reference implementation.

.. toctree::
  :maxdepth: 2

  dev-wallet-wx


------------------
Indices and tables
------------------

.. toctree::
  :hidden:

  glossary

* :doc:`glossary`
* :ref:`search`

