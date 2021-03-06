GNU Taler Merchant Backend Operator Manual
##########################################

Introduction
============

About GNU Taler
---------------

GNU Taler is an open protocol for an electronic payment system with a
free software reference implementation. GNU Taler offers secure, fast
and easy payment processing using well understood cryptographic
techniques. GNU Taler allows customers to remain anonymous, while
ensuring that merchants can be held accountable by governments. Hence,
GNU Taler is compatible with anti-money-laundering (AML) and
know-your-customer (KYC) regulation, as well as data protection
regulation (such as GDPR).

GNU Taler is not yet production-ready, after following this manual you
will have a backend that can process payments in “KUDOS”, but not
regular currencies. This is not so much because of limitations in the
backend, but because we are not aware of a Taler exchange operator
offering regular currencies today.

.. _About-this-manual:

About this manual
-----------------

This tutorial targets system administrators who want to install a GNU
Taler merchant *backend*.

We expect some moderate familiarity with the compilation and
installation of free software packages. An understanding of cryptography
is not required.

This first chapter of the tutorial will give a brief overview of the
overall Taler architecture, describing the environment in which the
Taler backend operates. The second chapter then explains how to install
the software, including key dependencies. The third chapter will explain
how to configure the backend, including in particular the configuration
of the bank account details of the merchant.

The last chapter gives some additional information about advanced topics
which will be useful for system administrators but are not necessary for
operating a basic backend.

.. _Architecture-overview:

Architecture overview
---------------------

:keywords: crypto-currency
:keywords: KUDOS

Taler is a pure payment system, not a new crypto-currency. As such, it
operates in a traditional banking context. In particular, this means
that in order to receive funds via Taler, the merchant must have a
regular bank account, and payments can be executed in ordinary
currencies such as USD or EUR. For testing purposes, Taler uses a
special currency “KUDOS” and includes its own special bank.

The Taler software stack for a merchant consists of four main
components:

-  frontend
   A frontend which interacts with the customer’s browser. The frontend
   enables the customer to build a shopping cart and place an order.
   Upon payment, it triggers the respective business logic to satisfy
   the order. This component is not included with Taler, but rather
   assumed to exist at the merchant. This manual describes how to
   integrate Taler with Web shop frontends.

-  back office
   A back office application that enables the shop operators to view
   customer orders, match them to financial transfers, and possibly
   approve refunds if an order cannot be satisfied. This component is
   again not included with Taler, but rather assumed to exist at the
   merchant. This manual will describe how to integrate such a component
   to handle payments managed by Taler.

-  backend
   A Taler-specific payment backend which makes it easy for the frontend
   to process financial transactions with Taler. The next two chapters
   will describe how to install and configure this backend.

-  DBMS
   Postgres
   A DBMS which stores the transaction history for the Taler backend.
   For now, the GNU Taler reference implemenation only supports
   Postgres, but the code could be easily extended to support another
   DBMS.

The following image illustrates the various interactions of these key
components:

::

   Missing diagram image

RESTful
Basically, the backend provides the cryptographic protocol support,
stores Taler-specific financial information in a DBMS and communicates
with the GNU Taler exchange over the Internet. The frontend accesses the
backend via a RESTful API. As a result, the frontend never has to
directly communicate with the exchange, and also does not deal with
sensitive data. In particular, the merchant’s signing keys and bank
account information is encapsulated within the Taler backend.

Installation
============

This chapter describes how to install the GNU Taler merchant backend.

Installing Taler using Docker
-----------------------------

This section provides instructions for the merchant backend installation
using ‘Docker‘.

For security reasons, we run Docker against a VirtualBox instance, so
the ``docker`` command should connect to a ``docker-machine`` instance
that uses the VirtualBox driver.

Therefore, the needed tools are: “docker“, “docker-machine“, and
“docker-compose“. Please refer to Docker’s official  [1]_ documentation
in order to get those components installed, as that is not in this
manual’s scope.

Before starting to build the merchant’s image, make sure a
“docker-machine“ instance is up and running.

Because all of the Docker source file are kept in our “deployment“
repository, we start by checking out the ``git://taler.net/deployment``
codebase:

