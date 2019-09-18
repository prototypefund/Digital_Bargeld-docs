taler-exchange-benchmark(1)
###########################


.. only:: html

   Name
   ====

   **taler-exchange-benchmark** - measure exchange performance


Synopsis
========

**taler-exchange-benchmark**
[**-c** *CONFIG_FILENAME* | **--config=**\ ‌\ *CONFIG_FILENAME*]
[**-b** *BANK_URL* | **—bank-url=**\ ‌\ *BANK_URL*]
[**-n** *HOWMANY_COINS* | **--coins-number=**\ ‌\ *HOWMANY_COINS*]
[**-l** *LOGLEVEL* | **--log-level=**\ ‌\ *LOGLEVEL*]
[**-h** | **--help**]

Description
===========

**taler-exchange-benchmark** is a command line tool to measure the time
spent to serve withdrawals/deposits/refreshes. It usually needs a
dedicate configuration file where all the services - the exchange and
the (fake)bank - listen to URLs not subject to any reverse proxy, as say
Nginx. Moreover, the benchmark runs on a “volatile” database, that means
that table are always erased during a single benchmark run.

**-c** *CONFIG_FILENAME* \| **--config=**\ ‌\ *CONFIG_FILENAME*
   (Mandatory) Use CONFIG_FILENAME.

**-b** *BANK_URL* \| **—bank-url=**\ ‌\ *BANK_URL*
   (Mandatory) The URL where the fakebank listens at. Must match the
   host component in the exchange’s escrow account “payto” URL.

**-n** *HOWMANY_COINS* \| **--coins-number=**\ ‌\ *HOWMANY_COINS*
   Defaults to 1. Specifies how many coins this benchmark should
   withdraw and spend. After being spent, each coin will be refreshed
   with a REFRESH_PROBABILITY probability, which is (hardcoded as) 0.1;
   future versions of this tool should offer this parameter as a CLI
   option.

**-l** *LOGLEVEL* \| **--log-level=**\ ‌\ *LOGLEVEL*
   GNUnet-compatible log level, takes values “ERROR/WARNING/INFO/DEBUG”

**-h** \| **--help**
   Prints a compiled-in help text.

See Also
========

taler-exchange-dbinit(1), taler-exchange-keyup(1),
taler-exchange-httpd(1), taler.conf(5)

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
