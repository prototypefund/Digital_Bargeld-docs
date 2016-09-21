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

  @author Marcello Stanisci
  @author Florian Dold

==============================
Operating the Merchant Backend
==============================

+++++++++++++
Configuration
+++++++++++++

The following data and facilities have to be set up, in order to run an exchange:

* Keying
* Currency
* Database
* Instances
* Exchanges

------
Keying
------

The merchant backend can serve HTTP over both TCP and UNIX domain socket.

The following values are to be configured under the section `[merchant]`:

* `SERVE`: must be set to `tcp` to serve HTTP over TCP, or `unix` to serve HTTP over a UNIX domain socket
* `PORT`: set to the TCP port to listen on if `SERVE` is `tcp`.
* `UNIXPATH`: set to the UNIX domain socket path to listen on if `SERVE` is `unix`
* `UNIXPATH_MODE`: number giving the mode with the access permission mask for the `UNIXPATH` (i.e. 660 = rw-rw----).

--------
Currency
--------

The merchant backend supports only one currency. This data is set under the respective
option `currency` in section `[taler]`.

--------
Database
--------

The option `db` under section `[merchant]` gets the DB backend's name the merchant
is going to use. So far, only `db = postgres` is supported. After choosing the backend,
it is mandatory to supply the connection string (namely, the database name). This is
possible in two ways:

* via an environment variable: `TALER_MERCHANTDB_POSTGRES_CONFIG`.
* via configuration option `config`, under section `[merchantdb-BACKEND]`. For example,
the demo merchant is configured as follows:

.. code-block:: text

  [merchant]
  ...
  db = postgres
  ...

  [merchantdb-postgres]
  config = postgres:///talerdemo
