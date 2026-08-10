From: Jason Yang <jason98166@gmail.com>
Date: Mon, 10 Aug 2026 20:10:13 +0800
Subject: [PATCH v3 5/5] phy: rockchip-samsung-dcphy: add MIPI D-PHY
 receiver support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-dcphy-rx-v1-v3-5-a2d25c29adfc@gmail.com>
References: <20260810-dcphy-rx-v1-v3-0-a2d25c29adfc@gmail.com>
In-Reply-To: <20260810-dcphy-rx-v1-v3-0-a2d25c29adfc@gmail.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Guochun Huang <hero.huang@rock-chips.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Michael Riesch <michael.riesch@collabora.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Yang <jason98166@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786363808; l=17787;
 i=jason98166@gmail.com; s=20260721; h=from:subject:message-id;
 bh=tMMXD0GP4BL/tBurC5Puf4KgLonyt1lpbxE8ChZX5UI=;
 b=+Z4yWbLcG8NVX5xN+wxPxTEpXzqQ1jhN2+xCfA6NguuG8Fy5WWJoqs4PHT344aeM7CxytS0aI
 Ko/mdVq2QrKBgerhD7xQgNfeWj+b3Bz8b9dmA0vWdr2aLZwcS4CwWKb
X-Developer-Key: i=jason98166@gmail.com; a=ed25519;
 pk=xQmD001Q/ooHl39PxyQtusbUQmgbOsSfpFryRVWZ/k4=
X-Endpoint-Received: by B4 Relay for jason98166@gmail.com/20260721 with auth_id=887
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the receiver (CSI) PHY: add the RX register layout (clock
lane and four data lanes), the HS-frequency settle table, and the
receiver bring-up and teardown, wired into the per-PHY power paths.
The PLL stays off in the receiver - RK3588 TRM section 22.6.3 step (3)
notes that "If Slave Lanes are only used, then PLL sequence can be
skipped", the sensor supplying the link clock instead - so configure()
only records the requested rate for the settle lookup.

The bring-up follows the TRM receiver start-up sequence (section 22.6.3
and the worked receiver example in section 22.6.4.3): assert S_RESETN,
program the settle configuration, enable the lanes, wait for PHY_READY,
and only then release S_RESETN. Step (8) of section 22.6.3 is explicit
that S_RESETN is released only "after all of PHY_READY of each Lane",
so PHY_READY is polled while the lane reset is still asserted.

The receiver reaches the shared common block through the same
use-counted helper as the transmitter, so a receiver-first power-on
also gets the APB reset and the BIAS programming.

The HS-RX settle values come from the rk3588 vendor kernel; the table
in the driver records why they are not derived from the TRM.

Tested on an RK3588 board with an IMX219 camera on DCPHY0's
receiver and a DSI panel on the same PHY's transmitter. Both power-on
orders work: transmitter first with the camera joining, and receiver
first with the transmitter joining mid-stream without disturbing the
capture (150 consecutive frames, byte-exact). Repeated camera
start/stop and panel enable/disable cycles complete without PHY
errors, the settle registers read back as programmed while streaming,
and the receiver-first bring-up was also verified with an OV5640.

Signed-off-by: Jason Yang <jason98166@gmail.com>
Assisted-by: Claude:claude-fable-5
---
 drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c | 356 +++++++++++++++++++++-
 1 file changed, 348 insertions(+), 8 deletions(-)

diff --git a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
index 09dbcf438f99..4f945b6dcc96 100644
--- a/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
+++ b/drivers/phy/rockchip/phy-rockchip-samsung-dcphy.c
@@ -246,6 +246,63 @@
 #define T_TA_GET(x)		FIELD_PREP(GENMASK(7, 4), x)
 #define T_TA_GO(x)		FIELD_PREP(GENMASK(3, 0), x)
 
