EBICS Implementation Notes
##########################

.. warning::

  This document summarizes and clarifies some aspects of the EBICS protocol
  that are important to LibEuFin.  Both version 3.0 and 2.5 are discussed here.

  It is not a specification, and it does not replace the official EBICS specification.

.. contents:: Table of Contents

EBICS Glossary
==============

.. glossary::
  :sorted:

  A004
    Electronic signature process, used in H004, deprecated in H005 with EBICS 3.0.

  A005
    Electronic signature process.  Used in H004 and H005.

  A006
    Electronic signature process.  Used in H004 and H005.

  BTF
    *Business Transaction Formats.*  Before EBICS 3.0, many different order types were
    used for business-related messages.  With EBICS 3.0, the more generic BTU and BTD
    order types are used for all business-related messages.

  EBICS
    The *Electronic Banking Internet Communication Standard*.

  ES
    Electronic Signature.  This abbreviation is commonly used in the context of EBICS.

    The following signature classes are defined (in descending order from
    strongest to weakest):

    E
      Single signature (German "Einzeln").
    A
      First signature.
    B
      Second signature.
    T
      Transport signature.  Only used to verify authorized submission,
      but not to verify the bank-technical authorization.

    In H004 and H005, the ES of the bank is specified as a "planned feature" that
    is not actually implemented yet.  Thus banks in practice only use their
    encryption key pair and authentication/identity key pair.

  EDS
    Distributed Electronic Signature.  Allows multiple subscribers to authorize an existing order.

  FTAM
    Historical predecessor protocol to EBICS (*file transfer, access and management*).
   
  HEV
    The *Host EBICS Version*.  Queried by the client with an HEV request message.

  Human Subscriber

   See :term:`Subscriber`. 

  H004
    Host protocol version 4.  Refers to the XML Schema defined in *EBICS 2.5*.

  H005
    Host protocol version 5.  Refers to the XML Schema defined in *EBICS 3.0*.

  Host ID
    Alphanumeric identifier for the EBICS Host.  One EBICS server can
    host multiple banks, and each bank is identified by the Host ID.
    This concept is similar to Taler's merchant backend instance identifiers.

  Order Number
    Interchangably called "Order ID".

    Each upload transaction gets a unique order number assigned by the bank server.
    The Order Number is used to match VEUs in a second upload to the original order.
    An Order Number matches the format "[A-Z][A-Z0-9]{3}" (and is not really a number!).

    Must be unique per customer ID and per order type

  Transaction ID
    A transaction ID is a 128-bit cryptographically strong random number.
    It is assigned by the bank server for every transaction, i.e. upload or download
    of an order.

    The transaction ID must not be guessable, as it would allow a potential
    attacker to upload segments of an upload that do not match the whole message's digest.

  Transaction key
    Symmetric encryption key for the data uploaded/downloaded in a transaction.

  Partner ID
    In German, this is called "Kunden ID" (= Customer ID).
    One partner can have multiple "participants", which are identified by user IDs.
    
    Practical example:  A company has one Partner ID.  Each person at the company
    that can access the company's bank accounts gets their own User ID.
    When the person is indirectly accessing the bank server (for example via
    a client server application), an additional "System ID" is created for this
    "technical subscriber".  When there is no technical subscriber, the System ID
    must be the same as the User ID.  Usually the System ID is optional though.

    The ``(partner, user, system)`` triple uniquely identifies a subscriber.

  User ID
    See :term:`Partner ID`.

  System ID
    See :term:`Partner ID`.

  ISO 20022
    *ISO 20022: Financial Services - Universal financial industry message scheme*.  Rather important
    standard for financial industry **business-related** messages.  In contrast, EBICS takes
    care of message transmission, segmentation, authentication, key management, etc.

    The full catalogue of messages is `available gratis <https://www.iso20022.org/full_catalogue.page>`_.

  UNIFI
    UNIversal Financial Industry message scheme.  Sometimes used to refer to
    :term:`ISO 20022`.

  Segmentation
    EBICS implements its own protocol-level segmentation of business-related messages.
    The segmentation can be seen as an alternative to the HTTP facilities of ``Accept-Ranges``.

    The order data of an ebics message may not exceed 1 MB.  The segmentation applies both
    to requests and responses.

  Subscriber
    Entity that wishes to communicate with the financial institution via EBICS.

    Subscribers can be *technical* or *human*.  Technical subscribers are typically
    a server in client-server applications, where the server talks to a financial institution
    via EBICS.

    Requests from technical subscribers have a ``SystemID`` in addition to a ``PartnerID``
    and ``UserId``.  A technical subscriber cannot sign a bank-technical request.

  Technical Subscriber
   See :term:`Subscriber`. 

  TLS
    *Transport Layer Security*.  All messages in EBICS are sent over HTTP with TLS.
    In the current version of the standard, only server certificates are required.

  VEU
    Distributed Electronic Signature (from German "Verteilte Elektronische Unterschrift").

  V001
    FTAM encryption algorithm ("Verschlüsselung"), superseeded in EBICS by E002.

  X002
    Identification and authentication signature in H004 and H005.


