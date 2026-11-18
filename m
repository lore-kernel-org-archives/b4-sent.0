From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 18 Nov 2026 12:00:20 +0100
Subject: [PATCH v8 6/6] arm64: dts: lx2160a: note that i2c6 and i2c7 share
 their pad mux
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-for-upstream-lx2160a-rcw-pinmux-v1-v8-6-d01bc837593e@free.fr>
References: <20261118-for-upstream-lx2160a-rcw-pinmux-v1-v8-0-d01bc837593e@free.fr>
In-Reply-To: <20261118-for-upstream-lx2160a-rcw-pinmux-v1-v8-0-d01bc837593e@free.fr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794999615; l=1826;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=yeushjxUh8hTfyjoadt5CEZb8ixL/R3BgEaH0ncLzqA=;
 b=70ZXOVv+w6B5PBj90dlUKI9rCkjVWwkQzQm3AvdGn1g+/uSRKSEinlbaTuHI4YXZhytwwK5SC
 Yx3WUMO/04oBjnqH8Nc224oNcYJM+JmHmGqV+6BMOxO8B4JPXiKzrY/
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IIC7 and IIC8, the i2c6 and i2c7 nodes, exist only on the SDHC2_DAT[7:4]
pads, and one RCW field, SDHC2_DAT74_PMUX, muxes all four of them:
 - 0b010 gives both buses
 - 0b001 gives GPIO2[18:15]

Both nodes point at the same two pin states of that field. A board that
enables one of the two buses gets a working bus recovery from them, so
they stay in the SoC dtsi.

A board that enables both cannot use them: the pinctrl core gives the
field to the first controller and the second one fails to probe, and
the bus recovery of one would switch the pads of the other one to GPIO
too. Say so above each node.

Suggested-by: Vladimir Oltean <vladimir.oltean@nxp.com>
Link: https://lore.kernel.org/all/avzGrorxOg2GmYOl@lxl00025.wbi.nxp.com/
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi b/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
index b0bb7bf944059..7bb593c01bd18 100644
--- a/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
+++ b/arch/arm64/boot/dts/freescale/fsl-lx216x.dtsi
@@ -1029,6 +1029,11 @@ i2c5: i2c@2050000 {
 			status = "disabled";
 		};
 
+		/*
+		 * i2c6 and i2c7 share the SDHC2_DAT74 pad mux: these pin
+		 * states, and so the bus recovery, work only while i2c7 is
+		 * disabled.
+		 */
 		i2c6: i2c@2060000 {
 			compatible = "fsl,vf610-i2c";
 			#address-cells = <1>;
@@ -1046,6 +1051,11 @@ i2c6: i2c@2060000 {
 			status = "disabled";
 		};
 
+		/*
+		 * i2c7 and i2c6 share the SDHC2_DAT74 pad mux: these pin
+		 * states, and so the bus recovery, work only while i2c6 is
+		 * disabled.
+		 */
 		i2c7: i2c@2070000 {
 			compatible = "fsl,vf610-i2c";
 			#address-cells = <1>;

-- 
2.43.0

