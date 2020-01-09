.. _wireformats:

Wire Transfer Methods
=====================

A wire transfer is essential for the exchange to transfer funds into a merchant's
account upon a successful deposit (see :ref:`deposit request <deposit>`).  The
merchant has to include the necessary information for the exchange to initiate the
wire transfer.

The information required for wire transfer depends on the method of wire transfer
used.  Since the wire transfers differ for each region, we document here the
ones currently supported by the exchange.

X-TALER-BANK
------------

The "x-taler-bank" wire format is used for testing and for integration with Taler's
simple "bank" system which in the future might be useful to setup a bank
for a local / regional currency or accounting system.  Using ``x-taler-bank``
wire method in combination with the Taler's bank, it is thus possible to
fully test the Taler system without using "real" currencies.  The URL
format for "x-taler-bank" is simple, in that it only specifies an account
number and the URL of the bank:

::

  payto://x-taler-bank/BANK_URI/ACCOUNT_IDENTIFIER

The account identifier given must be a non-empty alphanumeric ASCII string.  As with
any payto://-URI, additional fields may be present (after a ?), but
are not required.  The BANK_URI may include a port number. If none is
given, ``https`` over port 443 is assumed.  If a port number is
given, ``http`` over the given port is to be used.  Note that this
means that you cannot run an x-taler-bank over @code{https} on a
non-canonical port.

Note that a particular exchange is usually only supporting one particular bank
with the ``x-taler-bank`` wire format, so it is not possible for a merchant with
an account at a different bank to use "x-taler-bank" to transfer funds across
banks. After all, this is for testing and not for real banking.

SEPA
----

The Single Euro Payments Area (SEPA) [#sepa]_ is a regulation for electronic
payments.  Since its adoption in 2012, all of the banks in the Eurozone and some
banks in other countries adhere to this standard for sending and receiving
payments.  Note that the currency of the transfer will (currently) always be ``EUR``.  In
case the receiving account is in a currency other than ``EUR``, the receiving bank
may covert the amount into that currency; currency exchange charges may be
levied by the receiving bank.

For the merchant to receive deposits through SEPA, the deposit request must
follow the payto:// specification for SEPA:

::

  payto://sepa/IBAN

.. [#sepa] SEPA - Single Euro Payments Area:
           http://www.ecb.europa.eu/paym/sepa/html/index.en.html
