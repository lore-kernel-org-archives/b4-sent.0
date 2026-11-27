From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Fri, 27 Nov 2026 16:27:06 +0100
Subject: [PATCH v5 05/12] phy: amlogic: meson-hdmi-tx: Add GXBB, GXL, GXM
 and G12A support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-meson-drm-create-hdmitx-phy-v5-5-88c43eb95468@aliel.fr>
References: <20261127-meson-drm-create-hdmitx-phy-v5-0-88c43eb95468@aliel.fr>
In-Reply-To: <20261127-meson-drm-create-hdmitx-phy-v5-0-88c43eb95468@aliel.fr>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Vinod Koul <vkoul@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, dri-devel@lists.freedesktop.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>, linux-pm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=16124;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=NTBs97DfwG0vi9rOD5s28+413MIcEak0TE0xF2PdIi0=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQzbnwn4O/Umn15S81tm86OvJwMS7rw4+mfjt1eZ/EtO7m
 J73Pv1+uaOUhUGMi0FWTJGlf67liXeXj575ukc9BWYOKxPIEAYuTgGYSO1mRoZjHsLyOe8+Mge9
 MN6wfOm+6Yuu2b7iL7wv5TBt25MF9077MDL8mC16cYa18vnXXp3MSzfsW35w5m9BPr55P/lneYr
 8PGDLDwA=
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the Meson8 HDMI TX PHY driver  for the HDMI TX PHY found on
Amlogic GXBB, GXL, GXM and G12A SoCs. The PHY is controlled through
the HHI_HDMI_PHY_CNTL0..5 registers of the same HHI system controller,
but differ in the analog settings, in the CNTL1 enable bits
(FIFO enable and FIFO write enable on GXBB and newer) and in the
presence of CNTL3 to CNTL5. The PHY node is a child of the HHI syscon,
so the regmap is still obtained from the parent syscon.

To support this, move the Meson8 hardcoded values into per-SoC match
data (register init values, rate table and maximum TMDS character
rate). The TMDS clock is now only requested on Meson8, the only SoC
where it is needed.

The driver now implements the generic PHY HDMI configuration options:
.validate() accepts only 8 bpc and a TMDS character rate covered by
the per-SoC table, .configure() programs the analog settings matching
that rate, and .power_on()/.power_off() handle the reset sequence and
the return to the initial state. The Meson8 behaviour is preserved,
except that the analog settings are now programmed from .configure()
instead of .power_on(), and that the reset sequence uses
read-modify-write updates of the CNTL1 enable bits.

The per-SoC register values and rate thresholds for GXBB and newer are
taken from the existing HDMI TX code in meson_dw_hdmi.c, so that the
PHY handling can be moved out of the display driver.

For DTs that do not provide a "phys" property on the HDMI TX node,
export meson_hdmi_phy_create_legacy() so that the display driver can
still create the PHY itself. It is marked as deprecated and will be
removed together with the fallback in meson_dw_hdmi.c.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/phy/amlogic/phy-meson-hdmi-tx.c | 341 ++++++++++++++++++++++++++------
 include/linux/phy/phy-meson-hdmi-tx.h   |  19 ++
 2 files changed, 305 insertions(+), 55 deletions(-)

diff --git a/drivers/phy/amlogic/phy-meson-hdmi-tx.c b/drivers/phy/amlogic/phy-meson-hdmi-tx.c
index e4e606ab4eef..158b13e26a55 100644
--- a/drivers/phy/amlogic/phy-meson-hdmi-tx.c
+++ b/drivers/phy/amlogic/phy-meson-hdmi-tx.c
@@ -1,18 +1,27 @@
 // SPDX-License-Identifier: GPL-2.0+
 /*
  * Amlogic Meson HDMI TX PHY driver
- * (Meson8/8b/8m2)
+ * (Meson8/8b/8m2, GXBB / GXL / GXM / G12A)
  *
  * Copyright (C) 2021 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
+ * Copyright (C) 2026 Ronald Claveau <linux-kernel-dev@aliel.fr>
+ *
+ * GXBB+ support Based on meson_dw_hdmi.c:
+ * Copyright (C) 2016 BayLibre, SAS
+ * Author: Neil Armstrong <narmstrong@baylibre.com>
+ * Copyright (C) 2015 Amlogic, Inc. All rights reserved.
  */
 
 #include <linux/bitfield.h>
 #include <linux/bits.h>
 #include <linux/clk.h>
