taler-exchange-httpd(1)
#######################

.. only:: html

   Name
   ====

   **taler-exchange-httpd** - run Taler exchange (with RESTful API)

Synopsis
========

**taler-exchange-httpd** [**-C** | **–connection-close**]
[**-c** *FILENAME* | **–config=**\ ‌\ *FILENAME*]
[**-f** *FILENAME* | **–file-input=**\ ‌\ *FILENAME*]
[**-h** | **–help**] [**-i** | **–init-db**]
[**-L** *LOGLEVEL* | **–loglevel=**\ ‌\ *LOGLEVEL*]
[**-t** *SECONDS* | **–timeout=**\ ‌\ *SECONDS*] [**-v** | **–version**]

Description
===========

**taler-exchange-httpd** is a command line tool to run the Taler
exchange (HTTP server). The required configuration, keys and database
must exist before running this command.

Its options are as follows:

**-C** \| **–connection-close**
   Force each HTTP connection to be closed after each request (useful in
   combination with **-f** to avoid having to wait for nc to time out).

**-c** *FILENAME* \| **–config=**\ ‌\ *FILENAME*
   Use the configuration and other resources for the merchant to operate
   from FILENAME.

**-h** \| **–help**
   Print short help on options.

**-i** \| **–init-db**
   Initialize the database by creating tables and indices if necessary.

**-v** \| **–version**
   Print version information.

**-f** *FILENAME* \| **–file-input=**\ ‌\ *FILENAME*
   This option is only available if the exchange was compiled with the
   configure option –enable-developer-mode. It is used for generating
   test cases against the exchange using AFL. When this option is
   present, the HTTP server will

   1. terminate after the first client’s HTTP connection is completed,
      and
   2. automatically start such a client using a helper process based on
      the nc(1) or ncat(1) binary using FILENAME as the standard input
      to the helper process.

   As a result, the process will effectively run with *FILENAME* as the
   input from an HTTP client and then immediately exit. This is useful
   to test taler-exchange-httpd against many different possible inputs
   in a controlled way.

**-t** *SECONDS* \| **–timeout=**\ ‌\ *SECONDS*
   Specifies the number of SECONDS after which the HTTPD should close
   (idle) HTTP connections.

**-L** *LOGLEVEL* \| **–loglevel=**\ ‌\ *LOGLEVEL*
   Specifies the log level to use. Accepted values are: DEBUG, INFO,
   WARNING, ERROR.

SIGNALS
=======

**taler-exchange-httpd** responds to the following signals:

``SIGUSR1``
   Sending a SIGUSR1 to the process will cause it to reload denomination
   and signing keys.

``SIGTERM``
   Sending a SIGTERM to the process will cause it to shutdown cleanly.

``SIGHUP``
   Sending a SIGHUP to the process will cause it to re-execute the
   taler-exchange-httpd binary in the PATH, passing it the existing
   listen socket. Then the old server process will automatically exit
   after it is done handling existing client connections; the new server
   process will accept and handle new client connections.

See Also
========

taler-exchange-dbinit(1), taler-exchange-keyup(1),
taler-exchange-reservemod(1), taler.conf(5).

Bugs
====

Report bugs by using https://gnunet.org/bugs or by sending electronic
mail to <taler@gnu.org>.
