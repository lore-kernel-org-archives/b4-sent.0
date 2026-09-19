From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sat, 19 Sep 2026 08:54:39 +0200
Subject: [PATCH RFC v3 11/12] arm64: dts: s32g: Add PCIe controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-s32g_serdes-v3-11-9d68868c1e89@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=9124;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=CObtpizqm2FbdaO4lznyHJO1W6Uk5JcEqGF+ZU0OltE=;
 b=TPbscWA4SDJpJ8EeJJ6VNcHNVAUNaot8uGc3VU0JgOhtBMLCNLmMoNVwQ9Q7MYtvlr+KWPd9d
 Z0oO0gZmI+JCgVIhQEkxBtwc55G0CpOp+lYQxZd8ERLgtvAncIxf8zj
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the two PCIe controllers of the S32G2 and S32G3, disabled. Each is
the root complex half of one SerDes subsystem: PCIe_0 pairs with
SerDes_0 and PCIe_1 with SerDes_1. A board device tree that routes a
SerDes lane to PCIe enables the controller and points the root port at
the lane PHY child node of the matching SerDes.

Both SoCs integrate the controllers identically - same register layout
and same GIC SPI assignment - so the nodes differ only in the
compatible: S32G3 adds "nxp,s32g3-pcie" ahead of the "nxp,s32g2-pcie"
base, as the binding describes. The S32G3-VNP-RDB3 and the
S32G2-VNP-RDB2 wire the same two root complexes to the M.2 slots and
the PCIe card slot.

Their configuration space (0x5f_ffffe000 and 0x4f_ffffe000) lies above
the 32-bit window mapped by soc@0, so the controllers are described at
the device tree root rather than under soc@0.

The root ports are labelled (pcie0_rp, pcie1_rp) so board device trees
can extend them by label. An overlay that instead re-declares a pcie@0
child inside the controller node makes dtc emit a unit_address_vs_reg
warning, because the overlay alone carries no reg for that node.

The GIC nodes gain '#address-cells = <0>'. The PCIe interrupt-map
entries name the GIC as their interrupt parent, and without it dtc
warns on every entry and falls back to zero.

Only the S32G3-VNP-RDB3 board device trees in this series enable a
controller; the S32G2 nodes stay disabled until a board enables them.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 arch/arm64/boot/dts/freescale/s32g2.dtsi | 81 ++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/freescale/s32g3.dtsi | 81 ++++++++++++++++++++++++++++++++
 2 files changed, 162 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/s32g2.dtsi b/arch/arm64/boot/dts/freescale/s32g2.dtsi
index 404913b208fb..539840340318 100644
--- a/arch/arm64/boot/dts/freescale/s32g2.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g2.dtsi
@@ -918,7 +918,88 @@ gic: interrupt-controller@50800000 {
 			      <0x50420000 0x2000>;
 			interrupts = <GIC_PPI 9 IRQ_TYPE_LEVEL_HIGH>;
 			interrupt-controller;
+			#address-cells = <0>;
 			#interrupt-cells = <3>;
 		};
 	};
