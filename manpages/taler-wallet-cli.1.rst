taler-wallet-cli(1)
###################

.. only:: html

   Name
   ====

**taler-wallet-cli** - interact with taler-wallet

Synopsis
========

**taler-auditor** [**-h** | **-\\-help**][**-\\-verbose**][**-V** | **-\\-version**]<command>[<args>]


Description
===========

**taler-wallet-cli** is a command line tool to be used by developers
for testing.

**-h** | **-\\-help**
   Print short help on options.

**-\\-verbose**
   Enable verbose output.

**-V** | **-\\-version**
   Output the version number.

**test-withdraw** [**-e** URL | **-\\-exchange** URL] [**-a** AMOUNT | **-\\-amount** AMOUNT][**-b** URL | **-\\-bank** URL]
   withdraw test currency from the test bank

**balance**
   show wallet balance

**history**
   show wallet history

**test-merchant-qrcode** [**-a** AMOUNT | **-\\-amount** AMOUNT][**-s** SUMMARY | **-\\-summary** SUMMARY]

**withdraw-uri** URI

**tip-uri** URI

**refund-uri** URI

**pay-uri** [**-y** | **-\\-yes**] URI

**integrationtest** [**-e** URL | **-\\-exchange** URL][**-m** URL | **-\\-merchant** URL][**-k** APIKEY | **-\\-merchant-api-key** APIKEY][**-b** URL | **-\\-bank** URL][**-w** AMOUNT | **-\\-withdraw-amount** AMOUNT][**-s** AMOUNT | **-\\-spend-amount** AMOUNT]
   Run integration test with bank, exchange and merchant.

.. See Also
   ========

Bugs
====

Report bugs by using https://bugs.gnunet.org or by sending electronic
mail to <taler@gnu.org>.
