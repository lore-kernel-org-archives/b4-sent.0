From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:56 +0100
Subject: [PATCH RFC v4 14/15] arm64: dts: s32g: Add PCIe controller nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-14-3bfe0589be8d@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=8174;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=4hEy+CFkkzDf8s4SiBEzs7e2GrzS7v0Nc6GdSnPh+L8=;
 b=V4wC68x4C2n9U3RVLjh/krysblPQcprKZ81C/Qc6SVpZM33LH67QzUIGKMqL5qrY/TWFx+pRQ
 Zos3EQ5XTpmC9/QJhcLHWGwI8ulnX4yumEIrU7CsFWjzwGXGTIkHE2O
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the two PCIe controllers of S32G2 and S32G3, disabled. PCIe_0 pairs
with SerDes_0 and PCIe_1 with SerDes_1. A board device tree enables a
controller and references the lanes of the matching SerDes from its
root port, one phys entry per lane. The nodes of both SoCs differ only
in the compatible.

The configuration space (0x5f_ffffe000 and 0x4f_ffffe000) lies above
the 32-bit window mapped by soc@0, so the controllers sit at the device
tree root.

The root ports are labelled (pcie0_rp, pcie1_rp), so that boards and
overlays can extend them by label.

Add '#address-cells = <0>' to the GIC nodes: the PCIe interrupt-map
entries name the GIC as their interrupt parent, and dtc warns without
it.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 arch/arm64/boot/dts/freescale/s32g2.dtsi | 81 ++++++++++++++++++++++++++++++++
 arch/arm64/boot/dts/freescale/s32g3.dtsi | 81 ++++++++++++++++++++++++++++++++
 2 files changed, 162 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/s32g2.dtsi b/arch/arm64/boot/dts/freescale/s32g2.dtsi
index 0b070f7b5f22..1b6affb15d03 100644
--- a/arch/arm64/boot/dts/freescale/s32g2.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g2.dtsi
@@ -916,7 +916,88 @@ gic: interrupt-controller@50800000 {
 			      <0x50420000 0x2000>;
 			interrupts = <GIC_PPI 9 IRQ_TYPE_LEVEL_HIGH>;
 			interrupt-controller;
+			#address-cells = <0>;
 			#interrupt-cells = <3>;
 		};
 	};
+
+	/*
+	 * The PCIe config space (0x5f_ffffe000 / 0x4f_ffffe000) lies above the
+	 * 32-bit window mapped by soc@0, so the controllers are not under it.
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
+			 <0x43000000 0x1 0x00000000 0x59 0x00000000 0x6 0xfffe0000>;
+		bus-range = <0x0 0xff>;
+		linux,pci-domain = <0>;
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
+			 <0x43000000 0x1 0x00000000 0x49 0x00000000 0x6 0xfffe0000>;
+		bus-range = <0x0 0xff>;
+		linux,pci-domain = <1>;
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
index 0d03daa881bf..9eed2428732a 100644
--- a/arch/arm64/boot/dts/freescale/s32g3.dtsi
+++ b/arch/arm64/boot/dts/freescale/s32g3.dtsi
@@ -1056,6 +1056,7 @@ serdes1: serdes@44180000 {
 
 		gic: interrupt-controller@50800000 {
 			compatible = "arm,gic-v3";
+			#address-cells = <0>;
 			#interrupt-cells = <3>;
 			interrupt-controller;
 			reg = <0x50800000 0x10000>,
@@ -1067,6 +1068,86 @@ gic: interrupt-controller@50800000 {
 		};
 	};
 
+	/*
+	 * The PCIe config space (0x5f_ffffe000 / 0x4f_ffffe000) lies above the
+	 * 32-bit window mapped by soc@0, so the controllers are not under it.
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
+			 <0x43000000 0x1 0x00000000 0x59 0x00000000 0x6 0xfffe0000>;
+		bus-range = <0x0 0xff>;
+		linux,pci-domain = <0>;
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
+			 <0x43000000 0x1 0x00000000 0x49 0x00000000 0x6 0xfffe0000>;
+		bus-range = <0x0 0xff>;
+		linux,pci-domain = <1>;
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

