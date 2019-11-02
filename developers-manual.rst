Developer's Manual
##################

.. toctree::
   :hidden:

   checklist-release
   checklist-demo-upgrade


.. note::

  This manual contains information for developers working on GNU Taler
  and related components.  It is not intended for a general audience.

.. contents:: Table of Contents

Fundamentals
============

Bug Tracking
------------

Bug tracking is done with Mantis (https://www.mantisbt.org/).  The bug tracker
is available at `<https://bugs.taler.net>`_. A registration on the Web site is
needed in order to use the bug tracker, only read access is granted without a
login.

Code Repositories
-----------------

Taler code is versioned via Git. For those users without write access, all the
codebases are found at the following URL:

::

   git://git.taler.net/<repository>

A complete list of all the existing repositories is currently found at
`<https://git.taler.net/>`_.


Committing code
---------------

To obtain Git access, you need to send us your SSH public key.  You can
find instructions on how to do so in the `Git book <https://git-scm.com/book/en/v2/Git-on-the-Server-Generating-Your-SSH-Public-Key>`_.
If you have been granted write access, you fist of all must change the URL of
the respective repository to:

::

   git://git@git.taler.net/<repository>

For an existing checkout, this can be done by editing the ``.git/config`` file.

The server is configured to reject all commits that have not been signed with
GnuPG. If you do not yet have a GnuPG key, you must create one, as explained
in the `GNU Privacy Handbook <https://www.gnupg.org/gph/en/manual/c14.html>`_.
You do not need to share the respective public key with us to make commits.
However, we recommend that you upload it to key servers, put it on your
business card and personally meet with other GNU hackers to have it signed
such that others can verify your commits later.

To sign all commits, you should run

::

   $ git config --global commit.gpgsign true

You can also sign individual commits only by adding the ``-S`` option to the
``git commit`` command. If you accidentally already made commits but forgot
to sign them, you can retroactively add signatures using:

::

   $ git rebase -S


Whether you commit to a personal branch, a feature branch or to master should
depend on your level of comfort and the nature of the change.  As a general
rule, the code in master must always build and tests should always pass, at
least on your own system. However, we all make mistakes and you should expect
to receive friendly reminders if your change did not live up to this simple
standard.  We plan to move to a system where the CI guarantees this invariant
in the future.


Taler Deployment on gv.taler.net
================================

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


Demo Upgrade Procedure
======================

Upgrading the ``demo`` environment should be done with care, and ideally be
coordinated on the mailing list before.  It is our goal for ``demo`` to always
run a "working version" that is compatible with various published wallets.

Before deploying on ``demo``, the same version of all components **must**
be deployed *and* tested on ``int``.

Please use the :doc:`demo upgrade checklist <checklist-demo-upgrade>` to make
sure everything is working.


Tagging components
------------------

All Taler components must be tagged with git before they are deployed on the
``demo`` environment, using a tag of the following form:

::

  demo-YYYY-MM-DD-SS
  YYYY = year
  MM = month
  DD = day
  SS = serial


Environment Layout
------------------

Environments have the following layout:

::

  $HOME/
    deployment (deployment.git checkout)
    envcfg.py  (configuration of the Taler environment)
    activate   (bash file, sourced to set environment variables)
    logs/      (log files)
    local/     (locally installed software)
    sources/   (sources repos of locally build components)
    sockets/   (unix domain sockets of running components)
    .config/taler.conf (main Taler configuration file)

Additionally, the ``demo-blue`` and ``demo-green`` environments have the following directory:

::

  $HOME/
    ...
    taler-shared (symlink to shared data directory between demo-green and demo-blue)

The ``int`` and ``test`` environments instead have this additional directory:

::

  $HOME/
    ...
    taler-data/ (on-disk state of Taler components, public and private keys)


Using envcfg.py
---------------

The ``$HOME/envcfg.py`` file contains (1) the name of the environment and (2) the version
of all components we build (in the form of a git rev).

The ``envcfg.py`` for demo looks like this:

.. code-block:: python

  env = "demo"
  tag = "demo-2019-10-05-01:
  tag_gnunet = tag
  tag_libmicrohttpd = tag
  tag_exchange = tag
  tag_merchant = tag
  tag_bank = tag
  tag_twister = tag
  tag_landing = tag
  tag_donations = tag
  tag_blog = tag
  tag_survey = tag
  tag_backoffice = tag

Currently only the variables ``env`` and ``tag_${component}`` are used.


Bootstrapping an Environment
----------------------------

.. code-block:: sh

  $ git clone https://git.taler.net/deployment.git ~/deployment
  $ cp ~/deployment/envcfg.py.template ~/envcfg.py
  $ $EDITOR ~/envcfg.py
  $ ./deployment/bin/taler-deployment bootstrap
  $ source ~/activate
  $ taler-deployment build
  $ taler-deployment-keyup
  $ taler-deployment-sign
  $ taler-deployment-start


Upgrading an Existing Environment
---------------------------------

.. code-block:: sh

  $ rm -rf ~/sources ~/local
  $ git -C ~/deployment pull
  $ $EDITOR ~/envcfg.py
  $ taler-deployment build
  $ taler-deployment-keyup
  $ taler-deployment-sign
  $ taler-deployment-start


Switching Demo Colors
---------------------

As the ``demo`` user, to switch to color ``${COLOR}``,
run the following script from ``deployment/bin``:

.. code-block:: sh

   $ taler-deployment-switch-demo-${COLOR}


Environments and Builders on taler.net
======================================

Documentation Builder
---------------------

All the Taler documentation is built by the user ``docbuilder`` that
runs a Buildbot worker.  The following commands set the ``docbuilder`` up,
starting with a empty home directory.

.. code-block:: sh

  # Log-in as the 'docbuilder' user.

  $ cd $HOME
  $ git clone git://git.taler.net/deployment
  $ ./deployment/bootstrap-docbuilder

  # If the previous step worked, the setup is
  # complete and the Buildbot worker can be started.

  $ buildbot-worker start worker/


Website Builder
---------------


Taler Websites, ``www.taler.net`` and ``stage.taler.net``, are built by the
user ``taler-websites`` by the means of a Buildbot worker.  The following
commands set the ``taler-websites`` up, starting with a empty home directory.

.. code-block:: sh

  # Log-in as the 'taler-websites' user.

  $ cd $HOME
  $ git clone git://git.taler.net/deployment
  $ ./deployment/bootstrap-sitesbuilder

  # If the previous step worked, the setup is
  # complete and the Buildbot worker can be started.

  $ buildbot-worker start worker/


Code coverage
-------------

Code coverage tests are run by the ``lcovworker`` user, and are also driven
by Buildbot.

.. code-block:: sh

  # Log-in as the 'lcovworker' user.

  $ cd $HOME
  $ git clone git://git.taler.net/deployment
  $ ./deployment/bootstrap-taler lcov

  # If the previous step worked, the setup is
  # complete and the Buildbot worker can be started.

  $ buildbot-worker start worker/

The results are then published at ``https://lcov.taler.net/``.

Service Checker
---------------

The user ``demo-checker`` runs periodic checks to see if all the
``*.demo.taler.net`` services are up and running.  It is driven by
Buildbot, and can be bootstrapped as follows.

.. code-block:: sh

  # Log-in as the 'demo-checker' user

  $ cd $HOME
  $ git clone git://git.taler.net/deployment
  $ ./deployment/bootstrap-demochecker

  # If the previous step worked, the setup is
  # complete and the Buildbot worker can be started.

  $ buildbot-worker start worker/


Tipping reserve top-up
----------------------

Both 'test' and 'demo' setups get their tip reserve topped up
by a Buildbot worker.  The following steps get the reserve topper
prepared.

.. code-block:: sh

  # Log-in as <env>-topper, with <env> being either 'test' or 'demo'

  $ git clone git://git.taler.net/deployment
  $ ./deployment/prepare-reservetopper <env>

  # If the previous steps worked, then it should suffice to start
  # the worker, with:

  $ buildbot-worker start worker/


Producing auditor reports
-------------------------

Both 'test' and 'demo' setups get their auditor reports compiled
by a Buildbot worker.  The following steps get the reports compiler
prepared.

.. code-block:: sh

  # Log-in as <env>-auditor, with <env> being either 'test' or 'demo'

  $ git clone git://git.taler.net/deployment
  $ ./deployment/prepare-auditorreporter <env>

  # If the previous steps worked, then it should suffice to start
  # the worker, with:

  $ buildbot-worker start worker/


Releases
========

Release Process and Checklists
------------------------------

Please use the :doc:`release checklist <checklist-release>`

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

.. code-block:: sh

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
Without it, test cases will fail because plugins can't be located.

.. code-block:: sh

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

.. code-block:: sh

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

Code Coverage
=============

Code coverage is done with the Gcov / Lcov
(http://ltp.sourceforge.net/coverage/lcov.php) combo, and it is run
nightly (once a day) by a Buildbot worker. The coverage results are
then published at ``https://lcov.taler.net/``.


Coding Conventions
==================

GNU Taler is developed primarily in C, Python and TypeScript.

Components written in C
-----------------------

These are the general coding style rules for Taler.

* Baseline rules are to follow GNU guidelines, modified or extended
  by the GNUnet style: https://gnunet.org/style

Naming conventions
^^^^^^^^^^^^^^^^^^

* include files (very similar to GNUnet):

  * if installed, must start with "``taler_``" (exception: platform.h),
    and MUST live in src/include/
  * if NOT installed, must NOT start with "``taler_``" and
    MUST NOT live in src/include/ and
    SHOULD NOT be included from outside of their own directory
  * end in "_lib" for "simple" libraries
  * end in "_plugin" for plugins
  * end in "_service" for libraries accessing a service, i.e. the exchange

* binaries:

  * taler-exchange-xxx: exchange programs
  * taler-merchant-xxx: merchant programs (demos)
  * taler-wallet-xxx: wallet programs
  * plugins should be libtaler_plugin_xxx_yyy.so: plugin yyy for API xxx
  * libtalerxxx: library for API xxx

* logging

  * tools use their full name in GNUNET_log_setup
    (i.e. 'taler-exchange-keyup') and log using plain 'GNUNET_log'.
  * pure libraries (without associated service) use 'GNUNET_log_from'
    with the component set to their library name (without lib or '.so'),
    which should also be their directory name (i.e. 'util')
  * plugin libraries (without associated service) use 'GNUNET_log_from'
    with the component set to their type and plugin name (without lib or '.so'),
    which should also be their directory name (i.e. 'exchangedb-postgres')
  * libraries with associated service) use 'GNUNET_log_from'
    with the name of the service,  which should also be their
    directory name (i.e. 'exchange')

* configuration

  * same rules as for GNUnet

* exported symbols

  * must start with TALER_[SUBSYSTEMNAME]_ where SUBSYSTEMNAME
    MUST match the subdirectory of src/ in which the symbol is defined
  * from libtalerutil start just with ``TALER_``, without subsystemname
  * if scope is ONE binary and symbols are not in a shared library,
    use binary-specific prefix (such as TMH = taler-exchange-httpd) for
    globals, possibly followed by the subsystem (TMH_DB_xxx).

* structs:

  * structs that are 'packed' and do not contain pointers and are
    thus suitable for hashing or similar operations are distinguished
    by adding a "P" at the end of the name. (NEW)  Note that this
    convention does not hold for the GNUnet-structs (yet).
  * structs that are used with a purpose for signatures, additionally
    get an "S" at the end of the name.

* private (library-internal) symbols (including structs and macros)

  * must not start with ``TALER_`` or any other prefix

* testcases

  * must be called "test_module-under-test_case-description.c"

* performance tests

  * must be called "perf_module-under-test_case-description.c"

Shell Scripts
-------------

Shell scripts should be avoided if at all possible.  The only permissible uses of shell scripts
in GNU Taler are:

* Trivial invocation of other commands.
* Scripts for compatibility (e.g. ``./configure``) that must run on
  as many systems as possible.

When shell scripts are used, they ``MUST`` begin with the following ``set`` command:

.. code-block:: shell

  # Make the shell fail on undefined variables and
  # commands with non-zero exit status.
  set -eu

Python
------

Supported Python Versions
^^^^^^^^^^^^^^^^^^^^^^^^^

Python code should be written and build against version 3.7 of Python.

Style
^^^^^

We use `yapf <https://github.com/google/yapf>`_ to reformat the
code to conform to our style instructions.
A reusable yapf style file can be found in ``taler-build-scripts``,
which is intended to be used as a git submodule.

Python for Scripting
^^^^^^^^^^^^^^^^^^^^

When using Python for writing small utilities, the following libraries
are useful:

* ``click`` for argument parsing (should be prefered over argparse)
* ``pathlib`` for path manipulation (part of the standard library)
* ``subprocess`` for "shelling out" to other programs.  Prefer ``subprocess.run``
  over the older APIs.

Testing library
===============

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

