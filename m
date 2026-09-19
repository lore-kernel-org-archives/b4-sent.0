From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sat, 19 Sep 2026 08:54:40 +0200
Subject: [PATCH RFC v3 12/12] arm64: dts: s32g: Add S32G3-RDB3 SerDes
 routing variants
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-s32g_serdes-v3-12-9d68868c1e89@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789800879; l=8208;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=5z4a13gWRMykKe+seCCTumv26V+4peuuuGKtho0kPws=;
 b=uo7Rz77sFsHHFKZLKP/otnbvVqBAA1sIeo+ZnR8YMNnaZwcWyUEXjmlvCvdHtffRIullQ+XMA
 0SQbpctcZToAc8EoLHdVwO9wAOcLd2M8Z+KmOlBJsVxfOl1saOMGMJg
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The S32G3-VNP-RDB3 board wires GMAC0 to an on-board KSZ9031 RGMII PHY by
default. Add two device tree variants that reroute GMAC0 over the
SerDes_0 XPCS lane for SGMII, matching the two SerDes lane layouts:

  - Mode 1: PCIe x1 root complex on lane 0 plus 1G SGMII via GMAC0
    (XPCS0) on lane 1.
  - Mode 3: dual SGMII, GMAC0 (XPCS0) on lane 0 and PFE_EMAC_2 (XPCS1)
    on lane 1.

The SerDes SUBSYS_MODE is derived from the lane child nodes present, so
each layout requires its own board device tree. The Mode 1 variant
enables both PCIe root complexes and extends their root ports by label
(pcie0_rp, pcie1_rp), matching the RDB3 wiring: PCIe_0 reaches the M.2
slots when board switch SW17-2 is ON, PCIe_1 the PCIe card slot.

The GMAC references its PCS with the standard pcs-handle property. On
this board the SGMII lane runs back-to-back to the on-board SJA1110
switch, so there is no PHY on the segment and nothing for phy-handle to
point at - the link partner is a switch port. The MAC-side link is
therefore described as a fixed 1G link and phylink uses out-of-band
negotiation. The SJA1110 itself is not described by these overlays.

Verified on the board:

  - Mode 3: GMAC0 links at 1G and passes traffic.
  - Mode 1: GMAC0 SGMII path up, and both PCIe root complexes come up -
    PCIe_1 enumerates the card-slot NIC and passes traffic at full line
    rate, PCIe_0 enumerates the M.2 slot with SW17-2 ON.

Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 arch/arm64/boot/dts/freescale/Makefile             |   6 ++
 .../dts/freescale/s32g399a-rdb3-serdes-mode1.dtso  | 111 +++++++++++++++++++++
 .../dts/freescale/s32g399a-rdb3-serdes-mode3.dtso  |  60 +++++++++++
 3 files changed, 177 insertions(+)

diff --git a/arch/arm64/boot/dts/freescale/Makefile b/arch/arm64/boot/dts/freescale/Makefile
index 95ae85ab4adf..3f68f36ac2be 100644
--- a/arch/arm64/boot/dts/freescale/Makefile
+++ b/arch/arm64/boot/dts/freescale/Makefile
@@ -786,5 +786,11 @@ dtb-$(CONFIG_ARCH_MXC) += imx8mm-phygate-tauri-l-rs232-rs485.dtb
 dtb-$(CONFIG_ARCH_S32) += s32g274a-evb.dtb
 dtb-$(CONFIG_ARCH_S32) += s32g274a-rdb2.dtb
 dtb-$(CONFIG_ARCH_S32) += s32g399a-rdb3.dtb
