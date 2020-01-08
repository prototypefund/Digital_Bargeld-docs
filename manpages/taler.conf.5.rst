taler.conf(5)
#############

.. only:: html

   Name
   ====

   **taler.conf** - Taler configuration file


Description
===========

The basic structure of the configuration file is the following. The file
is split into sections. Every section begins with “[SECTIONNAME]” and
contains a number of options of the form “OPTION=VALUE”. Empty lines and
lines beginning with a “#” are treated as comments. Files containing
default values for many of the options described below are installed
under $TALER_PREFIX/share/taler/config.d/. The configuration file given
with **-c** to Taler binaries overrides these defaults.

Global Options
--------------

The following options are from the “[taler]” section and used by
virtually all Taler components.

CURRENCY
   Name of the currency, i.e. “EUR” for Euro.

The “[PATHS]” section is special in that it contains paths that can be
referenced using “$” in other configuration values that specify
filenames. For Taler, it commonly contains the following paths:

TALER_HOME
   Home directory of the user, usually “${HOME}”. Can be overwritten by
   testcases by setting ${TALER_TEST_HOME}.

TALER_DATA_HOME
   Where should Taler store its long-term data. Usually
   “${TALER_HOME}/.local/share/taler/”

TALER_CONFIG_HOME
   Where is the Taler configuration kept. Usually
   “${TALER_HOME}/.config/taler/”

TALER_CACHE_HOME
   Where should Taler store cached data. Usually
   “${TALER_HOME}/.cache/taler/”

TALER_RUNTIME_DIR
   Where should Taler store system runtime data (like UNIX domain
   sockets). Usually “${TMP}/taler-system-runtime”.

EXCHANGE OPTIONS
----------------

The following options are from the “[exchange]” section and used by most
exchange tools.

DB
   Plugin to use for the database, i.e. “postgres”

PORT
   Port on which the HTTP server listens, i.e. 8080.

MASTER_PUBLIC_KEY
   Crockford Base32-encoded master public key, public version of the
   exchange´s long-time offline signing key.

MASTER_PRIV_FILE
   Location of the master private key on disk. Only used by tools that
   can be run offline (as the master key is for offline signing).

BASE_URL
   Specifies the base URL under which the exchange can be reached. Added
   to wire transfers to enable tracking by merchants.

SIGNKEY_DURATION
   For how long is a signing key valid?

LEGAL_DURATION
   For how long are signatures with signing keys legally valid?

LOOKAHEAD_SIGN
   How long do we generate denomination and signing keys ahead of time?

LOOKAHEAD_PROVIDE
   How long into the future do we provide signing and denomination keys
   to clients?

TERMS_DIR
   Directory where the terms of service of the exchange operator can be fund. The directory must contain sub-directories for every supported language, using the two-character language code in lower case, i.e. "en/" or "fr/".  Each subdirectory must then contain files with the terms of service in various formats.  The basename of the file of the current policy must be specified under TERMS_ETAG.  The extension defines the mime type. Supported extensions include "html", "htm", "txt", "pdf", "jpg", "jpeg", "png" and "gif".  For example, using a TERMS_ETAG of "0", the structure could be the following:
   - $TERMS_DIR/en/0.pdf
   - $TERMS_DIR/en/0.html
   - $TERMS_DIR/en/0.txt
   - $TERMS_DIR/fr/0.pdf
   - $TERMS_DIR/fr/0.html
   - $TERMS_DIR/de/0.txt

TERMS_ETAG
   Basename of the file(s) in the TERMS_DIR with the current terms of service.  The value is also used for the "Etag" in the HTTP request to control caching. Whenever the terms of service change, the TERMS_ETAG MUST also change, and old values MUST NOT be repeated.  For example, the date or version number of the terms of service SHOULD be used for the Etag.  If there are minor (i.e. spelling) fixes to the terms of service, the TERMS_ETAG probably SHOULD NOT be changed. However, whenever users must approve the new terms, the TERMS_ETAG MUST change.

PRIVACY_DIR
   Works the same as TERMS_DIR, just for the privacy policy.
PRIVACY_ETAG
   Works the same as TERMS_ETAG, just for the privacy policy.


