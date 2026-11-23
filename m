From: Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
Date: Mon, 23 Nov 2026 06:54:08 +0000
Subject: [PATCH v2 2/3] phy: sun4i-usb: Assert PHY resets in
 sun4i_usb_phy_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-usb-sunxi-reset-fix-v2-2-4e51d3a64964@roadbobek.com>
References: <20261123-usb-sunxi-reset-fix-v2-0-4e51d3a64964@roadbobek.com>
In-Reply-To: <20261123-usb-sunxi-reset-fix-v2-0-4e51d3a64964@roadbobek.com>
To: Bin Liu <b-liu@ti.com>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Hans de Goede <hansg@kernel.org>, 
 Felipe Balbi <balbi@ti.com>, Kishon Vijay Abraham I <kishon@kernel.org>, 
 Maxime Ripard <mripard@kernel.org>, Andre Przywara <andre.przywara@arm.com>
Cc: linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, 
 Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795416949; l=2483;
 i=admin@roadbobek.com; s=20261117; h=from:subject:message-id;
 bh=LiuKo9Ttgw8d9A6ryR0X7JCOtqPXd1JaEy/qalojwDQ=;
 b=4snw45SeWS1PIYm2o3Nk760eHMEsEip6mSYpLIf2vwaZCQS2LzedxtnTIUXgPuRkPzG3OhHWd
 l1/KHUDf6tnCvfWaf0ax6iOs134d4XMOkIXArhpCOWh3YJAMzdJtMD2
X-Developer-Key: i=admin@roadbobek.com; a=ed25519;
 pk=TcWSTwITMylwCZLYbw80sv2LQx1zButqiT90TFVvhas=
X-Endpoint-Received: by B4 Relay for admin@roadbobek.com/20261117 with auth_id=1548
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a bootloader initializes USB before booting Linux without first
tearing down the controller, phy->reset may already be deasserted when
Linux probes the USB PHY driver.

Because reset_control_deassert() alone is a no-op on an already
deasserted reset line, stale USB PHY state can persist across the
bootloader-to-kernel handoff. Asserting phy->reset inside
sun4i_usb_phy_init(), however, could disrupt active PHYs on SoCs with
needs_phy2_siddq (such as the Allwinner H616), where PHY0, PHY1, and
PHY3 depend on PHY2 remaining out of reset once enabled.

Request exclusive reset controls via devm_reset_control_get_exclusive()
and assert all PHY resets in sun4i_usb_phy_probe() before registering
the PHY provider so every PHY starts from a clean reset state before
any consumer calls sun4i_usb_phy_init().

Tested on an Allwinner A33 Q8 tablet (Laser MID-786).

Fixes: ba4bdc9e1dc0 ("PHY: sunxi: Add driver for sunxi usb phy")
Signed-off-by: Bobek Brzeczyszczykiewicz <admin@roadbobek.com>
---
 drivers/phy/allwinner/phy-sun4i-usb.c | 21 ++++++++++++++++++++-
 1 file changed, 20 insertions(+), 1 deletion(-)

diff --git a/drivers/phy/allwinner/phy-sun4i-usb.c b/drivers/phy/allwinner/phy-sun4i-usb.c
index f26eed0db17e..a62558124d2d 100644
--- a/drivers/phy/allwinner/phy-sun4i-usb.c
+++ b/drivers/phy/allwinner/phy-sun4i-usb.c
@@ -787,7 +787,7 @@ static int sun4i_usb_phy_probe(struct platform_device *pdev)
 			continue;
 
 		snprintf(name, sizeof(name), "usb%d_reset", i);
-		phy->reset = devm_reset_control_get(dev, name);
+		phy->reset = devm_reset_control_get_exclusive(dev, name);
 		if (IS_ERR(phy->reset)) {
 			if (PTR_ERR(phy->reset) == -ENOENT)
 				break;
@@ -855,6 +855,25 @@ static int sun4i_usb_phy_probe(struct platform_device *pdev)
 	}
 	data->num_phys = i;
 
+	/*
+	 * Assert reset on each PHY before they get deasserted in
+	 * sun4i_usb_phy_init(), in case the bootloader left them active.
+	 */
+	for (i = 0; i < data->num_phys; i++) {
+		struct sun4i_usb_phy *phy = data->phys + i;
+
+		if (data->cfg->missing_phys & BIT(i))
+			continue;
+
+		ret = reset_control_assert(phy->reset);
+		if (ret) {
+			dev_err(dev, "Err asserting reset on PHY: %d\n", ret);
+			return ret;
+		}
+	}
+
+	usleep_range(10, 20); /* hold PHY in reset briefly */
+
 	data->id_det_irq = gpiod_to_irq(data->id_det_gpio);
 	if (data->id_det_irq > 0) {
 		ret = devm_request_irq(dev, data->id_det_irq,

-- 
2.53.0

