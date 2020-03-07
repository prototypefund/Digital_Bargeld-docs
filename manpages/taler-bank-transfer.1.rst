taler-bank-transfer(1)
######################

.. only:: html

   Name
   ====

   **taler-bank-transfer** - trigger a transfer at the bank (or obtain transaction history)

Synopsis
========

**taler-bank-transfer**
[**-a** *VALUE* | **--amount=**\ ‌\ *VALUE*]
[**-b** *URL* | **--bank=**\ ‌\ *URL*]
[**-c** *FILENAME* | **--config=**\ ‌\ *FILENAME*]
[**-C** *ACCOUNT* | **--credit=**\ ‌\ *ACCOUNT*]
[**-D** *ACCOUNT* | **--debit=**\ ‌\ *ACCOUNT*]
[**-h** | **--help**]
[**-i** | **--credit-history**]
[**-o** | **--debit-history**]
[**-p** *PASSPHRASE* | **--pass=**\ ‌\ *PASSPHRASE*]
[**-s** *ACCOUNT-SECTION* | **--section=**\ ‌\ *ACCOUNT-SECTION*]
[**-S** *STRING* | **--subject=**\ ‌\ *STRING*]
[**-u** *USERNAME* | **--user=**\ ‌\ *USERNAME*]
[**-v** | **--version**]
[**-w** *ROW* | **--since-when=**\ ‌\ *ROW*]

Description
===========

**taler-bank-transfer** is a command line tool to trigger bank transfers or
inspect wire transfers for exchange accounts using the wire API.  The tool is
expected to be used during testing or for diagnostics.

You can do one of the following four operations during one invocation.

  (1) Execute wire transfer from the exchange to consumer account (**-C**).
  (2) Execute wire transfer from consumer account to the exchange (**-D**).
  (3) Inspect credit history of the exchange (**-i**).
  (4) Inspect debit history of the exchange (**-o**).

Doing more than one of these at a time will result in an error.  Note,
however, that the **-C** and **-D** options also can be used to act as filters
on transaction history operations.


Options
=======

**-a** *VALUE* \| **--amount=**\ ‌\ *VALUE*
   Amount to transfer. Given in the Taler-typical format of
   CURRENCY:VALUE.FRACTION.

**-b** *URL* \| **--bank=**\ ‌\ *URL*
   URL at which the bank is operation.  Conflicts with **-s**.

**-c** *FILENAME* \| **--config=**\ ‌\ *FILENAME*
   Use the given configuration file.

**-C** *ACCOUNT* \| **--credit=**\ ‌\ *ACCOUNT*
   When doing a wire transfer from the exchange, the money should be credited to *ACCOUNT*.
   Specifies the payto:// URI of the account.  Can also be used as a filter by credit
   account when looking at transaction histories.

**-D** *ACCOUNT* \| **--debit=**\ ‌\ *ACCOUNT*
   When doing a wire transfer to the exchange, the *ACCOUNT* is to be debited.
   Specifies the payto:// URI of the account.  Can also be used as a filter by debit
   account when looking at transaction histories.

**-h** \| **--help**
   Print short help on options.

**-i** \| **--credit-history**
   Obtain credit history of the exchange. Conflicts with **-o**.

**-o** \| **--debit-history**
   Obtain debit history of the exchange. Conflicts with **-i**.

**-S** *SUBJECT* \| **--subject=**\ ‌\ *SUBJECT*
   Use *SUBJECT* for the wire transfer subject.  Must be a reserve public key for credit operations and a wire transfer identifier for debit operations. If not specified, a random value will be generated instead.

**-s** *ACCOUNT_SECTION* \| **--section=**\ ‌\ *ACCOUNT-SECTION*
   Obtain exchange account information from the *ACCOUNT-SECTION* of the configuration. Conflicts with **-u**, **-p** and **-b**.  Note that either **-b** or **-s** must be specified.

**-u** *USERNAME* \| **--user=**\ ‌\ *USERNAME*
   Specifies the username for authentication.  Optional and conflicts with **-s**. If neither **-u** nor **-s** are used, we will attempt to talk to the bank without authentication.

**-p** *PASSPHRASE* \| **--pass=**\ ‌\ *PASSPHRASE*
   Specifies the pass phrase for authentication.  Conflicts with **-s**.

**-v** \| **--version**
   Print version information.

**-w** *ROW* \| **--since-when=**\ ‌\ *ROW*
   Specifies a *ROW* from which the history should be obtained. If not given, the 10 youngest transactions are returned.


See Also
========

taler-bank-manage(1), taler.conf(5), https://docs.taler.net/core/api-wire.html#wire-transfer-test-apis

Bugs
====

Report bugs by using https://gnunet.org/bugs/ or by sending electronic
mail to <taler@gnu.org>
