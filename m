From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 22 Oct 2026 00:11:20 +0800
Subject: [PATCH 23/27] usb: dwc3: Configure RK3572 PIPE port before
 discovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-add-board-ok3572-c-v1-23-0b0fd85a31ee@qq.com>
References: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
In-Reply-To: <20261022-add-board-ok3572-c-v1-0-0b0fd85a31ee@qq.com>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Elaine Zhang <zhangqing@rock-chips.com>, Lee Jones <lee@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Jisheng Zhang <jszhang@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 David Wu <david.wu@rock-chips.com>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>
Cc: Cunhao Lu <1579567540@qq.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 mfd@lists.linux.dev, linux-gpio@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792599138; l=2530;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=h5W+2vCeTnJq9csdidWq+DAD3u6T94cfAIF4kAYsWso=;
 b=JgKhkQkYYvj1vSafR0hKio8ahXnc0hk8CyRtyjQdwxIIZQYev4aN+8zACYBJOUlMgSQpvu3SB
 SOO/YLIkEiWDyGdl3tkSvR9xQJXkTc4rP1GaSxaHL42QX07bWlQbOdt
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Firmware may leave the USB3 PIPE port disabled, causing DWC3 to discover
only USB2. Configure the port before reading controller capabilities.

Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
 drivers/usb/dwc3/dwc3-generic-plat.c | 31 +++++++++++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/drivers/usb/dwc3/dwc3-generic-plat.c b/drivers/usb/dwc3/dwc3-generic-plat.c
index ca69ac0eb07ce..11e71fc76be1a 100644
--- a/drivers/usb/dwc3/dwc3-generic-plat.c
+++ b/drivers/usb/dwc3/dwc3-generic-plat.c
@@ -22,6 +22,10 @@
 #define EIC7700_HSP_AXI_LP_XM_CSYSREQ	BIT(0)
 #define EIC7700_HSP_AXI_LP_XS_CSYSREQ	BIT(16)
 
+#define RK3572_PIPE_USB3		0x1100
+#define RK3572_PIPE_USB2_ONLY		0x0189
+#define RK3572_PIPE_WRITE_MASK		GENMASK(31, 16)
+
 struct dwc3_generic {
 	struct device		*dev;
 	struct dwc3		dwc;
@@ -85,6 +89,27 @@ static int dwc3_spacemit_k1_init(struct dwc3_generic *dwc3g)
 	return 0;
 }
 
+static int dwc3_rk3572_init(struct dwc3_generic *dwc3g)
+{
+	struct device *dev = dwc3g->dev;
+	enum usb_device_speed speed = usb_get_maximum_speed(dev);
+	struct regmap *grf;
+	u32 offset, value = RK3572_PIPE_USB2_ONLY;
+
+	grf = syscon_regmap_lookup_by_phandle_args(dev->of_node, "rockchip,grf",
+						   1, &offset);
+	if (IS_ERR(grf))
+		return dev_err_probe(dev, PTR_ERR(grf), "failed to get PHP GRF\n");
+
+	if (device_property_match_string(dev, "phy-names", "usb3-phy") >= 0 &&
+	    speed != USB_SPEED_LOW && speed != USB_SPEED_FULL &&
+	    speed != USB_SPEED_HIGH)
+		value = RK3572_PIPE_USB3;
+
+	/* Configure the PIPE port before the core reads its port count. */
+	return regmap_write(grf, offset, RK3572_PIPE_WRITE_MASK | value);
+}
+
 static int dwc3_generic_probe(struct platform_device *pdev)
 {
 	const struct dwc3_generic_config *plat_config;
@@ -231,11 +256,17 @@ static const struct dwc3_generic_config eic7700_dwc3 =  {
 	.properties = DWC3_DEFAULT_PROPERTIES,
 };
 
+static const struct dwc3_generic_config rk3572_dwc3 = {
+	.init = dwc3_rk3572_init,
+	.properties = DWC3_DEFAULT_PROPERTIES,
+};
+
 static const struct of_device_id dwc3_generic_of_match[] = {
 	{ .compatible = "spacemit,k1-dwc3", &spacemit_k1_dwc3},
 	{ .compatible = "spacemit,k3-dwc3", },
 	{ .compatible = "fsl,ls1028a-dwc3", &fsl_ls1028_dwc3},
 	{ .compatible = "eswin,eic7700-dwc3", &eic7700_dwc3},
+	{ .compatible = "rockchip,rk3572-dwc3", &rk3572_dwc3 },
 	{ .compatible = "starfive,jhb100-dwc3", },
 	{ /* sentinel */ }
 };

-- 
2.34.1

