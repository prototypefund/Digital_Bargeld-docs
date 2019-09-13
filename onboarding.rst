Developer Onboarding Manual
###########################


Taler installation
==================

This section describes the GNU Taler deployment on ``gv.taler.net``.

User Acccounts
--------------

On ``gv.taler.net``, there are four users that are set up to serve Taler on
the internet:

-  ``taler-test``: serves ``*.test.taler.net`` and gets automatically
   built by Buildbot.

-  ``taler-internal``: serves ``*.int.taler.net``, and does *NOT* get
   automatically built.

The following two users are *never* automatically built, and they both
serve ``*.demo.taler.net``. At any given time, only one is active and
serves the HTTP requests from the outside; the other one can so be
compiled without any downtime. If the compilation succeeds, the inactive
user can be switched to become active (see next section), and vice versa.

-  ``demo-blue``
-  ``demo-green``

Compile and switch color.
-------------------------

If the setup is already bootstrapped, then it should only be needed to
login as ’demo-X’ (with X being the inactive color); and then:

::

   $ source activate
   $ taler-deployment-build

and then switch the color by logging in as the *demo* user, and switch
the color with the following command:

::

   $ taler-deployment-switch-demo-X

Full bootstrap.
---------------

In order to bootstrap a Taler installation under a empty home directory,
do:

::

   $ cd $HOME 
   $ git clone git://git.taler.net/deployment

Then run the prepare script that will (1) download all the repositories
(2) build the codebases, (3) configure the system, and (4) generate the
needed data.

::
   $ ./deployment/bin/taler-deployment-prepare
    
..

   **Note**

   If the DB schema of merchant/exchange/auditor changed, at this point
   it MIGHT be necessary to reset all the tables. To this regard,
   consider running one of the following commands:

   ::

      # To reset the merchant DB.
      $ taler-merchant-dbinit -r

      # To reset the exchange DB.
      $ taler-exchange-dbinit -r

      # To reset the exchange DB.
      $ taler-auditor-dbinit -r

If all the steps succeeded, then it should be possible to launch all the
services. Give:

::

   $ taler-deployment-start

   # or restart, if you want to kill old processes and
   # start new ones.
   $ taler-deployment-restart

Verify that all services are up and running:

::

   $ taler-deployment-arm -I
   $ tail logs/<component>-<date>.log

How to upgrade the code.
------------------------

Some repositories, especially the ones from the released components,
have a *stable* branch, that keeps older and more stable code.
Therefore, upon each release we must rebase those stable branches on the
master.

The following commands do that:

::

   $ cd $REPO

   $ git pull origin master stable
   $ git checkout stable

   # option a: resolve conflicts resulting from hotfixes
   $ git rebase master
   $ ...

   # option b: force stable to master
   $ git update-ref refs/heads/stable master

   $ git push # possibly with --force

   # continue development
   $ git checkout master

.. _Testing-components:

Building the documentation
==========================

All the Taler documentation is built by the user `docbuilder` that
runs a Buildbot worker.  The following commands set the `docbuilder` up,
starting with a empty home directory.

::
  # Log-in as the 'docbuilder' user.

  $ cd $HOME
  $ git clone git://git.taler.net/deployment
  $ ./deployment/bootstrap-docbuilder

  # If the previous step worked, the setup is
  # complete and the Buildbot worker can be started.

  $ buildbot-worker start worker/


Building the Websites.
======================

Taler Websites, `www.taler.net` and `stage.taler.net`, are built by the user `taler-websites`
by the means of a Buildbot worker.  The following commands set the `taler-websites` up,
starting with a empty home directory.

::
  # Log-in as the 'taler-websites' user.

  $ cd $HOME
  $ git clone git://git.taler.net/deployment
  $ ./deployment/bootstrap-sitesbuilder

  # If the previous step worked, the setup is
  # complete and the Buildbot worker can be started.

  $ buildbot-worker start worker/



Testing components
==================

This chapter is a VERY ABSTRACT description of how testing is
implemented in Taler, and in NO WAY wants to substitute the reading of
the actual source code by the user.

In Taler, a test case is a array of ``struct TALER_TESTING_Command``,
informally referred to as ``CMD``, that is iteratively executed by the
testing interpreter. This latter is transparently initiated by the
testing library.

However, the developer does not have to defined CMDs manually, but
rather call the proper constructor provided by the library. For example,
if a CMD is supposed to test feature ``x``, then the library would
provide the ``TALER_TESTING_cmd_x ()`` constructor for it. Obviously,
each constructor has its own particular arguments that make sense to
test ``x``, and all constructor are thoroughly commented within the
source code.

Internally, each CMD has two methods: ``run ()`` and ``cleanup ()``. The
former contains the main logic to test feature ``x``, whereas the latter
cleans the memory up after execution.