Order Types
===========

By convention, order types beginning with "H" are administrative order types, and other ones are
bank-technical order types.  This convention isn't always followed consistently by EBICS.

Relevant Order Types
--------------------

.. ebics:orders::
  :sorted:

  BTD
    **Only EBICS3.0+**. Business Transaction Format Download.
    Administrative order type to download a file, described in more detail by the BTF structure

  BTU
    **Only EBICS3.0+**. Business Transaction Format Upload.
    Administrative order type to upload a file, described in more detail by the BTF structure

  C52
    **Before EBICS 3.0**.  Download bank-to-customer account report (intra-day information).

  C53
    **Before EBICS 3.0**.  Download bank-to-customer statement report (prior day bank statement).

  CRZ
    Type: Download.

    Fetch payment status report (pain.002)

  CCC
    Type: Upload.

    Send SEPA Credit Transfer Initiation (pain.001) via XML container.
    This is the DFÜ variant (Appendix 3 DFÜ-Agreement)

  CCT
    Type: Upload.

    Send SEPA Credit Transfer Initiation (pain.001) directly.
    This is the DFÜ variant (Appendix 3 DFÜ-Agreement)

  CIZ
    Type: Download.

    Payment Status Report for Credit Transfer Instant.

  FUL
    **Before EBICS 3.0, France**.  File Upload.  Mainly used by France-style EBICS.

  FDL
    **Before EBICS 3.0, France**.  File Download.  Mainly used by France-style EBICS.

  HIA
    Transmission of the subscriber keys for (1) identification and authentication and (2)
    encryption within the framework of subscriber initialisation.

  HPB
    Query the three RSA keys of the financial institute.

  HPD
    Host Parameter Data.  Used to query the capabilities of the financial institution.

  INI
    Transmission of the subscriber keys for bank-technical electronic signatures.

  HAC
    Customer acknowledgement.  Allows downloading a detailed "log" of the activities
    done via EBICS, in the pain.002 XML format.

  HCS
    Change keys without having to send a new INI/HIA letter.

  SPR
    Suspend a subscriber.  Used when a key compromise is suspected.

  HCS
    Change the subscribers keys (``K_SIG``, ``K_IA`` and ``K_ENC``).

Other Order Types
-----------------

The following order types are, for now, not relevant for LibEuFin:


.. ebics:orders::
  :sorted:

  AZV
    Type: Upload.

    From German "Auslandszahlungsverkehr".  Used to submit
    cross-border payments in a legacy format.

  CDZ
    Type: Download.

    Download payment status report for direct debit.

  CCU
    Type: Upload.

    German "Eilüberweisung".

  H3K
    Type: Upload.

    Send all three RSA key pairs for initialization at once, accompanied
    by a CA certificate for the keys.  This is (as far as we know) used in France,
    but not used by any German banks.  When initializing a subscriber with H3K,
    no INI and HIA letters are required.

  HVE
    Type: Upload.

    Host Verification of Electronic Signature.  Used to submit an electronic signature separately
    from a previously uploaded order.

  HVD
    Type: Download.

    Retrieve VEU state.

  HVU
    Type: Download.

    Retrieve VEU overview.

  HVS
    Type: Upload.

    Cancel Previous Order (from German "Storno").  Used to submit an electronic signature separately
    from a previously uploaded order.

  HSA
    Order to migrate from FTAM to EBICS.  **Removed in EBICS 3.0**.

  PUB
    Type: Upload.

    Change of the bank-technical key (``K_SIG``).
    Superseeded by HSA.

  HCA
    Type: Upload.

    Change the identification and authentication key as well as the encryption key (``K_IA`` and ``K_ENC``).
    Superseeded by HCS.

  PTK
    Type: Download.

    Download a human-readable protocol of operations done via EBICS.
    Mandatory for German banks.  Superseeded by the machine-readable
    HAC order type.



Formats
=======

ISO 20022
---------

ISO 20022 is XML-based and defines message format for many finance-related activities.

ISO 20022 messages are identified by a message identifier in the following format:

  <business area> . <message identifier> . <variant> . <version>

