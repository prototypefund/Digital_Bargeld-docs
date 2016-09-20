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

  @author Christian Grothoff

========
Exchange
========

------------
Introduction
------------
TBD

.. _keys:

----
Keys
----
TBD (do mention "starting date")

---------------
Database Scheme
---------------

The exchange database must be initialized using `taler-exchange-dbinit`.  This
tool creates the tables required by the Taler exchange to operate.  The
tool also allows you to reset the Taler exchange database, which is useful
for test cases but should never be used in production.  Finally,
`taler-exchange-dbinit` has a function to garbage collect a database,
allowing administrators to purge records that are no longer required.

The database scheme used by the exchange look as follows:

.. image:: exchange-db.png