::

   $ git clone git://taler.net/deployment

Now we actually build the merchant’s image. From the same directory as
above:

::

   $ cd deployment/docker/merchant/
   $ docker-compose build

If everything worked as expected, the merchant is ready to be launched.
From the same directory as the previous step:

::

   # Recall: the docker-machine should be up and running.
   $ docker-compose up

You should see some live logging from all the involved containers. At
this stage of development, you should also ignore some (harmless) error
message from postresql about already existing roles and databases.

To test if everything worked as expected, it suffices to issue a simple
request to the merchant, as:

::

   $ curl http://$(docker-machine ip)/
   # A greeting message should be returned by the merchant.

.. _Generic-instructions:

Generic instructions
--------------------

This section provides generic instructions for the merchant backend
installation independent of any particular operating system. Operating
system specific instructions are provided in the following sections. You
should follow the operating system specific instructions if those are
available, and only consult the generic instructions if no
system-specific instructions are provided for your specific operating
system.

.. _Installation-of-dependencies:

Installation of dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following packages need to be installed before we can compile the
backend:

-  autoconf >= 2.69

-  automake >= 1.14

-  libtool >= 2.4

-  autopoint >= 0.19

-  libltdl >= 2.4

-  libunistring >= 0.9.3

-  libcurl >= 7.26 (or libgnurl >= 7.26)

-  GNU libmicrohttpd >= 0.9.39

-  GNU libgcrypt >= 1.6

-  libjansson >= 2.7

-  Postgres >= 9.4, including libpq

-  libgnunetutil (from Git)

-  GNU Taler exchange (from Git)

Except for the last two, these are available in most GNU/Linux
distributions and should just be installed using the respective package
manager.

The following sections will provide detailed instructions for installing
the libgnunetutil and GNU Taler exchange dependencies.

.. _Installing-libgnunetutil:

Installing libgnunetutil
~~~~~~~~~~~~~~~~~~~~~~~~

:keywords: GNUnet

Before you install libgnunetutil, you must download and install the
dependencies mentioned in the previous section, otherwise the build may
succeed but fail to export some of the tooling required by Taler.

To download and install libgnunetutil, proceed as follows:

::

   $ git clone https://gnunet.org/git/gnunet/
   $ cd gnunet/
   $ ./bootstrap
   $ ./configure [--prefix=GNUNETPFX]
   $ # Each dependency can be fetched from non standard locations via
   $ # the '--with-<LIBNAME>' option. See './configure --help'.
   $ make
   # make install

If you did not specify a prefix, GNUnet will install to ``/usr/local``,
which requires you to run the last step as ``root``.

.. _Installing-the-GNU-Taler-exchange:

Installing the GNU Taler exchange
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:keywords: exchange

After installing GNUnet, you can download and install the exchange as
follows:

::

   $ git clone git://taler.net/exchange
   $ cd exchange
   $ ./bootstrap
   $ ./configure [--prefix=EXCHANGEPFX] \
                 [--with-gnunet=GNUNETPFX]
   $ # Each dependency can be fetched from non standard locations via
   $ # the '--with-<LIBNAME>' option. See './configure --help'.
   $ make
   # make install

If you did not specify a prefix, the exchange will install to
``/usr/local``, which requires you to run the last step as ``root``.
Note that you have to specify ``--with-gnunet=/usr/local`` if you
installed GNUnet to ``/usr/local`` in the previous step.

.. _Installing-the-GNU-Taler-merchant-backend:

Installing the GNU Taler merchant backend
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:keywords: backend

The following steps assume all dependencies are installed.

Use the following commands to download and install the merchant backend:

::

   $ git clone git://taler.net/merchant
   $ cd merchant
   $ ./bootstrap
   $ ./configure [--prefix=PFX] \
                 [--with-gnunet=GNUNETPFX] \
                 [--with-exchange=EXCHANGEPFX]
   $ # Each dependency can be fetched from non standard locations via
   $ # the '--with-<LIBNAME>' option. See './configure --help'.
   $ make
   $ make install

Note that you have to specify ``--with-exchange=/usr/local`` and/or
``--with-exchange=/usr/local`` if you installed the exchange and/or
GNUnet to ``/usr/local`` in the previous steps.