Some financial instututions (such as the Deutsche Kreditwirtschaft) may decided to use
a subset of elements/attributes in a message, this is what the ``<variant>`` part is for.
"Standard" ISO20022 have variant ``001``.

The most important message types for LibEuFin are:

camt - Cash Management
  Particularly camt.053 (BankToCustomerStatement)

pain - Payment Initiation
  Particularly pain.001 (CustomerCreditTransferInitiation) to initiate a payment and
  pain.002 (CustomerPaymentStatus) to get the status of a payment.


SWIFT Proprietary
=================

SWIFT Proprietary messages are in a custom textual format.
The relevant messages are MT940 and MT942

* MT940 contains *pre-advice*, in the sense that transactions in it might still
  change or be reversed
* MT942 contains the settled transactions by the end of the day

SWIFT will eventually transition from MT messages to ISO20022,
but some banks might still only give us account statements in the old
SWIFT format.

  

Key Management
==============

RSA key pairs are used for three purposes:

1. Authorization of requests by signing the order data.  Called the *bank-technical key pair*,
   abbreviated here as ``K_SIG``.
2. Identification/authentication of the subscriber.  Called the *identification and authentication key pair*,
   abbreviated here as ``K_IA``.
3. Decryption of the symmetric key used to decrypt the bank's response.  Called the *encryption key pair*,
   abbreviated here as ``K_ENC``.

One subscriber *may* use three different key pairs for these purposes.
The identification and authentication key pair may be the same as the encryption key pair.
The bank-technical key pair may not be used for any other purpose..


Real-time Transactions
======================

Real-time transactions will be supported with EBICS starting November 2019.
That's the earliest date, some banks may offer it later or not at all.

For us, :ebics:order:`CIZ` is the relevant order type that we need to ask banks
for.


Payment Reversal
================

It looks like there is no way to "reject" payments, unless you are the bank.

There is a concept of payment reversal (with ``pain.007`` for direct debit and ``camt.055`` for SEPA Credit Transfer),
but they are a way for the *payer / sender* to reverse a payment before it is finalized.


Bank Support
============

All German banks that are part of the Deutsche Kreditwirtschaft *must* support EBICS.

The exact subset of EBICS order types must be agreed on contractually by the bank and customer.
The following subsections list the message types that we know are supported by particular banks.

GLS Bank
--------

According to publicly available `forms
<https://www.gls-laden.de/media/pdf/f1/c6/f2/nderungsauftrag.pdf>`_, GLS Bank
supports the following order types:

* :ebics:order:`AZV`
* :ebics:order:`PTK`
* :ebics:order:`CDZ`
* :ebics:order:`CRZ`
* :ebics:order:`CCC`
* :ebics:order:`CCT`
* :ebics:order:`CCU`
* :ebics:order:`HVE`
* :ebics:order:`HVS`
* ... and mandatory administrative messages

Sparkasse München
-----------------

See `this document <https://www.sskm.de/content/dam/myif/ssk-muenchen/work/dokumente/pdf/allgemein/ebics-default-geschaeftsvorfaelle.pdf>`__.


HypoVereinsbank
---------------

See `this document <https://www.hypovereinsbank.de/content/dam/hypovereinsbank/shared/pdf/Auftragsarten_Internet_Nov2018_181118.pdf>`__.

Standards and Resources
=======================

EBICS
-----

The EBICS standard documents are available at `<http://www.ebics.org>`_.

EBICS 3.0:

* The main EBICS 3.0 specification
  (``2017-03-29-EBICS_V_3.0-FinalVersion.pdf``).
* Annex 1 specifies EBICS return codes, as EBICS doesn't use HTTP status codes directly
  (``2017-03-29-EBICS_V_3.0_Annex1_ReturnCodes-FinalVersion.pdf``) .
* Annex BTF contains the registry of BTF codes.

DFÜ Agreement
-------------

The DFÜ Agreement is the set of standards used by the German Banking Industry Committee (Deutsche Kreditwirtschaft).

The following Annexes (also see the `DK Website <https://die-dk.de/zahlungsverkehr/electronic-banking/dfu-verfahren-ebics/>`_) are
relevant for implementing EBICS:

* Annex 1 is the EBICS specification
* (Annex 2 is deprecated)
* Annex 3 describes the data formats used by German banks within EBICS.

EBICS Compendium
----------------

The `EBICS Compendium <https://www.ppi.de/en/payments/ebics/ebics-compendium/>`_ has some additional info on EBICS.
It is published by a company that sells a proprietary EBICS server implementation.

Others
------

* `<https://wiki.windata.de/index.php?title=EBICS-Auftragsarten>`_
* `<https://www.gls-laden.de/media/pdf/f1/c6/f2/nderungsauftrag.pdf>`_


