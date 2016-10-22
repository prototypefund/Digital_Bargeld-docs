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

The following data and facilities have to be set up, in order to run a merchant backend:

* Serving
* Currency
* Database
* Exchanges
* Keying
* Bank account
* Instances

In this document, we assume that ``$HOME/.config/taler.conf`` is being customized.

-------
Serving
-------

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
* via configuration option `config`, under section `[merchantdb-BACKEND]`. For example, the demo merchant is configured as follows:

.. code-block:: text

  [merchant]
  ...
  db = postgres
  ...

  [merchantdb-postgres]
  config = postgres:///talerdemo

---------
Exchanges
---------

The options `uri` and `master_key`, under section `[merchant-exchange-MYEXCHANGE]`, let
the merchant add the exchange `MYEXCHANGE` among the exchanges the merchant wants to work
with. `MYEXCHAGE` is just a mnemonic name chosen by the merchant (which is not currently used
in any computation), and the merchant can add as many exchanges as it is needed.
`uri` is the exchange's base URL. Please note that a valid `uri` complies with the following
pattern::

   schema://hostname/

`master_key` is the base32 encoding of the exchange's master key (see :ref:`/keys <keys>`).
In our demo, we use the following configuration::

   [merchant-exchange-test]
   URI = https://exchange.test.taler.net/
   MASTER_KEY = CQQZ9DY3MZ1ARMN5K1VKDETS04Y2QCKMMCFHZSWJWWVN82BTTH00

------
Keying
------

The option `keyfile` under section `[merchant-instance-default]` is the path to the
merchant's :ref:`default instance <instances-lab>` private key. This key is needed to
sign certificates and other messages sent to wallets and exchanges.
To generate a 100% compatible key, it is recommended to use the ``gnunet-ecc`` tool.

------------
Bank account
------------

This piece of information is used when the merchant redeems coins to the exchange.
That way, the exchange will know to which bank account it has to transfer real money.
The merchant must specify which system it wants receive wire transfers with. We support
a `test` wire format so far, and supporting `SEPA` is among our priorities.

The wire format is specified in the option `wireformat` under section `[merchant]`,
and the wire details are given via a JSON file, whose path must be indicated in the
option `X_response_file` under section `[default-wireformat]`, where `X` matches
the chosen wireformat. In our demo, we have::

  [merchant]
  ..
  wireformat = test
  ..

  [merchant-instance-wireformat-default]
  test_response_file = ${TALER_CONFIG_HOME}/merchant/wire/test.json

The file `test.json` obeys to the following specification

.. code-block:: tsref

  interface WireDetails {
    // matches wireformat
    type: string; 

    // base URL of the merchant's bank
    bank_uri: string;

    // merchant's signature (unused, can be any value)
    signature: string; 

    // merchant's account number at the bank
    account_number: Integer;
    
    // the salt (unused, can be any value)
    salt: any;
  }

As an example, `test.json` used in our demo is shown below::

  {
  "type": "test",
  "bank_uri": "https://bank.test.taler.net/",
  "sig": "MERCHANTSIGNATURE",
  "account_number": 6,
  "salt": "SALT"
  }



.. _instances-lab:

---------
Instances
---------

In Taler, multiple shops can rely on the same :ref:`merchant backend <merchant-arch>`.
In Taler terminology, each of those shops is called `(merchant) instance`. Any instance
is defined by its private key and its wire details. In order to add the instance `X` to
the merchant backend, we have to add the sections `[merchant-instance-X]` and `[X-wireformat]`,
and edit them as we did for the `default` instance. For example, in our demo we add the
instance `Tor` as follows::
  
  [merchant-instance-Tor]
  KEYFILE = ${TALER_DATA_HOME}/merchant/tor.priv
  
  ..

  [merchant-instance-wireformat-Tor]
  TEST_RESPONSE_FILE = ${TALER_CONFIG_HOME}/merchant/wire/tor.json

Please note that :ref:`Taler messagging<merchant-api>` is designed so that the merchant
frontend can instruct the backend on which instance has to be used in the various operations.
This information is optional, and if not given, the backend will act as the `default` instance.
