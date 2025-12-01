From: Maud Spierings <maudspierings@gocontroll.com>
Date: Mon, 01 Dec 2025 12:56:52 +0100
Subject: [PATCH v2 3/3] arm64: dts: freescale: tx8p-ml81: fix eqos
 nvmem-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251201-disp_fix-v2-3-9b03026311b6@gocontroll.com>
References: <20251201-disp_fix-v2-0-9b03026311b6@gocontroll.com>
In-Reply-To: <20251201-disp_fix-v2-0-9b03026311b6@gocontroll.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764590218; l=1812;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=UarncIoORvGu/J2XyFu3oe6mX1a3LvZl4JDeYZkFnbQ=;
 b=gYKT+KLzWn3ITTap+LEFHxcxFrpOkXKJ8kY/KJYUf/jCvfQaELRPEDwdtupElv4zeUZvbg20I
 rzAGTOlmmbgBk02fE/9w1MNX79W2vPLkBWEZ7qlLhJTB6WklRhwFQ/J
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this SoM eqos is the primary ethernet interface, Ka-Ro fuses the
address for it in eth_mac1, eth_mac2 seems to be left unfused. In their
downstream u-boot they fetch it from eth_mac1 [1][2], by setting alias
of eqos to ethernet0, the driver then fetches the mac address based on
the alias number.

Set eqos to read from eth_mac1 instead of eth_mac2. Also set fec to
point at eth_mac2 as it may be fused later even though it is disabled
by default.

With this changed barebox is now capable of loading the correct address.

Link: https://github.com/karo-electronics/karo-tx-uboot/blob/380543278410bbf04264d80a3bfbe340b8e62439/drivers/net/dwc_eth_qos.c#L1167 [1]
Link: https://github.com/karo-electronics/karo-tx-uboot/blob/380543278410bbf04264d80a3bfbe340b8e62439/arch/arm/dts/imx8mp-karo.dtsi#L12 [2]

Fixes: bac63d7c5f46 ("arm64: dts: freescale: add Ka-Ro Electronics tx8p-ml81 COM")
Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi b/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi
index fe8ba16eb40e..761ee046eb72 100644
--- a/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi
+++ b/arch/arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi
@@ -47,6 +47,7 @@ &eqos {
 				 <&clk IMX8MP_SYS_PLL2_100M>,
 				 <&clk IMX8MP_SYS_PLL2_50M>;
 	assigned-clock-rates = <266000000>, <100000000>, <50000000>;
+	nvmem-cells = <&eth_mac1>;
 	phy-handle = <&ethphy0>;
 	phy-mode = "rmii";
 	pinctrl-0 = <&pinctrl_eqos>;
@@ -75,6 +76,10 @@ ethphy0: ethernet-phy@0 {
 	};
 };
 
+&fec {
+	nvmem-cells = <&eth_mac2>;
+};
+
 &gpio1 {
 	gpio-line-names = "SODIMM_152",
 			  "SODIMM_42",

-- 
2.52.0