EXCHANGE POSTGRES BACKEND DATABASE OPTIONS
------------------------------------------

The following options must be in section “[exchangedb-postgres]” if the
“postgres” plugin was selected for the database.

CONFIG
   How to access the database, i.e. “postgres:///taler” to use the
   “taler” database. Testcases use “talercheck”.

MERCHANT OPTIONS
----------------

The following options are from the “[merchant]” section and used by the
merchant backend.

DB
   Plugin to use for the database, i.e. “postgres”

PORT
   Port on which the HTTP server listens, i.e. 8080.

WIRE_TRANSFER_DELAY
   How quickly do we want the exchange to send us money? Note that wire
   transfer fees will be higher if we ask for money to be wired often.
   Given as a relative time, i.e. “5 s”

DEFAULT_MAX_WIRE_FEE
   Maximum wire fee we are willing to accept from exchanges. Given as a
   Taler amount, i.e. “EUR:0.1”

DEFAULT_MAX_DEPOSIT_FEE
   Maximum deposit fee we are willing to cover. Given as a Taler amount,
   i.e. “EUR:0.1”

MERCHANT POSTGRES BACKEND DATABASE OPTIONS
------------------------------------------

The following options must be in section “[merchantdb-postgres]” if the
“postgres” plugin was selected for the database.

CONFIG
   How to access the database, i.e. “postgres:///taler” to use the
   “taler” database. Testcases use “talercheck”.

MERCHANT INSTANCES
------------------

The merchant configuration must specify a set of instances, containing
at least the “default” instance. The following options must be given in
each “[instance-NAME]” section.

KEYFILE
   Name of the file where the instance´s private key is to be stored,
   i.e. “${TALER_CONFIG_HOME}/merchant/instance/name.priv”

NAME
   Human-readable name of the instance, i.e. “Kudos Inc.”

Additionally, for instances that support tipping, the following options
are required.

TIP_EXCHANGE
   Base-URL of the exchange that holds the reserve for tipping,
   i.e. “https://exchange.demo.taler.net/”

TIP_EXCHANGE_PRIV_FILENAME
   Filename with the private key granting access to the reserve,
   i.e. “${TALER_CONFIG_HOME}/merchant/reserve/tip.priv”

KNOWN EXCHANGES (for merchants and wallets)
-------------------------------------------

The merchant configuration can include a list of known exchanges if the
merchant wants to specify that certain exchanges are explicitly trusted.
For each trusted exchange, a section [exchange-NAME] must exist, where
NAME is a merchant-given name for the exchange. The following options
must be given in each “[exchange-NAME]” section.

BASE_URL
   Base URL of the exchange, i.e. “https://exchange.demo.taler.net/”

MASTER_KEY
   Crockford Base32 encoded master public key, public version of the
   exchange´s long-time offline signing key

CURRENCY
   Name of the currency for which this exchange is trusted, i.e. “KUDOS”

KNOWN AUDITORS (for merchants and wallets)
------------------------------------------

The merchant configuration can include a list of known exchanges if the
merchant wants to specify that certain auditors are explicitly trusted.
For each trusted exchange, a section [auditor-NAME] must exist, where
NAME is a merchant-given name for the exchange. The following options
must be given in each “[auditor-NAME]” section.

BASE_URL
   Base URL of the auditor, i.e. “https://auditor.demo.taler.net/”

AUDITOR_KEY
   Crockford Base32 encoded auditor public key.

CURRENCY
   Name of the currency for which this auditor is trusted, i.e. “KUDOS”

ACCOUNT OPTIONS (for exchanges and merchants)
---------------------------------------------

An exchange (or merchant) can have multiple bank accounts. The following
options are for sections named “[account-SOMETHING]”. The SOMETHING is
arbitrary and should be chosen to uniquely identify the bank account for
the operator. Additional authentication options may need to be specified
in the account section depending on the PLUGIN used.

URL
   Specifies the payto://-URL of the account. The general format is
   payto://METHOD/DETAILS. This option is used for exchanges and
   merchants.