.. _Installing-Taler-on-Debian-GNU_002fLinux:

Installing Taler on Debian GNU/Linux
------------------------------------

:keywords: Wheezy
:keywords: Debian

Debian wheezy is too old and lacks most of the packages required.

On Debian jessie, only GNU libmicrohttpd needs to be compiled from
source. To install dependencies on Debian jesse, run the following
commands:

::

   # apt-get install \
     autoconf \
     automake \
     autopoint \
     libtool \
     libltdl-dev \
     libunistring-dev \
     libcurl4-gnutls-dev \
     libgcrypt20-dev \
     libjansson-dev \
     libpq-dev \
     postgresql-9.4
   # wget https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz
   # wget https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz.sig
   # gpg -v libmicrohttpd-latest.tar.gz # Should show signed by 939E6BE1E29FC3CC
   # tar xf libmicrohttpd-latest.tar.gz
   # cd libmicrohttpd-0*
   # ./configure
   # make install

For more recent versions of Debian, you should instead run:

::

   # apt-get install \
     autoconf \
     automake \
     autopoint \
     libtool \
     libltdl-dev \
     libunistring-dev \
     libcurl4-gnutls-dev \
     libgcrypt20-dev \
     libjansson-dev \
     libpq-dev \
     postgresql-9.5 \
     libmicrohttpd-dev

For the rest of the installation, follow the generic installation
instructions starting with the installation of libgnunetutil. Note that
if you used the Debian wheezy instructions above, you need to pass
``--with-microhttpd=/usr/local/`` to all ``configure`` invocations.

How to configure the merchant’s backend
=======================================

:keywords: taler-config
:keywords: taler.conf

The installation already provides reasonable defaults for most of the
configuration options. However, some must be provided, in particular the
database account and bank account that the backend should use. By
default, the file ``$HOME/.config/taler.conf`` is where the Web shop
administrator specifies configuration values that augment or override
the defaults. The format of the configuration file is the well-known INI
file format. You can edit the file by hand, or use the ``taler-config``
commands given as examples. For more information on ``taler-config``,
see `Using taler-config <#Using-taler_002dconfig>`__.

.. _Backend-options:

Backend options
---------------

The following table describes the options that commonly need to be
modified. Here, the notation ``[$section]/$option`` denotes the option
``$option`` under the section ``[$section]`` in the configuration file.

Service address
   The following option sets the transport layer address used by the
   merchant backend:

:keywords: UNIX domain socket
:keywords: TCP

   ::

      [MERCHANT]/SERVE = TCP | UNIX

   If given,

   -  ``TCP``, then we need to set the TCP port in ``[MERCHANT]/PORT``

   -  ``UNIX``, then we need to set the unix domain socket path and mode
      in ``[MERCHANT]/UNIXPATH`` and ``[MERCHANT]/UNIXPATH_MODE``. The
      latter takes the usual permission mask given as a number, e.g. 660
      for user/group read-write access.

   The frontend can then connect to the backend over HTTP using the
   specified address. If frontend and backend run within the same
   operating system, the use of a UNIX domain socket is recommended to
   avoid accidentally exposing the backend to the network.

:keywords: port
   To run the Taler backend on TCP port 8888, use:

   ::

      $ taler-config -s MERCHANT -o SERVE -V TCP
      $ taler-config -s MERCHANT -o PORT -V 8888

Currency
   Which currency the Web shop deals in, i.e. “EUR” or “USD”, is
   specified using the option

:keywords: currency
:keywords: KUDOS

   ::

      [TALER]/CURRENCY

   For testing purposes, the currency MUST match “KUDOS” so that tests
   will work with the Taler demonstration exchange at
   https://exchange.demo.taler.net/:

   ::

      $ taler-config -s TALER -o CURRENCY -V KUDOS

Database
:keywords: DBMS

   In principle is possible for the backend to support different DBMSs.
   The option

   ::

      [MERCHANT]/DB

   specifies which DBMS is to be used. However, currently only the value
   "postgres" is supported. This is also the default.

   In addition to selecting the DBMS software, the backend requires
   DBMS-specific options to access the database.

   For postgres, you need to provide:

   ::

      [merchantdb-postgres]/config

