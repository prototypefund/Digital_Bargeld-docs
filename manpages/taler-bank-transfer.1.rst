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
[**-c** *FILENAME* | **--config=**\ ‌\ *FILENAME*] [**-h** | **--help**]
[**-D** *ACCOUNT* | **--debit=**\ ‌\ *ACCOUNT*]
[**-C** *ACCOUNT* | **--credit=**\ ‌\ *ACCOUNT*]
[**-s** *STRING* | **--subject=**\ ‌\ *STRING*]
[**-u** *USERNAME* | **--user=**\ ‌\ *USERNAME*]
[**-p** *PASSPHRASE* | **--pass=**\ ‌\ *PASSPHRASE*]
[**-v** | **--version**]

Description
===========

**taler-bank-transfer** is a command line tool to trigger bank
transfers.

**-a** *VALUE* \| **--amount=**\ ‌\ *VALUE*
   Amount to transfer. Given in the Taler-typical format of
   CURRENCY:VALUE.FRACTION

**-b** *URL* \| **--bank=**\ ‌\ *URL*
   URL at which the bank is operation.

**-c** *FILENAME* \| **--config=**\ ‌\ *FILENAME*
   Use the given configuration file.

**-h** \| **--help**
   Print short help on options.

**-D** *ACCOUNT* \| **--debit=**\ ‌\ *ACCOUNT*
   The money should be debited from ACCOUNT. Specifies the number of the
   account.

**-C** *ACCOUNT* \| **--credit=**\ ‌\ *ACCOUNT*
   The money should be credited to ACCOUNT. Specifies the number of the
   account.

**-s** *STRING* \| **--subject=**\ ‌\ *STRING*
   Use STRING for the wire transfer subject.

**-u** *USERNAME* \| **--user=**\ ‌\ *USERNAME*
   Specifies the username for authentication.

**-p** *PASSPHRASE* \| **--pass=**\ ‌\ *PASSPHRASE*
   Specifies the pass phrase for authentication.

**-v** \| **--version**
   Print version information.

See Also
========

taler-bank-manage(1), taler.conf(5)

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>
