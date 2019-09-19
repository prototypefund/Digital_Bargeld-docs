EBICS
#####

.. warning::

  This document summarizes and clarifies some aspects of the EBICS protocol
  that are important to LibEuFin.  Both version 3.0 and 2.5 are discussed here.

  It is not a specification, and it does not replace the official EBICS specification.

EBICS Glossary
==============

.. glossary::

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

  EDS
    Distributed Electronic Signature.  Allows multiple subscribers to authorize an existing order.
   
  HEV
    The *Host EBICS Version*.  Queried by the client with an HEV request message.

  Human Subscriber

   See :term:`Subscriber`. 

  H005
    Host protocol version 5.  Refers to the XML Schema defined in *EBICS 3.0*.

  Host ID
    Alphanumeric identifier for the EBICS Host, i.e. the financial institution's EBICS server.
    Given to the EBICS client by the financial institution.

  ISO 20022
    *ISO 20022: Financial Services - Universal financial industry message scheme*.  Rather important
    standard for financial industry **business-related** messages.  In contrast, EBICS takes
    care of message transmission, segmentation, authentication, key management, etc.

    The full catalogue of messages is `available gratis <https://www.iso20022.org/full_catalogue.page>`_.

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

Order Types
===========


HPD
  Host Parameter Data.  Used to query the capabilities of the financial institution.

HVE:
  Host Verification of Electronic Signature.  Used to submit an electronic signature separately
  from a previously uploaded order.

HVS:
  Cancel Previous Order (from German "Storno").  Used to submit an electronic signature separately
  from a previously uploaded order.
