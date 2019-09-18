taler-exchange-aggregator(1)
############################

.. only:: html

   Name
   ====

   **taler-exchange-aggregator** - aggregate and execute exchange transactions

Synopsis
========

**taler-exchange-aggregator**
[**-d** *DIRNAME* | **--exchange-dir=**\ ‌\ *DIRNAME*]
[**-h** | **--help**] [**-t** | **--test**] [**-v** | **--version**]

Description
===========

**taler-exchange-aggregator** is a command line tool to run pending
transactions from the Taler exchange.

**-d** *DIRNAME* \| **--exchange-dir=**\ ‌\ *DIRNAME*
   Use the configuration and other resources for the exchange to operate
   from *DIRNAME*.

**-h** \| **--help**
   Print short help on options.

**-t** \| **--test**
   Run in test mode and exit when idle.

**-v** \| **--version**
   Print version information.

See Also
========

taler-exchange-dbinit(1), taler-exchange-keyup(1),
taler-exchange-httpd(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