In a test life, each CMD needs some internal state, made by values it
keeps in memory. Often, the test has to *share* those values with other
CMDs: for example, CMD1 may create some key material and CMD2 needs this
key material to encrypt data.

The offering of internal values from CMD1 to CMD2 is made by *traits*. A
trait is a ``struct TALER_TESTING_Trait``, and each CMD contains a array
of traits, that it offers via the public trait interface to other
commands. The definition and filling of such array happens transparently
to the test developer.

For example, the following example shows how CMD2 takes an amount object
offered by CMD1 via the trait interface.

Note: the main interpreter and the most part of CMDs and traits are
hosted inside the exchange codebase, but nothing prevents the developer
from implementing new CMDs and traits within other codebases.

::

   /* Withouth loss of generality, let's consider the
    * following logic to exist inside the run() method of CMD1 */
   ..

   struct TALER_Amount *a;
   /**
    * the second argument (0) points to the first amount object offered,
    * in case multiple are available.
    */
   if (GNUNET_OK != TALER_TESTING_get_trait_amount_obj (cmd2, 0, &a))
     return GNUNET_SYSERR;
   ...

   use(a); /* 'a' points straight into the internal state of CMD2 */

In the Taler realm, there is also the possibility to alter the behaviour
of supposedly well-behaved components. This is needed when, for example,
we want the exchange to return some corrupted signature in order to
check if the merchant backend detects it.

This alteration is accomplished by another service called *twister*. The
twister acts as a proxy between service A and B, and can be programmed
to tamper with the data exchanged by A and B.

Please refer to the Twister codebase (under the ``test`` directory) in
order to see how to configure it.

.. _Releases:

Releases
========

Release Process and Checklists
------------------------------

This document describes the process for releasing a new version of the
various Taler components to the official GNU mirrors.

The following components are published on the GNU mirrors

-  taler-exchange (exchange.git)
-  taler-merchant (merchant.git)
-  talerdonations (donations.git)
-  talerblog (blog.git)
-  taler-bank (bank.git)
-  taler-wallet-webex (wallet-webex.git)

Tagging
-------

Tag releases with an **annotated** commit, like

::

   git tag -a v0.1.0 -m "Official release v0.1.0"
   git push origin v0.1.0

Database for tests
------------------

For tests in the exchange and merchant to run, make sure that a database
*talercheck* is accessible by *$USER*. Otherwise tests involving the
database logic are skipped.

Exchange, merchant
------------------

Set the version in ``configure.ac``. The commit being tagged should be
the change of the version.

For the exchange test cases to pass, ``make install`` must be run first.
Without it, test cases will fail because plugins can’t be located.

::

   ./bootstrap
   ./configure # add required options for your system
   make dist
   tar -xf taler-$COMPONENT-$VERSION.tar.gz
   cd taler-$COMPONENT-$VERSION
   make install check

Wallet WebExtension
-------------------

The version of the wallet is in *manifest.json*. The ``version_name``
should be adjusted, and *version* should be increased independently on
every upload to the WebStore.

::

   ./configure
   make dist

Upload to GNU mirrors
---------------------

See
*https://www.gnu.org/prep/maintain/maintain.html#Automated-FTP-Uploads*

Directive file:

::

   version: 1.2
   directory: taler
   filename: taler-exchange-0.1.0.tar.gz

Upload the files in **binary mode** to the ftp servers.

.. _Code:

Code
====

Taler code is versioned via Git. For those users without write access,
all the codebases are found at the following URL:

::

   git://git.taler.net/<repository>

A complete list of all the existing repositories is currently found at
``https://git.taler.net/``. Note: ``<repository>`` must NOT have the
``.git`` extension.

.. _Bugtracking:

Bugtracking
===========

Bug tracking is done with Mantis (https://www.mantisbt.org/). All the
bugs are then showed and managed at ``https://bugs.gnunet.org/``, under
the "Taler" project. A registration on the Web site is needed in order
to use the bug tracker.

.. _Continuous-integration:

Continuous integration
======================

CI is done with Buildbot (https://buildbot.net/), and builds are
triggered by the means of Git hooks. The results are published at
``https://buildbot.wild.gv.taler.net/``.

In order to avoid downtimes, CI uses a "blue/green" deployment
technique. In detail, there are two users building code on the system,
the "green" and the "blue" user; and at any given time, one is running
Taler services and the other one is either building the code or waiting
for that.

There is also the possibility to trigger builds manually, but this is
only reserved to "admin" users.

.. _Code-coverage:

Code coverage
=============

Code coverage is done with the Gcov / Lcov
(http://ltp.sourceforge.net/coverage/lcov.php) combo, and it is run
\*nightly\* (once a day) by a Buildbot worker. The coverage results are
then published at ``https://lcov.taler.net/``.
