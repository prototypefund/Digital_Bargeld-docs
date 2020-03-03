..
  This file is part of GNU TALER.
  Copyright (C) 2014-2018 Taler Systems SA

  TALER is free software; you can redistribute it and/or modify it under the
  terms of the GNU General Public License as published by the Free Software
  Foundation; either version 2.1, or (at your option) any later version.

  TALER is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
  A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License along with
  TALER; see the file COPYING.  If not, see <http://www.gnu.org/licenses/>

  @author Torsten Grote

GNU Taler Merchant POS Manual
#############################

The GNU Taler merchant POS (point of sale) terminal allows sellers to

* process customers' orders by adding or removing products
* calculate the amount owed by the customer
* let the customer make a Taler payment via QR code or NFC

Android App
===========

.. note::
    The Android app is currently optimized for tablet devices, not phones.

At first start, the Android app asks you for a configuration URL
and a user name as well as a password for HTTP basic authentication.

At every start of the app,
it uses the saved configuration data
to fetch the current configuration (defined below)
and populates the currency, the products and their categories.

The Tabled UI is separated into three columns:

* Right: Product categories that the user can select to show different products
* Middle: Products available in the selected category and their prices
* Left: The current order, the ordered products, their quantity and prices
  as well as the total amount.

At the bottom of the main UI there is a row of buttons:

* Restart: Clears the current order and turns into an Undo button which restores the order.
* -1/+1: Available when ordered items are selected
  and allows you to increment/decrement their quantity.
* Reconfigure: Allows you to change the app configuration settings (URL and username/password)
  and to forget the password (for locking the app).
* History: Shows the payment history.
* Complete: Finalize an order and prompt the customer to pay.

Testing nightly builds
----------------------

Every change to the app's source code triggers an automatic build
that gets published in a F-Droid repository.
If you don't have it already, download the `F-Droid app <https://f-droid.org/>`_
and then click the following link (on your phone) to add the nightly repository.

    `GNU Taler Nightly F-Droid Repository <fdroidrepos://gnu-taler.gitlab.io/fdroid-repo-nightly/fdroid/repo?fingerprint=55F8A24F97FAB7B0960016AF393B7E57E7A0B13C2D2D36BAC50E1205923A7843>`_

.. note::
    Nightly apps can be installed alongside official releases
    and thus are meant **only for testing purposes**.
    Use at your own risk!

Building from source
--------------------

Import in and build with Android Studio or run on the command line:

.. code-block:: sh

  $ git clone https://git.taler.net/merchant-terminal-android.git
  $ cd merchant-terminal-android
  $ ./gradlew assembleRelease

APIs and Data Formats
=====================

The GNU Taler merchant POS configuration is a single JSON file with the following structure.


  .. ts:def:: MerchantConfiguration

    interface MerchantConfiguration {
      // Configuration for how to connect to the backend instance.
      config: BackendConfiguration;

      // The available product categories
      categories: MerchantCategory[];

      // Products offered by the merchant (similar to `Product`).
      products: MerchantProduct[];

      // Map from labels to locations
      locations: { [label: string]: [location: Location], ... };
    }

The elements of the JSON file are defined as follows:

  .. ts:def:: BackendConfiguration

    interface BackendConfiguration {
      // The URL to the Taler Merchant Backend
      base_url: string;

      // The name of backend instance to be used (see `Backend Options <Backend-options>`)
      instance: string;

      // The API key used for authentication
      api_key: string;
    }

  .. ts:def:: MerchantCategory

    interface MerchantCategory {
      // A unique numeric ID of the category
      id: number;

      // The name of the category. This will be shown to users and used in the order summary.
      name: string;

      // Map from IETF BCP 47 language tags to localized names
      name_i18n?: { [lang_tag: string]: string };
    }


  .. ts:def:: MerchantProduct

    interface MerchantProduct {
      // A merchant-internal unique identifier for the product
      product_id: string;

      // Human-readable product description
      // that will be shown to the user and used in contract terms
      description: string;

      // Map from IETF BCP 47 language tags to localized descriptions
      description_i18n?: { [lang_tag: string]: string };

      // The price of the product
      price: Amount;

      // A list of category IDs this product belongs to.
      // Typically, a product only belongs to one category, but more than one is supported.
      categories: number[];

      // Where to deliver this product. This may be an URL for online delivery
      // (i.e. 'http://example.com/download' or 'mailto:customer@example.com'),
      // or a location label defined inside the configuration's 'locations'.
      delivery_location: string;
    }
