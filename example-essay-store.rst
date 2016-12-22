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

The frontend shows a list of buyable articles in its homepage, and once the
user clicks one of them, they will either get the Taler :ref:`contract <contract>`
or a credit card paywall if they don't have the Taler wallet.

Each article thus links to a `offer URL`, whose layout is shown below.

  `https://shop.demo.taler.net/essay/Appendix_A:_A_Note_on_Software`

Once the server side logic receives a request for a offer URL, it needs to
instruct the browser to retrieve a Taler contract.  This action can be taken
either with or without JavaScript, see the next section.

-----------------------
Triggering the contract
-----------------------

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

-----------------
Fulfillment logic
-----------------

The state accounts for a product being paid or not, so the fulfillment handler
will firstly check that:

.. sourcecode:: python

  def article(name, data=None):
      # Get list of payed articles from the state
      payed_articles = session.get("payed_articles", [])

      if name in payed_articles:
          ...
          # This statement ends the successful case.
          return send_file(get_article_file(article))
      ...

In case the article has not been paid yet, the fulfillment handler needs
to `reconstruct` the contract, in order to get a precise reference about the
purchase in progress.

All the information needed to reconstruct the contract is contained in the
fulfillment URL parameters; the URL layout is as follows:

  `https://shop.demo.taler.net/essay/Appendix_A:_A_Note_on_Software?uuid=<CONTRACT-HASHCODE>&timestamp=<TIMESTAMP>tid=<TRANSACTION_ID>`

The way the contract is reconstructed is exactly the same as it was generated
in the previous steps:  we need to call ``make_contract`` to get the original
:ref:`proposition <proposition>` and then ``sign_contract``.  Recall that aside
from allowing the backend to add missing fields to the proposition, ``sign_contract``
returns the contract hashcode also, that we should compare with the ``uuid``
parameter given by the wallet as a URL parameter.

In our blog, all the fulfillment logic is implemented in the function ``article``,
defined in ``talerfrontends/blog/blog.py``.  It is important to note that this
function is `the same` function that runs the offer URL; in fact, as long as your
URL design allows it, it is not mandatory to split up things.  In our example, the
offer URL differs from the fulfillment URL respect to the number (and type) of
parameters, so the ``article`` function can easily decide whether it has to handle
a "offer" or a "fulfillment" case.  See below how the function detects the right
case and reconstruct the contract.

.. sourcecode:: python

  ...
  hc = request.args.get("uuid")
  tid_str = request.args.get("tid")
  timestamp_str = request.args.get("timestamp")
  if hc is None or tid_str is None or timestamp_str is None:
      contract_url = make_url("/generate-contract", ("article_name",name))
      ... # Go on operating the offer URL and return

  # Operate fulfillment URL
  try:
      tid = int(tid_str)
  except ValueError:
      raise MalformedParameterError("tid")
  try:
      timestamp = int(timestamp_str)
  except ValueError:
      raise MalformedParameterError("timestamp")

  # 'name' is the article name, and is set to the right value by Flask
  restored_contract = make_contract(article_name=name, tid=tid, timestamp=timestamp)
  contract_resp = sign_contract(restored_contract)

  # Return error if uuid mismatch with the hashcode coming from the backend
  if contract_resp["H_contract"] != hc:
      e = jsonify(error="contract mismatch", was=hc, expected=contract_resp["H_contract"])
      return e, 400

   # We save the article's name in the state since after
   # receiving the payment this value will point to the
   # article to be delivered to the customer.  Note how the
   # contract's hashcode is used to index the state.
   session[hc] = si = session.get(hc, {})
   si['article_name'] = name


After a successful contract reconstruction, the handler needs to instruct
the wallet to actually send the payment.  There are as usual two ways this
can be accomplished: with and without JavaScript.

**With JavaScript**

..
  Mention that the template is the same we used for a offer URL!

We return a HTML page, whose template is in
``talerfrontends/blog/templates/purchase.html``, that imports ``taler-wallet-lib.js``,
so that the function ``taler.executePayment()`` can be invoked into the user's
browser.

The fulfillment handler needs to render ``purchase.html`` so that the right
parameters get passed to ``taler.executePayment()``.

See below how the function ``article`` does the rendering.

.. sourcecode:: python

  return render_template('templates/purchase.html',
                         hc=hc,
                         pay_url=quote(pay_url),
                         offering_url=quote(offering_url),
                         article_name=name,
                         no_contract=0,
                         data_attribute="data-taler-executecontract=%s,%s,%s" % (hc, pay_url, offering_url))

After the rendering, (part of) ``purchase.html`` will look like shown below.

.. sourcecode:: html

  ...
  <script src="/static/web-common/taler-wallet-lib.js" type="application/javascript"></script>
  <script src="/static/purchase.js" type="application/javascript"></script>
  ...
  <meta name="pay_url" value="https://shop.demo.taler.net/pay">
  <meta name="offering_url" value="https://shop.demo.taler.net/essay/Appendix_A:_A_Note_on_Software">
  <!-- Fake hashcode -->
  <meta name="hc" value="D7D5HDJRP36GTBBRGHXP7204VR773HHQBNFFCY5YY4P18026PAJ0">

  ...
  ...

  <div id="ccfakeform" class="fade">
    <p>
    Oops, it looks like you don't have a Taler wallet installed.  Why don't you enter
    all your credit card details before reading the article? <em>You can also
    use GNU Taler to complete the purchase at any time.</em>
    </p>
  
    <form>
      <!-- Credit card pay form. -->
    </form>
  </div>
  
  <div id="talerwait">
    <em>Processing payment with GNU Taler, please wait <span id="action-indicator"></span></em>
  </div>
  ...

