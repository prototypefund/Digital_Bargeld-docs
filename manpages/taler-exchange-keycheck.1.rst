taler-exchange-keycheck(1)
##########################

.. only:: html

   Name
   ====

   **taler-exchange-keycheck** - check validity of Taler signing and
   denomination keys

Synopsis
========

**taler-exchange-keycheck**
[**-d** *DIRNAME* | **–exchange-dir=**\ ‌\ *DIRNAME*]
[**-h** | **–help**] [**-v** | **–version**]

Description
===========

**taler-exchange-keycheck** can be used to check if the signing and
denomination keys in the operation directory are well-formed. This can
be useful after importing fresh keys from the offline system to ensure
that the files are correct.

Its options are as follows:

**-d** *DIRNAME* \| **–exchange-dir=**\ ‌\ *DIRNAME*
   Use the configuration and other resources for the exchange to operate
   from *DIRNAME*.

**-h** \| **–help**
   Print short help on options.

**-v** \| **–version**
   Print version information.

See Also
========

taler-exchange-httpd(1), taler-exchange-keyup(1),
taler-exchange-dbinit(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
