..
  This file is part of GNU TALER.
  Copyright (C) 2014, 2015, 2016 GNUnet e.V. and INRIA
  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.
  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Christian Grothoff

======================
Operating the Exchange
======================

+++++++++++++
Configuration
+++++++++++++

The following data and facilities have to be set up, in order to run an exchange:

* Keying
* Serving
* Currency
* Bank account
* Coins
* Database

In this document, we assume that ``$HOME/.config/taler.conf`` is being customized.

------
Keying
------

The exchange works with three types of keys:

* `master key`
* `sign keys`
* `denomination keys` (see section `Coins`)

`master key`: in section `[exchange]`, edit the two following values:

* `master_priv_file`: Path to the exchange's master private file.
* `master_public_key`: Must specify the exchange's master public key.

`sign keys`: the following two options under `[exchange_keys]` section control `sign keys`:

* `lookahead_sign`: How long should one signing key be used?
* `signkey_duration`: How much time we want to cover with our `signkeys`? Note that if `signkey_duration` is bigger than `lookahead_sign`, `taler-exchange-keyup` will generate a quantity of `signkeys` which is sufficient to cover all the gap.

.. note::
  `signkeys` will be used in future versions of Taler.

-------
Serving
-------

The exchange can serve HTTP over both TCP and UNIX domain socket. It needs this
configuration *twice*, because it opens one connection for ordinary REST calls, and one
for "/admin" and "/test" REST calls, because the operator may want to restrict the access to "/admin".

The following values are to be configured under the section `[exchange]` and `[exchange-admin]`:

* `SERVE`: must be set to `tcp` to serve HTTP over TCP, or `unix` to serve HTTP over a UNIX domain socket
* `PORT`: set to the TCP port to listen on if `SERVE` is `tcp`.
* `UNIXPATH`: set to the UNIX domain socket path to listen on if `SERVE` is `unix`
* `UNIXPATH_MODE`: number giving the mode with the access permission mask for the `UNIXPATH` (i.e. 660 = rw-rw----).

The exchange can be started with the `-D` option to disable the administrative
functions entirely.  It is recommended that the administrative API is only
accessible via a properly protected UNIX domain socket.

--------
Currency
--------

The exchange supports only one currency. This data is set under the respective
option `currency` in section `[taler]`.

------------
Bank account
------------

The command line tool `taler-exchange-wire` is used to create a file with
the JSON response to /wire requests using the exchange's offline
master key.  The resulting file's path needs to be added to the configuration
under the respective option for the wire transfer method, i.e.
`sepa_response_file` in section `[exchange-wire-incoming-sepa]` when the
`wireformat` option in the configuration file allows `sepa` transactions. For example,
the utility may be invoked as follows::
  
  taler-exchange-wire -j '{"name": "The Exchange", "account_number": 10, "bank_uri": "https://bank.demo.taler.net", "type": "test"}' -t test -o exchange.json

Note that the value given to option `-t` must match the value in the JSON's field ``"type"``. `exchange.json` will be the same JSON given to ``-j`` plus the field
``"sig"``, which holds the signature of the JSON given in option ``-j`` made with exchange's master key. Finally, if `taler-exchange-wire` will not find any master
key at the location mentioned in `master_priv_file`, it will automatically generate (and use) one.

--------
Database
--------

The option `db` under section `[exchange]` lets specify which DB backend the exchange
is going to use. So far, only `db = postgres` is supported. After choosing the backend,
it is mandatory to supply the connection string (namely, the database name). This is
possible in two ways:

* via an environment variable: `TALER_EXCHANGEDB_POSTGRES_CONFIG`.
* via configuration option `db_conn_str`, under section `[exchangedb-BACKEND]`. For example, the demo exchange is configured as follows:

.. code-block:: text

  [exchange-postgres]
  db_conn_str = postgres:///talerdemo

-------------------------
Coins (denomination keys)
-------------------------

Sections specifying denomination (coin) information start with "coin\_".  By convention, the name continues with "$CURRENCY_[$SUBUNIT]_$VALUE", i.e. `[coin_eur_ct_10]` for a 10 cent piece.  However, only the "coin\_" prefix is mandatory.  Each "coin\_"-section must then have the following options:

* `value`: How much is the coin worth, the format is CURRENCY:VALUE.FRACTION.  For example, a 10 cent piece is "EUR:0.10".
* `duration_withdraw`: How long can a coin of this type be withdrawn?  This limits the losses incurred by the exchange when a denomination key is compromised.
* `duration_overlap`: What is the overlap of the withdrawal timespan for this coin type?
* `duration_spend`: How long is a coin of the given type valid?  Smaller values result in lower storage costs for the exchange.
* `fee_withdraw`: What does it cost to withdraw this coin? Specified using the same format as `value`.
* `fee_deposit`: What does it cost to deposit this coin? Specified using the same format as `value`.
* `fee_refresh`: What does it cost to refresh this coin? Specified using the same format as `value`.
* `rsa_keysize`: How many bits should the RSA modulus (product of the two primes) have for this type of coin.

-----------------------
Univarsal keys duration
-----------------------

Each key, regardless of whether it is a `signkey` or a `denom key`, has a :ref:`starting date <keys>`.
The option `lookahead_provide`, under section `[exchange_keys]`, is such that only keys whose starting date is younger than
`lookahead_provide` will be issued by the exchange.

+++++++++
Utilities
+++++++++

------------------
Reserve management
------------------

Incoming transactions to the exchange's provider result in the creation or update of reserves, identified by their withdrawal key.
The command line tool `taler-exchange-reservemod` allows create and add money to reserves in the exchange's database.
