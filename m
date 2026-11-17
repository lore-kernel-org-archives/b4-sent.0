From: Vincent Jardin <vjardin@free.fr>
Date: Tue, 17 Nov 2026 15:53:13 +0100
Subject: [PATCH v7 3/6] soc: fsl: guts: add the RCW override of the pad
 muxes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-for-upstream-lx2160a-rcw-pinmux-v1-v7-3-5d7201970629@free.fr>
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
 Ioana Ciornei <ioana.ciornei@nxp.com>, Vincent Jardin <vjardin@free.fr>, 
 Frank Li <Frank.li@nxp.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794927205; l=7041;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=4Khm3hCvrMogp9PTwDSYhfZupNH5AvurpUf5Y1BHs04=;
 b=VfJiGnU5EmkBWPuf/u2CfnqXt93x/dVG6rXlc/mN3xMKHaj4yG9NwTGOrhzXlanTWs+5gOYdb
 +CuNK5wRGLZDJQ/yknMSXwemRFLGTaCq9ZlwGNzDQh3P8KxGbQNFbKg
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fsl_guts_rcw_rmw() only serves the SerDes lane modes. Export it for
the pad-mux fields of the RCW, and for them only:
 - fsl_guts_pmux_read() reads the pad-mux fields of a status register
 - fsl_guts_pmux_override() changes pad-mux fields of one under
   rcwcr_lock and waits for the status register to follow
 - fsl_guts_pmux_override_supported() tells whether the SoC has pad-mux
   fields and whether the DCSR view of DCFG, which holds the override
   registers, is mapped

Each SoC lists in its fsl_soc_data the fields that can be overridden,
per RCWSR: a register or a field outside of this list is refused, so
the SerDes protocols stay with fsl_guts_lane_set_mode(). The LX2160A
lists the pad muxes of RCWSR12 to RCWSR14 and of RCWSR27.

Suggested-by: Vladimir Oltean <vladimir.oltean@nxp.com>
Acked-by: Frank Li <Frank.li@nxp.com>
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/soc/fsl/guts.c   | 125 ++++++++++++++++++++++++++++++++++++++++++++++-
 include/linux/fsl/guts.h |   3 ++
 2 files changed, 127 insertions(+), 1 deletion(-)

diff --git a/drivers/soc/fsl/guts.c b/drivers/soc/fsl/guts.c
index 28361c63e26c1..a4b767f1e297a 100644
--- a/drivers/soc/fsl/guts.c
+++ b/drivers/soc/fsl/guts.c
@@ -53,6 +53,12 @@ struct fsl_soc_serdes_rcw_override {
 	int val;
 };
 