+#include <linux/delay.h>
 #include <linux/mfd/syscon.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/phy/phy.h>
+#include <linux/phy/phy-hdmi.h>
+#include <linux/phy/phy-meson-hdmi-tx.h>
 #include <linux/platform_device.h>
 #include <linux/regmap.h>
 
@@ -22,26 +31,167 @@
  * Magic register values in the driver below are taken from the vendor
  * BSP / kernel.
  */
-#define HHI_HDMI_PHY_CNTL0				0x3a0
-	#define HHI_HDMI_PHY_CNTL0_HDMI_CTL1		GENMASK(31, 16)
-	#define HHI_HDMI_PHY_CNTL0_HDMI_CTL0		GENMASK(15, 0)
-
-#define HHI_HDMI_PHY_CNTL1				0x3a4
-	#define HHI_HDMI_PHY_CNTL1_CLOCK_ENABLE		BIT(1)
-	#define HHI_HDMI_PHY_CNTL1_SOFT_RESET		BIT(0)
+#define HHI_HDMI_PHY_CNTL0	0x3a0 /* 0xe8 */
+#define HHI_HDMI_PHY_CNTL1	0x3a4 /* 0xe9 */
+#define  PHY_CNTL1_INIT		0x03900000
+#define  PHY_INVERT		BIT(17)
+#define  PHY_CNTL1_SOFT_RESET	BIT(0)
+#define  PHY_CNTL1_CLOCK_EN	BIT(1)
+#define  PHY_CNTL1_FIFO_EN	BIT(2)	/* GXBB and newer */
+#define  PHY_CNTL1_FIFO_WR_EN	BIT(3)	/* GXBB and newer */
+
+#define HHI_HDMI_PHY_CNTL2	0x3a8 /* 0xea */
+#define HHI_HDMI_PHY_CNTL3	0x3ac /* 0xeb, GXBB and newer */
+#define HHI_HDMI_PHY_CNTL4	0x3b0 /* 0xec */
+#define HHI_HDMI_PHY_CNTL5	0x3b4 /* 0xed, G12A */
+
+/* The code resets the PHY 3 times in a row */
+#define PHY_RESET_COUNT		3
+
+struct meson_hdmi_phy_rate {
+	unsigned int min_rate;	/* TMDS character rate, in Hz */
+	u32 cntl0;
+	u32 cntl3;		/* only used if has_cntl3 */
+	u32 cntl5;		/* only used if has_cntl5 */
+};
 
