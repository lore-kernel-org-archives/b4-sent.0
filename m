From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 11 Nov 2026 03:26:02 -0500
Subject: [PATCH v2 2/3] usb: dwc2: Add Siflower SF19A2890 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-sf19a2890-dwc2-v2-2-cba9dd4a4256@telaak.dev>
References: <20261111-sf19a2890-dwc2-v2-0-cba9dd4a4256@telaak.dev>
In-Reply-To: <20261111-sf19a2890-dwc2-v2-0-cba9dd4a4256@telaak.dev>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Minas Harutyunyan <hminas@synopsys.com>
Cc: Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794385586; l=1619;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=nQKb53x4kS6TUNVquwYjce7H9GBsH2tS7RH2pY4HKw8=;
 b=a8hF7jD8+wGLj45IBtGTJ6U3mPI2ivMNDb9cwpRa6nTl63O35D19TalR4isiXM9W34IRBFU4s
 iUlgq61tyEXBbnDCcFABnU7zAuxunQJbFyQg0cG8Yk3QCNztzuMPWJX
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuanhong Guo <gch981213@gmail.com>

The Siflower SF19A2890 has a DWC OTG 3.30a controller. Limit its
transfers to 65535 bytes and its AHB bursts to INCR4, the settings the
OpenWrt port has run it with.

Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
[Joseph Telaak:
  - take it from OpenWrt's siflower target and rebase on v7.4-rc1
  - commit message and subject]
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/usb/dwc2/params.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/usb/dwc2/params.c b/drivers/usb/dwc2/params.c
index 091bfcfef753..b31fa1f5ad64 100644
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
@@ -334,6 +342,8 @@ const struct of_device_id dwc2_of_match_table[] = {
 	  .data = dwc2_set_amlogic_a1_params },
 	{ .compatible = "amcc,dwc-otg", .data = dwc2_set_amcc_params },
 	{ .compatible = "apm,apm82181-dwc-otg", .data = dwc2_set_amcc_params },
+	{ .compatible = "siflower,sf19a2890-usb",
+	  .data = dwc2_set_sf19a2890_params },
 	{ .compatible = "sophgo,cv1800b-usb",
 	  .data = dwc2_set_cv1800_params },
 	{ .compatible = "st,stm32f4x9-fsotg",

-- 
Git-155)

