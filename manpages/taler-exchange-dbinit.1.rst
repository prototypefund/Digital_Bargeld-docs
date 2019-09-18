taler-exchange-dbinit(1)
########################

.. only:: html

   Name
   ====

   **taler-exchange-dbinit** - initialize Taler exchange database


Synopsis
========

**taler-exchange-dbinit**
[**-d** *DIRNAME* | **–exchange-dir=**\ ‌\ *DIRNAME*]
[**-h** | **–help**] [**-g** | **–gc**] [**-r** | **–reset**]
[**-v** | **–version**]

Description
===========

**taler-exchange-dbinit** is a command line tool to initialize the Taler
exchange database. It creates the necessary tables and indices for the
Taler exchange to operate.

Its options are as follows:

**-d** *DIRNAME* \| **–exchange-dir=**\ ‌\ *DIRNAME*
   Use the configuration and other resources for the exchange to operate
   from *DIRNAME*.

**-h** \| **–help**
   Print short help on options.

**-g** \| **–gc**
   Garbage collect database. Deletes all unnecessary data in the
   database.

**-r** \| **–reset**
   Drop tables. Dangerous, will delete all existing data in the database
   before creating the tables.

**-v** \| **–version**
   Print version information.

See Also
========

taler-exchange-httpd(1), taler-exchange-keyup(1),
taler-exchange-reservemod(1), taler.conf(5).

Bugs
====

Report bugs by using https://bugs.gnunet.org or by sending electronic
mail to <taler@gnu.org>.
