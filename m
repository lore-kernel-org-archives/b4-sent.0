From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:38:57 +0000
Subject: [PATCH RFC 05/22] usb: dwc3: apple: Do not use host-vbus-glitches
 workaround
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-5-172beda182b8@kernel.org>
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
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2484; i=sven@kernel.org;
 h=from:subject:message-id; bh=K4xGHgVuy+gCBsZ5+L/7Ixe1BRKZmb/9H0zcphQVQWY=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy26XL+h6aXW/svSIoXp77ec99t4L5FxRE9iT+zz8Sv
 zhiwRuPjlIWBjEOBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEtgkwMvwx/5Zrkv990taN
 vudNDv9UPxd3rKY64paVQMfvQ4/PLU1l+Gd1L/hZwftLj6zC8xxPRr+ZtPYtr82Ze3sXXmI6wiC
 9XIkHAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

It results in SErrors during init presumedly because MMIO accesses fail
while certain parts are shutdown.

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/dwc3/core.c | 1 +
 drivers/usb/dwc3/core.h | 2 ++
 drivers/usb/dwc3/host.c | 5 ++++-
 3 files changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index 26aa507a738f001409a97ef563c6561433a1cac5..8d2dc7fa18114102cc8893c4ca0e745e16f30754 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -2273,6 +2273,7 @@ int dwc3_core_probe(const struct dwc3_probe_data *data)
 
 			dwc->dr_mode = USB_DR_MODE_OTG;
 			dwc->role_switch_reset_quirk = true;
+			dwc->no_early_roothub_poweroff = true;
 		}
 	}
 
diff --git a/drivers/usb/dwc3/core.h b/drivers/usb/dwc3/core.h
index 38f32f2a6193c1b2662ab4f38f4d20cf4b0e198d..3c3a36ec37345b2f9e71444ba3b90b52dbd24443 100644
--- a/drivers/usb/dwc3/core.h
+++ b/drivers/usb/dwc3/core.h
@@ -1155,6 +1155,7 @@ struct dwc3_scratchpad_array {
  * @susphy_state: state of DWC3_GUSB2PHYCFG_SUSPHY + DWC3_GUSB3PIPECTL_SUSPHY
  *		  before PM suspend.
  * @role_switch_reset_quirk: set to force reinitialization after any role switch
+ * @no_early_roothub_poweroff: set to skip early root hub port power off
  * @imod_interval: set the interrupt moderation interval in 250ns
  *			increments or 0 to disable.
  * @max_cfg_eps: current max number of IN eps used across all USB configs.
@@ -1394,6 +1395,7 @@ struct dwc3 {
 	unsigned		susphy_state:1;
 
 	unsigned		role_switch_reset_quirk:1;
+	unsigned		no_early_roothub_poweroff:1;
 
 	u16			imod_interval;
 
diff --git a/drivers/usb/dwc3/host.c b/drivers/usb/dwc3/host.c
index f7a71e6f9d80aca632f1f970d900a3de8a76f0a7..f7c3a0fc5fe258705311f89c1ba11ff599c01afe 100644
--- a/drivers/usb/dwc3/host.c
+++ b/drivers/usb/dwc3/host.c
@@ -134,8 +134,11 @@ int dwc3_host_init(struct dwc3 *dwc)
 	/*
 	 * Some platforms need to power off all Root hub ports immediately after DWC3 set to host
 	 * mode to avoid VBUS glitch happen when xhci get reset later.
+	 * On Apple platforms we must not touch any MMIO yet because dwc3
+	 * will not work correctly before its PHY has been initialized.
 	 */
-	dwc3_power_off_all_roothub_ports(dwc);
+	if (!dwc->no_early_roothub_poweroff)
+		dwc3_power_off_all_roothub_ports(dwc);
 
 	irq = dwc3_host_get_irq(dwc);
 	if (irq < 0)

-- 
2.34.1

