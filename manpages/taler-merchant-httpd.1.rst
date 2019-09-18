taler-merchant-httpd(1)
#######################

.. only:: html

       Name
       ====

       **taler-merchant-httpd** - Run Taler merchant backend (with RESTful API)


Synopsis
========

**taler-merchant-httpd** [*options*]


Description
===========

taler-merchant-httpd is a command line tool to run the Taler merchant
(HTTP backend).  The required configuration and database must exist
before running this command.


Options
=======

-C, --connection-close
       Force each HTTP connection to be closed after each request
       (useful in combination with -f to avoid having to wait for nc to
       time out).

-c FILENAME, --config=FILENAME
       Use the configuration and other resources for the merchant to
       operate from FILENAME.

-h, --help
       Print short help on options.

-v, --version
       Print version information.


Signals
========

SIGTERM
       Sending a SIGTERM to the process will cause it to shutdown
       cleanly.


Bugs
====

Report bugs by using Mantis <https://gnunet.org/bugs/> or by sending
electronic mail to <taler@gnu.org>


See Also
========

taler-merchant-dbinit(1), taler-merchant-tip-enable(1), taler.conf(5)
