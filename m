From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:22:07 -0500
Subject: [PATCH 2/3] usb: dwc2: Add Siflower SF19A2890 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-dwc2-v1-2-d959375e26ab@telaak.dev>
References: <20261104-sf19a2890-dwc2-v1-0-d959375e26ab@telaak.dev>
In-Reply-To: <20261104-sf19a2890-dwc2-v1-0-d959375e26ab@telaak.dev>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Minas Harutyunyan <hminas@synopsys.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776930; l=1563;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=MDtPwfl6Th0PkvI7Z1Y+LGIu11doKKB4kqplBwGeUCs=;
 b=G0d+lB1otAcPXOo/UZILLhyUDs9letOhYgjaKwkkj2uzOcx4N0lWYNGRuj3Zc43f5InYGC7ER
 4fCn6vVABKZDcXXHk/AWI2FDK2JWppkQseYG4V+54oCo7Dkuemi85ws
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuanhong Guo <gch981213@gmail.com>

The Siflower SF19A2890 has a DWC OTG 3.30a controller. Limit its
transfers to 65535 bytes and its AHB bursts to INCR4, the settings the
OpenWrt port has run it with.

Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
[jt: from OpenWrt's siflower target, rebased on v7.4-rc1, commit message,
 subject]
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/usb/dwc2/params.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/usb/dwc2/params.c b/drivers/usb/dwc2/params.c
index 091bfcfef..f6379e616 100644
--- a/drivers/usb/dwc2/params.c
+++ b/drivers/usb/dwc2/params.c
@@ -237,6 +237,14 @@ static void dwc2_set_cv1800_params(struct dwc2_hsotg *hsotg)
 	p->power_down = DWC2_POWER_DOWN_PARAM_NONE;
 }
 
+static void dwc2_set_sf19a2890_params(struct dwc2_hsotg *hsotg)
+{
+	struct dwc2_core_params *p = &hsotg->params;
+
+	p->max_transfer_size = 65535;
+	p->ahbcfg = GAHBCFG_HBSTLEN_INCR4 << GAHBCFG_HBSTLEN_SHIFT;
+}
+
 static void dwc2_set_stm32f4x9_fsotg_params(struct dwc2_hsotg *hsotg)
 {
 	struct dwc2_core_params *p = &hsotg->params;
@@ -336,6 +344,8 @@ const struct of_device_id dwc2_of_match_table[] = {
 	{ .compatible = "apm,apm82181-dwc-otg", .data = dwc2_set_amcc_params },
 	{ .compatible = "sophgo,cv1800b-usb",
 	  .data = dwc2_set_cv1800_params },
+	{ .compatible = "siflower,sf19a2890-usb",
+	  .data = dwc2_set_sf19a2890_params },
 	{ .compatible = "st,stm32f4x9-fsotg",
 	  .data = dwc2_set_stm32f4x9_fsotg_params },
 	{ .compatible = "st,stm32f4x9-hsotg" },

-- 
Git-155)