+
+	/*
+	 * PCIe controllers. Their config space (0x5f_ffffe000 / 0x4f_ffffe000)
+	 * lies above the 32-bit window mapped by soc@0, so the root complexes
+	 * are described at the device tree root. Disabled here; a board file
+	 * that wires a lane to PCIe enables the controller and adds the phys.
+	 */
+	pcie0: pcie@40400000 {
+		compatible = "nxp,s32g2-pcie";
+		reg = <0x00 0x40400000 0x0 0x00001000>,	/* dbi */
+		      <0x00 0x40420000 0x0 0x00001000>,	/* dbi2 */
+		      <0x00 0x40460000 0x0 0x00001000>,	/* atu */
+		      <0x00 0x40470000 0x0 0x00001000>,	/* dma */
+		      <0x00 0x40481000 0x0 0x000000f8>,	/* ctrl */
+		      <0x5f 0xffffe000 0x0 0x00002000>;	/* config */
+		reg-names = "dbi", "dbi2", "atu", "dma", "ctrl", "config";
+		dma-coherent;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		device_type = "pci";
+		ranges = <0x01000000 0x0 0x00000000 0x5f 0xfffe0000 0x0 0x00010000>,
+			 <0x02000000 0x0 0x00000000 0x58 0x00000000 0x0 0x80000000>,
+			 <0x02000000 0x1 0x00000000 0x59 0x00000000 0x6 0xfffe0000>;
+		bus-range = <0x0 0xff>;
+		interrupts = <GIC_SPI 125 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 123 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "msi", "dma";
+		#interrupt-cells = <1>;
+		interrupt-map-mask = <0 0 0 0x7>;
+		interrupt-map = <0 0 0 1 &gic GIC_SPI 128 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 2 &gic GIC_SPI 129 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 3 &gic GIC_SPI 130 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 4 &gic GIC_SPI 131 IRQ_TYPE_LEVEL_HIGH>;
+		status = "disabled";
+
+		pcie0_rp: pcie@0 {
+			reg = <0x0 0x0 0x0 0x0 0x0>;
+			#address-cells = <3>;
+			#size-cells = <2>;
+			ranges;
+			device_type = "pci";
+		};
+	};
+
+	pcie1: pcie@44100000 {
+		compatible = "nxp,s32g2-pcie";
+		reg = <0x00 0x44100000 0x0 0x00001000>,	/* dbi */
+		      <0x00 0x44120000 0x0 0x00001000>,	/* dbi2 */
+		      <0x00 0x44160000 0x0 0x00001000>,	/* atu */
+		      <0x00 0x44170000 0x0 0x00001000>,	/* dma */
+		      <0x00 0x44181000 0x0 0x000000f8>,	/* ctrl */
+		      <0x4f 0xffffe000 0x0 0x00002000>;	/* config */
+		reg-names = "dbi", "dbi2", "atu", "dma", "ctrl", "config";
+		dma-coherent;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		device_type = "pci";
+		ranges = <0x01000000 0x0 0x00000000 0x4f 0xfffe0000 0x0 0x00010000>,
+			 <0x02000000 0x0 0x00000000 0x48 0x00000000 0x0 0x80000000>,
+			 <0x02000000 0x1 0x00000000 0x49 0x00000000 0x6 0xfffe0000>;
+		bus-range = <0x0 0xff>;
+		interrupts = <GIC_SPI 216 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 214 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "msi", "dma";
+		#interrupt-cells = <1>;
+		interrupt-map-mask = <0 0 0 0x7>;
+		interrupt-map = <0 0 0 1 &gic GIC_SPI 219 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 2 &gic GIC_SPI 220 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 3 &gic GIC_SPI 221 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 4 &gic GIC_SPI 222 IRQ_TYPE_LEVEL_HIGH>;
+		status = "disabled";
+
+		pcie1_rp: pcie@0 {
+			reg = <0x0 0x0 0x0 0x0 0x0>;
+			#address-cells = <3>;
+			#size-cells = <2>;
+			ranges;
+			device_type = "pci";
+		};
+	};
 };
