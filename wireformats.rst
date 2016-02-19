.. _wireformats:

Wire Transfer Formats
=====================

A wire transfer is essential for the mint to transfer funds into a merchant's
account upon a successful deposit (see :ref:`deposit request <deposit>`).  The
merchant has to include the necessary information for the mint to initiate the
wire transfer.

The information required for wire transfer depends on the type of wire transfer
used.  Since the wire transfers differ for each region, we document here the
ones currently supported by the mint.

TEST
----

The TEST wire format is used for testing and for integration with Taler's
simple "bank" system which in the future might be useful to setup a bank
for a local / regional currency or accounting system.  Using the TEST
wire format in combination with the Taler's bank, it is thus possible to
fully test the Taler system without using real currencies.  The wire
format for "TEST" is very simple, in that it only specifies an account
number in a field "account_number".  The account number given must be
a positive 53-bit integer.  Additional fields may be present, but are
not required.

For the merchant or mint to receive deposits through TEST, the deposit
request must thus contain a JSON object with the following fields:

  * `type`: the string constant `"TEST"`
  * `account_number`: the account number of the merchant at the bank


SEPA
----

The Single Euro Payments Area (SEPA) [#sepa]_ is a regulation for electronic
payments.  Since its adoption in 2012, all of the banks in the Eurozone and some
banks in other countries adhere to this standard for sending and receiving
payments.  Note that the currency of the transfer will (currently) always be *EURO*.  In
case the receiving account is in a currency other than EURO, the receiving bank
may covert the amount into that currency; currency exchange charges may be
levied by the receiving bank.

For the merchant to receive deposits through SEPA, the deposit request must
contain a JSON object with the following fields:

  .. The following are taken from Page 33, SEPA_SCT.pdf .

  * `type`: the string constant `"SEPA"`
  * `IBAN`: the International Bank Account Number (IBAN) of the account of the beneficiary
  * `name`: the name of the beneficiary
  * `bic`: the Bank Identification Code (BIC) code of the beneficiary's bank
  * `r`: random salt (used to make brute-forcing the hash harder)

The JSON object may optionally contain:
  * `address`: the address of the Beneficiary

.. [#sepa] SEPA - Single Euro Payments Area:
          http://www.ecb.europa.eu/paym/sepa/html/index.en.html
