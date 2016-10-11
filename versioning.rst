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

==================
GNU Taler Versions
==================

This text describes how we assign version numbers for Taler software.
This is about the version numbers of package releases, not of the
libraries. For Taler libraries, we use libtool semantic versioning
conventions.

Taler software release version numbers use the scheme
MAJOR.MINOR-PACKAGE.

Here, MAJOR is used to indicate the compatibility level and is
increased for all significant releases that are always made across all
Taler components.

The MINOR numbers is used for small updates that may address minor
issues but do not break compatibility.  MINOR release may be made only
for a particular component, leaving other components untouched.  Hence
you should expect to see say an exchange version 4.5 and a wallet
version 4.10.  As they both start with "4", they are expected to be
protocol-compatible.

PACKAGE is reserved for distributions, such as Debian.  These distributions
may apply their own patch sets or scripting, and they are expected to
increment PACKAGE.  The upstream Taler releases will just be of the
format MAJOR.MINOR.

-----------------------
Alpha and Beta releases
-----------------------

Before Taler is considered reasonably stable for actual use, we will
prefix the number "0." to the release version.  Thus, all alpha and
beta releases will have a three-digit release number of the form
"0.MAJOR.MINOR".

-----------------------
Roadmap
-----------------------

A roadmap with the features we plan to have in each release is
in our bugtracker at https://gnunet.org/bugs/.  The roadmap
is subject to change.
