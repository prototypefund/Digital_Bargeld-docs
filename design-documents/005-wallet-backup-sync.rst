Design Doc 005: Wallet Backup and Sync
######################################

.. warning::

  This is an unfinished draft.

Summary
=======

This document discusses considerations for backup and synchronization of wallets.


Requirements
============

* Backup and sync must not require any synchronous communication between the
  wallets
* Wallets operating (payments/withdrawals/...) for longer periods of time without
  synchronizing should be handled well
* Conflicts should be resolved automatically in pretty much all cases
* One wallet can be enrolled with multiple sync servers, and a wallet can
  join
* Other wallets connected to the sync server are trusted.

Proposed Solution
=================

The blob stored on the backup/sync server is a compressed and encrypted JSON file.

The various entity types managed by the wallet are modeled LWW-Sets (Last Write
Wins Set CRDT).  Timestamps for inserts/deletes are are Lamport timestamps.  Concurrent, conflicting insert/delete
operations are resolved in favor of "delete".

The managed entities are:

 * set of exchanges with the data from /keys, /wire
 * set of directly trusted exchange public keys
 * set of trusted auditors for currencies
 * set of reserves together with reserve history
 * set of accepted bank withdrawal operations
 * set of coins together with coin history and blinding secret (both for normal withdrawal and refresh)
   and coin source info (refresh operation, tip, reserve)
 * set of purchases (contract terms, applied refunds, ...)

(Some of these might be further split up to allow more efficient updates.)

Entities that are **not** synchronized are:

* purchases before the corresponding order has been claimed
* withdrawal operations before they have been accepted by the user

Entities that **could** be synchronized (to be decided):
 
* private keys of other sync accounts
* coin planchets
* tips before the corresponding coins have been withdrawn
* refresh sessions (not only the "meta data" about the operation,
  but everything)
 

Garbage collection
------------------

There are two types of garbage collection involved:

1. CRDT tombstones / other administrative data in the sync blob.  These can be deleted
   after we're sure all wallets enrolled in the sync server have a Lamport timestamp
   larger than the timestamp of the tombstone.  Wallets include their own Lamport timestamp
   in the sync blob:

   .. code:: javascript

     {
       clocks: {
         my_desktop_wallet: 5,
         my_phone_wallet: 3
       },
       ...
     }

   All tombstones / overwritten set elements with a timestamp smaller than the
   smallest clock value can be deleted.

2. Normal wallet GC.  The deletion operations resulting from the wallet garbage
   collection (i.g. deleting legally expired denomination keys, coins, exchange
   signing keys, ...) are propagated to the respective CRDT set in the sync
   blob.


Ghost Entities
--------------

Sometimes a wallet can learn about an operation that happened in another synced
wallet **before** a sync over the sync server happens.  An example of this is a
deposit operation.  When two synced wallets spend the same coin on something,
one of them will receive an error from the exchange that proves the coin has
been spent on something else.  The wallet will add a "ghost entry" for such an
event, in order to be able to show a consistent history (i.e. all numbers
adding up) to the user.

When the two wallets sync later, the ghost entry is replaced by the actual
purchase entity from the wallet that initiated the spending.

Ghost entities are not added to the sync state.


References
==========

* Shapiro, M., Preguiça, N., Baquero, C., & Zawirski, M. (2011). A
  comprehensive study of convergent and commutative replicated data types. [`PDF <https://hal.inria.fr/inria-00555588/document>`__]

Discussion / Q&A
================

* Why is backup/sync not split into two services / use-cases?

  * For privacy reasons, we can't use some interactive sync service.  Thus we
    use the backup blob as a CRDT that also synchronization for us.

* Do we synchronize the list of other backup enrollments?  How
  do we handle distributing the different private keys for them?

  * If we automatically sync the sync enrollments and the old sync account
    is compromised, the new sync account would automatically be compromised as well!

  * If every wallet had its own sync key pair, we could select which existing wallets
    to roll over as well.

* How do we handle a synced wallet that becomes malicious deleting all coins or purchased products?

  * This needs to balance the genuine need to permanently delete data.
  * Should the sync server allow to fetch previous versions of the sync blob?
  * Should the individual wallets keep tombstones (i.e. entities just marked as deleted)
    around for some time, or should they delete and "sanitize" (delete data not needed for the CRDT)
    tombstones as soon as possible?

* How are wallets identified for backup/sync?

  * UUID / EdDSA pub and nick name?  When nickname clashes,
    some number is added based on lexical sort of the random id ("phone#1", "phone#2").

* Do we have a passphrase for our backup account key(s)?

  * ???