WIRE_RESPONSE
   Specifies the name of the file in which the /wire response for this
   account should be located. Used by the Taler exchange service and the
   taler-exchange-wire tool and the taler-merchant-httpd (to generate
   the files).

PLUGIN
   Name of the plugin can be used to access the account
   (i.e. “taler_bank”). Used by the merchant backend for back
   office operations (i.e. to identify incoming wire transfers) and by
   the exchange.

ENABLE_DEBIT
   Must be set to YES for the accounts that the
   taler-exchange-aggregator should debit. Not used by merchants.

ENABLE_CREDIT
   Must be set to YES for the accounts that the taler-exchange-wirewatch
   should check for credits. It is yet uncertain if the merchant
   implementation may check this flag as well.

HONOR_instance
   Must be set to YES for the instances (where “instance” is the section
   name of the instance) of the merchant backend that should allow
   incoming wire transfers for this bank account.

ACTIVE_instance
   Must be set to YES for the instances (where “instance” is the section
   name of the instance) of the merchant backend that should use this
   bank account in new offers/contracts. Setting ACTIVE_instance to YES
   requires also setting ENABLE_instance to YES.

TALER-BANK AUTHENTICATION OPTIONS (for accounts)
------------------------------------------------

The following authentication options are supported by the “taler-bank”
wire plugin. They must be specified in the “[account-]” section that
uses the “taler-bank” plugin.

TALER_BANK_AUTH_METHOD
   Authentication method to use. “none” or “basic” are currently
   supported.

USERNAME
   Username to use for authentication. Used with the “basic”
   authentication method.

PASSWORD
   Password to use for authentication. Used with the “basic”
   authentication method.


EXCHANGE WIRE FEE OPTIONS
-------------------------

For each supported wire method (i.e. “x-taler-bank” or “sepa”), sections
named “[fees-METHOD]” state the (aggregate) wire transfer fee and the
reserve closing fees charged by the exchange. Note that fees are
specified using the name of the wire method, not by the plugin name. You
need to replace “YEAR” in the option name by the calendar year for which
the fee should apply. Usually, fees should be given for serveral years
in advance.

WIRE-FEE-YEAR
   Aggregate wire transfer fee merchants are charged in YEAR. Specified
   as a Taler amount using the usual amount syntax
   (CURRENCY:VALUE.FRACTION).

CLOSING-FEE-YEAR
   Reserve closing fee customers are charged in YEAR. Specified as a
   Taler amount using the usual amount syntax (CURRENCY:VALUE.FRACTION).

EXCHANGE COIN OPTIONS
---------------------

The following options must be in sections starting with ``"[coin_]"`` and
are used by taler-exchange-keyup to create denomination keys.

VALUE
   Value of the coin, i.e. “EUR:1.50” for 1 Euro and 50 Cents (per
   coin).

DURATION_OVERLAP
   How much should validity periods for these coins overlap?

DURATION_WITHDRAW
   How long should the same key be used for clients to withdraw coins of
   this value?

DURATION_SPEND
   How long do clients have to spend these coins?

FEE_WITHDRAW
   What fee is charged for withdrawl?

FEE_DEPOSIT
   What fee is charged for depositing?

FEE_REFRESH
   What fee is charged for refreshing?

FEE_REFUND
   What fee is charged for refunds? When a coin is refunded, the deposit
   fee is returned. Instead, the refund fee is charged to the customer.

RSA_KEYSIZE
   What is the RSA keysize modulos (in bits)?

AUDITOR OPTIONS
---------------

The following options must be in section “[auditor]” for the Taler
auditor.

DB
   Plugin to use for the database, i.e. “postgres”

AUDITOR_PRIV_FILE
   Name of the file containing the auditor’s private key

AUDITOR POSTGRES BACKEND DATABASE OPTIONS
-----------------------------------------

The following options must be in section “[auditordb-postgres]” if the
“postgres” plugin was selected for the database.

CONFIG
   How to access the database, i.e. "postgres:///taler" to use the
   "taler" database. Testcases use “talercheck”.

SEE ALSO
========

taler-exchange-dbinit(1), taler-exchange-httpd(1),
taler-exchange-keyup(1), taler-exchange-wire(1).

BUGS
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>.