-#define HHI_HDMI_PHY_CNTL2				0x3a8
+struct meson_hdmi_phy_data {
+	const struct meson_hdmi_phy_rate *rates;
+	unsigned int num_rates;
+	unsigned int max_rate;	/* Hz, TMDS character rate maximum */
+	bool has_tmds_clk;	/* Meson8 only */
+	bool has_cntl3;
+	bool has_cntl5;
+	u32 cntl0_init;
+	u32 cntl1_init;
+	u32 cntl1_en;		/* CNTL1 enable bits (clock, fifo, ...) */
+};
 
 struct meson_hdmi_phy {
-	struct regmap		*hhi;
-	struct clk		*tmds_clk;
+	struct regmap *hhi;
+	struct clk *tmds_clk;	/* optional, Meson8 only */
+	const struct meson_hdmi_phy_data *data;
+};
+
+/* Meson8, Meson8b, Meson8m2 */
+static const struct meson_hdmi_phy_rate meson8_rates[] = {
+	/* 2.97Gbps */
+	{ 297000000, 0x08c31e8b },
+	/* below 2.97Gbps, down to 250Mbps */
+	{ 25000000,  0x08c34d0b },
+};
+
+/* GXBB */
+static const struct meson_hdmi_phy_rate gxbb_rates[] = {
+	/* 5.94Gbps, 3.7125Gbps */
+	{ 371250000, 0x33353245, 0x2100115b },
+	/* 2.97Gbps */
+	{ 297000000, 0x33634283, 0xb000115b },
+	/* 1.485Gbps, down to 159Mbps */
+	{ 15900000,  0x33632122, 0x2000115b },
+};
+
+/* GXL / GXM */
+static const struct meson_hdmi_phy_rate gxl_rates[] = {
+	/* 5.94Gbps, 3.7125Gbps */
+	{ 371250000, 0x333d3282, 0x2136315b },
+	/* 2.97Gbps */
+	{ 297000000, 0x33303382, 0x2036315b },
+	/* 1.485Gbps */
+	{ 148500000, 0x33303362, 0x2016315b },
+	/* 742.5Mbps, down to 159Mbps */
+	{ 15900000,  0x33604142, 0x0016315b },
+};
+
+/* G12A */
+static const struct meson_hdmi_phy_rate g12a_rates[] = {
+	/* 5.94Gbps, 3.7125Gbps */
+	{ 371250000, 0x37eb65c4, 0x2ab0ff3b, 0x0000080b },
+	/* 2.97Gbps */
+	{ 297000000, 0x33eb6262, 0x2ab0ff3b, 0x00000003 },
+	/* 1.485Gbps, down to 159Mbps */
+	{ 15900000,  0x33eb4242, 0x2ab0ff3b, 0x00000003 },
+};
+
+static const struct meson_hdmi_phy_data meson8_data = {
+	.rates = meson8_rates,
+	.num_rates = ARRAY_SIZE(meson8_rates),
+	.max_rate = 297000000, /* HDMI 1.4b limited to 4k@30 */
+	.has_tmds_clk = true,
+	.cntl0_init = 0x08418d00,
+	.cntl1_init = 0x0,
+	.cntl1_en = PHY_CNTL1_CLOCK_EN,
+};
+
+static const struct meson_hdmi_phy_data gxbb_data = {
+	.rates = gxbb_rates,
+	.num_rates = ARRAY_SIZE(gxbb_rates),
+	.max_rate  = 600000000, /* HDMI 2.0 */
+	.has_cntl3 = true,
+	.cntl0_init = 0x0,
+	.cntl1_init = PHY_CNTL1_INIT | PHY_INVERT,
+	.cntl1_en = PHY_CNTL1_CLOCK_EN | PHY_CNTL1_FIFO_EN |
+		    PHY_CNTL1_FIFO_WR_EN,
+};
+
+static const struct meson_hdmi_phy_data gxl_data = {
+	.rates = gxl_rates,
+	.num_rates = ARRAY_SIZE(gxl_rates),
+	.max_rate  = 600000000, /* HDMI 2.0 */
+	.has_cntl3 = true,
+	.cntl0_init = 0x0,
+	.cntl1_init = PHY_CNTL1_INIT,
+	.cntl1_en = PHY_CNTL1_CLOCK_EN | PHY_CNTL1_FIFO_EN |
+		    PHY_CNTL1_FIFO_WR_EN,
+};
+
+static const struct meson_hdmi_phy_data g12a_data = {
+	.rates = g12a_rates,
+	.num_rates = ARRAY_SIZE(g12a_rates),
+	.max_rate  = 600000000, /* HDMI 2.0 */
+	.has_cntl3 = true,
+	.has_cntl5 = true,
+	.cntl0_init = 0x000b4242, /* Bandgap */
+	.cntl1_init = PHY_CNTL1_INIT,
+	.cntl1_en = PHY_CNTL1_CLOCK_EN | PHY_CNTL1_FIFO_EN |
+		    PHY_CNTL1_FIFO_WR_EN,
 };
 
