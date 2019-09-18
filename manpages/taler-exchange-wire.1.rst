taler-exchange-wire(1)
######################

.. only:: html

   Name
   ====

   **taler-exchange-wire** - create the master-key signed responses to
   /wire

Synopsis
========

**taler-exchange-wire** [**-h** | **–help**]
[**-m** *MASTERKEYFILE* | **–master=**\ ‌\ *MASTERKEYFILE*]
[**-v** | **–version**]

Description
===========

**taler-exchange-wire** is used to create the exchange’s reply to a
/wire request. It converts the bank details into the appropriate signed
response. This needs to be done using the long-term offline master key.

Its options are as follows:

**-h** \| **–help**
   Print short help on options.

**-m** *MASTERKEYFILE* \| **–master=**\ ‌\ *MASTERKEYFILE*
   Specifies the name of the file containing the exchange’s master key.

**-v** \| **–version**
   Print version information.

See Also
========

taler-exchange-httpd(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