+dtb-$(CONFIG_ARCH_S32) += s32g399a-rdb3-serdes-mode1.dtb
+dtb-$(CONFIG_ARCH_S32) += s32g399a-rdb3-serdes-mode3.dtb
+s32g399a-rdb3-serdes-mode1-dtbs := s32g399a-rdb3.dtb s32g399a-rdb3-serdes-mode1.dtbo
+s32g399a-rdb3-serdes-mode3-dtbs := s32g399a-rdb3.dtb s32g399a-rdb3-serdes-mode3.dtbo
+dtb-$(CONFIG_ARCH_S32) += s32g399a-rdb3-serdes-mode1.dtbo
+dtb-$(CONFIG_ARCH_S32) += s32g399a-rdb3-serdes-mode3.dtbo
 dtb-$(CONFIG_ARCH_S32) += s32n79-rdb.dtb
 dtb-$(CONFIG_ARCH_S32) += s32v234-evb.dtb
diff --git a/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode1.dtso b/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode1.dtso
new file mode 100644
index 000000000000..43219d9bb6eb
--- /dev/null
+++ b/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode1.dtso
@@ -0,0 +1,111 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR BSD-3-Clause)
+/*
+ * Copyright 2021-2026 NXP
+ *
+ * NXP S32G3 Reference Design Board 3 (S32G-VNP-RDB3),
+ * SerDes_0 Mode 1: PCIe x1 (lane 0) + 1G SGMII via GMAC0 (XPCS0, lane 1).
+ *
+ * Overlay applied on top of s32g399a-rdb3.dtb. It reroutes GMAC0 from the
+ * on-board RGMII PHY to the SerDes_0 XPCS0 lane and brings up the PCIe
+ * controllers as root complexes. The lane layout present here selects
+ * SerDes SUBSYS_MODE 1.
+ */
+
+/dts-v1/;
+/plugin/;
+
+&serdes0 {
+	#address-cells = <1>;
+	#size-cells = <0>;
+	status = "okay";
+
+	/* Mode 1 lane layout: PCIe on lane 0, GMAC SGMII (XPCS0) on lane 1. */
+	serdes0_pcie0: phy@0 {
+		reg = <0>;
+		compatible = "nxp,s32g-serdes-pcie-phy";
+		#phy-cells = <0>;
+	};
+
+	serdes0_xpcs0: phy@1 {
+		reg = <1>;
+		compatible = "nxp,s32g-serdes-xpcs";
+		nxp,xpcs-instance = <0>;
+	};
+};
+
+&serdes1 {
+	#address-cells = <1>;
+	#size-cells = <0>;
+	status = "okay";
+
+	/*
+	 * SerDes_1 Mode 1 lane layout: PCIe on lane 0, SGMII (PFE_MAC0
+	 * via XPCS0) on lane 1.
+	 *
+	 * Both lanes must be described: the SerDes driver derives the
+	 * SUBSYS_MODE from the full lane mux, so lane 1 has to be present
+	 * as XPCS instance 0 (PFE_MAC0) for the mode-1 match to succeed.
+	 * PFE is not modeled as a MAC consumer in this upstreaming device
+	 * tree, so the XPCS lane is only brought up by the SerDes driver
+	 * and left without a pcs-handle user.
+	 */
+	serdes1_pcie0: phy@0 {
+		reg = <0>;
+		compatible = "nxp,s32g-serdes-pcie-phy";
+		#phy-cells = <0>;
+	};
+
+	serdes1_xpcs0: phy@1 {
+		reg = <1>;
+		compatible = "nxp,s32g-serdes-xpcs";
+		nxp,xpcs-instance = <0>;
+	};
+};
+
+/*
+ * Both PCIe root complexes are wired on the RDB3:
+ *  - PCIe_0 reaches the M.2 slots (M-key or E-key) when board switch
+ *    SW17-2 is set to ON. It consumes SerDes_0 lane-0 PCIe phy.
+ *  - PCIe_1 reaches the PCIe card slot. It consumes SerDes_1 lane-0 PCIe phy.
+ */
+&pcie0 {
+	status = "okay";
+};
+
+&pcie0_rp {
+	num-lanes = <1>;
+	phys = <&serdes0_pcie0>;
+};
+
+&pcie1 {
+	status = "okay";
+};
+
+&pcie1_rp {
+	num-lanes = <1>;
+	phys = <&serdes1_pcie0>;
+};
+
+&gmac0 {
+	/delete-property/ phy-handle;
+	clocks = <&clks 24>, <&clks 17>, <&clks 16>, <&clks 15>;
+	clock-names = "stmmaceth", "tx", "rx", "ptp_ref";
+	phy-mode = "sgmii";
+	pcs-handle = <&serdes0_xpcs0>;
+	status = "okay";
+
+	/*
+	 * GMAC0 is wired back-to-back to the on-board SJA1110 switch over
+	 * this SGMII lane. There is no PHY on the segment, so there is
+	 * nothing to reference with phy-handle: the link partner is a
+	 * switch port. Describe it as a fixed 1G link; phylink then uses
+	 * out-of-band negotiation. The switch itself is not described by
+	 * this overlay. The PCS also supports in-band negotiation, for
+	 * boards whose link partner is described.
+	 */
+	fixed-link {
+		speed = <1000>;
+		full-duplex;
+		pause;
+	};
+};
diff --git a/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode3.dtso b/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode3.dtso
new file mode 100644
index 000000000000..195c8043c18a
--- /dev/null
+++ b/arch/arm64/boot/dts/freescale/s32g399a-rdb3-serdes-mode3.dtso
@@ -0,0 +1,60 @@
+// SPDX-License-Identifier: (GPL-2.0+ OR BSD-3-Clause)
+/*
+ * Copyright 2021-2026 NXP
+ *
+ * NXP S32G3 Reference Design Board 3 (S32G-VNP-RDB3),
+ * SerDes_0 Mode 3: dual SGMII, GMAC0 (XPCS0, lane 0) + PFE_EMAC_2
+ * (XPCS1, lane 1), both 1G.
+ *
+ * Overlay applied on top of s32g399a-rdb3.dtb. It reroutes GMAC0 from the
+ * on-board RGMII PHY to the SerDes_0 XPCS0 lane. The lane-1 XPCS1
+ * (PFE_EMAC_2) is described so the mode is derivable and both XPCS
+ * instances are initialised; it has no upstream MAC consumer in this
+ * device tree. The lane layout present here selects SerDes SUBSYS_MODE 3.
+ */
+
+/dts-v1/;
+/plugin/;
+
+&serdes0 {
+	#address-cells = <1>;
+	#size-cells = <0>;
+	status = "okay";
+
+	/* Mode 3 lane layout: GMAC SGMII (XPCS0) on lane 0, PFE2 (XPCS1) on lane 1. */
+	serdes0_xpcs0: phy@0 {
+		reg = <0>;
+		compatible = "nxp,s32g-serdes-xpcs";
+		nxp,xpcs-instance = <0>;
+	};
+
+	serdes0_xpcs1: phy@1 {
+		reg = <1>;
+		compatible = "nxp,s32g-serdes-xpcs";
+		nxp,xpcs-instance = <1>;
+	};
+};
+
+&gmac0 {
+	/delete-property/ phy-handle;
+	clocks = <&clks 24>, <&clks 17>, <&clks 16>, <&clks 15>;
+	clock-names = "stmmaceth", "tx", "rx", "ptp_ref";
+	phy-mode = "sgmii";
+	pcs-handle = <&serdes0_xpcs0>;
+	status = "okay";
+
+	/*
+	 * GMAC0 is wired back-to-back to the on-board SJA1110 switch over
+	 * this SGMII lane. There is no PHY on the segment, so there is
+	 * nothing to reference with phy-handle: the link partner is a
+	 * switch port. Describe it as a fixed 1G link; phylink then uses
+	 * out-of-band negotiation. The switch itself is not described by
+	 * this overlay. The PCS also supports in-band negotiation, for
+	 * boards whose link partner is described.
+	 */
+	fixed-link {
+		speed = <1000>;
+		full-duplex;
+		pause;
+	};
+};

-- 
2.55.0

