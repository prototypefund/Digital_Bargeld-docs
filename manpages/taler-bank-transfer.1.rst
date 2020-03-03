taler-bank-transfer(1)
######################

.. only:: html

   Name
   ====

   **taler-bank-transfer** - trigger a transfer at the bank

Synopsis
========

**taler-bank-transfer** [**-a** *VALUE* | **--amount=**\ ‌\ *VALUE*]
[**-b** *URL* | **--bank=**\ ‌\ *URL*]
[**-c** *FILENAME* | **--config=**\ ‌\ *FILENAME*]
[**-h** | **--help**]
[**-C** *ACCOUNT* | **--credit=**\ ‌\ *ACCOUNT*]
[**-s** *STRING* | **--subject=**\ ‌\ *STRING*]
[**-u** *USERNAME* | **--user=**\ ‌\ *USERNAME*]
[**-p** *PASSPHRASE* | **--pass=**\ ‌\ *PASSPHRASE*]
[**-v** | **--version**]

Description
===========

**taler-bank-transfer** is a command line tool to trigger bank
transfers to the exchange.  Useful for testing provided that
the configured Taler Wire Gateway supports the wire transfer
API.

**-a** *VALUE* \| **--amount=**\ ‌\ *VALUE*
   Amount to transfer. Given in the Taler-typical format of
   CURRENCY:VALUE.FRACTION. Mandatory option.

**-b** *URL* \| **--bank=**\ ‌\ *URL*
   URL at which the bank is operation.  Mandatory option.

**-c** *FILENAME* \| **--config=**\ ‌\ *FILENAME*
   Use the given configuration file.

**-h** \| **--help**
   Print short help on options.

**-C** *ACCOUNT* \| **--credit=**\ ‌\ *ACCOUNT*
   The money should be credited to ACCOUNT. Specifies the number of the
   account.  Mandatory option.

**-s** *STRING* \| **--subject=**\ ‌\ *STRING*
   Use STRING for the wire transfer subject.  Must be a reserve public key.
   Mandatory option.

**-u** *USERNAME* \| **--user=**\ ‌\ *USERNAME*
   Specifies the username for authentication.  Mandatory option.

**-p** *PASSPHRASE* \| **--pass=**\ ‌\ *PASSPHRASE*
   Specifies the pass phrase for authentication.  Mandatory option.

**-v** \| **--version**
   Print version information.

See Also
========

taler-bank-manage(1), taler.conf(5), https://docs.taler.net/core/api-wire.html#wire-transfer-test-apis

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>
