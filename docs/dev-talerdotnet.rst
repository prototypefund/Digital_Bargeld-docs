..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016 INRIA
  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.
  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Florian Dold

============================
Infrastructure on taler.net
============================

-------------------------------
The test and demo environments
-------------------------------

FIXME: describe

-------------------------------
Per-user environments
-------------------------------

..
  NOTE: this is already documented in deployment.rst.

Every user that is in the `www-data` group can set up a custom environment,
available under `https://env.taler.net/$USER/`.

.. code-block:: none

  $ cd $HOME
  $ git clone /var/git/
  $ cd deployment
  $ ./bootstrap-standalone

This will set up a full Taler environment (with exchange,
merchant, merchant frontends, bank) as well as a per-user postgres instance.

Sourcing the `~/.activate` script makes the following commands available:

* `taler-deployment-update` to build the environment
* `taler-deployment-config-generate` to generate an unsigned configuration
* `taler-deployment-config-sign` to sign parts of the config like the wire transfer
* `taler-deployment-start` to start the environment (including the postgres instance)
* `taler-deployment-stop` to stop the environment (including the postgres instance)

--------
Buildbot
--------
.. note::
  `worker` and `slave` are used interchangeably

The user running the buildbot master is `containers`.

++++++
Master
++++++

To start the master, log in as `containers`, and run:

.. code-block:: none

  $ ~/buildbot/start.sh

  # To stop it, run:
  $ ~/buildbot/stop.sh

There is also a "restart" script, runnable as follows:


.. code-block:: none

  $ ~/buildbot/restart.sh

+++++++++++++++
Selenium worker
+++++++++++++++

This worker is responsible for running the Selenium wallet test:
an automatic clicker that performs the cycle withdraw-and-spend.

The `containers` user is also responsible for running the Selenium
buildbot worker.

Start it with:

.. code-block:: none

  $ source ~/buildbot/venv/bin/activate
  $ buildbot-worker start ~/buildbot/selenium_worker/

  # stop it with:
  $ buildbot-worker stop ~/buildbot/selenium_worker/

  # deactivate the virtual env with
  $ deactivate

+++++++++++
Lcov worker
+++++++++++

The worker is implemented by the `lcovslave` user and is responsible
for generating the HTML showing the coverage of our tests, then available
on `https://lcov.taler.net`.

..
  NOTE: document https://lcov.taler.net/ set-up

To start the worker, log in as `lcovslave` and run:

.. code-block:: none

  $ source ~/activate
  $ taler-deployment-bbstart

  # To stop it:
  $ taler-deployment-bbstop

+++++++++++++++
Switcher worker
+++++++++++++++

Taler.net uses a "blue/green" fashion to update the code it
uses in demos.  Practically, there are two users: `test-green`
and `test-blue`, and only one of them is "active" at any time.

Being `active` means that whenever nginx receives a HTTP request
for one of the Taler services (at our demo), it routes the request
to either test-blue or test-green via unix domain sockets.

Upon any push to any of the Taler's subprojects, this worker is
responsible for building the code hosted at the inactive user and,
if all tests succeed, switching the active user to the one whose code
has just been compiled and tested.

The worker is implemented by the `testswitcher` user. This user
has some additional "sudo" rights, since it has to act as `test-blue`,
`test-green` and `test` user in order to accompish its task.
Note that the "sudo file" is tracked in this (`deployment`) repository,
under the `sudoers` directory.

To start the worker, log in as `testswitcher` and run:

.. code-block:: none

  $ source ~/venv/bin/activate
  $ buildbot-worker start ~/buildbot/slave

  # To stop it:
  $ buildbot-worker stop ~/buildbot/slave

  # To exit the virtual env
  $ deactivate

+++++++++++++
Manual switch
+++++++++++++

After the desired blue/green party has been compiled, it is possible to
log-in as `test` and run the script ``~/.ln-<COLOR>.sh``, in order to make
``test-<COLOR>`` active.

-------------------
Site lcov.taler.net
-------------------

The directory ``/var/www/lcov.taler.net`` contains the following two symlinks

* `exchange` --> ``/home/lcovslave/exchange/doc/coverage``
* `merchant` --> ``/home/lcovslave/merchant/doc/coverage``

The pointed locations are updated by the `lcovslave`.
