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

**With JavaScript**

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

Note that the ``taler`` object is exported by ``taler-wallet-lib.js``, and contains all
is needed to communicate with the wallet.


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
  JavaScript in our pages, we are forced to import any used script instead.

**Without JavaScript**

This case is handled by the function ``article`` defined in
``talerfrontends/blog/blog.py``.  Its objective is to set the "402 Payment
Required" HTTP status code, and the HTTP header ``X-Taler-Contract-Url``
to the actual contract's URL for this purchase.

Upon returning such a response, the wallet will automatically fetch the
contract from the URL indicated by ``X-Taler-Contract-Url``, and show it
to the user.

Below is shown how the function ``article`` prepares and returns such a
response.

.. sourcecode:: python

  ...
  # Create response.
  response = make_response(render_template('templates/fallback.html'), 402)
  # Set "X-Taler-Contract-Url" header to the contract's URL.
  response.headers["X-Taler-Contract-Url"] = contract_url
  return response

The ``make_response`` function is exported by Flask, so it's beyond the scope
of this document to explain it;  however, it returns a "response object" having
the "402 Payment Required" as HTTP status code, and the
HTML file ``talerfrontends/blog/templates/fallback.html`` as the body.
``fallback.html`` contains the credit card pay form, so that if the wallet is
not installed, the browser would keep that page shown.

``contract_url`` is defined in the earlier steps of the same function; however,
in this example it looks like:
``https://shop.demo.taler.net/essay/generate-contract?article_name=Appendix_A:_A_Note_on_Software``.

The next task for this frontend is generating and returning the contract.
That is accomplished by the function ``generate_contract``, defined in
``talerfrontends/blog/blog.py``.  See below.

.. sourcecode:: python

  def generate_contract():
      now = int(time.time())
      tid = random.randint(1, 2**50)
      article_name = expect_parameter("article_name")
      contract = make_contract(article_name=article_name, tid=tid, timestamp=now)
      contract_resp = sign_contract(contract)
      logger.info("generated contract: %s" % str(contract_resp))
      return jsonify(**contract_resp)


Its task is then to provide the ``make_contract`` subroutine all the
values it needs to generate a contract.  Those values are: the timestamp
for the contract, the transaction ID, and the article name; respectively,
``now``, ``tid``, and ``article_name``.

After ``make_contract`` returns, the variable ``contract`` will hold a
`dict` type that complies with a contract :ref:`proposition <proposition>`.
We then call ``sign_contract`` feeding it with the proposition, so that
it can forward it to the backend and return it signed.  Finally we return
the signed proposition, complying with the :ref:`Offer <contract>` object.

For simplicity, any article costs the same price, so no database operation
is required to create the proposition.

Both ``make_contract`` and ``sign_contract`` are defined in
``talerfrontends/blog/helpers.py``.

At this point, the user can accept the contract, which triggers the wallet
to visit the fulfillment page.  The main logic for a fulfillment page handler
is to (1) return the claimed product, if it has been paid, or (2) instruct the
wallet to send the payment.

..
  - TODO Document fulfillment URL layout.
  - Mention handler function's name.
  - Mention filename where the handler is located.
  - Say 'somehow' that this handler is the same from
    the offer URL.

The state accounts for a product being paid or not, so the fulfillment handler
will firstly check that:

.. sourcecode:: python


def article(name, data=None):
    # Get list of payed articles from the state
    payed_articles = session.get("payed_articles", [])

    if name in payed_articles:
        ...
        return send_file(get_article_file(article))






..
  Fundamental steps:
  
  - How the handler detects offer vs fulfillment.
  
  To mention:
  
  - difference between fulfillment and offer URL, although
    that pattern is not mandatory at all.
  - how few details we need to reconstruct the contract.
