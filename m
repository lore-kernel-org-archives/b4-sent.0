From: Vincent Jardin <vjardin@free.fr>
Date: Tue, 17 Nov 2026 15:53:16 +0100
Subject: [PATCH v7 6/6] arm64: dts: lx2160a: drop the I2C bus recovery of
 i2c6 and i2c7
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-for-upstream-lx2160a-rcw-pinmux-v1-v7-6-5d7201970629@free.fr>
References: <20261117-for-upstream-lx2160a-rcw-pinmux-v1-v7-0-5d7201970629@free.fr>
In-Reply-To: <20261117-for-upstream-lx2160a-rcw-pinmux-v1-v7-0-5d7201970629@free.fr>
To: Dong Aisheng <aisheng.dong@nxp.com>, Fabio Estevam <festevam@gmail.com>, 
 Frank Li <Frank.Li@nxp.com>, Jacky Bai <ping.bai@nxp.com>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 NXP S32 Linux Team <s32@nxp.com>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-arm-kernel@lists.infradead.org, imx@lists.linux.dev, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, 
 Ioana Ciornei <ioana.ciornei@nxp.com>, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794927205; l=2654;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=vH8MdQeBHmXHEmIM/7mJDStPvh7UoIZQhzsf1k+YUgg=;
 b=TY4Y5UULvkw7v8OwtygAKyOg/A4iU1UMM9UwpKRr5LQhc+5ET88yOGXEiq+5PZDVQi4JNHkvR
 j0Jj60HPKW/A5cOCrZdukT5PEDicOfvX1AKwIC3880akwWgqHx0leme
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IIC7 and IIC8, the i2c6 and i2c7 nodes, exist only on the SDHC2_DAT[7:4]
pads, and one RCW field, SDHC2_DAT74_PMUX, muxes all four of them:
 - 0b010 gives both buses
 - 0b001 gives GPIO2[18:15]

The bus recovery of one controller therefore switches the pads of the
other one to GPIO too, and breaks a transfer of that bus, or its
target role.
No lock shared by the two drivers can avoid that.

The description cannot work either: both nodes point at the same two
states of the same pad-mux group, so the controller that probes second
fails with "pin ... already requested".
No board enables either bus, which is why it did not show.

Drop the pinctrl and the recovery GPIOs of both nodes, and the two states
nothing else uses. A board that uses one of the buses can add its own.

Suggested-by: Vladimir Oltean <vladimir.oltean@nxp.com>
Link: https://lore.kernel.org/all/avtsY-7-I7_pdyD0@lxl00025.wbi.nxp.com/
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi | 20 --------------------
 1 file changed, 20 deletions(-)

diff --git a/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi b/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
index b0bb7bf944059..64903e935131b 100644
--- a/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
@@ -852,16 +852,6 @@ esdhc0_data75_pins: sdhc1-dir-sdhc-pins {
 					groups = "sdhc1-dir";
 				};
 
-				gpio1_18_15_pins: iic8-iic7-gpio-pins {
-					function = "gpio";
-					groups = "sdhc2-data74";
-				};
-
-				i2c6_i2c7_pins: iic8-iic7-i2c-pins {
-					function = "i2c";
-					groups = "sdhc2-data74";
-				};
-
 				i2c0_pins: iic1-i2c-pins {
 					function = "i2c";
 					groups = "iic1";
@@ -1038,11 +1028,6 @@ i2c6: i2c@2060000 {
 			clock-names = "ipg";
 			clocks = <&clockgen QORIQ_CLK_PLATFORM_PLL
 					    QORIQ_CLK_PLL_DIV(16)>;
-			pinctrl-names = "default", "gpio";
-			pinctrl-0 = <&i2c6_i2c7_pins>;
-			pinctrl-1 = <&gpio1_18_15_pins>;
-			scl-gpios = <&gpio1 16 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
-			sda-gpios = <&gpio1 15 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
 			status = "disabled";
 		};
 
@@ -1055,11 +1040,6 @@ i2c7: i2c@2070000 {
 			clock-names = "ipg";
 			clocks = <&clockgen QORIQ_CLK_PLATFORM_PLL
 					    QORIQ_CLK_PLL_DIV(16)>;
-			pinctrl-names = "default", "gpio";
-			pinctrl-0 = <&i2c6_i2c7_pins>;
-			pinctrl-1 = <&gpio1_18_15_pins>;
-			scl-gpios = <&gpio1 18 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
-			sda-gpios = <&gpio1 17 (GPIO_ACTIVE_HIGH | GPIO_OPEN_DRAIN)>;
 			status = "disabled";
 		};
 

-- 
2.43.0

