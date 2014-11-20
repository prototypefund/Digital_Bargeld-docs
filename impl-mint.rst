===================================
The Mint Reference Implementation
===================================



--------------------
Key update
--------------------
New denomination and signing keys can be uploaded to the mint
via the HTTP interface.  It is, of course, only possible to upload keys signed
by the mint's master key.

As an additional constraint, it is only possible to upload new keys while the
mint still has one valid signing key (otherwise, MitM-attacks would be possible).

Alternative:  Transfer key is signed by the master key.

.. http:GET:: /admin/keyup/public

  Transmit the public part of the new key in plain-text.

  :query denom_info: Public part of the denomination issue
  :query transfer_pub: Public key used by the party doing the key transfer

.. http:GET:: /admin/keyup/private

  Transmit the private part of the new text, encrypted with the shared secret derived from the
  ephemeral public key and the sender's private key.


-------------------
Database Scheme
-------------------

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
    -- if funds are insufficient or the mint has not
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

    -- Signature over the minting request by the customer.
    customer_sig      BYTEA,

    -- The signed blind blank coin.
    blind_signed_coin BYTEA,

    -- The denomination public key used to sign the
    -- blind signed coin.
    denom_pub         BYTEA,

    -- The purse that requested the minting of this
    -- coin.
    withdraw_pub      BYTEA REFERENCES purses(withdraw_pub)
  );


The table `coins` stores information about coins known to the mint.

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
    -- if funds are insufficient or the mint has not
    -- generated it yet.
    blinding_pub        BYTEA,

    -- The blinding key (private part).
    blinding_priv       BYTEA,
    -- The coin blank provided by the customer.
    blind_blank_coin  BYTEA,
    -- encrypted stuff
    coin_link_enc BYTEA,
  );


----------------
Key Management
----------------
The command line tool `taler-mint-keyup` updates the signing key and
list of denominations offered by the mint.  This process requires the
mint's master key, and should be done offline in order to protect the master key.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Configuring keys and coin types
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The denominations and key expirations for the mint are specified in a configuration file.

The section `[mint_keys]` containts the following entries:

* `signkey_duration`: How long should one signing key be used?
* `lookahead_sign`:  For how far into the future should keys be issued?  This determines the frequency
  of offline signing with the master key.
* `lookahead_provide`: How far into the future should the mint provide keys?  This determines the attack
  window on keys.
* `coin_types`: Space-separated list of coin aliases that the mint should provide.  The coin aliases
  are used as the key configuration sections regarding the coin type.

The configuration refers to each denomination type by an alphanumeric alias.  This alias is used to identify
the same denomination in different sections.  Configuration values are assigned as `<ALIAS> = <VALUE>`
in the respective section.

* `[mint_denom_duration_withdraw]`: How long can a coin of this type be withdrawn?
  This limits the losses incured by the mint when a denomination key is compromised.
* `[mint_denom_duration_overlap]`: What is the overlap of the withdrawal timespan for
  a coin type?
* `[mint_denom_duration_spend]`: How long is a coin of the given type valid?  Smaller
  values result in lower storage costs for the mint.
* `[mint_denom_value]`: What is the value of the coin? Given as `T : A / B`, where `T` is the currency
  identifier, `A` and `B` are integers denoting the value (`A` is the numerator, `B` is the denominator).
* `[mint_denom_fee_withdraw]`: What does it cost to withdraw this coin? Given as `T : A / B`, where `T` is the currency
  identifier, `A` and `B` are integers denoting the value (`A` is the numerator, `B` is the denominator).
* `[mint_denom_fee_refresh]`: What does it cost to refresh this coin? Given as `T : A / B`, where `T` is the currency
  identifier, `A` and `B` are integers denoting the value (`A` is the numerator, `B` is the denominator).
* `[mint_denom_fee_deposit]`: What does it cost to refresh this coin? Given as `T : A / B`, where `T` is the currency
  identifier, `A` and `B` are integers denoting the value (`A` is the numerator, `B` is the denominator).
* `[mint_denom_kappa]`: How easy should cheating be for the customer when refreshing?

^^^^^^^^^^^^^^^^^^^
Key Storage Format
^^^^^^^^^^^^^^^^^^^
The mint's key directory contains the two subdirectories `signkeys` and `coinkeys`.

The file `master.pub` stores the mint's master public key.

The directory `signkeys` contains signkey files, where the name is the start date of the respective key.

The `coinkeys` directory additionaly contains a subdirectory for each coin type alias.  These contain
coinkey files, where the name is again the start timestamp of the respective key.


-------
Purses
-------
Incoming transactions to the mint's provider result in the creation or update of `purses`, identified
by their withdrawal key.

The command line tool `taler-mint-modpurse` allows create and add money to purses in the mint's database.


