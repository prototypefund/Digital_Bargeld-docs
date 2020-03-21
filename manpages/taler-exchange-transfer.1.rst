taler-exchange-transfer(1)
############################

.. only:: html

   Name
   ====

   **taler-exchange-transfer** - execute scheduled wire transfers

Synopsis
========

**taler-exchange-transfer**
[**-h** | **--help**] [**-t** | **--test**] [**-v** | **--version**]

Description
===========

**taler-exchange-transfer** is a command line tool to actually execute scheduled wire transfers (using the bank/wire gateway).
The transfers are prepared by the **taler-exchange-aggregator** and **taler-exchange-closer** tools.

**-c** *FILENAME* \| **–config=**\ ‌\ *FILENAME*
   Use the configuration and other resources for the exchange to operate
   from *FILENAME*.

**-h** \| **--help**
   Print short help on options.

**-t** \| **--test**
   Run in test mode and exit when idle.

**-v** \| **--version**
   Print version information.

See Also
========

taler-exchange-aggregator(1), taler-exchange-closer(1),
taler-exchange-httpd(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