:keywords: Postgres

   This option specifies a postgres access path using the format
   ``postgres:///$DBNAME``, where ``$DBNAME`` is the name of the
   Postgres database you want to use. Suppose ``$USER`` is the name of
   the user who will run the backend process. Then, you need to first
   run

   ::

      $ sudu -u postgres createuser -d $USER

   as the Postgres database administrator (usually ``postgres``) to
   grant ``$USER`` the ability to create new databases. Next, you should
   as ``$USER`` run:

   ::

      $ createdb $DBNAME

   to create the backend’s database. Here, ``$DBNAME`` must match the
   database name given in the configuration file.

   To configure the Taler backend to use this database, run:

   ::

      $ taler-config -s MERCHANTDB-postgres -o CONFIG \
        -V postgres:///$DBNAME

Exchange
:keywords: exchange

   To add an exchange to the list of trusted payment service providers,
   you create a section with a name that starts with “exchange-”. In
   that section, the following options need to be configured:

   -  The “url” option specifies the exchange’s base URL. For example,
      to use the Taler demonstrator use:

      ::

         $ taler-config -s EXCHANGE-demo -o URL \
           -V https://exchange.demo.taler.net/

   -  master key
      The “master_key” option specifies the exchange’s master public key
      in base32 encoding. For the Taler demonstrator, use:

      ::

         $ taler-config -s EXCHANGE-demo -o master_key \
           -V CQQZ9DY3MZ1ARMN5K1VKDETS04Y2QCKMMCFHZSWJWWVN82BTTH00

      Note that multiple exchanges can be added to the system by using
      different tokens in place of ``demo`` in the example above. Note
      that all of the exchanges must use the same currency. If you need
      to support multiple currencies, you need to configure a backend
      per currency.

Instances
:keywords: instance

   The backend allows the user to run multiple instances of shops with
   distinct business entities against a single backend. Each instance
   uses its own bank accounts and key for signing contracts. It is
   mandatory to configure a "default" instance.

   -  The “KEYFILE” option specifies the file containing the instance’s
      private signing key. For example, use:

      ::

         $ taler-config -s INSTANCE-default -o KEYFILE \
           -V '${TALER_CONFIG_HOME}/merchant/instace/default.key'

   -  The “NAME” option specifies a human-readable name for the
      instance. For example, use:

      ::

         $ taler-config -s INSTANCE-default -o NAME \
           -V 'Kudos Inc.'

   -  The optional “TIP_EXCHANGE” and “TIP_EXCHANGE_PRIV_FILENAME”
      options are discussed in Tipping visitors

Accounts
:keywords: wire format

   In order to receive payments, the merchant backend needs to
   communicate bank account details to the exchange. For this, the
   configuration must include one or more sections named “ACCOUNT-name”
   where ``name`` can be replaced by some human-readable word
   identifying the account. For each section, the following options
   should be provided:

   -  The “URL” option specifies a ``payto://``-URL for the account of
      the merchant. For example, use:

      ::

         $ taler-config -s ACCOUNT-bank -o NAME \
           -V 'payto://x-taler-bank/bank.demo.taler.net/4'

   -  The “WIRE_RESPONSE” option specifies where Taler should store the
      (salted) JSON encoding of the wire account. The file given will be
      created if it does not exist. For example, use:

      ::

         $ taler-config -s ACCOUNT-bank -o WIRE_RESPONSE \
           -V '{$TALER_CONFIG_HOME}/merchant/bank.json'

   -  For each ``instance`` that should use this account, you should set
      ``HONOR_instance`` and ``ACTIVE_instance`` to YES. The first
      option will cause the instance to accept payments to the account
      (for existing contracts), while the second will cause the backend
      to include the account as a possible option for new contracts.

      For example, use:

      ::

         $ taler-config -s ACCOUNT-bank -o HONOR_default \
           -V YES
         $ taler-config -s ACCOUNT-bank -o ACTIVE_default \
           -V YES

      to use “account-bank” for the “default” instance.

   Note that additional instances can be specified using different
   tokens in the section name instead of ``default``.

.. _Sample-backend-configuration:

