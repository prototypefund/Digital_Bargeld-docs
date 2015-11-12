===================================
Interaction with banks Web portals
===================================

This section describes the interactions that should occur between
a wallet and a bank which chooses to adapt its Web portal to interact
with the Taler wallet. This interaction is supposed to occur when
the user is sending a SEPA transfer to some mint (i.e. he is creating
a new reserve).

   .. note::
     For its being in early stage of development, the following protocol is
     implemented inside the mint code, through a ad-hoc website.

Through this interaction, the wallet can generate a new reserve's public
key and insert it into the 'subject' field of the transfer without manual
copy&paste. Secondly, the wallet is then able to fetch the amount to be
tranferred to the mint directly from the Web form, in order to poll the mint
to check if the desired amount has been transferred.

----------------------
Mutual acknowledgement
----------------------

The mutual acknowledgement between a wallet and a bank portal occurs when
the user is on the page which hosts the SEPA form, and is realized by the
mean of JavaScript signals issued on the `body` HTML element.

When the bank wants to notify to a wallet, it sends the following event:

  .. js:data:: taler-wire-probe

This event must be sent from a callback for the `onload` event of the
`body` element, otherwise the extension would have not time to
register a listener for this event.  It also needs to be sent when
the Taler extension is dynamically loaded, like when the user activates
the extension while he is on the SEPA form page.  This is done by
listening for the

  .. js:data:: taler-load

event.  If the Taler extension is present, it will respond with a

  .. js:data:: taler-wallet-present

event.  The handler should then activate its mechanism to trigger the generation
of a new reserve key in the wallet, for example by updating the DOM to enable a
dedicated button.

If the Taler extension is unloaded while the user is visiting a SEPA form page,
the page should listen for a

  .. js:data:: taler-unload

event, in order to hide the previously enabled button.

-------------------------
How to trigger the wallet
-------------------------

This interaction will make the wallet generate a new reserve public key as
well as paste this information inside the SEPA form. Lastly, it allows the
wallet to fetch the desired amount to be transferred to the mint from the
SEPA form. Typically, it is initiated by the user pushing a button.

The wallet listens to a 

  .. js:data:: taler-create-reserve

event, through which it expects to receive the following object:

.. sourcecode:: javascript
  {input_amount: input-amount-id,
   input_pub: input-pub-id}

`input-amount-id` is the `id` attribute of the HTML `input` element which
hosts the amount to wire to the desired mint. Please note that the wallet will
only accept amounts of the form `n[.x[y]] CUR`, where `CUR` is the ISO code
of the specified currency. So it may be necessary for the bank's webmaster to
preprocess this data to give it to the wallet in the right format. The wallet
will fetch this element through the following event, triggere by the `onsubmit`
attribute:

  .. js:data:: reserve-submitted

`input-pub-id` must be the `id` of the `input` element which represents this
SEPA transfer's "subject".

The following source code highlights the key steps for adding the Taler button
to trigger the wallet on a SEPA form page:

.. sourcecode:: javascript

    function has_taler_wallet_callback(aEvent){
       // This function is called if a Taler wallet is available.
       // suppose the radio button for the Taler option has
       // the DOM ID attribute 'taler-wallet-trigger'
      var tbutton = document.getElementById("taler-wallet-trigger");
      tbutton.removeAttribute("disabled");
    };

    function taler_wallet_load_callback(aEvent){
      // let the Taler wallet know that this is a SEPA form page
      // which supports Taler (the extension will have
      // missed our initial 'taler-wire-probe' from onload())
      document.body.dispatchEvent(new Event('taler-wire-probe'));
    };

    function taler_wallet_unload_callback(aEvent){
       // suppose the button which triggers the wallet has
       // the DOM ID attribute 'taler-wallet-trigger'
       var tbutton = document.getElementById("taler-wallet-trigger");
       tbutton.setAttribute("disabled", "true");
    };

.. sourcecode:: html

   <body onload="function(){
        // First, we set up the listener to be called if a wallet is present.
        document.body.addEventListener("taler-wallet-present", has_taler_wallet_callback, false);
        // Detect if a wallet is dynamically added (rarely needed)
        document.body.addEventListener("taler-load", taler_wallet_load_callback, false);
        // Detect if a wallet is dynamically removed (rarely needed)
        document.body.addEventListener("taler-unload", taler_wallet_unload_callback, false);
        // Finally, signal the wallet that this is a payment page.
        document.body.dispatchEvent(new Event('taler-wire-probe'));
      };">
     ...
   </body>

Finally, the following snippet shows how to trigger the wallet to make it
fetch the amount from the DOM

.. sourcecode:: html

  <form .. action=/bank_sepa.php .. onsubmit="signal_reserve()">
  ..
  </form>

  <script type="text/javascript">
  ..
  function signal_reserve(){
    var reserve_submitted = new Event("reserve-submitted");
    document.body.dispatchEvent(reserve_submitted);
  }

  </script>
