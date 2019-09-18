taler-merchant-benchmark(1)
###########################


.. only:: html

  Name
  ====

  **taler-merchant-benchmark** - generate Taler-style benchmarking payments


Synopsis
========

**taler-merchant-benchmark** [*subcommand*] [*options*]


Description
===========

**taler-merchant-benchmark** is a command line tool to populate your
merchant database with payments for benchmarking.


Subcommands
===========

ordinary
       Generate normal payments: all the payments are performed (by the
       default instance) and aggregated by the exchange.  Takes the following
       options.

       -p PN, --payments-number=PN
              Perform PN many payments, defaults to 1.


       -t TN, --tracks-number=TN
              Perform TN many tracking operations, defaults to 1.


corner
       Drive the generator to create unusual situations, like for example
       leaving payments unaggregated, or using a non-default merchant
       instance.  Takes the following options.


       -t TC, --two-coins=TC
              Perform TC many payments that use two coins (normally, all the
              payments use only one coin).  TC defaults to 1.


       -i AI, --alt-instance=AI
              Use AI as the instance, instead of 'default' (which is the
              default instance used.)


       -u UN, --unaggregated-number=UN
              Generate UN payments that will be left unaggregated.  Note that
              subsequent invocations of the generator may pick those
              unaggregated payments and actually aggregated them.



Common Options
==============

-k K, --currency=K
       Use currency K, mandatory.


-m URL, --merchant-url=URL
       Use URL as the merchant base URL during the benchmark.  The URL
       is mainly used to download and pay for contracts.  Mandatory.


-b URL, --bank-url=URL
       Use URL as the bank's base URL during the benchmark.  The URL is
       used to test whether the bank is up and running.  Mandatory.

-c FILENAME, --config=FILENAME
       Use the configuration and other resources for the merchant to
       operate from FILENAME.

-h, --help
       Print short help on options.

-v, --version
       Print version information.

-l LF, --logfile=LF
       Sends logs to file whose path is LF.


-L LOGLEVEL, --log=LOGLEVEL
       Use loglevel LOGLEVEL.


Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.


See Also
========

taler-merchant-dbinit(1), taler-merchant-tip-enable(1), taler.conf(5)
