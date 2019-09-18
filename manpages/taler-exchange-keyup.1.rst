taler-exchange-keyup(1)
#######################

.. only:: html

   Name
   ====

   **taler-exchange-keyup** - set up Taler exchange denomination and signing
   keys

Synopsis
========

**taler-exchange-keyup**
[**-d** *DIRNAME* | **–exchange-dir=**\ ‌\ *DIRNAME*]
[**-h** | **–help**] [**-m** *FILE* | **–master-key=**\ ‌\ *FILE*]
[**-o** *FILE* | **–output=**\ ‌\ *FILE*]
[**-r** *DKH* | **–revoke=**\ ‌\ *DKH*]
[**-t** *TIMESTAMP* | **–time=**\ ‌\ *TIMESTAMP*]
[**-v** | **–version**]

Description
===========

**taler-exchange-keyup** is a command line tool to setup Taler
denomination and signing keys. This tool requires access to the
exchange’s long-term offline signing key and should be run in a secure
(offline) environment under strict controls. The resulting keys can then
be copied to the main online directory where the Taler HTTP server
operates.

Its options are as follows:

**-d** *DIRNAME* \| **–exchange-dir=**\ ‌\ *DIRNAME*
   Use the configuration and other resources for the exchange to operate
   from *DIRNAME*.

**-h** \| **–help**
   Print short help on options.

**-m** *FILE* \| **–master-key=**\ ‌\ *FILE*
   Location of the private EdDSA offline master key of the exchange.

**-o** *FILE* \| **–output=**\ ‌\ *FILE*
   Where to write a denomination key signing request file to be given to
   the auditor.

**-r** *DKH* \| **–revoke=**\ ‌\ *DKH*
   Revoke the denomination key where the denomination public key’s hash
   is DKH.

**-t** *TIMESTAMP* \| **–time=**\ ‌\ *TIMESTAMP*
   Operate as if the current time was *TIMESTAMP*.

**-v** \| **–version**
   Print version information.

See Also
========

taler-exchange-httpd(1), taler-exchange-keyup(1),
taler-exchange-keycheck(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