Sample backend configuration
----------------------------

:keywords: configuration

The following is an example for a complete backend configuration:

::

   [TALER]
   CURRENCY = KUDOS

   [MERCHANT]
   SERVE = TCP
   PORT = 8888
   DATABASE = postgres

   [MERCHANTDB-postgres]
   CONFIG = postgres:///donations

   [INSTANCE-default]
   KEYFILE = $DATADIR/key.priv
   NAME = "Kudos Inc."

   [ACCOUNT-bank]
   URL = payto://x-taler-bank/bank.demo.taler.net/4
   WIRE_RESPONSE = $DATADIR/bank.json
   HONOR_default = YES
   ACTIVE_default = YES
   TALER_BANK_AUTH_METHOD = basic
   USERNAME = my_user
   PASSWORD = 1234pass

   [merchant-exchange-trusted]
   EXCHANGE_BASE_URL = https://exchange.demo.taler.net/
   MASTER_KEY = CQQZ9DY3MZ1ARMN5K1VKDETS04Y2QCKMMCFHZSWJWWVN82BTTH00
   CURRENCY = KUDOS

Given the above configuration, the backend will use a database named
``donations`` within Postgres.

The backend will deposit the coins it receives to the exchange at
https://exchange.demo.taler.net/, which has the master key
"CQQZ9DY3MZ1ARMN5K1VKDETS04Y2QCKMMCFHZSWJWWVN82BTTH00".

Please note that ``doc/config.sh`` will walk you through all
configuration steps, showing how to invoke ``taler-config`` for each of
them.

.. _Launching-the-backend:

Launching the backend
---------------------

:keywords: backend
:keywords: taler-merchant-httpd

Assuming you have configured everything correctly, you can launch the
merchant backend using:

::

   $ taler-merchant-httpd

When launched for the first time, this command will print a message
about generating your private key. If everything worked as expected, the
command

::

   $ curl http://localhost:8888/

should return the message

::

   Hello, I'm a merchant's Taler backend. This HTTP server is not for humans.

Please note that your backend is right now likely globally reachable.
Production systems should be configured to bind to a UNIX domain socket
or properly restrict access to the port.

.. _Testing:

Testing
=======

The tool ``taler-merchant-generate-payments`` can be used to test the
merchant backend installation. It implements all the payment’s steps in
a programmatically way, relying on the backend you give it as input.
Note that this tool gets installed along all the merchant backend’s
binaries.

This tool gets configured by a config file, that must have the following
layout:

::

   [PAYMENTS-GENERATOR]

   # The exchange used during the test: make sure the merchant backend
   # being tested accpets this exchange.
   # If the sysadmin wants, she can also install a local exchange
   # and test against it.
   EXCHANGE = https://exchange.demo.taler.net/

   # This value must indicate some URL where the backend
   # to be tested is listening; it doesn't have to be the
   # "official" one, though.
   MERCHANT = http://localbackend/

   # This value is used when the tool tries to withdraw coins,
   # and must match the bank used by the exchange. If the test is
   # done against the exchange at https://exchange.demo.taler.net/,
   # then this value can be "https://bank.demo.taler.net/".
   BANK = https://bank.demo.taler.net/

   # The merchant instance in charge of serving the payment.
   # Make sure this instance has a bank account at the same bank
   # indicated by the 'bank' option above.
   INSTANCE = default

   # The currency used during the test. Must match the one used
   # by merchant backend and exchange.
   CURRENCY = KUDOS

Run the test in the following way:

::

   $ taler-merchant-generate-payments [-c config] [-e EURL] [-m MURL]

The argument ``config`` given to ``-c`` points to the configuration file
and is optional – ``~/.config/taler.conf`` will be checked by default.
By default, the tool forks two processes: one for the merchant backend,
and one for the exchange. The option ``-e`` (``-m``) avoids any exchange
(merchant backend) fork, and just runs the generator against the
exchange (merchant backend) running at ``EURL`` (``MURL``).

Please NOTE that the generator contains *hardcoded* values, as for
deposit fees of the coins it uses. In order to work against the used
exchange, those values MUST match the ones used by the exchange.

The following example shows how the generator "sets" a deposit fee of
EUR:0.01 for the 5 EURO coin.

