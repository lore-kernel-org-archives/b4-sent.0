From: Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
Date: Fri, 23 Oct 2026 12:15:28 +0000
Subject: [PATCH 2/2] usb: gadget: f_ecm: do not notify from ecm_set_alt()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-ncm-ecm-lpm-v1-2-d01e81fbf460@leica-geosystems.com>
References: <20261023-ncm-ecm-lpm-v1-0-d01e81fbf460@leica-geosystems.com>
In-Reply-To: <20261023-ncm-ecm-lpm-v1-0-d01e81fbf460@leica-geosystems.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Neill Kapron <nkapron@google.com>, Kuen-Han Tsai <khtsai@google.com>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1818;
 i=massimo.toscanelli@leica-geosystems.com; h=from:subject:message-id;
 bh=1yFrqwzUswmQN5891X/izJlFIQr+YSlAI0VR6/27q08=;
 b=owGbwMvMwCVmIB2leGXyl1LG02pJDFm3/f/Pydxz17jQRNTtduXz3IyTfUeOfP59eevrLd6vf
 1fNDz3U31HKwiDGxSArpshybUv49wjb3LAdWV2rYOawMoEMYeDiFICJvH/NyLCy6dZu0dfezYLc
 J00Tf71ce7M1/P2ueXd/Wm79tvliS8Y2hv9JXBHvSpS5ghvvyO87+2XjDCXRFnO5tbI1gcG7TlW
 tecEHAA==
X-Developer-Key: i=massimo.toscanelli@leica-geosystems.com; a=openpgp;
 fpr=D6B457F7583D6D56B86A8AAA301B5A21D493F475
X-Endpoint-Received: by B4 Relay for massimo.toscanelli@leica-geosystems.com/default with auth_id=1289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ecm_set_alt() calls ecm_notify() for both altsettings of the data
interface. So a notification is already queued at SET_CONFIGURATION,
when altsetting 0 is selected, and it waits until the host reads the
interrupt endpoint.

The USB 2.0 LPM ECN (section 2.2.2) lets a device answer NYET to an LPM
request when it has data pending for the host, and DWC3 does so. So
when the host loads no class driver, the device never enters L1.

For altsetting 1 the call is not needed: gether_connect() already
calls ecm_open() or ecm_close(), and both notify. The extra call only
restarts the sequence while the first notification is in flight, so
the host gets two connection notifications before the speed one. The
removed comment calls this a minor disagreement with the ECM spec.

Remove the call and the comment.

Fixes: da741b8c56d6 ("usb ethernet gadget: split CDC Ethernet function")
Signed-off-by: Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
---
 drivers/usb/gadget/function/f_ecm.c | 8 --------
 1 file changed, 8 deletions(-)

diff --git a/drivers/usb/gadget/function/f_ecm.c b/drivers/usb/gadget/function/f_ecm.c
index e495bac4efe..c8c3a7d1c80 100644
--- a/drivers/usb/gadget/function/f_ecm.c
+++ b/drivers/usb/gadget/function/f_ecm.c
@@ -581,14 +581,6 @@ static int ecm_set_alt(struct usb_function *f, unsigned intf, unsigned alt)
 			if (IS_ERR(net))
 				return PTR_ERR(net);
 		}
-
-		/* NOTE this can be a minor disagreement with the ECM spec,
-		 * which says speed notifications will "always" follow
-		 * connection notifications.  But we allow one connect to
-		 * follow another (if the first is in flight), and instead
-		 * just guarantee that a speed notification is always sent.
-		 */
-		ecm_notify(ecm);
 	} else
 		goto fail;
 

-- 
2.43.0

