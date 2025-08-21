From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:38:58 +0000
Subject: [PATCH RFC 06/22] usb: dwc3: apple: Use synchronous role switch
 for apple
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-6-172beda182b8@kernel.org>
References: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
In-Reply-To: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2573; i=sven@kernel.org;
 h=from:subject:message-id; bh=058aqG9bEa8oe7SO+GMmVlqjGZcjvS/tEo3r4EQvouk=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy2+UC0hd+Bh823r3XcKJ8oEPnnJ3HmfjaXOV2l7ybd
 2dpspNjRykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAij7IYGfq0fz73rlgw8+zH
 w99XssXN+PqrL/+oTxr39wN3ha5FGaswMvyzSAzbEJJwf1ad3P38q6p3lrSHS6XvVD/GPOHQ5a5
 VR3gB
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Apple's dwc3 is connected to a Type-C PHY which supports multiple
protocols (USB2, 3, DisplayPort, Thunderbolt) and has to act as a Type-C
protocol mux driven by the PD prot driver (tipd). The mode and mux
transitions have to be tightly synchronized with dwc3 bringup and
shutdown.

To avoid racing PHY (re-)configuration during hotplug or role switch
events run the role switching inside dwc3 synchronously instead of
relying on a work queue on these controllers.

Signed-off-by: Hector Martin <marcan@marcan.st>
[sven: added commit description]
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/dwc3/core.c | 6 +++++-
 drivers/usb/dwc3/core.h | 3 +++
 2 files changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index 8d2dc7fa18114102cc8893c4ca0e745e16f30754..f8013ba2bdc22fa5e719df0841b12b84d9465b62 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -317,7 +317,10 @@ void dwc3_set_mode(struct dwc3 *dwc, u32 mode)
 	dwc->desired_dr_role = mode;
 	spin_unlock_irqrestore(&dwc->lock, flags);
 
-	queue_work(system_freezable_wq, &dwc->drd_work);
+	if (dwc->synchronous_drd_switch)
+		__dwc3_set_mode(&dwc->drd_work);
+	else
+		queue_work(system_freezable_wq, &dwc->drd_work);
 }
 
 u32 dwc3_core_fifo_space(struct dwc3_ep *dep, u8 type)
@@ -2274,6 +2277,7 @@ int dwc3_core_probe(const struct dwc3_probe_data *data)
 			dwc->dr_mode = USB_DR_MODE_OTG;
 			dwc->role_switch_reset_quirk = true;
 			dwc->no_early_roothub_poweroff = true;
+			dwc->synchronous_drd_switch = true;
 		}
 	}
 
diff --git a/drivers/usb/dwc3/core.h b/drivers/usb/dwc3/core.h
index 3c3a36ec37345b2f9e71444ba3b90b52dbd24443..98e748cc348dfd9de1962c93fcf9f6a6690c2388 100644
--- a/drivers/usb/dwc3/core.h
+++ b/drivers/usb/dwc3/core.h
@@ -1156,6 +1156,8 @@ struct dwc3_scratchpad_array {
  *		  before PM suspend.
  * @role_switch_reset_quirk: set to force reinitialization after any role switch
  * @no_early_roothub_poweroff: set to skip early root hub port power off
+ * @synchronous_drd_switch: set to perform role switches synchronously instead
+ *			    of using a workqueue
  * @imod_interval: set the interrupt moderation interval in 250ns
  *			increments or 0 to disable.
  * @max_cfg_eps: current max number of IN eps used across all USB configs.
@@ -1396,6 +1398,7 @@ struct dwc3 {
 
 	unsigned		role_switch_reset_quirk:1;
 	unsigned		no_early_roothub_poweroff:1;
+	unsigned		synchronous_drd_switch:1;
 
 	u16			imod_interval;
 

-- 
2.34.1

