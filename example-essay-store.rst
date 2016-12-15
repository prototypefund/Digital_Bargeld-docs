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

  @author Marcello Stanisci

====================
Example: Essay Store
====================

This section shows how to set up a merchant :ref:`frontend <merchant-arch>`, and is
inspired by our demonstration shop running at `https://blog.demo.taler.net/`.
It is recommended that the reader is already familiar with the
:ref:`payment protocol and terminology <payprot>`.

The code we are going to describe is available at
https://git.taler.net/merchant-frontends.git/tree/talerfrontends/blog
and is implemented in Python+Flask.

The desired effect is the homepage showing a list of buyable articles, and once the
user clicks one of them, they will either get the Taler :ref:`contract <contract>`
or a credit card paywall if they have no Taler wallet installed.

This logic is implemented in the offer URL, which shows the article name:

  `https://shop.demo.taler.net/essay/Appendix_A:_A_Note_on_Software`

Once the server side logic receives a request for a offer URL, it needs to
instruct the wallet to retrieve a Taler contract.  This action can be taken
either with or with*out* the use of JavaScript, see next two sections.

.. note::

  The code samples shown below are intentionally incomplete, as often
  one function contains logic for multiple actions.  Thus in order to not
  mix concepts form different actions under one section, parts of code not
  related to the section being documented have been left out.

+++++++++++++++
With JavaScript
+++++++++++++++

We return a HTML page, whose template is in
``talerfrontends/blog/templates/purchase.html``, that imports ``taler-wallet-lib.js``,
so that the function ``taler.offerContractFrom()`` can be invoked into the user's
browser.

The server side handler for a offer URL needs to render ``purchase.html`` by passing
the right parameters to ``taler.offerContractFrom()``.

The rendering is done by the ``article`` function at ``talerfrontends/blog/blog.py``,
and looks like the following sample.

.. sourcecode:: python

  return render_template('templates/purchase.html',
                          article_name=name,
                          no_contract=1,
                          contract_url=quote(contract_url),
                          data_attribute="data-taler-contractoffer=%s" % contract_url)

After the rendering, (part of) ``purchase.html`` will look like shown below.

.. sourcecode:: html

  ...
  <script src="/static/web-common/taler-wallet-lib.js" type="application/javascript"></script>
  <script src="/static/purchase.js" type="application/javascript"></script>
  ...
  <meta name="contract_url" value="https://shop.demo.taler.net/generate-contract?article_name=Appendix_A:_A_Note_on_Software">

  ...
  ...

  <div id="ccfakeform" class="fade">
    <p>
    Oops, it looks like you don't have a Taler wallet installed.  Why don't you enter
    all your credit card details before reading the article? <em>You can also
    use GNU Taler to complete the purchase at any time.</em>
    </p>
  
    <form>
      First name<br> <input type="text"></input><br>
      Family name<br> <input type="text"></input><br>
      Age<br> <input type="text"></input><br>
      Nationality<br> <input type="text"></input><br>
      Gender<br> <input type="radio" name"gender">Male</input>
      CC number<br> <input type="text"></input><br>
      <input type="radio" name="gender">Female</input><br>
    </form>
    <form method="get" action="/cc-payment/{{ article_name }}">
      <input type="submit"></input>
    </form>
  </div>
  
  <div id="talerwait">
    <em>Processing payment with GNU Taler, please wait <span id="action-indicator"></span></em>
  </div>
  ...

The script ``purchase.js`` is now in charge of implementing the behaviour we seek.
It needs to register two handlers: one called whenever the wallet is detected in the
browser, the other if the user has no wallet installed.

That is done with:

.. sourcecode:: javascript

  taler.onPresent(handleWalletPresent);
  taler.onAbsent(handleWalletAbsent);

.. note::

  The ``taler`` object is exported by ``taler-wallet-lib.js``, and contains all is
  needed to communicate with the wallet.


``handleWalletAbsent`` doesn't need to do much: it has to only hide the "please wait"
message and uncover the credit card pay form.  See below.

.. sourcecode:: javascript

  function handleWalletAbsent() {
    document.getElementById("talerwait").style.display = "none";
    document.body.style.display = "";
  }

On the other hand, ``handleWalletPresent`` needs to firstly hide the credit card
pay form and show the "please wait" message.  After that, it needs to fetch the
contract URL from the responsible ``meta`` tag, and finally invoke ``taler.offerContractFrom()`` using it.  See below both parts.

.. sourcecode:: javascript

  function handleWalletPresent() {
    document.getElementById("ccfakeform").style.display = "none";
    document.getElementById("talerwait").style.display = "";
    ...
    ...
      // Fetch contract URL from 'meta' tag.
      let contract_url = document.querySelectorAll("[name=contract_url]")[0];
      taler.offerContractFrom(decodeURIComponent(contract_url.getAttribute("value")));
    ...
  }

.. note::

  In order to get our code validated by W3C validators, we can't have inline
  JavaScript in our pages, but we are forced to import any used script.

++++++++++++++++++
Without JavaScript
++++++++++++++++++


..
  Fundamental steps:
  
  - How 402 HTTP headers are set in each step.
  - How OTOH JavaScript accomplishes the same.
  - How the handler detects offer vs fulfillment.
  
  To mention:
  
  - difference between fulfillment and offer URL, although
    that pattern is not mandatory at all.
  - how few details we need to reconstruct the contract.
