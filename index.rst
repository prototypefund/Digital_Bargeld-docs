GNU Taler Documentation
=======================

We are building an anonymous, taxable payment system using modern
cryptography.  Customers will use traditional money transfers to send
money to a digital Mint and in return receive (anonymized) digital
cash.  Customers can use this digital cash to anonymously pay
Merchants.  Merchants can redeem the digital cash for traditional
money at the digital Mint.  As Merchants are not anonymous, they can
be taxed, enabling income or sales taxes to be withheld by the state
while providing anonymity for Customers.

Cryptography is used to ensure that none of the participants can
defraud the others without being detected immediately; however, in
practice a fradulent Mint might go bankrupt instead of paying the
Merchants and thus the Mint will need to be audited regularly like any
other banking institution.

The system will be based on free software and open protocols.
In this document, we describe the REST-based API of the Mint,
which is at the heart of the system.


-----------------
Operator Handbook
-----------------

The *Operator Handbook* is for people who want to run a mint or a merchant.
It focuses on how to install, configure and run the required software.

.. toctree::
  :maxdepth: 2

  impl-mint


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


--------------------------------------
Taler HTTP Core Protocol Specification
--------------------------------------

The *Protocol Specification* defines the HTTP-based, predominantly RESTful
interfaces between the core components of Taler.

.. toctree::
  :maxdepth: 2

  api-mint
  api-merchant

  wireformats


------------------
Developer Handbook
------------------

The *Developer Handbook* brings developers up to speed who want to hack on the
core components of the Taler reference implementation.

.. toctree::
  :maxdepth: 2

  dev-wallet-wx
  dev-merchant


------------------
Indices and tables
------------------

.. toctree::
  :maxdepth: 1

  glossary

* :ref:`search`

