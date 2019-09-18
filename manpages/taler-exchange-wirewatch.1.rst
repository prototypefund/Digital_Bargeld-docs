taler-exchange-wirewatch(1)
###########################

.. only:: html

   Name
   ====

   **taler-exchange-wirewatch** - watch for incoming wire transfers

Synopsis
========

**taler-exchange-wirewatch**
[**-t** *PLUGINNAME* | **–type=**\ ‌\ *PLUGINNAME*] [**-h** | **–help**]
[**-T** | **–test**] [**-r** | **–reset**] [**-v** | **–version**]

Description
===========

**taler-exchange-wirewatch** is a command line tool to import wire
transactions into the Taler exchange database.

Its options are as follows:

**-t** *PLUGINNAME* \| **–type=**\ ‌\ *PLUGINNAME*

   Use the specified wire plugin and its configuration to talk to the
   bank.

**-h** \| **–help**

   Print short help on options.

**-T** \| **–test**

   Run in test mode and exit when idle.

**-r** \| **–reset**

   Ignore our own database and start with transactions from the
   beginning of time.

**-v** \| **–version**

   Print version information.

See Also
========

taler-exchange-aggregator(1), taler-exchange-httpd(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
