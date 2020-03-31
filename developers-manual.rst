..
  This file is part of GNU TALER.

  Copyright (C) 2014-2020 Taler Systems SA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Christian Grothoff

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

Taler code is versioned with Git. For those users without write access, all the
codebases are found at the following URL:

::

   git://git.taler.net/<repository>

A complete list of all the existing repositories is currently found at
`<https://git.taler.net/>`_.


Committing code
---------------

Before you can obtain Git write access, you must sign the copyright
agreement. As we collaborate closely with GNUnet, we use their
copyright agreement -- with the understanding that your contributions
to GNU Taler are included in the assignment.  You can find the
agreement on the `GNUnet site <https://gnunet.org/en/copyright.html>`_.
Please sign and mail it to Christian Grothoff as he currently collects
all the documents for GNUnet e.V.

To obtain Git access, you need to send us your SSH public key. Most core
team members have administrative Git access, so simply contact whoever
is your primary point of contact so far. You can
find instructions on how to generate an SSH key
in the `Git book <https://git-scm.com/book/en/v2/Git-on-the-Server-Generating-Your-SSH-Public-Key>`_.
If you have been granted write access, you first of all must change the URL of
the respective repository to:

::

   ssh://git@git.taler.net/<repository>

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

In order to keep a linear and clean commits history, we advise to avoid
merge commits and instead always rebase your changes before pushing to
the master branch.  If you commit and later find out that new commits were
pushed, the following command will pull the new commits and rebase yours
on top of them.

::

   # -S instructs Git to (re)sign your commits
   $ git pull --rebase -S


Observing changes
-----------------

Every commit to the master branch of any of our public repositories
(and almost all are public) is automatically sent to the
gnunet-svn@gnu.org mailinglist.  That list is for Git commits only,
and must not be used for discussions. It also carries commits from
our main dependencies, namely GNUnet and GNU libmicrohttpd.  While
it can be high volume, the lists is a good way to follow overall
development.


Communication
-------------

We use the #taler channel on the Freenode IRC network and the taler@gnu.org
public mailinglist for discussions.  Not all developers are active on IRC, but
all developers should probably subscribe to the low-volume Taler mailinglist.
There are separate low-volume mailinglists for gnunet-developers (@gnu.org)
and for libmicrohttpd (@gnu.org).


Taler Deployment on gv.taler.net
================================

This section describes the GNU Taler deployment on ``gv.taler.net``.
``gv`` is our server at BFH. It hosts the Git repositories, Web sites,
CI and other services.  Developers can receive an SSH account and
e-mail alias for the system.  As with Git, ask your primary team
contact for shell access if you think you need it.

Our old server, ``tripwire``, is currently offline and will likely
go back online to host ``production`` systems for operating real
Taler payments at BFH in the future.

DNS
---

DNS records for taler.net are controlled by the GNU Taler
maintainers, specifically Christian and Florian. If you
need a sub-domain to be added, please contact one of them.


User Acccounts
--------------

On ``gv.taler.net``, there are four system users that are set up to
serve Taler on the Internet:

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
    taler-data (on-disk state, public and private keys)
    .config/taler.conf (main Taler configuration file)

On ``demo-blue`` and ``demo-green``, ``taler-data`` is a symlink pointing to ``$HOME/demo/shared-data``
instead of a directory.


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
  tag_sync = tag

Currently only the variables ``env`` and ``tag_${component}`` are used.

When deploying to ``demo``, the ``envcfg.py`` should be committed to ``deployment.git/envcfg/envcfg-demo-YYYY-MM-DD-SS.py``.


Bootstrapping an Environment
----------------------------