+/* D-PHY receiver registers (clock lane + four data lanes) */
+#define DPHY_SC_GNR_CON0	0x0b00
+#define DPHY_SC_GNR_CON1	0x0b04
+#define DPHY_SC_ANA_CON1	0x0b0c
+#define HS_RX_BIAS_CON(x)	FIELD_PREP(GENMASK(15, 11), x)
+#define DPHY_SC_ANA_CON2	0x0b10
+#define HS_TERM_SW(x)		FIELD_PREP(GENMASK(2, 0), x)
+#define DPHY_SC_ANA_CON3	0x0b14
+#define ULPS_HYS_SW_DPHY(x)	FIELD_PREP(GENMASK(10, 8), x)
+#define DPHY_SC_TIME_CON0	0x0b30
+#define T_CLK_SETTLE(x)		FIELD_PREP(GENMASK(7, 0), x)
+#define T_CLK_MISS(x)		FIELD_PREP(GENMASK(11, 8), x)
+#define COMBO_SD0_GNR_CON0	0x0c00
+#define COMBO_SD0_GNR_CON1	0x0c04
+#define COMBO_SD0_ANA_CON1	0x0c0c
+#define COMBO_SD0_ANA_CON2	0x0c10
+#define SKEW_DLYSEL(x)		FIELD_PREP(GENMASK(9, 8), x)
+#define RX_TERM_SW(x)		FIELD_PREP(GENMASK(2, 0), x)
+#define COMBO_SD0_ANA_CON3	0x0c14
+#define SEL_ESCPOL		BIT(11)
+#define LP_HYS_SW(x)		FIELD_PREP(GENMASK(5, 4), x)
+#define COMBO_SD0_ANA_CON7	0x0c24
+#define CLK_DBL_CTRL(x)		FIELD_PREP(GENMASK(7, 6), x)
+#define COMBO_SD0_TIME_CON0	0x0c30
+#define T_HS_SETTLE(x)		FIELD_PREP(GENMASK(7, 0), x)
+#define SETTLE_CLK_SEL		BIT(8)
+#define COMBO_SD0_TIME_CON1	0x0c34
+#define T_ERR_SOT_SYNC(x)	FIELD_PREP(GENMASK(7, 0), x)
+#define COMBO_SD0_DESKEW_CON2	0x0c48
+#define SKEW_CAL_CLK_COARSE_SET(x) FIELD_PREP(GENMASK(4, 0), x)
+#define COMBO_SD1_GNR_CON0	0x0d00
+#define COMBO_SD1_GNR_CON1	0x0d04
+#define COMBO_SD1_ANA_CON1	0x0d0c
+#define COMBO_SD1_ANA_CON2	0x0d10
+#define COMBO_SD1_ANA_CON3	0x0d14
+#define COMBO_SD1_ANA_CON7	0x0d24
+#define COMBO_SD1_TIME_CON0	0x0d30
+#define COMBO_SD1_TIME_CON1	0x0d34
+#define COMBO_SD1_DESKEW_CON2	0x0d48
+#define COMBO_SD2_GNR_CON0	0x0e00
+#define COMBO_SD2_GNR_CON1	0x0e04
+#define COMBO_SD2_ANA_CON1	0x0e0c
+#define COMBO_SD2_ANA_CON2	0x0e10
+#define COMBO_SD2_ANA_CON3	0x0e14
+#define COMBO_SD2_ANA_CON7	0x0e24
+#define COMBO_SD2_TIME_CON0	0x0e30
+#define COMBO_SD2_TIME_CON1	0x0e34
+#define COMBO_SD2_DESKEW_CON2	0x0e48
+#define DPHY_SD3_GNR_CON0	0x0f00
+#define DPHY_SD3_GNR_CON1	0x0f04
+#define DPHY_SD3_ANA_CON1	0x0f0c
+#define DPHY_SD3_ANA_CON2	0x0f10
+#define DPHY_SD3_ANA_CON3	0x0f14
+#define DPHY_SD3_TIME_CON0	0x0f30
+#define DPHY_SD3_TIME_CON1	0x0f34
+#define DPHY_SD3_DESKEW_CON2	0x0f48
+
 /* MIPI_CDPHY_GRF registers */
 #define MIPI_DCPHY_GRF_CON0		0x0000
 #define S_CPHY_MODE			FIELD_PREP_WM16(BIT(3), 1)