The script ``purchase.js`` is now in charge of calling ``taler.executePayment()``.
It will try to register two handlers: one called whenever the wallet is detected in the
browser, the other if the user has no wallet installed.

That is done with:

.. sourcecode:: javascript

  taler.onPresent(handleWalletPresent);
  taler.onAbsent(handleWalletAbsent);

.. note::
  
  So far, the template and script code are exactly the same as the offer URL case,
  since we use them for both cases:  see below how the script distinguishes offer
  from fulfillment case.

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
needed parameters from the responsible ``meta`` tags, and finally invoke
``taler.offerContractFrom()`` using those parameters.  See below its whole definition.
Note, that since we are in the fulfillment case, the credit card pay form is `almost`
useless, as it is highly unlikely that the wallet is not installed.

.. sourcecode:: javascript

  function handleWalletPresent() {
    document.getElementById("ccfakeform").style.display = "none";
    document.getElementById("talerwait").style.display = "";

    // The `no_contract` value is provided by the function `article` via a
    // 'meta' tag in the template.  When this value equals 1, then we are in the
    // "offer URL" case, otherwise we are in the "fulfillment URL" case.
    let no_contract = document.querySelectorAll("[name=no_contract]")[0];
    if (Number(no_contract.getAttribute("value"))) {
      let contract_url = document.querySelectorAll("[name=contract_url]")[0];
      taler.offerContractFrom(decodeURIComponent(contract_url.getAttribute("value")));
    }
    else {
      // Fulfillment case.
      let hc = document.querySelectorAll("[name=hc]")[0];
      let pay_url = document.querySelectorAll("[name=pay_url]")[0];
      let offering_url = document.querySelectorAll("[name=offering_url]")[0];
      taler.executePayment(hc.getAttribute("value"),
                           decodeURIComponent(pay_url.getAttribute("value")),
                           decodeURIComponent(offering_url.getAttribute("value")));
    }
  }

Once the browser executes ``taler.executePayment()``, the wallet will send the coins
to ``pay_url``.  Once the payment succeeds, the wallet will again visits the
fulfillment URL, this time getting the article thanks to the "payed" status set by
the ``pay_url`` handler.

**Without JavaScript**

This case is handled by the function ``article`` defined in
``talerfrontends/blog/blog.py``.  Its objective is to set the "402 Payment
Required" HTTP status code, along with the HTTP headers ``X-Taler-Contract-Hash``,
``X-Taler-Pay-Url``, and ``X-Taler-Offer-Url``.

..
  FIXME:
  Are those three parameters anywhere, at least 'kindof' introduced?

Upon returning such a response, the wallet will automatically send the
payment to the URL indicated in ``X-Taler-Pay-Url``.

The excerpt below shows how the function ``article`` prepares and returns such a
response.

.. sourcecode:: python

  response = make_response(render_template('templates/fallback.html'), 402)
  response.headers["X-Taler-Contract-Hash"] = hc
  response.headers["X-Taler-Pay-Url"] = pay_url
  response.headers["X-Taler-Offer-Url"] = offering_url
  return response

The template ``fallback.html`` contains the credit card pay form, which will be
used in the rare case where the wallet would not be detected in a fulfillment
session.  Once the payment succeeds, the wallet will again visits the
fulfillment URL, this time getting the article thanks to the "payed" status set by
the ``pay_url`` handler.

---------
Pay logic
---------

The pay handler for the blog is implemented by the function
``pay`` at ``talerfrontends/blog/blog.py``.  Its main duty is
to receive the :ref:`deposit permission <DepositPermission>`
from the wallet, forward it to the backend, and return the outcome
to the wallet.  See below the main steps of its implementation.

.. sourcecode:: python

  def pay():
      # Get the uploaded deposit permission
      deposit_permission = request.get_json()

      if deposit_permission is None:
          e = jsonify(error="no json in body")
          return e, 400

      # Pick the contract's hashcode from deposit permission
      hc = deposit_permission.get("H_contract")

      # Return error if no hashcode was found
      if hc is None:
          e = jsonify(error="malformed deposit permission", hint="H_contract missing")
          return e, 400

      # Get a handle to the state for this contract, using the
      # hashcode from deposit permission as the index
      si = session.get(hc)

      # If no session was found for this contract, then either it
      # expired or one of the hashcodes (the one we got from 
      # reconstructing the contract in the fulfillment handler,
      # and the one we just picked from the deposit permission)
      # is bogus.  Note how using the contract's hashcode as index
      # makes harder for the wallet to use different hashcodes
      # in different steps of the protocol.
      if si is None:
          e = jsonify(error="no session for contract")
          return e, 400 

      # Forward the deposit permission to the backend
      r = requests.post(urljoin(BACKEND_URL, 'pay'), json=deposit_permission)

      # Return error if the backend returned a HTTP status code
      # other than 200 OK
      if 200 != r.status_code:
          raise BackendError(r.status_code, r.text)

      # The payment went through.  Now set the state as "payed"
      # and return 200 OK.
      ...

      # Resume the article name
      article = si["article_name"]

      # We keep a *list* of articles the customer can currently
      # read
      payed_articles = session["payed_articles"] = session.get("payed_articles", [])

      # Add the article name among the ones that were already paid
      if article not in payed_articles:
          payed_articles.append(article)

      ...

      # Return success
      return r.text, 200