.. code-block:: sh

  $ git clone https://git.taler.net/deployment.git ~/deployment
  $ cp ~/deployment/envcfg/$ENVCFGFILE ~/envcfg.py
  $ ./deployment/bin/taler-deployment bootstrap
  $ source ~/activate
  $ taler-deployment build
  $ taler-deployment-prepare
  $ taler-deployment-start
  $ taler-deployment-arm -I # check everything works

  Caution: there is currently a known bug in the part that sets up the bank
  account password of the exchange might either not exist or be broken.
  Thus, that must currently still be done manually! (#6099).


Upgrading an Existing Environment
---------------------------------

.. code-block:: sh

  $ rm -rf ~/sources ~/local
  $ git -C ~/deployment pull
  $ cp ~/deployment/envcfg/$ENVCFGFILE ~/envcfg.py
  $ taler-deployment bootstrap
  $ taler-deployment build
  $ taler-deployment-prepare
  $ taler-deployment-restart
  $ taler-deployment-arm -I # check everything works

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


Database schema versioning
--------------------------

The Postgres databases of the exchange and the auditor are versioned.
See the 0000.sql file in the respective directory for documentation.

Every set of changes to the database schema must be stored in a new
versioned SQL script. The scripts must have contiguous numbers. After
any release (or version being deployed to a production or staging
environment), existing scripts MUST be immutable.

Developers and operators MUST NOT make changes to database schema
outside of this versioning.



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

Update the Texinfo documentation using the files from docs.git:

.. code-block::

   # Get the latest documentation repository
   cd $GIT/docs
   git pull
   make texinfo
   # The *.texi files are now in _build/texinfo
   #
   # This checks out the prebuilt branch in the prebuilt directory
   git worktree add prebuilt prebuilt
   cd prebuilt
   # Copy the pre-built documentation into the prebuilt directory
   cp -r ../_build/texinfo .
   # Push and commit to branch
   git commit -a -S -m "updating texinfo"
   git status
   # Verify that all files that should be tracked are tracked,
   # new files will have to be added to the Makefile.am in
   # exchange.git as well!
   git push
   # Remember $REVISION of commit
   #
   # Go to exchange
   cd $GIT/exchange/doc/prebuilt
   # Update submodule to point to latest commit
   git checkout $REVISION

Finally, the Automake ``Makefile.am`` files may have to be adjusted to
include new ``*.texi`` files or images.


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
``https://buildbot.taler.net/``.

In order to avoid downtimes, CI uses a "blue/green" deployment
technique. In detail, there are two users building code on the system,
the "green" and the "blue" user; and at any given time, one is running
Taler services and the other one is either building the code or waiting
for that.

There is also the possibility to trigger builds manually, but this is
only reserved to "admin" users.

Android Apps
============

Android App Nightly Builds
--------------------------

There are currently three Android apps:

* Wallet
  [`Git Repo <https://git.taler.net/wallet-android.git>`__]
  [`Git Mirror <https://gitlab.com/gnu-taler/wallet-android>`__]
  [`CI <https://git.taler.net/wallet-android.git/tree/.gitlab-ci.yml>`__]
* Merchant PoS Terminal
  [`Git Repo <https://git.taler.net/merchant-terminal-android.git/>`__]
  [`Git Mirror <https://gitlab.com/gnu-taler/merchant-terminal-android>`__]
  [`CI <https://git.taler.net/merchant-terminal-android.git/tree/.gitlab-ci.yml>`__]
* Cashier
  [`Git Repo <https://git.taler.net/cashier-terminal-android.git/>`__]
  [`Git Mirror <https://gitlab.com/gnu-taler/cashier-terminal-android>`__]
  [`CI <https://git.taler.net/cashier-terminal-android.git/tree/.gitlab-ci.yml>`__]

Their git repositories are mirrored at Gitlab to utilize their CI
and `F-Droid <https://f-droid.org>`_'s Gitlab integration
to `publish automatic nightly builds <https://f-droid.org/docs/Publishing_Nightly_Builds/>`_
for each change on the ``master`` branch.

All three apps publish their builds to the same F-Droid nightly repository
(which is stored as a git repository):
https://gitlab.com/gnu-taler/fdroid-repo-nightly

You can download the APK files directly from that repository
or add it to the F-Droid app for automatic updates
by clicking the following link (on the phone that has F-Droid installed).

    `GNU Taler Nightly F-Droid Repository <fdroidrepos://gnu-taler.gitlab.io/fdroid-repo-nightly/fdroid/repo?fingerprint=55F8A24F97FAB7B0960016AF393B7E57E7A0B13C2D2D36BAC50E1205923A7843>`_

.. note::
    Nightly apps can be installed alongside official releases
    and thus are meant **only for testing purposes**.
    Use at your own risk!

.. _Build-apps-from-source:

Building apps from source
-------------------------

Note that this guide is different from other guides for building Android apps,
because it does not require you to run non-free software.
It uses the Merchant PoS Terminal as an example, but works as well for the other apps.

First, ensure that you have the required dependencies installed:

* Java Development Kit 8 or higher (default-jdk-headless)
* git
* unzip

Then you can get the app's source code using git:

.. code-block:: shell

  # Start by cloning the git repository
  git clone https://git.taler.net/merchant-terminal-android.git

  # Change into the directory of the cloned app
  cd merchant-terminal-android

  # Find out which Android SDK version you will need
  grep -i compileSdkVersion app/build.gradle

The last command will return something like ``compileSdkVersion 29``.
So visit the `Android Rebuilds <http://android-rebuilds.beuc.net/>`_ project
and look for that version of the Android SDK there.
If the SDK version is not yet available as a free rebuild,
you can try to lower the ``compileSdkVersion`` in the app's ``app/build.gradle`` file.
Note that this might break things
or require you to also lower other versions such as ``targetSdkVersion``.

In our example, the version is ``29`` which is available,
so download the "SDK Platform" package of "Android 10.0.0 (API 29)"
and unpack it:

.. code-block:: shell

  # Change into the directory that contains your downloaded SDK
  cd $HOME

  # Unpack/extract the Android SDK
  unzip android-sdk_eng.10.0.0_r14_linux-x86.zip

  # Tell the build system where to find the SDK
  export ANDROID_SDK_ROOT="$HOME/android-sdk_eng.10.0.0_r14_linux-x86"

  # Change into the directory of the cloned app
  cd merchant-terminal-android

  # Build the app
  ./gradlew assembleRelease

If you get an error message complaining about build-tools

    > Failed to install the following Android SDK packages as some licences have not been accepted.
         build-tools;29.0.3 Android SDK Build-Tools 29.0.3

you can try changing the ``buildToolsVersion`` in the app's ``app/build.gradle`` file
to the latest "Android SDK build tools" version supported by the Android Rebuilds project.

After the build finished successfully, you find your APK in ``app/build/outputs/apk/release/``.

.. _Code-coverage:

Code Coverage
=============

Code coverage is done with the Gcov / Lcov
(http://ltp.sourceforge.net/coverage/lcov.php) combo, and it is run
nightly (once a day) by a Buildbot worker. The coverage results are
then published at ``https://lcov.taler.net/``.


Coding Conventions
==================

GNU Taler is developed primarily in C, Kotlin, Python and TypeScript.

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

Kotlin
------

We so far have no specific guidelines, please follow best practices
for the language.


Python
------

Supported Python Versions
^^^^^^^^^^^^^^^^^^^^^^^^^

Python code should be written and build against version 3.7 of Python.

Style
^^^^^

We use `yapf <https://github.com/google/yapf>`_ to reformat the
code to conform to our style instructions.
A reusable yapf style file can be found in ``build-common``,
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

   /* Without loss of generality, let's consider the
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


User-Facing Terminology
=======================

This section contains terminology that should be used and that should not be
used in the user interface and help materials.

Terms to Avoid
--------------

Refreshing
  Refreshing is the internal technical terminology for the protocol to
  give change for partially spent coins

  **Use instead**: "Obtaining change"

Coin
  Coins are an internal construct, the user should never be aware that their balance
  is represented by coins if different denominations.

  **Use instead**: "(Digital) Cash" or "(Wallet) Balance"

Consumer
  Has bad connotation of consumption.

  **Use instead**: Customer or user.

Proposal
  The term used to describe the process of the merchant facilitating the download
  of the signed contract terms for an order.

  **Avoid**.  Generally events that relate to proposal downloads
  should not be shown to normal users, only developers.  Instead, use
  "communication with mechant failed" if a proposed order can't be downloaded.

Anonymous E-Cash
  Should be generally avoided, since Taler is only anonymous for
  the customer. Also some people are scared of anonymity (which as
  a term is also way too absolute, as anonymity is hardly ever perfect).

  **Use instead**:  "Privacy-preserving", "Privacy-friedly"

Payment Replay
  The process of proving to the merchant that the customer is entitled
  to view a digital product again, as they already paid for it.

  **Use instead**:  In the event history, "re-activated digital content purchase"
  could be used. (FIXME: this is still not nice.)

Session ID
  See Payment Replay.

Order
  Too ambiguous in the wallet.

  **Use instead**: Purchase

Fulfillment URL
  URL that the serves the digital content that the user purchased
  with their payment.  Can also be something like a donation receipt.


Terms to Use
------------

Auditor
  Regulatory entity that certifies exchanges and oversees their operation.

Exchange Provider
  The entity/service that gives out digital cash in exchange for some
  other means of payment.

  In some contexts, using "Issuer" could also be appropriate.
  When showing a balance breakdown,
  we can say "100 Eur (issued by exchange.euro.taler.net)".
  Sometimes we may also use the more generic term "Payment Service Provider"
  when the concept of an "Exchange" is still unclear to the reader.

Refund
  A refund is given by a merchant to the customer (rather the customer's wallet)
  and "undoes" a previous payment operation.

Payment
  The act of sending digital cash to a merchant to pay for an order.

Purchase
  Used to refer to the "result" of a payment, as in "view purchase".
  Use sparsingly, as the word doesn't fit for all payments, such as donations.

Contract Terms
  Partially machine-readable representation of the merchant's obligation after the
  customer makes a payment.

Merchant
  Party that receives a payment.

Wallet
  Also "Taler Wallet".  Software component that manages the user's digital cash
  and payments.


Developer Glossary
==================

This glossary is meant for developers.  It contains some terms that we usually do not
use when talking to end users or even system administrators.

.. glossary::
  :sorted:

  absolute time
    method of keeping time in :term:`GNUnet` where the time is represented
    as the number of microseconds since 1.1.1970 (UNIX epoch).  Called
    absolute time in contrast to :term:`relative time`.

  aggregate
    the :term:`exchange` combines multiple payments received by the
    same :term:`merchant` into one larger :term:`wire transfer` to
    the respective merchant's :term:`bank` account

  auditor
    trusted third party that verifies that the :term:`exchange` is operating correctly

  bank
    traditional financial service provider who offers wire :term:`transfers <transfer>` between accounts

  close
  closes
  closed
  closing
    operation an :term:`exchange` performs on a :term:`reserve` that has not been
    :term:`drained` by :term:`withdraw` operations. When closing a reserve, the
    exchange wires the remaining funds back to the customer, minus a :term:`fee`
    for closing

  customer
    individual in control of a Taler :term:`wallet`, usually using it to
    :term:`spend` the :term:`coins` on :term:`contracts`.

  coin
  coins
    coins are individual token representing a certain amount of value, also known as the :term:`denomination` of the coin

  commitment
  refresh commitment
    data that the wallet commits to during the :term:`melt` stage of the
    :term:`refresh` protocol where it
    has to prove to the :term:`exchange` that it is deriving the :term:`fresh`
    coins as specified by the Taler protocol.  The commitment is verified
    probabilistically (see: :term:`kappa`) during the :term:`reveal` stage.

  contract
  contracts
    formal agreement between :term:`merchant` and :term:`customer` specifying the
    :term:`contract terms` and signed by the merchant and the :term:`coins` of the
    customer

  contract terms
    the individual clauses specifying what the buyer is purchasing from the
    :term:`merchant`

  denomination
    unit of currency, specifies both the currency and the face value of a :term:`coin`,
    as well as associated fees and validity periods

  denomination key
    (RSA) key used by the exchange to certify that a given :term:`coin` is valid and of a
    particular :term:`denomination`

  deposit
  deposits
  depositing
    operation by which a merchant passes coins to an exchange, expecting the
    exchange to credit his bank account in the future using an
    :term:`aggregate` :term:`wire transfer`

  drain
  drained
    a :term:`reserve` is being drained when a :term:`wallet` is using the
    reserve's private key to :term:`withdraw` coins from it. This reduces
    the balance of the reserve. Once the balance reaches zero, we say that
    the reserve has been (fully) drained.  Reserves that are not drained
    (which is the normal process) are :term:`closed` by the exchange.

  dirty
  dirty coin
    a coin is dirty if its public key may be known to an entity other than
    the customer, thereby creating the danger of some entity being able to
    link multiple transactions of coin's owner if the coin is not refreshed

  exchange
    Taler's payment service provider.  Issues electronic coins during
    withdrawal and redeems them when they are deposited by merchants

  expired
  expiration
    Various operations come with time limits. In particular, denomination keys
    come with strict time limits for the various operations involving the
    coin issued under the denomination. The most important limit is the
    deposit expiration, which specifies until when wallets are allowed to
    use the coin in deposit or refreshing operations. There is also a "legal"
    expiration, which specifies how long the exchange keeps records beyond the
    deposit expiration time.  This latter expiration matters for legal disputes
    in courts and also creates an upper limit for refreshing operations on
    special zombie coin

  GNUnet
    Codebase of various libraries for a better Internet, some of which
    GNU Taler depends upon.

  fakebank
    implementation of the :term:`bank` API in memory to be used only for test
    cases.

  fee
    an :term:`exchange` charges various fees for its service. The different
    fees are specified in the protocol. There are fees per coin for
    :term:`withdrawing`, :term:`depositing`, :term:`melting`, and
    :term:`refunding`.  Furthermore, there are fees per wire transfer
    for :term:`closing` a :term:`reserve`: and for
    :term:`aggregate` :term:`wire transfers` to the :term:`merchant`.

  fresh
  fresh coin
    a coin is fresh if its public key is only known to the customer

  json
  JSON
  JavaScript Object Notation
    serialization format derived from the JavaScript language which is
    commonly used in the Taler protocol as the payload of HTTP requests
    and responses.

  kappa
    security parameter used in the :term:`refresh` protocol. Defined to be 3.
    The probability of successfully evading the income transparency with the
    refresh protocol is 1:kappa.

  LibEuFin
    FIXME: explain

  link
  linking
    specific step in the :term:`refresh` protocol that an exchange must offer
    to prevent abuse of the :term:`refresh` mechanism.  The link step is
    not needed in normal operation, it just must be offered.

  master key
    offline key used by the exchange to certify denomination keys and
    message signing keys

  melt
  melted
  melting
    step of the :term:`refresh` protocol where a :term:`dirty coin`
    is invalidated to be reborn :term:`fresh` in a subsequent
    :term:`reveal` step.

  merchant
    party receiving payments (usually in return for goods or services)

  message signing key
     key used by the exchange to sign online messages, other than coins

  order
    FIXME: to be written!

  owner
    a coin is owned by the entity that knows the private key of the coin

  relative time
    method of keeping time in :term:`GNUnet` where the time is represented
    as a relative number of microseconds.  Thus, a relative time specifies
    an offet or a duration, but not a date.  Called relative time in
    contrast to :term:`absolute time`.

  recoup
    Operation by which an exchange returns the value of coins affected
    by a :term:`revocation` to their :term:`owner`, either by allowing the owner to
    withdraw new coins or wiring funds back to the bank account of the :term:`owner`.

  planchet
    precursor data for a :term:`coin`. A planchet includes the coin's internal
    secrets (coin private key, blinding factor), but lacks the RSA signature
    of the :term:`exchange`.  When :term:`withdrawing`, a :term:`wallet`
    creates and persists a planchet before asking the exchange to sign it to
    get the coin.

  purchase
    Refers to the overall process of negotiating a :term:`contract` and then
    making a payment with :term:`coins` to a :term:`merchant`.

  privacy policy
    Statment of an operator how they will protect the privacy of users.

  proof
    Message that cryptographically demonstrates that a particular claim is correct.

  proposal
    a list of :term:`contract terms` that has been completed and signed by the
    merchant backend.

  reserve
    Funds set aside for future use; either the balance of a customer at the
    exchange ready for withdrawal, or the funds kept in the exchange;s bank
    account to cover obligations from coins in circulation.

  refresh
  refreshing
    operation by which a :term:`dirty coin` is converted into one or more
    :term:`fresh` coins.  Involves :term:`melting` the :term:`dirty coin` and
    then :term:`revealing` so-called :term:`transfer keys`.

  refund
  refunding
    operation by which a merchant steps back from the right to funds that he
    obtained from a :term:`deposit` operation, giving the right to the funds back
    to the customer

  refund transaction id
    unique number by which a merchant identifies a :term:`refund`. Needed
    as refunds can be partial and thus there could be multiple refunds for
    the same :term:`purchase`.

  reserve
    accounting mechanism used by the exchange to track customer funds
    from incoming :term:`wire transfers`.  A reserve is created whenever
    a customer wires money to the exchange using a well-formed public key
    in the subject.  The exchange then allows the customer's :term:`wallet`
    to :term:`withdraw` up to the amount received in :term:`fresh`
    :term:`coins` from the reserve, thereby draining the reserve. If a
    reserve is not drained, the exchange eventually :term:`closes` it.

  reveal
  revealing
    step in the :term:`refresh` protocol where some of the transfer private
    keys are revealed to prove honest behavior on the part of the wallet.
    In the reveal step, the exchange returns the signed :term:`fresh` coins.

  revoke
  revocation
    exceptional operation by which an exchange withdraws a denomination from
    circulation, either because the signing key was compromised or because
    the exchange is going out of operation; unspent coins of a revoked
    denomination are subjected to recoup.

  sharing
    users can share ownership of a :term:`coin` by sharing access to the coin&#39;s
    private key, thereby allowing all co-owners to spend the coin at any
    time.

  spend
  spending
    operation by which a customer gives a merchant the right to deposit
    coins in return for merchandise

  transfer
  transfers
  wire transfer
  wire transfers
    method of sending funds between :term:`bank` accounts

  transfer key
  transfer keys
    special cryptographic key used in the :term:`refresh` protocol, some of which
    are revealed during the :term:`reveal` step. Note that transfer keys have,
    despite the name, no relationship to :term:`wire transfers`.  They merely
    help to transfer the value from a :term:`dirty coin` to a :term:`fresh coin`

  terms
    the general terms of service of an operator, possibly including
    the :term:`privacy policy`.  Not to be confused with the
    :term:`contract terms` which are about the specific purchase.

  transaction
    method by which ownership is exclusively transferred from one entity

  version
    Taler uses various forms of versioning. There is a database
    schema version (stored itself in the database, see \*-0000.sql) describing
    the state of the table structure in the database of an :term:`exchange`,
    :term:`auditor` or :term:`merchant`. There is a protocol
    version (CURRENT:REVISION:AGE, see GNU libtool) which specifies
    the network protocol spoken by an :term:`exchange` or :term:`merchant`
    including backwards-compatibility. And finally there is the software
    release version (MAJOR.MINOR.PATCH, see https://semver.org/) of
    the respective code base.

  wallet
    software running on a customer's computer; withdraws, stores and
    spends coins

  WebExtension
    Cross-browser API used to implement the GNU Taler wallet browser extension.

  wire gateway
    FIXME: explain

  wire transfer identifier
  wtid
    Subject of a wire transfer from the exchange to a merchant;
    set by the aggregator to a random nonce which uniquely
    identifies the transfer.

  withdraw
  withdrawing
  withdrawal
    operation by which a :term:`wallet` can convert funds from a :term:`reserve` to
    fresh coins

  zombie
  zombie coin
    coin where the respective :term:`denomination key` is past its
    :term:`deposit` :term:`expiration` time, but which is still (again) valid
    for an operation because it was :term:`melted` while it was still
    valid, and then later again credited during a :term:`recoup` process
