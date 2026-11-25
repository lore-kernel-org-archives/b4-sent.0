From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Wed, 25 Nov 2026 10:33:57 +0100
Subject: [PATCH RFC v4 15/15] arm64: dts: s32g: Add S32G3-RDB3 SerDes
 routing variants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-s32g_serdes-v4-15-3bfe0589be8d@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795599274; l=5200;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=ey+259q8NVdz+nmA6w91HlJzOAXDIhQhflExVQ+Y8o0=;
 b=O0br6DpDGuG00R9/Celm9Vz7oEv9fLtAFCfkd5v/N6CHAZKEdn/Imv4bxMILlCtnoOJSiljUK
 aZxBB69RSipClJeod4fr8tGUD+wbk0T49UrIEPVkvvKgfIFgP0hgD4B
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The S32G3-VNP-RDB3 wires GMAC0 to an on-board KSZ9031 RGMII PHY by
default. Add two board variants which route GMAC0 over SerDes_0 for
SGMII instead:

  - mode 1: PCIe x1 on lane 0, GMAC0 SGMII (XPCS0) on lane 1;
  - mode 3: GMAC0 SGMII (XPCS0) on lane 0. Lane 1 (XPCS1, PFE_MAC2)
    has no consumer, as there is no PFE driver, and is not described.

The variants are full .dts files that include s32g399a-rdb3.dts, not
overlays: they drop the phy-handle of GMAC0, and /delete-property/ has
no effect in an overlay.

The routing is described by the consumers: the PCIe root ports
reference lane 0 with PHY_TYPE_PCIE, GMAC0 references its lane with
PHY_TYPE_SGMII and XPCS0, and takes the PCS from the SerDes through
pcs-handle.

The mode 1 variant also enables both PCIe root complexes: PCIe_0
reaches the M.2 slots when board switch SW17-2 is ON, PCIe_1 the PCIe
card slot. SerDes_1 carries only PCIe_1 on lane 0, as there is no PFE
driver to reference lane 1, and runs the first matching mode, PCIe x2,
with an x1 link.

The SGMII lane goes to the on-board SJA1110 switch, which the variants
do not describe, so the MAC side is a fixed 1G link.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 arch/arm64/boot/dts/freescale/Makefile             |  2 +
 .../dts/freescale/s32g399a-rdb3-serdes-mode1.dts   | 65 ++++++++++++++++++++++
 .../dts/freescale/s32g399a-rdb3-serdes-mode3.dts   | 40 +++++++++++++
 3 files changed, 107 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/Makefile b/arch/arm64/boot/dts/freescale/Makefile
index a80cccf34eb5..f92670254c6a 100644
--- a/arch/arm64/boot/dts/freescale/Makefile
+++ b/arch/arm64/boot/dts/freescale/Makefile
@@ -1047,5 +1047,7 @@ dtb-$(CONFIG_ARCH_MXC) += imx8mm-phygate-tauri-l-rs232-rs485.dtb
 dtb-$(CONFIG_ARCH_S32) += s32g274a-evb.dtb
 dtb-$(CONFIG_ARCH_S32) += s32g274a-rdb2.dtb
 dtb-$(CONFIG_ARCH_S32) += s32g399a-rdb3.dtb
+dtb-$(CONFIG_ARCH_S32) += s32g399a-rdb3-serdes-mode1.dtb
+dtb-$(CONFIG_ARCH_S32) += s32g399a-rdb3-serdes-mode3.dtb
 dtb-$(CONFIG_ARCH_S32) += s32n79-rdb.dtb
 dtb-$(CONFIG_ARCH_S32) += s32v234-evb.dtb
diff --git a/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode1.dts b/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode1.dts
new file mode 100644
index 000000000000..c881376db27a
--- /dev/null
+++ b/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode1.dts
@@ -0,0 +1,65 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR BSD-3-Clause)
+/*
+ * Copyright 2021-2026 NXP
+ *
+ * NXP S32G3 Reference Design Board 3 (S32G-VNP-RDB3),
+ * SerDes_0 Mode 1: PCIe x1 (lane 0) + 1G SGMII via GMAC0 (XPCS0, lane 1).
+ */
+
+#include <dt-bindings/phy/phy.h>
+#include "s32g399a-rdb3.dts"
+
+/ {
+	model = "NXP S32G3 Reference Design Board 3 (S32G-VNP-RDB3), SerDes_0 Mode 1";
+};
+
+&serdes0 {
+	status = "okay";
+};
+
+/*
+ * SerDes_1: PCIe_1 on lane 0. Lane 1 (PFE) has no consumer, so the first
+ * matching mode, PCIe x2, is used.
+ */
+&serdes1 {
+	status = "okay";
+};
+
+/*
+ * PCIe_0 reaches the M.2 slots (M-key or E-key) when board switch SW17-2 is
+ * ON, PCIe_1 the PCIe card slot.
+ */
+&pcie0 {
+	status = "okay";
+};
+
+&pcie0_rp {
+	num-lanes = <1>;
+	phys = <&serdes0 0 PHY_TYPE_PCIE 0 0>;
+};
+
+&pcie1 {
+	status = "okay";
+};
+
+&pcie1_rp {
+	num-lanes = <1>;
+	phys = <&serdes1 0 PHY_TYPE_PCIE 0 0>;
+};
+
+&gmac0 {
+	/delete-property/ phy-handle;
+	clocks = <&clks 24>, <&clks 17>, <&clks 16>, <&clks 15>;
+	clock-names = "stmmaceth", "tx", "rx", "ptp_ref";
+	phy-mode = "sgmii";
+	phys = <&serdes0 1 PHY_TYPE_SGMII 0 1000>;
+	pcs-handle = <&serdes0>;
+	status = "okay";
+
+	/* The lane goes to the on-board SJA1110 switch, not described here */
+	fixed-link {
+		speed = <1000>;
+		full-duplex;
+		pause;
+	};
+};
diff --git a/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode3.dts b/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode3.dts
new file mode 100644
index 000000000000..8b90d5f14d2a
--- /dev/null
+++ b/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode3.dts
@@ -0,0 +1,40 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR BSD-3-Clause)
+/*
+ * Copyright 2021-2026 NXP
+ *
+ * NXP S32G3 Reference Design Board 3 (S32G-VNP-RDB3),
+ * SerDes_0 Mode 3: 1G SGMII via GMAC0 (XPCS0, lane 0). Lane 1 (XPCS1,
+ * PFE_MAC2) is not described.
+ */
+
+#include <dt-bindings/phy/phy.h>
+#include "s32g399a-rdb3.dts"
+
+/ {
+	model = "NXP S32G3 Reference Design Board 3 (S32G-VNP-RDB3), SerDes_0 Mode 3";
+};
+
+/*
+ * SerDes_0 mode 3: GMAC0 via XPCS0 on lane 0. Lane 1, PFE_MAC2 via XPCS1,
+ * has no consumer, as there is no PFE driver.
+ */
+&serdes0 {
+	status = "okay";
+};
+
+&gmac0 {
+	/delete-property/ phy-handle;
+	clocks = <&clks 24>, <&clks 17>, <&clks 16>, <&clks 15>;
+	clock-names = "stmmaceth", "tx", "rx", "ptp_ref";
+	phy-mode = "sgmii";
+	phys = <&serdes0 0 PHY_TYPE_SGMII 0 1000>;
+	pcs-handle = <&serdes0>;
+	status = "okay";
+
+	/* The lane goes to the on-board SJA1110 switch, not described here */
+	fixed-link {
+		speed = <1000>;
+		full-duplex;
+		pause;
+	};
+};

-- 
2.55.0