diff --git a/arch/arm64/boot/dts/freescale/s32g3.dtsi b/arch/arm64/boot/dts/freescale/s32g3.dtsi
index 0d001b2895c6..fdf086363c02 100644
--- a/arch/arm64/boot/dts/freescale/s32g3.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g3.dtsi
@@ -1058,6 +1058,7 @@ stm11: timer@4052c000 {
 
 		gic: interrupt-controller@50800000 {
 			compatible = "arm,gic-v3";
+			#address-cells = <0>;
 			#interrupt-cells = <3>;
 			interrupt-controller;
 			reg = <0x50800000 0x10000>,
@@ -1069,6 +1070,86 @@ gic: interrupt-controller@50800000 {
 		};
 	};
 
+	/*
+	 * PCIe controllers. Their config space (0x5f_ffffe000 / 0x4f_ffffe000)
+	 * lies above the 32-bit window mapped by soc@0, so the root complexes
+	 * are described at the device tree root. Disabled here; a board file
+	 * that wires a lane to PCIe enables the controller and adds the phys.
+	 */
+	pcie0: pcie@40400000 {
+		compatible = "nxp,s32g3-pcie", "nxp,s32g2-pcie";
+		reg = <0x00 0x40400000 0x0 0x00001000>,	/* dbi */
+		      <0x00 0x40420000 0x0 0x00001000>,	/* dbi2 */
+		      <0x00 0x40460000 0x0 0x00001000>,	/* atu */
+		      <0x00 0x40470000 0x0 0x00001000>,	/* dma */
+		      <0x00 0x40481000 0x0 0x000000f8>,	/* ctrl */
+		      <0x5f 0xffffe000 0x0 0x00002000>;	/* config */
+		reg-names = "dbi", "dbi2", "atu", "dma", "ctrl", "config";
+		dma-coherent;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		device_type = "pci";
+		ranges = <0x01000000 0x0 0x00000000 0x5f 0xfffe0000 0x0 0x00010000>,
+			 <0x02000000 0x0 0x00000000 0x58 0x00000000 0x0 0x80000000>,
+			 <0x02000000 0x1 0x00000000 0x59 0x00000000 0x6 0xfffe0000>;
+		bus-range = <0x0 0xff>;
+		interrupts = <GIC_SPI 125 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 123 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "msi", "dma";
+		#interrupt-cells = <1>;
+		interrupt-map-mask = <0 0 0 0x7>;
+		interrupt-map = <0 0 0 1 &gic GIC_SPI 128 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 2 &gic GIC_SPI 129 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 3 &gic GIC_SPI 130 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 4 &gic GIC_SPI 131 IRQ_TYPE_LEVEL_HIGH>;
+		status = "disabled";
+
+		pcie0_rp: pcie@0 {
+			reg = <0x0 0x0 0x0 0x0 0x0>;
+			#address-cells = <3>;
+			#size-cells = <2>;
+			ranges;
+			device_type = "pci";
+		};
+	};
+
+	pcie1: pcie@44100000 {
+		compatible = "nxp,s32g3-pcie", "nxp,s32g2-pcie";
+		reg = <0x00 0x44100000 0x0 0x00001000>,	/* dbi */
+		      <0x00 0x44120000 0x0 0x00001000>,	/* dbi2 */
+		      <0x00 0x44160000 0x0 0x00001000>,	/* atu */
+		      <0x00 0x44170000 0x0 0x00001000>,	/* dma */
+		      <0x00 0x44181000 0x0 0x000000f8>,	/* ctrl */
+		      <0x4f 0xffffe000 0x0 0x00002000>;	/* config */
+		reg-names = "dbi", "dbi2", "atu", "dma", "ctrl", "config";
+		dma-coherent;
+		#address-cells = <3>;
+		#size-cells = <2>;
+		device_type = "pci";
+		ranges = <0x01000000 0x0 0x00000000 0x4f 0xfffe0000 0x0 0x00010000>,
+			 <0x02000000 0x0 0x00000000 0x48 0x00000000 0x0 0x80000000>,
+			 <0x02000000 0x1 0x00000000 0x49 0x00000000 0x6 0xfffe0000>;
+		bus-range = <0x0 0xff>;
+		interrupts = <GIC_SPI 216 IRQ_TYPE_LEVEL_HIGH>,
+			     <GIC_SPI 214 IRQ_TYPE_LEVEL_HIGH>;
+		interrupt-names = "msi", "dma";
+		#interrupt-cells = <1>;
+		interrupt-map-mask = <0 0 0 0x7>;
+		interrupt-map = <0 0 0 1 &gic GIC_SPI 219 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 2 &gic GIC_SPI 220 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 3 &gic GIC_SPI 221 IRQ_TYPE_LEVEL_HIGH>,
+				<0 0 0 4 &gic GIC_SPI 222 IRQ_TYPE_LEVEL_HIGH>;
+		status = "disabled";
+
+		pcie1_rp: pcie@0 {
+			reg = <0x0 0x0 0x0 0x0 0x0>;
+			#address-cells = <3>;
+			#size-cells = <2>;
+			ranges;
+			device_type = "pci";
+		};
+	};
+
 	timer {
 		compatible = "arm,armv8-timer";
 		interrupt-parent = <&gic>;

-- 
2.55.0

