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
  @author Marcello Stanisci

========
Exchange
========

.. _keys-duration:

-------------
Keys duration
-------------

`signkeys`. The option `lookahead_sign` is such that, being `t` the time when `taler-exchange-keyup`
is run, `taler-exchange-keyup` will generate `n` `signkeys`, where `t + (n * signkey_duration) = t +
lookahead_sign`. In other words, we generate a number of keys which is sufficient to cover a period of
`lookahead_sign`. As for the starting date, the first generated key will get a starting time of `t`,
and the `j`-th key will get a starting time of `x + signkey_duration`, where `x` is the starting time
of the `(j-1)`-th key.

`denom keys`. The option `lookahead_sign` is such that, being `t` the time when `taler-exchange-keyup`
is run, `taler-exchange-keyup` will generate `n` `denom keys` for each denomination, where
`t + (n * duration_withdraw) = t + lookahead_sign`. In other words, for each denomination, we generate a
number of keys which is sufficient to cover a period of `lookahead_sign`. As for the starting date, the
first generated key will get a starting time of `t`, and the `j`-th key will get a starting time of
`x + duration_withdraw`, where `x` is the starting time of the `(j-1)`-th key.



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


-------------------
Signing key storage
-------------------

The private online signing keys of the exchange are stored in a
subdirectory "signkeys/" of the "KEYDIR" which is an option in the
"[exchange]" section of the configuration file.  The filename is the
starting time at which the signing key can be used in microseconds
since the Epoch.  The file format is defined by the `struct
TALER_EXCHANGEDB_PrivateSigningKeyInformationP`:

.. sourcecode:: c
  struct TALER_EXCHANGEDB_PrivateSigningKeyInformationP {
     struct TALER_ExchangePrivateKeyP signkey_priv;
     struct TALER_ExchangeSigningKeyValidityPS issue;
  };

------------------------
Denomination key storage
------------------------

The private denomination keys of the exchange are store in a
subdirectory "denomkeys/" of the "KEYDIR" which is an option in the
"[exchange]" section of the configuration file.  "denomkeys/" contains
further subdirectories, one per denomination.  The specific name of
the subdirectory under "denomkeys/" is ignored by the exchange.
However, the name is important for the "taler-exchange-keyup" tool
that generates the keys.  The tool combines a human-readable encoding
of the denomination (i.e.  for EUR:1.50 the prefix would be
"EUR_1_5-", or for EUR:0.01 the name would be "EUR_0_01-") with a
postfix that is a truncated Crockford32 encoded hash of the various
attributes of the denomination key (relative validity periods, fee
structure and key size).  Thus, if any attributes of a coin change,
the name of the subdirectory will also change, even if the
denomination remains the same.

Within this subdirectory, each file represents a particular
denomination key.  The filename is the starting time at which the
signing key can be used in microseconds since the Epoch.  The
format on disk begins with a
`struct TALER_EXCHANGEDB_DenominationKeyInformationP` giving
the attributes of the denomination key and the associated
signature with the exchange's long-term offline key:

.. sourcecode:: c
  struct TALER_EXCHANGEDB_DenominationKeyInformationP {
    struct TALER_MasterSignatureP signature;
    struct TALER_DenominationKeyValidityPS properties;
  };

This is then followed by the variable-size RSA private key in
libgcrypt's S-expression format, which can be decoded using
`GNUNET_CRYPTO_rsa_private_key_decode()`.


------------------------
Auditor signature storage
-------------------------

Signatures from auditors are stored in the directory specified
in the exchange configuration section "exchangedb" under the
option "AUDITOR_BASE_DIR".  The exchange does not care about
the specific names of the files in this directory.

Each file must contain a header with the public key information
of the auditor, the master public key of the exchange, and
the number of signed denomination keys:

.. sourcecode:: c
  struct AuditorFileHeaderP {
    struct TALER_AuditorPublicKeyP apub;
    struct TALER_MasterPublicKeyP mpub;
    uint32_t dki_len;
  };

This is then followed by `dki_len` signatures of the auditor of type
`struct TALER_AuditorSignatureP`, which are then followed by another
`dki_len` blocks of type `struct TALER_DenominationKeyValidityPS`.
The auditor's signatures must be signatures over the information of
the corresponding denomination key validity structures embedded in a
`struct TALER_ExchangeKeyValidityPS` structure using the
`TALER_SIGNATURE_AUDITOR_EXCHANGE_KEYS` purpose.