+/* Pad-mux fields of the one-based RCWSRn, the ones that may be overridden */
+struct fsl_soc_pmux_mask {
+	unsigned int rcwsr;
+	u32 mask;
+};
+
 struct fsl_soc_data {
 	const char *sfp_compat;
 	u32 uid_offset;
@@ -62,6 +68,7 @@ struct fsl_soc_data {
 	int (*serdes_get_rcw_override)(int index, int lane,
 				       enum lynx_lane_mode lane_mode,
 				       struct fsl_soc_serdes_rcw_override *override);
+	const struct fsl_soc_pmux_mask *pmux;
 };
 
 enum qoriq_die {
@@ -369,6 +376,110 @@ int fsl_guts_lane_set_mode(int serdes_idx, int lane, enum lynx_lane_mode lane_mo
 }
 EXPORT_SYMBOL_NS_GPL(fsl_guts_lane_set_mode, "FSL_GUTS");
 
+static const struct fsl_soc_pmux_mask *
+fsl_guts_get_pmux_mask(unsigned int rcwsr)
+{
+	const struct fsl_soc_pmux_mask *pmux;
+
+	if (!soc.data || !soc.data->pmux)
+		return NULL;
+
+	for (pmux = soc.data->pmux; pmux->rcwsr; pmux++) {
+		if (pmux->rcwsr == rcwsr)
+			return pmux;
+	}
+
+	return NULL;
+}
+
+/**
+ * fsl_guts_pmux_read() - read the pad-mux fields of a RCW status register
+ * @rcwsr: one-based index of the status register, as in RCWSR12
+ * @val: the pad-mux fields read, the other fields of the register are 0
+ *
+ * Return: 0 on success, -ENODEV before the DCFG block is mapped, -EINVAL
+ * when the register holds no pad-mux field on this SoC
+ */
+int fsl_guts_pmux_read(unsigned int rcwsr, u32 *val)
+{
+	const struct fsl_soc_pmux_mask *pmux;
+
+	if (!soc.dcfg_ccsr)
+		return -ENODEV;
+
+	pmux = fsl_guts_get_pmux_mask(rcwsr);
+	if (!pmux)
+		return -EINVAL;
+
+	*val = fsl_guts_read(&soc.dcfg_ccsr->rcwsr[rcwsr - 1]) & pmux->mask;
+
+	return 0;
+}
+EXPORT_SYMBOL_NS_GPL(fsl_guts_pmux_read, "FSL_GUTS");
+
+/**
+ * fsl_guts_pmux_override() - override pad-mux fields of the RCW
+ * @rcwsr: one-based index of the RCWSR and RCWCR pair, as in RCWSR12
+ * @val: the new value of the fields, in place
+ * @mask: the fields to change
+ *
+ * Only the pad-mux fields that the SoC lists can be changed: a SerDes
+ * protocol is changed with fsl_guts_lane_set_mode(), and the other fields
+ * of the RCW are refused.
+ *
+ * The fields outside @mask keep the value the status register shows. The
+ * override register is written and the status register polled until it
+ * shows the result, as fsl_guts_lane_set_mode() does for a SerDes lane.
+ *
+ * Context: takes rcwcr_lock, shared with fsl_guts_lane_set_mode(), and
+ * busy-polls the status register a bounded number of times. Does not
+ * sleep, shall not be called from interrupt context.
+ *
+ * Return:
+ * * 0 on success
+ * * -ENODEV before the DCFG block is mapped
+ * * -EOPNOTSUPP without a DCSR mapping of DCFG
+ * * -EINVAL when @mask is not made of pad-mux fields of the register
+ * * negative error otherwise
+ */
+int fsl_guts_pmux_override(unsigned int rcwsr, u32 val, u32 mask)
+{
+	const struct fsl_soc_pmux_mask *pmux;
+	int err;
+
+	if (!soc.dcfg_ccsr)
+		return -ENODEV;
+	if (!soc.dcfg_dcsr)
+		return -EOPNOTSUPP;
+
+	pmux = fsl_guts_get_pmux_mask(rcwsr);
+	if (!pmux || !mask || (mask & ~pmux->mask))
+		return -EINVAL;
+
+	spin_lock(&soc.rcwcr_lock);
+	err = fsl_guts_rcw_rmw(rcwsr - 1, val & mask, mask);
+	spin_unlock(&soc.rcwcr_lock);
+	if (err)
+		pr_err("RCW override of RCWSR%u failed: %pe\n", rcwsr,
+		       ERR_PTR(err));
+
+	return err;
+}
+EXPORT_SYMBOL_NS_GPL(fsl_guts_pmux_override, "FSL_GUTS");
+
+/**
+ * fsl_guts_pmux_override_supported() - can the pad muxes be overridden?
+ *
+ * Return: true when the SoC lists pad-mux fields and the DCFG block is
+ * mapped with its DCSR view, the second reg of the dcfg node, which holds
+ * the override registers
+ */
+bool fsl_guts_pmux_override_supported(void)
+{
+	return soc.dcfg_ccsr && soc.dcfg_dcsr && soc.data && soc.data->pmux;
+}
+EXPORT_SYMBOL_NS_GPL(fsl_guts_pmux_override_supported, "FSL_GUTS");
+
 static u64 fsl_guts_get_soc_uid(const char *compat, unsigned int offset)
 {
 	struct device_node *np;
@@ -579,6 +690,18 @@ static const struct fsl_soc_data ls1028a_data = {
 	.num_serdes_lanes = 4,
 };
 
+static const struct fsl_soc_pmux_mask lx2160a_pmux[] = {
+	{ 12, GENMASK(29, 0) },	/* IIC2..SDHC1_DIR */
+	{ 13, GENMASK(29, 0) },	/* SDHC2_DAT74..EVT43 */
+	{ 14, GENMASK(10, 0) },	/* EVT20..IIC1 */
+	{ 27, GENMASK(7, 0) },	/* EC1, EC2, USB_EXT, GTX_CLK, SDHC1_DS */
+	{}
+};
+
+static const struct fsl_soc_data lx2160a_data = {
+	.pmux = lx2160a_pmux,
+};
+
 /*
  * Table for matching compatible strings, for device tree
  * guts node, for Freescale QorIQ SOCs.
@@ -606,7 +729,7 @@ static const struct of_device_id fsl_guts_of_match[] = {
 	{ .compatible = "fsl,ls1088a-dcfg", .data = &ls1088a_data},
 	{ .compatible = "fsl,ls1012a-dcfg", },
 	{ .compatible = "fsl,ls1046a-dcfg", .data = &ls1046a_data},
-	{ .compatible = "fsl,lx2160a-dcfg", },
+	{ .compatible = "fsl,lx2160a-dcfg", .data = &lx2160a_data},
 	{ .compatible = "fsl,ls1028a-dcfg", .data = &ls1028a_data},
 	{}
 };
diff --git a/include/linux/fsl/guts.h b/include/linux/fsl/guts.h
index 8d5ffb985feed..ae245afeb7b9d 100644
--- a/include/linux/fsl/guts.h
+++ b/include/linux/fsl/guts.h
@@ -142,6 +142,9 @@ int fsl_guts_lane_validate(int serdes_idx, int lane,
 			   enum lynx_lane_mode lane_mode);
 int fsl_guts_lane_set_mode(int serdes_idx, int lane,
 			   enum lynx_lane_mode lane_mode);
+int fsl_guts_pmux_read(unsigned int rcwsr, u32 *val);
+int fsl_guts_pmux_override(unsigned int rcwsr, u32 val, u32 mask);
+bool fsl_guts_pmux_override_supported(void);
 
 /* Alternate function signal multiplex control */
 #define MPC85xx_PMUXCR_QE(x) (0x8000 >> (x))

-- 
2.43.0