::

   // from <merchant_repository>/src/sample/generate_payments.c
   { .oc = OC_PAY,
     .label = "deposit-simple",
     .expected_response_code = MHD_HTTP_OK,
     .details.pay.contract_ref = "create-proposal-1",
     .details.pay.coin_ref = "withdraw-coin-1",
     .details.pay.amount_with_fee = concat_amount (currency, "5"),
     .details.pay.amount_without_fee = concat_amount (currency, "4.99") },

The logic calculates the deposit fee according to the subtraction:
``amount_with_fee - amount_without_fee``.

The following example shows a 5 EURO coin configuration - needed by the
used exchange - which is compatible with the hardcoded example above.

::

   [COIN_eur_5]
   value = EUR:5
   duration_overlap = 5 minutes
   duration_withdraw = 7 days
   duration_spend = 2 years
   duration_legal = 3 years
   fee_withdraw = EUR:0.00
   fee_deposit = EUR:0.01 # important bit
   fee_refresh = EUR:0.00
   fee_refund = EUR:0.00
   rsa_keysize = 1024

If the command terminates with no errors, then the merchant backend is
correctly installed.

After this operation is done, the merchant database will have some dummy
data in it, so it may be convenient to clean all the tables; to this
purpose, issue the following command:

::

   $ taler-merchant-dbinit -r


Advanced topics
===============

Configuration format
--------------------

:keywords: configuration

In Taler realm, any component obeys to the same pattern to get
configuration values. According to this pattern, once the component has
been installed, the installation deploys default values in
${prefix}/share/taler/config.d/, in .conf files. In order to override
these defaults, the user can write a custom .conf file and either pass
it to the component at execution time, or name it taler.conf and place
it under $HOME/.config/.

A config file is a text file containing sections, and each section
contains its values. The right format follows:

::

   [section1]
   value1 = string
   value2 = 23

   [section2]
   value21 = string
   value22 = /path22

Throughout any configuration file, it is possible to use ``$``-prefixed
variables, like ``$VAR``, especially when they represent filesystem
paths. It is also possible to provide defaults values for those
variables that are unset, by using the following syntax:
``${VAR:-default}``. However, there are two ways a user can set
``$``-prefixable variables:

by defining them under a ``[paths]`` section, see example below,

::

   [paths]
   TALER_DEPLOYMENT_SHARED = ${HOME}/shared-data
   ..
   [section-x]
   path-x = ${TALER_DEPLOYMENT_SHARED}/x

or by setting them in the environment:

::

   $ export VAR=/x

The configuration loader will give precedence to variables set under
``[path]``, though.

The utility ``taler-config``, which gets installed along with the
exchange, serves to get and set configuration values without directly
editing the .conf. The option ``-f`` is particularly useful to resolve
pathnames, when they use several levels of ``$``-expanded variables. See
``taler-config --help``.

Note that, in this stage of development, the file
``$HOME/.config/taler.conf`` can contain sections for *all* the
component. For example, both an exchange and a bank can read values from
it.

The repository ``git://taler.net/deployment`` contains examples of
configuration file used in our demos. See under ``deployment/config``.

   **Note**

   Expectably, some components will not work just by using default
   values, as their work is often interdependent. For example, a
   merchant needs to know an exchange URL, or a database name.

.. _Using-taler_002dconfig:

Using taler-config
------------------

:keywords: taler-config

The tool ``taler-config`` can be used to extract or manipulate
configuration values; however, the configuration use the well-known INI
file format and can also be edited by hand.

Run

::

   $ taler-config -s $SECTION

to list all of the configuration values in section ``$SECTION``.

Run

::

   $ taler-config -s $section -o $option

to extract the respective configuration value for option ``$option`` in
section ``$section``.

Finally, to change a setting, run

::

   $ taler-config -s $section -o $option -V $value

to set the respective configuration value to ``$value``. Note that you
have to manually restart the Taler backend after you change the
configuration to make the new configuration go into effect.

Some default options will use $-variables, such as ``$DATADIR`` within
their value. To expand the ``$DATADIR`` or other $-variables in the
configuration, pass the ``-f`` option to ``taler-config``. For example,
compare:

