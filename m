From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:55 +0100
Subject: [PATCH RFC v4 13/15] arm64: dts: s32g: Add SerDes controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-13-3bfe0589be8d@oss.nxp.com>
References: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
In-Reply-To: <20261125-s32g_serdes-v4-0-3bfe0589be8d@oss.nxp.com>
To: Vincent Guittot <vincent.guittot@linaro.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, imx@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=3600;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=dcO9jRk3SJhIq8VC26nfvLMtB2oUb3ElUxxnM7do7KQ=;
 b=F3dQzM1oXkyzvZBR6BCAlyYbN2dFCk0QO32eA+NJbp+we14/iP+uGQPU4zMZbqI8xBe43EhO5
 UqrV4pyUu7MC7dmtH6DRcsO3B8vZNV5WykYfB4lBgz6hP7ORx8Kfxsv
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the two SerDes subsystem nodes of S32G2 and S32G3, disabled. Each
is a four-cell PHY provider; a board device tree enables an instance
and describes the routing through the phys references of the PCIe
root ports and Ethernet controllers.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 arch/arm64/boot/dts/freescale/s32g2.dtsi | 30 ++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/freescale/s32g3.dtsi | 30 ++++++++++++++++++++++++++++++
 2 files changed, 60 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/s32g2.dtsi b/arch/arm64/boot/dts/freescale/s32g2.dtsi
index ff5d2a061d50..0b070f7b5f22 100644
--- a/arch/arm64/boot/dts/freescale/s32g2.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g2.dtsi
@@ -877,6 +877,36 @@ gmac0mdio: mdio {
 			};
 		};
 
+		serdes0: serdes@40480000 {
+			compatible = "nxp,s32g2-serdes0", "nxp,s32g2-serdes";
+			reg = <0x40480000 0x108>,
+			      <0x40483008 0x10>,
+			      <0x40482000 0x800>,
+			      <0x40482800 0x800>;
+			reg-names = "ss-pcie", "pcie-phy", "xpcs0", "xpcs1";
+			clocks = <&clks 1>, <&clks 2>, <&clks 3>, <&clks 4>;
+			clock-names = "axi", "aux", "apb", "ref";
+			resets = <&scmi_reset 9>, <&scmi_reset 8>;
+			reset-names = "serdes", "pcie";
+			#phy-cells = <4>;
+			status = "disabled";
+		};
+
+		serdes1: serdes@44180000 {
+			compatible = "nxp,s32g2-serdes1", "nxp,s32g2-serdes";
+			reg = <0x44180000 0x108>,
+			      <0x44183008 0x10>,
+			      <0x44182000 0x800>,
+			      <0x44182800 0x800>;
+			reg-names = "ss-pcie", "pcie-phy", "xpcs0", "xpcs1";
+			clocks = <&clks 1>, <&clks 2>, <&clks 3>, <&clks 4>;
+			clock-names = "axi", "aux", "apb", "ref";
+			resets = <&scmi_reset 11>, <&scmi_reset 10>;
+			reset-names = "serdes", "pcie";
+			#phy-cells = <4>;
+			status = "disabled";
+		};
+
 		gic: interrupt-controller@50800000 {
 			compatible = "arm,gic-v3";
 			reg = <0x50800000 0x10000>,
diff --git a/arch/arm64/boot/dts/freescale/s32g3.dtsi b/arch/arm64/boot/dts/freescale/s32g3.dtsi
index fbe87475bcf6..0d03daa881bf 100644
--- a/arch/arm64/boot/dts/freescale/s32g3.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g3.dtsi
@@ -956,6 +956,21 @@ gmac0mdio: mdio {
 			};
 		};
 
+		serdes0: serdes@40480000 {
+			compatible = "nxp,s32g3-serdes0", "nxp,s32g3-serdes";
+			reg = <0x40480000 0x108>,
+			      <0x40483008 0x10>,
+			      <0x40482000 0x800>,
+			      <0x40482800 0x800>;
+			reg-names = "ss-pcie", "pcie-phy", "xpcs0", "xpcs1";
+			clocks = <&clks 1>, <&clks 2>, <&clks 3>, <&clks 4>;
+			clock-names = "axi", "aux", "apb", "ref";
+			resets = <&scmi_reset 9>, <&scmi_reset 8>;
+			reset-names = "serdes", "pcie";
+			#phy-cells = <4>;
+			status = "disabled";
+		};
+
 		swt8: watchdog@40500000 {
 			compatible = "nxp,s32g3-swt", "nxp,s32g2-swt";
 			reg = <0x40500000 0x1000>;
@@ -1024,6 +1039,21 @@ stm11: timer@4052c000 {
 			status = "disabled";
 		};
 
+		serdes1: serdes@44180000 {
+			compatible = "nxp,s32g3-serdes1", "nxp,s32g3-serdes";
+			reg = <0x44180000 0x108>,
+			      <0x44183008 0x10>,
+			      <0x44182000 0x800>,
+			      <0x44182800 0x800>;
+			reg-names = "ss-pcie", "pcie-phy", "xpcs0", "xpcs1";
+			clocks = <&clks 1>, <&clks 2>, <&clks 3>, <&clks 4>;
+			clock-names = "axi", "aux", "apb", "ref";
+			resets = <&scmi_reset 11>, <&scmi_reset 10>;
+			reset-names = "serdes", "pcie";
+			#phy-cells = <4>;
+			status = "disabled";
+		};
+
 		gic: interrupt-controller@50800000 {
 			compatible = "arm,gic-v3";
 			#interrupt-cells = <3>;

-- 
2.55.0

