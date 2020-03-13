taler-exchange-closer(1)
############################

.. only:: html

   Name
   ====

   **taler-exchange-closer** - close idle reserves

Synopsis
========

**taler-exchange-closer**
[**-d** *DIRNAME* | **--exchange-dir=**\ ‌\ *DIRNAME*]
[**-h** | **--help**] [**-t** | **--test**] [**-v** | **--version**]

Description
===========

**taler-exchange-closer** is a command line tool to run close
reserves that have been idle for too long, causing transfers
to the originating bank account to be scheduled.

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

taler-exchange-transfer(1), taler-exchange-httpd(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
