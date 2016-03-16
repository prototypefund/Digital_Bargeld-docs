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

===================================
The Exchange Reference Implementation
===================================

----------------------
The Configuration File
----------------------

The section `[exchange]` contains various global options for the exchange:

* `master_public_key`: Must specify the exchange's master public key.
* `wireformat`: The wireformat supported by the exchange (i.e. "SEPA")
* `currency`: The currency supported by the exchange (i.e. "EUR")


^^^^^^^^^^^^^^^^^^^^^^
SEPA accounts
^^^^^^^^^^^^^^^^^^^^^^

The command line tool `taler-exchange-sepa` is used to create a file with
the JSON response to /wire/sepa requests using the exchange's offline
master key.  This file needs to be created and added to the configuration under SEPA_RESPONSE_FILE in section [exchange-wire-sepa] when the 
`wireformat` option in the configuration file allows SEPA transactions.


^^^^^^^^^^^^^^^^^^^^^^
Key Management Options
^^^^^^^^^^^^^^^^^^^^^^

The command line tool `taler-exchange-keyup` updates the signing key and list of denominations offered by the exchange.  This process requires the exchange's master key, and should be done offline in order to protect the master key.  For this, `taler-exchange-keyup` uses additional configuration options.

The section `[exchange_keys]` containts the following entries:

* `signkey_duration`: How long should one signing key be used?
* `lookahead_sign`:  For how far into the future should keys be issued?  This determines the frequency
  of offline signing with the master key.
* `lookahead_provide`: How far into the future should the exchange provide keys?  This determines the attack
  window on keys.


Sections specifying denomination (coin) information start with "coin\_".  By convention, the name continues with "$CURRENCY_[$SUBUNIT]_$VALUE", i.e. "[coin_eur_ct_10] for a 10 cent piece.  However, only the "coin\_" prefix is mandatory.  Each "coin\_"-section must then have the following options:

* `value`: How much is the coin worth, the format is CURRENCY:VALUE.FRACTION.  For example, a 10 cent piece is "EUR:0.10".
* `duration_withdraw`: How long can a coin of this type be withdrawn?  This limits the losses incured by the exchange when a denomination key is compromised.
* `duration_overlap`: What is the overlap of the withdrawal timespan for this coin type?
* `duration_spend`: How long is a coin of the given type valid?  Smaller values result in lower storage costs for the exchange.
* `fee_withdraw`: What does it cost to withdraw this coin? Specified using the same format as `value`.
* `fee_deposit`: What does it cost to deposit this coin? Specified using the same format as `value`.
* `fee_refresh`: What does it cost to refresh this coin? Specified using the same format as `value`.
* `rsa_keysize`: How many bits should the RSA modulus (product of the two primes) have for this type of coin.


------------------
Reserve management
------------------

Incoming transactions to the exchange's provider result in the creation or update of reserves, identified by their withdrawal key.

The command line tool `taler-exchange-reservemod` allows create and add money to reserves in the exchange's database.


-------------------
Database Scheme
-------------------

  .. note::

     This documentation is outdated (no bug number yet either).


.. sourcecode:: postgres

  CREATE TABLE purses (
    -- The customer's withdraw public key for the purse.
    withdraw_pub     BYTEA PRIMARY KEY,

    -- Purse balance (value part).
    balance_value    INT4 NOT NULL,

    -- Purse balance (fractional part).
    balance_fraction INT4 NOT NULL,

    -- Purse balance (fractional).
    balance_currency VARCHAR(4),

    -- Expiration time stamp for the purse.
    expiration       INT8,

    -- The blinding key (public part) for the purse, can be NULL
    -- if funds are insufficient or the exchange has not
    -- generated it yet.
    blinding_pub        BYTEA,

    -- The blinding key (private part).
    blinding_priv       BYTEA,

    -- Key that was used to create the last signature on the
    -- purse status
    status_sign_pub     BYTEA,

    -- Cached status signature
    status_sig          BYTEA
  );


.. sourcecode:: postgres

  CREATE TABLE collectable_blindcoins (
    -- The public part of the blinding key.
    -- Note that this is not a foreign key,
    -- as the blinding key is removed from the purse
    -- table once a coin has been requested with it.
    -- Furthermore, the private part is not required
    -- anymore.
    blind_pub bytea   PRIMARY KEY,

    -- The coin blank provided by the customer.
    blind_blank_coin  BYTEA,

    -- Signature over the exchangeing request by the customer.
    customer_sig      BYTEA,

    -- The signed blind blank coin.
    blind_signed_coin BYTEA,

    -- The denomination public key used to sign the
    -- blind signed coin.
    denom_pub         BYTEA,

    -- The purse that requested the exchangeing of this
    -- coin.
    withdraw_pub      BYTEA REFERENCES purses(withdraw_pub)
  );


The table `coins` stores information about coins known to the exchange.

.. sourcecode:: postgres

  CREATE TABLE coins (
    denom_pub BYTEA NOT NULL,
    denom_sig BYTEA NOT NULL,
    coin_pub BYTEA NOT NULL,

    -- melting session, or NULL if not melted
    melt_session BYTEA,

    -- remaining value of the coin
    balance_currency int4,
    balance_value int4,
    balance_fraction int4,

    -- lock id, not NULL if not locked
    lock int
  );

The following tables are used for refreshing.

.. sourcecode:: postgres

  CREATE TABLE refresh_sessions (
    session_pub BYTEA,
    order_sig BYTEA,
    index_reveal INT2,
  );

  CREATE TABLE refresh_melt (
    session_pub BYTEA REFERENCES refresh_sessions (session_pub),
    session_sig BYTEA,
    denom_pub BYTEA,
    denom_sig BYTEA,
    coin_pub BYTEA,
    coin_sig BYTEA,
  );

  -- create links to old coins
  CREATE TABLE refresh_link_commits (
    session_pub BYTEA,
    session_sig BYTEA,
    coin_pub BYTEA,
    transfer_pub BYTEA,
    link_secret_enc BYTEA,
    link_secret_hash BYTEA,
    idx INTEGER
  );

  CREATE TABLE refresh_order (
    -- EdDSA public key of the melting session
    session_pub BYTEA REFERENCES refresh_sessions (session_pub),
    -- denomination key for the newly ordered coin
    denom_pub BYTEA,
    -- signature from session key over coin order
    session_sig BYTEA,
  );

  CREATE TABLE refresh_coin_commits (
    session_pub BYTEA,
    idx INTEGER,
    coin_link_enc BYTEA,
    -- The blinding key (public part) for the purse, can be NULL
    -- if funds are insufficient or the exchange has not
    -- generated it yet.
    blinding_pub        BYTEA,

    -- The blinding key (private part).
    blinding_priv       BYTEA,
    -- The coin blank provided by the customer.
    blind_blank_coin  BYTEA,
    -- encrypted stuff
    coin_link_enc BYTEA,
  );


------------------
Key Storage Format
------------------

The exchange's key directory contains the two subdirectories `signkeys` and `coinkeys`.

The directory `signkeys` contains signkey files, where the name is the start date of the respective key.

The `coinkeys` directory additionaly contains a subdirectory for each coin type alias.  These contain coinkey files, where the name is again the start timestamp of the respective key.