::

   $ taler-config -s ACCOUNT-bank \
                  -o WIRE_RESPONSE
   $ taler-config -f -s ACCOUNT-bank \
                  -o WIRE_RESPONSE

While the configuration file is typically located at
``$HOME/.config/taler.conf``, an alternative location can be specified
to ``taler-merchant-httpd`` and ``taler-config`` using the ``-c``
option.

.. _Merchant-key-management:

Merchant key management
-----------------------

:keywords: merchant key
:keywords: KEYFILE

The option “KEYFILE” in the section “INSTANCE-default” specifies the
path to the instance’s private key. You do not need to create a key
manually, the backend will generate it automatically if it is missing.
While generally unnecessary, it is possible to display the corresponding
public key using the ``gnunet-ecc`` command-line tool:

::

   $ gnunet-ecc -p                                  \
     $(taler-config -f -s INSTANCE-default \
                    -o KEYFILE)

.. _Tipping-visitors:

Tipping visitors
----------------

:keywords: tipping

Taler can also be used to tip Web site visitors. For example, you may be
running an online survey, and you want to reward those people that have
dutifully completed the survey. If they have installed a Taler wallet,
you can provide them with a tip for their deeds. This section describes
how to setup the Taler merchant backend for tipping.

There are four basic steps that must happen to tip a visitor.

.. _Configure-a-reserve-and-exchange-for-tipping:

Configure a reserve and exchange for tipping
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:keywords: gnunet-ecc
:keywords: reserve key

To tip users, you first need to create a reserve. A reserve is a pool of
money held in escrow at the Taler exchange. This is the source of the
funds for the tips. Tipping will fail (resulting in disappointed
visitors) if you do not have enough funds in your reserve!

First, we configure the backend. You need to enable tipping for each
instance separately, or you can use an instance only for tipping. To
configure the “default” instance for tipping, use the following
configuration:

::

   [INSTANCE-default]
   # this is NOT the tip.priv
   KEYFILE = signing_key.priv
   # replace the URL with the URL of the exchange you will use
   TIP_EXCHANGE = https://exchange:443/
   # here put the path to the file created with "gnunet-ecc -g1 tip.priv"
   TIP_RESERVE_PRIV_FILENAME = tip.priv

Note that the KEYFILE option should have already been present for the
instance. It has nothing to do with the “tip.priv” file we created
above, and you should probably use a different file here.

Instead of manually editing the configuration, you could also run:

::

   $ taler-config -s INSTANCE-default \
       -o TIP_RESERVE_PRIV_FILENAME \
       -V tip.priv
   $ taler-config -s INSTANCE-default \
       -o TIP_EXCHANGE \
       -V https://exchange:443/

Next, to create the ``TIP_RESERVE_PRIV_FILENAME`` file, use:

::

   $ gnunet-ecc -g 1   \
     $(taler-config -f -s INSTANCE-default \
         -o TIP-RESERVE_PRIV_FILENAME)

This will create a file with the private key that will be used to
identify the reserve. You need to do this once for each instance that is
configured to tip.

Now you can (re)start the backend with the new configuration.

.. _Fund-the-reserve:

Fund the reserve
~~~~~~~~~~~~~~~~

:keywords: reserve
:keywords: close

To fund the reserve, you must first extract the public key from
“tip.priv”:

::

   $ gnunet-ecc --print-public-key \
     $(taler-config -f -s INSTANCE-default \
         -o TIP-RESERVE_PRIV_FILENAME)

In our example, the output for the public key is:

::

   QPE24X8PBX3BZ6E7GQ5VAVHV32FWTTCADR0TRQ183MSSJD2CHNEG

You now need to make a wire transfer to the exchange’s bank account
using the public key as the wire transfer subject. The exchange’s bank
account details can be found in JSON format at
“https://exchange:443//wire/METHOD” where METHOD is the respective wire
method (i.e. “sepa”). Depending on the exchange’s operator, you may also
be able to find the bank details in a human-readable format on the main
page of the exchange.

Make your wire transfer and (optionally) check at
“https://exchange:443/reserve/status/reserve_pub=QPE24X...” whether your
transfer has arrived at the exchange.