+static const struct meson_hdmi_phy_rate *
+meson_hdmi_phy_find_rate(const struct meson_hdmi_phy_data *data, u64 rate)
+{
+	unsigned int i;
+
+	if (rate > data->max_rate)
+		return NULL;
+
+	for (i = 0; i < data->num_rates; i++)
+		if (rate >= data->rates[i].min_rate)
+			return &data->rates[i];
+
+	return NULL;
+}
+
+/* Fallback to init mode: CNTL1 first, then CNTL0 (order matters) */
+static void meson_hdmi_phy_set_init_state(struct meson_hdmi_phy *priv)
+{
+	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL1, priv->data->cntl1_init);
+	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, priv->data->cntl0_init);
+}
+
 static int meson_hdmi_phy_init(struct phy *phy)
 {
 	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
+	int ret;
 
-	return clk_prepare_enable(priv->tmds_clk);
+	/* No-op if there is no clock (GXBB and newer) */
+	ret = clk_prepare_enable(priv->tmds_clk);
+	if (ret)
+		return ret;
+
+	meson_hdmi_phy_set_init_state(priv);
+
+	return 0;
 }
 
 static int meson_hdmi_phy_exit(struct phy *phy)
@@ -53,33 +203,64 @@ static int meson_hdmi_phy_exit(struct phy *phy)
 	return 0;
 }
 
-static int meson_hdmi_phy_power_on(struct phy *phy)
+static int meson_hdmi_phy_configure(struct phy *phy,
+				    union phy_configure_opts *opts)
 {
 	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
-	unsigned int i;
-	u16 hdmi_ctl0;
+	const struct meson_hdmi_phy_rate *r;
+
+	r = meson_hdmi_phy_find_rate(priv->data, opts->hdmi.tmds_char_rate);
+	if (!r)
+		return -EINVAL;
+
+	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, r->cntl0);
+	if (priv->data->has_cntl3)
+		regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, r->cntl3);
+	if (priv->data->has_cntl5)
+		regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL5, r->cntl5);
+
+	/* Disable clock, (and fifo, fifo_wr where present), release reset */
+	regmap_update_bits(priv->hhi, HHI_HDMI_PHY_CNTL1,
+			   priv->data->cntl1_en | PHY_CNTL1_SOFT_RESET, 0);
 
-	if (clk_get_rate(priv->tmds_clk) >= 2970UL * 1000 * 1000)
-		hdmi_ctl0 = 0x1e8b;
-	else
-		hdmi_ctl0 = 0x4d0b;
+	return 0;
+}
+
+static int meson_hdmi_phy_validate(struct phy *phy, enum phy_mode mode,
+				   int submode, union phy_configure_opts *opts)
+{
+	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
 
-	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0,
-		     FIELD_PREP(HHI_HDMI_PHY_CNTL0_HDMI_CTL1, 0x08c3) |
-		     FIELD_PREP(HHI_HDMI_PHY_CNTL0_HDMI_CTL0, hdmi_ctl0));
+	if (mode != PHY_MODE_HDMI || submode != PHY_HDMI_MODE_TMDS)
+		return -EINVAL;
 
-	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL1, 0x0);
+	if (opts->hdmi.bpc != 8)
+		return -EINVAL;
 
-	/* Reset three times, just like the vendor driver does */
-	for (i = 0; i < 3; i++) {
-		regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL1,
-			     HHI_HDMI_PHY_CNTL1_CLOCK_ENABLE |
-			     HHI_HDMI_PHY_CNTL1_SOFT_RESET);
-		usleep_range(1000, 2000);
+	if (!meson_hdmi_phy_find_rate(priv->data, opts->hdmi.tmds_char_rate))
+		return -EINVAL;
+
+	return 0;
+}
 
