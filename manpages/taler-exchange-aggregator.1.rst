taler-exchange-aggregator(1)
############################

.. only:: html

   Name
   ====

   **taler-exchange-aggregator** - aggregate deposits into wire transfers

Synopsis
========

**taler-exchange-aggregator**
[**-h** | **--help**] [**-t** | **--test**] [**-v** | **--version**]

Description
===========

**taler-exchange-aggregator** is a command line tool to run aggregate deposits
to the same merchant into larger wire transfers. The actual transfers are then
done by **taler-exchange-transfer**.

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

taler-exchange-transfer(1), taler-exchange-closer(1),
taler-exchange-httpd(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
