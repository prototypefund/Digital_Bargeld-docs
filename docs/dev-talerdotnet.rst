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


