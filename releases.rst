..

  This file is part of GNU TALER.
  Copyright (C) 2016 INRIA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Florian Dold


==============================
Release Process and Checklists
==============================

This document describes the process for releasing a new version of the various
Taler components to the official GNU mirrors.

The following components are published on the GNU mirrors

* taler-exchange (exchange.git)
* taler-merchant (merchant.git)
* talerfrontends (merchant-frontends.git)
* taler-bank (bank.git)
* taler-wallet-webex (wallet-webex.git)


--------
Tagging
-------

Tag releases with an *annotated* commit, like

.. code-block: none

  git tag -a v0.1.0 -m "Official release v0.1.0"
  git push origin v0.1.0

------------------
Database for tests
-----------------

For tests in the exchange and merchant to run, make sure that
a database `talertest` is accessible by `$USER`.  Otherwise tests
involving the database logic are skipped.

------------------
Exchange, merchant
------------------

Set the version in `configure.ac`.  The commit being tagged
should be the change of the version.

For the exchange test cases to pass, `make install` must be run first.
Without it, test cases will fail because plugins can't be located.

.. code-block:

  ./bootstrap
  ./configure # add required options for your system
  make dist
  tar -xf taler-$COMPONENT-$VERSION.tar.gz
  cd taler-$COMPONENT-$VERSION
  make install check

--------------------
Wallet WebExtension
--------------------

The version of the wallet is in `manifest.json`.  The `version_name` should be
adjusted, and `version` should be increased independently on every upload to
the WebStore.

.. code-block:

  ./configure
  make dist



FIXME: selenium test cases


----------------------
Upload to GNU mirrors
----------------------

See https://www.gnu.org/prep/maintain/maintain.html#Automated-FTP-Uploads

Directive file: 

.. code-block:

  version: 1.2
  directory: taler
  filename: taler-exchange-0.1.0.tar.gz


Upload the files in *binary mode* to the ftp servers.