@@ -298,6 +355,7 @@ struct samsung_mipi_phy {
 	/* Electrical layer (PHY_TYPE_DPHY/CPHY), not the DT cell value. */
 	u8 type;
 	unsigned int lanes;
+	unsigned long long hs_clk_rate;
 };
 
 struct samsung_mipi_dcphy {
@@ -998,6 +1056,238 @@ struct samsung_mipi_dphy_timing samsung_mipi_dphy_timing_table[] = {
 	{  80,  2,   0,  0, 28,  5,  0, 22,  2,  0,  5},
 };
 
+/* D-PHY receiver HS-RX configuration lookup */
+struct samsung_mipi_dphy_rx_hsfreq_range {
+	u32 range_h_mbps;
+	u16 cfg_bit;
+};
+
+/*
+ * HS RX settle values taken verbatim from the rk3588 vendor kernel.
+ * The TRM defines these fields but defers the per-data-rate table to a
+ * timing supplement. Each cfg_bit is a pre-combined SETTLE_CLK_SEL |
+ * T_HS_SETTLE value for the data-lane TIME_CON0: bit 8 selects the
+ * divide-by-2 settle clock below 1500 Mbps per the TRM (the vendor
+ * table switches one bucket early, at 1490 Mbps, and is kept
+ * unchanged). The TRM marks bit 8 read-only, but the vendor kernel has
+ * always programmed it. Sorted by .range_h_mbps ascending.
+ */
+static const struct samsung_mipi_dphy_rx_hsfreq_range samsung_mipi_dphy_rx_hsfreq_ranges[] = {
+	{   80, 0x105 }, {  100, 0x106 }, {  120, 0x107 }, {  140, 0x108 },
+	{  160, 0x109 }, {  180, 0x10a }, {  200, 0x10b }, {  220, 0x10c },
+	{  240, 0x10d }, {  270, 0x10e }, {  290, 0x10f }, {  310, 0x110 },
+	{  330, 0x111 }, {  350, 0x112 }, {  370, 0x113 }, {  390, 0x114 },
+	{  410, 0x115 }, {  430, 0x116 }, {  450, 0x117 }, {  470, 0x118 },
+	{  490, 0x119 }, {  510, 0x11a }, {  540, 0x11b }, {  560, 0x11c },
+	{  580, 0x11d }, {  600, 0x11e }, {  620, 0x11f }, {  640, 0x120 },
+	{  660, 0x121 }, {  680, 0x122 }, {  700, 0x123 }, {  720, 0x124 },
+	{  740, 0x125 }, {  760, 0x126 }, {  790, 0x127 }, {  810, 0x128 },
+	{  830, 0x129 }, {  850, 0x12a }, {  870, 0x12b }, {  890, 0x12c },
+	{  910, 0x12d }, {  930, 0x12e }, {  950, 0x12f }, {  970, 0x130 },
+	{  990, 0x131 }, { 1010, 0x132 }, { 1030, 0x133 }, { 1060, 0x134 },
+	{ 1080, 0x135 }, { 1100, 0x136 }, { 1120, 0x137 }, { 1140, 0x138 },
+	{ 1160, 0x139 }, { 1180, 0x13a }, { 1200, 0x13b }, { 1220, 0x13c },
+	{ 1240, 0x13d }, { 1260, 0x13e }, { 1280, 0x13f }, { 1310, 0x140 },
+	{ 1330, 0x141 }, { 1350, 0x142 }, { 1370, 0x143 }, { 1390, 0x144 },
+	{ 1410, 0x145 }, { 1430, 0x146 }, { 1450, 0x147 }, { 1470, 0x148 },
+	{ 1490, 0x149 }, { 1580, 0x007 }, { 1740, 0x008 }, { 1910, 0x009 },
+	{ 2070, 0x00a }, { 2240, 0x00b }, { 2410, 0x00c }, { 2570, 0x00d },
+	{ 2740, 0x00e }, { 2910, 0x00f }, { 3070, 0x010 }, { 3240, 0x011 },
+	{ 3410, 0x012 }, { 3570, 0x013 }, { 3740, 0x014 }, { 3890, 0x015 },
+	{ 4070, 0x016 }, { 4240, 0x017 }, { 4400, 0x018 }, { 4500, 0x019 },
+};
+
+static int samsung_mipi_dphy_rx_lookup_hsfreq(u32 lane_mbps, u16 *cfg_bit)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(samsung_mipi_dphy_rx_hsfreq_ranges); i++) {
+		if (lane_mbps <= samsung_mipi_dphy_rx_hsfreq_ranges[i].range_h_mbps) {
+			*cfg_bit = samsung_mipi_dphy_rx_hsfreq_ranges[i].cfg_bit;
+			return 0;
+		}
+	}
+
+	return -ERANGE;
+}
+
+/* SKEW_DLYSEL per data rate, from the RK3588 TRM ANA_CON2 description */
+static u32 samsung_mipi_dphy_rx_data_lane_dlysel(u32 lane_mbps)
+{
+	if (lane_mbps < 1500)
+		return 0;
+	if (lane_mbps < 2000)
+		return SKEW_DLYSEL(3);
+	if (lane_mbps < 3000)
+		return SKEW_DLYSEL(2);
+	if (lane_mbps < 4000)
+		return SKEW_DLYSEL(1);
+	return 0;
+}
+
+/*
+ * Per-data-lane register bases, indexed by lane number. The clock lane
+ * shares the same block spacing but is programmed separately: its
+ * TIME_CON0 holds T_CLK_SETTLE/T_CLK_MISS rather than the per-rate
+ * T_HS_SETTLE/SETTLE_CLK_SEL, and it has no deskew configuration.
+ */
+static const u32 rx_data_lane_gnr_con0[] = {
+	COMBO_SD0_GNR_CON0, COMBO_SD1_GNR_CON0,
+	COMBO_SD2_GNR_CON0, DPHY_SD3_GNR_CON0,
+};
+
+static const u32 rx_lane_time_con0[] = {
+	COMBO_SD0_TIME_CON0, COMBO_SD1_TIME_CON0,
+	COMBO_SD2_TIME_CON0, DPHY_SD3_TIME_CON0,
+};
+
+static const u32 rx_lane_time_con1[] = {
+	COMBO_SD0_TIME_CON1, COMBO_SD1_TIME_CON1,
+	COMBO_SD2_TIME_CON1, DPHY_SD3_TIME_CON1,
+};
+
+/*
+ * These RX analog tuning values come from the vendor BSP. The
+ * termination (RX_TERM_SW/HS_TERM_SW = 2) is the 96.6 ohm setting the
+ * TRM ANA_CON2 value list annotates as the default, although the
+ * register itself resets to 102 ohm. Data lane 0 differs on purpose:
+ * the vendor's default receive profile applies the LP hysteresis and
+ * the inverted escape clock polarity to lane 0 only, and a coarse
+ * skew-calibration clock of 0 there against 3 on the other lanes.
+ * Data lane 3 is a plain D-PHY lane with no ANA_CON7, so it gets no
+ * CLK_DBL_CTRL write.
+ */
+static void samsung_mipi_dphy_rx_config_common(struct samsung_mipi_dcphy *samsung)
+{
+	struct samsung_mipi_phy *rx = &samsung->phys[SAMSUNG_MIPI_RX];
+	u32 dlysel = samsung_mipi_dphy_rx_data_lane_dlysel(div_u64(rx->hs_clk_rate,
+								   1000000));
+	u32 ana_con2_common = dlysel | RX_TERM_SW(2);
+
+	/* Clock lane */
+	regmap_write(samsung->regmap, DPHY_SC_GNR_CON1, T_PHY_READY(0x1450));
+	regmap_write(samsung->regmap, DPHY_SC_ANA_CON1, HS_RX_BIAS_CON(0x10));
+	regmap_write(samsung->regmap, DPHY_SC_ANA_CON2, HS_TERM_SW(2));
+	regmap_write(samsung->regmap, DPHY_SC_ANA_CON3, ULPS_HYS_SW_DPHY(6));
+
+	/* Data lane 0; a zero lane count is rejected at power-on */
+	regmap_write(samsung->regmap, COMBO_SD0_GNR_CON1, T_PHY_READY(0x1450));
+	regmap_write(samsung->regmap, COMBO_SD0_ANA_CON1, HS_RX_BIAS_CON(0x10));
+	regmap_write(samsung->regmap, COMBO_SD0_ANA_CON2, ana_con2_common);
+	regmap_write(samsung->regmap, COMBO_SD0_ANA_CON3,
+		     ULPS_HYS_SW_DPHY(6) | LP_HYS_SW(3) | SEL_ESCPOL);
+	regmap_write(samsung->regmap, COMBO_SD0_ANA_CON7, CLK_DBL_CTRL(1));
+	regmap_write(samsung->regmap, COMBO_SD0_DESKEW_CON2, SKEW_CAL_CLK_COARSE_SET(0));
+
+	/* Data lane 1 */
+	if (rx->lanes > 1) {
+		regmap_write(samsung->regmap, COMBO_SD1_GNR_CON1, T_PHY_READY(0x1450));
+		regmap_write(samsung->regmap, COMBO_SD1_ANA_CON1, HS_RX_BIAS_CON(0x10));
+		regmap_write(samsung->regmap, COMBO_SD1_ANA_CON2, ana_con2_common);
+		regmap_write(samsung->regmap, COMBO_SD1_ANA_CON3, ULPS_HYS_SW_DPHY(6));
+		regmap_write(samsung->regmap, COMBO_SD1_ANA_CON7, CLK_DBL_CTRL(1));
+		regmap_write(samsung->regmap, COMBO_SD1_DESKEW_CON2, SKEW_CAL_CLK_COARSE_SET(3));
+	}
+
+	/* Data lane 2 */
+	if (rx->lanes > 2) {
+		regmap_write(samsung->regmap, COMBO_SD2_GNR_CON1, T_PHY_READY(0x1450));
+		regmap_write(samsung->regmap, COMBO_SD2_ANA_CON1, HS_RX_BIAS_CON(0x10));
+		regmap_write(samsung->regmap, COMBO_SD2_ANA_CON2, ana_con2_common);
+		regmap_write(samsung->regmap, COMBO_SD2_ANA_CON3, ULPS_HYS_SW_DPHY(6));
+		regmap_write(samsung->regmap, COMBO_SD2_ANA_CON7, CLK_DBL_CTRL(1));
+		regmap_write(samsung->regmap, COMBO_SD2_DESKEW_CON2, SKEW_CAL_CLK_COARSE_SET(3));
+	}
+
+	/* Data lane 3 */
+	if (rx->lanes > 3) {
+		regmap_write(samsung->regmap, DPHY_SD3_GNR_CON1, T_PHY_READY(0x1450));
+		regmap_write(samsung->regmap, DPHY_SD3_ANA_CON1, HS_RX_BIAS_CON(0x10));
+		regmap_write(samsung->regmap, DPHY_SD3_ANA_CON2, ana_con2_common);
+		regmap_write(samsung->regmap, DPHY_SD3_ANA_CON3, ULPS_HYS_SW_DPHY(6));
+		regmap_write(samsung->regmap, DPHY_SD3_DESKEW_CON2, SKEW_CAL_CLK_COARSE_SET(3));
+	}
+}
+
+static int samsung_mipi_dphy_rx_config_settle(struct samsung_mipi_dcphy *samsung)
+{
+	struct samsung_mipi_phy *rx = &samsung->phys[SAMSUNG_MIPI_RX];
+	u32 lane_mbps = div_u64(rx->hs_clk_rate, 1000000);
+	unsigned int i;
+	u16 cfg_bit;
+	int ret;
+
+	ret = samsung_mipi_dphy_rx_lookup_hsfreq(lane_mbps, &cfg_bit);
+	if (ret) {
+		dev_err(samsung->dev,
+			"no RX hsfreq cfg for %u Mbps (limit ~4500 Mbps)\n",
+			lane_mbps);
+		return ret;
+	}
+
+	/*
+	 * Clock-lane settle uses the fixed value from the TRM RX bring-up
+	 * example, unlike the per-rate data-lane settle below.
+	 */
+	regmap_write(samsung->regmap, DPHY_SC_TIME_CON0,
+		     T_CLK_SETTLE(0x01) | T_CLK_MISS(0x03));
+
+	for (i = 0; i < rx->lanes; i++) {
+		regmap_update_bits(samsung->regmap, rx_lane_time_con0[i],
+				   T_HS_SETTLE(0xff) | SETTLE_CLK_SEL, cfg_bit);
+		regmap_update_bits(samsung->regmap, rx_lane_time_con1[i],
+				   T_ERR_SOT_SYNC(0xff), T_ERR_SOT_SYNC(0x03));
+	}
+
+	return 0;
+}
+
+static void samsung_mipi_dphy_rx_lane_disable(struct samsung_mipi_dcphy *samsung)
+{
+	struct samsung_mipi_phy *rx = &samsung->phys[SAMSUNG_MIPI_RX];
+	unsigned int i;
+
+	regmap_update_bits(samsung->regmap, DPHY_SC_GNR_CON0, PHY_ENABLE, 0);
+	for (i = 0; i < rx->lanes; i++)
+		regmap_update_bits(samsung->regmap, rx_data_lane_gnr_con0[i],
+				   PHY_ENABLE, 0);
+}
+
+static int samsung_mipi_dphy_rx_lane_enable(struct samsung_mipi_dcphy *samsung)
+{
+	struct samsung_mipi_phy *rx = &samsung->phys[SAMSUNG_MIPI_RX];
+	unsigned int i;
+	u32 sts;
+	int ret;
+
+	regmap_update_bits(samsung->regmap, DPHY_SC_GNR_CON0, PHY_ENABLE, PHY_ENABLE);
+	for (i = 0; i < rx->lanes; i++)
+		regmap_update_bits(samsung->regmap, rx_data_lane_gnr_con0[i],
+				   PHY_ENABLE, PHY_ENABLE);
+
+	ret = regmap_read_poll_timeout(samsung->regmap, DPHY_SC_GNR_CON0,
+				       sts, sts & PHY_READY, 200, 4000);
+	if (ret) {
+		dev_err(samsung->dev, "RX clock lane not ready\n");
+		goto err_lane_disable;
+	}
+
+	for (i = 0; i < rx->lanes; i++) {
+		ret = regmap_read_poll_timeout(samsung->regmap, rx_data_lane_gnr_con0[i],
+					       sts, sts & PHY_READY, 200, 2000);
+		if (ret) {
+			dev_err(samsung->dev, "RX data lane %u not ready\n", i);
+			goto err_lane_disable;
+		}
+	}
+
+	return 0;
+
+err_lane_disable:
+	samsung_mipi_dphy_rx_lane_disable(samsung);
+	return ret;
+}
+
 /*
  * The APB reset is block-level and has to be assumed to return the whole
  * register file to the defaults of TRM section 22.4.2, which would leave
@@ -1047,6 +1337,55 @@ static void samsung_mipi_dcphy_common_put(struct samsung_mipi_dcphy *samsung)
 	samsung->common_users--;
 }
 
+static int samsung_mipi_dphy_rx_power_on(struct samsung_mipi_dcphy *samsung)
+{
+	struct samsung_mipi_phy *rx = &samsung->phys[SAMSUNG_MIPI_RX];
+	int ret;
+
+	if (!rx->hs_clk_rate || !rx->lanes)
+		return -EINVAL;
+
+	samsung_mipi_dcphy_common_get(samsung);
+
+	reset_control_assert(samsung->s_phy_rst);
+
+	samsung_mipi_dphy_rx_config_common(samsung);
+
+	ret = samsung_mipi_dphy_rx_config_settle(samsung);
+	if (ret)
+		goto out_deassert;
+
+	ret = samsung_mipi_dphy_rx_lane_enable(samsung);
+
+out_deassert:
+	reset_control_deassert(samsung->s_phy_rst);
+
+	if (ret)
+		samsung_mipi_dcphy_common_put(samsung);
+
+	return ret;
+}
+
+static int samsung_mipi_dphy_rx_power_off(struct samsung_mipi_dcphy *samsung)
+{
+	reset_control_assert(samsung->s_phy_rst);
+
+	samsung_mipi_dphy_rx_lane_disable(samsung);
+
+	reset_control_deassert(samsung->s_phy_rst);
+
+	/*
+	 * Let the lanes settle out of reset before the block may be reset
+	 * again by the next bring-up. The delay follows the vendor driver;
+	 * the TRM does not document a teardown sequence.
+	 */
+	usleep_range(500, 1000);
+
+	samsung_mipi_dcphy_common_put(samsung);
+
+	return 0;
+}
+
 static void samsung_mipi_dphy_lane_enable(struct samsung_mipi_dcphy *samsung)
 {
 	regmap_write(samsung->regmap, DPHY_MC_GNR_CON1, T_PHY_READY(0x2000));
@@ -1444,7 +1783,7 @@ static int samsung_mipi_dcphy_power_on(struct phy *phy)
 
 	mutex_lock(&samsung->lock);
 	if (samsung_phy->id == SAMSUNG_MIPI_RX)
-		ret = -EOPNOTSUPP;
+		ret = samsung_mipi_dphy_rx_power_on(samsung);
 	else
 		ret = samsung_mipi_dphy_tx_power_on(samsung);
 	mutex_unlock(&samsung->lock);
@@ -1464,7 +1803,7 @@ static int samsung_mipi_dcphy_power_off(struct phy *phy)
 
 	mutex_lock(&samsung->lock);
 	if (samsung_phy->id == SAMSUNG_MIPI_RX)
-		ret = -EOPNOTSUPP;
+		ret = samsung_mipi_dphy_rx_power_off(samsung);
 	else
 		ret = samsung_mipi_dphy_tx_power_off(samsung);
 	mutex_unlock(&samsung->lock);
@@ -1566,14 +1905,15 @@ static int samsung_mipi_dcphy_configure(struct phy *phy,
 	struct samsung_mipi_dcphy *samsung = samsung_phy->parent;
 	unsigned long long target_rate = opts->mipi_dphy.hs_clk_rate;
 
-	/* The receiver is brought up in a later change. */
-	if (samsung_phy->id == SAMSUNG_MIPI_RX)
-		return -EOPNOTSUPP;
-
 	samsung_phy->lanes = opts->mipi_dphy.lanes > 4 ? 4 : opts->mipi_dphy.lanes;
 
-	samsung_mipi_dcphy_pll_calc_rate(samsung, target_rate);
-	opts->mipi_dphy.hs_clk_rate = samsung->pll.rate;
+	if (samsung_phy->id == SAMSUNG_MIPI_RX) {
+		/* The sensor supplies the link clock; the PLL stays off. */
+		samsung_phy->hs_clk_rate = target_rate;
+	} else {
+		samsung_mipi_dcphy_pll_calc_rate(samsung, target_rate);
+		opts->mipi_dphy.hs_clk_rate = samsung->pll.rate;
+	}
 
 	return 0;
 }

-- 
2.43.0

