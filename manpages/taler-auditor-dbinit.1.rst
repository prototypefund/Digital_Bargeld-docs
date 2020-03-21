taler-auditor-dbinit(1)
#######################

.. only:: html

   Name
   ====

   **taler-auditor-dbinit** - initialize Taler auditor database


Synopsis
========

**taler-auditor-dbinit**
[**-h** | **–help**] [**-g** | **–gc**] [**-R** | **–reset**] [**-r** | **–restart**]
[**-v** | **–version**]

Description
===========

**taler-exchange-dbinit** is a command line tool to initialize the Taler
exchange database. It creates the necessary tables and indices for the
Taler exchange to operate.

Its options are as follows:

**-c** *FILENAME* \| **–config=**\ ‌\ *FILENAME*
   Use the configuration and other resources for the exchange to operate
   from *FILENAME*.

**-h** \| **–help**
   Print short help on options.

**-g** \| **–gc**
   Garbage collect database. Deletes all unnecessary data in the
   database.

**-R** \| **–reset**
   Drop tables. Dangerous, will delete all existing data in the database.

**-r** \| **--restart**
   Restart all auditors from the beginning. Useful for
   testing.

**-v** \| **–version**
   Print version information.

See Also
========

taler-auditor-httpd(1), taler-auditor(1), taler.conf(5).

Bugs
====

Report bugs by using https://bugs.gnunet.org or by sending electronic
mail to <taler@gnu.org>.