-		regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL1,
-			     HHI_HDMI_PHY_CNTL1_CLOCK_ENABLE);
-		usleep_range(1000, 2000);
+static int meson_hdmi_phy_power_on(struct phy *phy)
+{
+	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
+	u32 en = priv->data->cntl1_en;
+	u32 mask = en | PHY_CNTL1_SOFT_RESET;
+	int i;
+
+	/* Reset PHY 3 times in a row */
+	for (i = 0; i < PHY_RESET_COUNT; i++) {
+		/* Enable and software reset */
+		regmap_update_bits(priv->hhi, HHI_HDMI_PHY_CNTL1,
+				   mask, mask);
+		fsleep(2000);
+
+		/* Enable and unreset */
+		regmap_update_bits(priv->hhi, HHI_HDMI_PHY_CNTL1,
+				   mask, en);
+		fsleep(2000);
 	}
 
 	return 0;
@@ -89,9 +270,7 @@ static int meson_hdmi_phy_power_off(struct phy *phy)
 {
 	struct meson_hdmi_phy *priv = phy_get_drvdata(phy);
 
-	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0,
-		     FIELD_PREP(HHI_HDMI_PHY_CNTL0_HDMI_CTL1, 0x0841) |
-		     FIELD_PREP(HHI_HDMI_PHY_CNTL0_HDMI_CTL0, 0x8d00));
+	meson_hdmi_phy_set_init_state(priv);
 
 	return 0;
 }
@@ -99,41 +278,90 @@ static int meson_hdmi_phy_power_off(struct phy *phy)
 static const struct phy_ops meson_hdmi_phy_ops = {
 	.init		= meson_hdmi_phy_init,
 	.exit		= meson_hdmi_phy_exit,
+	.configure	= meson_hdmi_phy_configure,
+	.validate	= meson_hdmi_phy_validate,
 	.power_on	= meson_hdmi_phy_power_on,
 	.power_off	= meson_hdmi_phy_power_off,
 	.owner		= THIS_MODULE,
 };
 
