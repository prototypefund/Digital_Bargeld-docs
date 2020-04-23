Design Doc 003: ToS rendering
#############################

Summary
=======

This document describes how terms of service (ToS) as well as other "legal
agreement documents" are served, represented and rendered.

Motivation
==========

Different exchanges and backup/sync providers each have their custom legal
agreement documents.  As we don't know all providers and they are not centrally
registered anywhere, these documents can't be hardcoded into wallet
applications.  Instead, these service providers expose endpoints that allow
downloading the latest version of these legal agreement documents.

These documents must be rendered on a variety of platforms in a user-friendly
way.

Proposed Solution
=================

The service providers can output legal agreements in various formats,
determined via the ``"Accept: "`` request header.  The format provider **must**
support the ``text/plain`` mime type.  The format provider **must** support
the ``text/markdown`` mime type.  Except for styling and navigation, the
content of each format of the same legal agreement document **should** be the
same.

Legal documents with mime type ``text/markdown`` **should** confirm to the
`commonmark specification <https://commonmark.org/>`__.

When wallets render ``text/markdown`` legal documents, they **must** disable
embedded HTML rendering.  Wallets **may** style the markdown rendering to improve
usability.  For example, they can make sections collabsible or add a nagivation side-bar
on bigger screens.

It is recommended that the ``text/markdown`` document is used as the "master
document" for generating the corresponding legal agreement document in other
formats.  However, service providers can also provide custom versions with more
appropriate styling, like a logo in the header of a printable PDF document.

Alternatives
============

We considered and rejected the following alternatives:

* Use only plain text.  This is not user-friendly, as inline formatting (bold,
  italic), styled section headers, paragraphs wrapped to the screen size,
  formatted lists and tables are not supported.

* Use HTML.  This has a variety of issues:

  * Service providers might provide HTML that does not render nicely on the
    device that our wallet application is running on.
  * Rendering HTML inside the application poses security risks.

* Use a strict subset of HTML.  This would mean we would have to define some
  standardized subset that all wallet implementations support, which is too
  much work.  Existing HTML renderers (such as Android's ``Html.fromHTML``)
  support undocumented subsets that lack features we want, such as ordered
  lists.  Defining our own HTML subset would also make authoring harder, as it
  forces authors of legal agreement documents to author in our HTML subset, as
  conversion tools from other format will not generate output in our HTML
  subset.

* Use reStructuredText (directly or via Sphinx).  This at first looks like an
  obvious choice for a master format, since Taler is already using reStructuredText
  for all its documentation.  But it doesn't work out well, since the only maintained
  implementation of a parser/renderer is written in Python.  Even with the Python implementation
  (docutils / Sphinx), we can't convert ``.rst`` to Markdown nicely.

Drawbacks
=========

* Markdown parsing / rendering libraries can be relatively large.

Discussion / Q&A
================

* Should the legal agreement endpoints have some mechanism to determine what
  content types they support?