Once the funds have arrived, you can start to use the reserve for
tipping.

Note that an exchange will typically close a reserve after four weeks,
wiring all remaining funds back to the sender’s account. Thus, you
should plan to wire funds corresponding to a campaign of about two weeks
to the exchange initially. If your campaign runs longer, you should wire
further funds to the reserve every other week to prevent it from
expiring.

.. _Authorize-a-tip:

Authorize a tip
~~~~~~~~~~~~~~~

When your frontend has reached the point where a client is supposed to
receive a tip, it needs to first authorize the tip. For this, the
frontend must use the “/tip-authorize” API of the backend. To authorize
a tip, the frontend has to provide the following information in the body
of the POST request:

-  The amount of the tip

-  The justification (only used internally for the back-office)

-  The URL where the wallet should navigate next after the tip was
   processed

-  The tip-pickup URL (see next section)

In response to this request, the backend will return a tip token, an
expiration time and the exchange URL. The expiration time will indicate
how long the tip is valid (when the reserve expires). The tip token is
an opaque string that contains all the information needed by the wallet
to process the tip. The frontend must send this tip token to the browser
in a special “402 Payment Required” response inside the ``X-Taler-Tip``
header.

The frontend should handle errors returned by the backend, such as
missconfigured instances or a lack of remaining funds for tipping.

.. _Picking-up-of-the-tip:

Picking up of the tip
~~~~~~~~~~~~~~~~~~~~~

The wallet will POST a JSON object to the shop’s “/tip-pickup” handler.
The frontend must then forward this request to the backend. The response
generated by the backend can then be forwarded directly to the wallet.

.. _Generate-payments:

Generate payments
-----------------

testing database
The merchant codebase offers the ``taler-merchant-benchmark`` tool to
populate the database with fake payments. This tool is in charge of
starting a merchant, exchange, and bank processes, and provide them all
the input to accomplish payments. Note that each component will use its
own configuration (as they would do in production).

The tool takes all of the values it needs from the command line, with
some of them being mandatory. Among those, we have:

-  ``--currency=K`` Use currency *K*, for example to craft coins to
   withdraw.

-  ``--bank-url=URL`` Assume that the bank is serving under the base URL
   *URL*. This option is only actually used by the tool to check if the
   bank was well launched.

-  ``--merchant-url=URL`` Reach the merchant through *URL*, for
   downloading contracts and sending payments.

The tool then comes with two operation modes: *ordinary*, and *corner*.
The first just executes normal payments, meaning that it uses the
default instance and make sure that all payments get aggregated. The
second gives the chance to leave some payments unaggregated, and also to
use merchant instances other than the default (which is, actually, the
one used by default by the tool).

Note: the abilty of driving the aggregation policy is useful for testing
the backoffice facility.

Any subcommand is also equipped with the canonical ``--help`` option, so
feel free to issue the following command in order to explore all the
possibilities. For example:

::

   $ taler-merchant-benchmark corner --help

will show all the options offered by the *corner* mode. Among the most
interesting, there are:

-  ``--two-coins=TC`` This option instructs the tool to perform *TC*
   many payments that use two coins, because normally only one coin is
   spent per payment.

-  ``--unaggregated-number=UN`` This option instructs the tool to
   perform *UN* (one coin) payments that will be left unaggregated.

-  ``--alt-instance=AI`` This option instructs the tool to perform
   payments using the merchant instance *AI* (instead of the *default*
   instance)

As for the ``ordinary`` subcommand, it is worth explaining the following
options:

-  ``--payments-number=PN`` Instructs the tool to perform *PN* payments.

-  ``--tracks-number=TN`` Instructs the tool to perform *TN* tracking
   operations. Note that the **total** amount of operations will be two
   times *TN*, since "one" tracking operation accounts for
   ``/track/transaction`` and ``/track/transfer``. This command should
   only be used to see if the operation ends without problems, as no
   actual measurement of performance is provided (despite of the
   ’benchmark’ work used in the tool’s name).

.. [1]
   https://docs.docker.com/

.. [2]
   Supporting SEPA is still work in progress; the backend will accept
   this configuration, but the exchange will not work with SEPA today.
