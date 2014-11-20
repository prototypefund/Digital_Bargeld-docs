Welcome to Taler's REST API documentation!
==========================================

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


Contents
========

Protocol Specification:

.. toctree::
  :maxdepth: 2

  api-mint
  api-merchant

Implementation:

.. toctree::
  :maxdepth: 2

  impl-mint

Supported Wire Transfer Formats:

.. toctree::
  :maxdepth: 2

  wireformats


Indices and tables
==================

* :ref:`search`

