From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sat, 19 Sep 2026 08:54:38 +0200
Subject: [PATCH RFC v3 10/12] arm64: dts: s32g: Add SerDes controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-s32g_serdes-v3-10-9d68868c1e89@oss.nxp.com>
References: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
In-Reply-To: <20260919-s32g_serdes-v3-0-9d68868c1e89@oss.nxp.com>
To: Ciprian Marian Costea <ciprianmarian.costea@oss.nxp.com>, 
 NXP S32 Linux Team <s32@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@nxp.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Magnus Damm <magnus.damm@gmail.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Bogdan Hamciuc <bogdan.hamciuc@nxp.com>, 
 Ionut Vicovan <ionut.vicovan@nxp.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Clark Wang <xiaoning.wang@nxp.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chester Lin <chester62515@gmail.com>, Matthias Brugger <mbrugger@suse.com>, 
 Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>, 
 Frank Li <Frank.Li@nxp.com>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-renesas-soc@vger.kernel.org, 
 imx@lists.linux.dev, linux-pci@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=3680;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=+XdDZhOByuFg4ugqbcosSUu/1UqTDyBj7h2t2yZcItw=;
 b=kZUh437M7THMDFoZdyk69tr7g1HHaMmr1ZlQyhm0sBeIJNMStvThEvrBZyUPuUKNJgHwFCwqz
 YeZiqpPQy75C/lroDEnwnQIfWWGthgowbolg75PLA4GriZYTmxmDaPO
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SerDes/PCIe combo-PHY controller nodes for S32G2 and S32G3 in
the disabled state. Each SoC integrates two SerDes instances (SerDes_0
and SerDes_1) with identical register layout; every instance exposes
the PCIe PHY and the two XPCS instances used for SGMII. Board device
trees enable the required instance and add the lane PHY child nodes
matching the wanted SerDes subsystem mode.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 arch/arm64/boot/dts/freescale/s32g2.dtsi | 32 ++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/freescale/s32g3.dtsi | 32 ++++++++++++++++++++++++++++++++
 2 files changed, 64 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/s32g2.dtsi b/arch/arm64/boot/dts/freescale/s32g2.dtsi
index 6a2774d53747..404913b208fb 100644
--- a/arch/arm64/boot/dts/freescale/s32g2.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g2.dtsi
@@ -877,6 +877,38 @@ gmac0mdio: mdio {
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
+			#address-cells = <1>;
+			#size-cells = <0>;
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
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
 		gic: interrupt-controller@50800000 {
 			compatible = "arm,gic-v3";
 			reg = <0x50800000 0x10000>,
diff --git a/arch/arm64/boot/dts/freescale/s32g3.dtsi b/arch/arm64/boot/dts/freescale/s32g3.dtsi
index da3915b7e915..0d001b2895c6 100644
--- a/arch/arm64/boot/dts/freescale/s32g3.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g3.dtsi
@@ -956,6 +956,38 @@ gmac0mdio: mdio {
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
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
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
+			#address-cells = <1>;
+			#size-cells = <0>;
+			status = "disabled";
+		};
+
 		swt8: watchdog@40500000 {
 			compatible = "nxp,s32g3-swt", "nxp,s32g2-swt";
 			reg = <0x40500000 0x1000>;

-- 
2.55.0

