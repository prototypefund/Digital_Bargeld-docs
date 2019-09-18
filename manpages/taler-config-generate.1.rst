taler-config-generate(1)
########################

.. only:: html

   Name
   ====

   **taler-config-generate** - tool to simplify Taler configuration
   generation

Synopsis
========

**taler-config-generate**
[**-c** *FILENAME* | **--config=**\ ‌\ *FILENAME*]
[**-C** *CURRENCY* | **--currency=**\ ‌\ *CURRENCY*]
[**-e** | **--exchange**] [**-f** *AMOUNT* | *-wirefee=*\ ‌\ *AMOUNT*]
[**-m** | **--merchant**] [**-t** | **--trusted**]
[**-w** *WIREFORMAT* | **--wire** *WIREFORMAT*]
[**-j** *JSON* | **--wire-json-merchant=**\ ‌\ *JSON*]
[**-J** *JSON* | **--wire-json-exchange=**\ ‌\ *JSON*] [**--bank-uri**]
[**--exchange-bank-account**] [**--merchant-bank-account**]
[**-h** | **--help**]
[**-L** *LOGLEVEL* | **--loglevel=**\ ‌\ *LOGLEVEL*]
[**-v** | **--version**]

Description
===========

**taler-config-generate** can be used to generate configuration files
for the Taler exchange or Taler merchants.

**-c** *FILENAME* \| **--config=**\ ‌\ *FILENAME*
   Location where to write the generated configuration. Existing file
   will be updated, not overwritten.

**-C** *CURRENCY* \| **--currency=**\ ‌\ *CURRENCY*
   Which currency should we use in the configuration.

**-e** \| **--exchange**
   Generate configuration for a Taler exchange.

**-f** *AMOUNT* \| *-wirefee=*\ ‌\ *AMOUNT*
   Setup wire transfer fees for the next 5 years for the exchange (for
   all wire methods).

**-m** \| **--merchant**
   Generate configuration for a Taler merchant.

**-t** \| **--trusted**
   Setup current exchange as trusted with current merchant. Generally
   only useful when configuring for testcases.

**-w** *WIREFORMAT* \| **--wire** *WIREFORMAT*
   Specifies which wire format to use (i.e. “test” or “sepa”)

**-j** *JSON* \| **--wire-json-merchant=**\ ‌\ *JSON*
   Wire configuration to use for the merchant.

**-J** *JSON* \| **--wire-json-exchange=**\ ‌\ *JSON*
   Wire configuration to use for the exchange.

**--bank-uri**
   Alternative to specify wire configuration to use for the exchange and
   merchant for the “test” wire method. Only useful if WIREFORMAT was
   set to “test”. Specifies the URI of the bank.

**--exchange-bank-account**
   Alternative to specify wire configuration to use for the exchange for
   the “test” wire method. Only useful if WIREFORMAT was set to “test”.
   Specifies the bank account number of the exchange.

**--merchant-bank-account**
   Alternative to specify wire configuration to use for the merchant for
   the “test” wire method. Only useful if WIREFORMAT was set to “test”.
   Specifies the bank account number of the merchant.

**-h** \| **--help**
   Shows this man page.

**-L** *LOGLEVEL* \| **--loglevel=**\ ‌\ *LOGLEVEL*
   Use LOGLEVEL for logging. Valid values are DEBUG, INFO, WARNING and
   ERROR.

**-v** \| **--version**
   Print GNUnet version number.

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