-static int meson_hdmi_phy_probe(struct platform_device *pdev)
+static struct phy *meson_hdmi_phy_alloc(struct device *dev,
+					struct regmap *hhi,
+					struct clk *tmds_clk,
+					const struct meson_hdmi_phy_data *data)
 {
-	struct device_node *np = pdev->dev.of_node;
 	struct meson_hdmi_phy *priv;
-	struct phy_provider *phy_provider;
-	struct resource *res;
 	struct phy *phy;
 
-	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
-	if (!res)
-		return -EINVAL;
-
-	priv = devm_kzalloc_obj(&pdev->dev, *priv);
+	priv = devm_kzalloc_obj(dev, *priv);
 	if (!priv)
-		return -ENOMEM;
+		return ERR_PTR(-ENOMEM);
 
-	priv->hhi = syscon_node_to_regmap(np->parent);
-	if (IS_ERR(priv->hhi))
-		return PTR_ERR(priv->hhi);
+	priv->hhi = hhi;
+	priv->tmds_clk = tmds_clk;
+	priv->data = data;
 
-	priv->tmds_clk = devm_clk_get(&pdev->dev, NULL);
-	if (IS_ERR(priv->tmds_clk))
-		return PTR_ERR(priv->tmds_clk);
-
-	phy = devm_phy_create(&pdev->dev, np, &meson_hdmi_phy_ops);
+	phy = devm_phy_create(dev, NULL, &meson_hdmi_phy_ops);
 	if (IS_ERR(phy))
-		return PTR_ERR(phy);
+		return phy;
 
 	phy_set_drvdata(phy, priv);
 
+	return phy;
+}
+
+/*
+ * DEPRECATED: only for DTs without a "phys" property on the HDMI TX node.
+ * Remove together with the fallback in meson_dw_hdmi.c.
+ */
+struct phy *meson_hdmi_phy_create_legacy(struct device *dev,
+					 struct regmap *hhi,
+					 enum meson_hdmi_phy_soc soc)
+{
+	static const struct meson_hdmi_phy_data *const soc_data[] = {
+		[MESON_HDMI_PHY_GXBB] = &gxbb_data,
+		[MESON_HDMI_PHY_GXL]  = &gxl_data,
+		[MESON_HDMI_PHY_G12A] = &g12a_data,
+	};
+
+	if (soc >= ARRAY_SIZE(soc_data))
+		return ERR_PTR(-EINVAL);
+
+	return meson_hdmi_phy_alloc(dev, hhi, NULL, soc_data[soc]);
+}
+EXPORT_SYMBOL_GPL(meson_hdmi_phy_create_legacy);
+
+static int meson_hdmi_phy_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	const struct meson_hdmi_phy_data *data;
+	struct phy_provider *phy_provider;
+	struct clk *tmds_clk = NULL;
+	struct regmap *hhi;
+	struct phy *phy;
+
+	data = of_device_get_match_data(dev);
+	if (!data)
+		return -EINVAL;
+
+	/* The PHY node is a child of the HHI syscon */
+	hhi = syscon_node_to_regmap(dev->of_node->parent);
+	if (IS_ERR(hhi))
+		return dev_err_probe(dev, PTR_ERR(hhi),
+				     "failed to get HHI regmap\n");
+
+	if (data->has_tmds_clk) {
+		tmds_clk = devm_clk_get(dev, NULL);
+		if (IS_ERR(tmds_clk))
+			return dev_err_probe(dev, PTR_ERR(tmds_clk),
+					     "failed to get TMDS clock\n");
+	}
+
+	phy = meson_hdmi_phy_alloc(dev, hhi, tmds_clk, data);
+	if (IS_ERR(phy))
+		return dev_err_probe(dev, PTR_ERR(phy),
+				     "failed to create PHY\n");
+
 	phy_provider = devm_of_phy_provider_register(&pdev->dev,
 						     of_phy_simple_xlate);
 
@@ -141,7 +369,10 @@ static int meson_hdmi_phy_probe(struct platform_device *pdev)
 }
 
 static const struct of_device_id meson_hdmi_phy_of_match[] = {
-	{ .compatible = "amlogic,meson8-hdmi-tx-phy" },
+	{ .compatible = "amlogic,meson8-hdmi-tx-phy",     .data = &meson8_data },
+	{ .compatible = "amlogic,meson-gxbb-hdmi-tx-phy", .data = &gxbb_data },
+	{ .compatible = "amlogic,meson-gxl-hdmi-tx-phy",  .data = &gxl_data },
+	{ .compatible = "amlogic,meson-g12a-hdmi-tx-phy", .data = &g12a_data },
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, meson_hdmi_phy_of_match);
diff --git a/include/linux/phy/phy-meson-hdmi-tx.h b/include/linux/phy/phy-meson-hdmi-tx.h
new file mode 100644
index 000000000000..fe76a5f7efdb
--- /dev/null
+++ b/include/linux/phy/phy-meson-hdmi-tx.h
@@ -0,0 +1,19 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+#ifndef __PHY_MESON_HDMI_TX_H
+#define __PHY_MESON_HDMI_TX_H
+
+struct device;
+struct regmap;
+
+enum meson_hdmi_phy_soc {
+	MESON_HDMI_PHY_GXBB,
+	MESON_HDMI_PHY_GXL,	/* GXL and GXM */
+	MESON_HDMI_PHY_G12A,
+};
+
+/* DEPRECATED: compat for DTs without "phys" on the HDMI TX node */
+struct phy *meson_hdmi_phy_create_legacy(struct device *dev,
+					 struct regmap *hhi,
+					 enum meson_hdmi_phy_soc soc);
+
+#endif /* __PHY_MESON_HDMI_TX_H */

-- 
2.56.1

