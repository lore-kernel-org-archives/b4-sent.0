From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Fri, 20 Nov 2026 19:15:47 +0100
Subject: [PATCH v2 08/11] drm/meson: dw-hdmi: Use the generic PHY framework
 for the HDMI TX PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-meson-drm-create-hdmitx-phy-v2-8-93d622d9bb07@aliel.fr>
References: <20261120-meson-drm-create-hdmitx-phy-v2-0-93d622d9bb07@aliel.fr>
In-Reply-To: <20261120-meson-drm-create-hdmitx-phy-v2-0-93d622d9bb07@aliel.fr>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=11635;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=IVjc52VxEABKOAzLGJrtpWvfsKoBQF3cV6lCjtPlORI=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQzZDX/G5sAbzOJMpJkctbx1IVk+xWv+t5rGryxlNrbv1R
 iHzPzt3lLIwiHExyIopsvTPtTzx7vLRM1/3qKfAzGFlAhnCwMUpABOZv4WRYed8TsFvXPxGfzZ1
 3LLxZPm4+5z/6S17A1KYZh2pOZdbK87wT8tRPPFy+JErvDlPinn6tvXvyf5ox3+U7ZzMzF2ihwO
 Z+AA=
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HDMI TX PHY registers (HHI_HDMI_PHY_CNTL0..5) were programmed
directly from this driver, with per-SoC tables selected by compatible
string. A dedicated PHY driver now exists, so use it through the
generic PHY API instead:

 - phy_init() replaces the initial CNTL0/CNTL1 programming,
 - phy_configure() replaces meson_hdmi_phy_setup_mode(), the TMDS
   character rate being derived from the (possibly 4:2:0 halved) pixel
   clock, with 8 bpc as before,
 - phy_power_on() replaces the three successive PHY resets,
 - phy_power_off() replaces the fallback to the initial state in
   dw_hdmi_phy_disable().

The "hdmi" PHY is looked up through the "phys" property of the HDMI TX
node. Device trees that do not provide it keep working: in that case
the PHY is created by this driver through
meson_hdmi_phy_create_legacy(), using a per-SoC identifier replacing the
former cntl0_init/cntl1_init fields, and a warning is printed. This
fallback is deprecated and will be removed once all device trees have
been converted.

Select PHY_MESON_HDMI_TX in Kconfig since the driver
now depends on it, including for the legacy path.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/gpu/drm/meson/Kconfig         |   1 +
 drivers/gpu/drm/meson/meson_dw_hdmi.c | 162 ++++++++++------------------------
 2 files changed, 50 insertions(+), 113 deletions(-)

diff --git a/drivers/gpu/drm/meson/Kconfig b/drivers/gpu/drm/meson/Kconfig
index 6645665f6038..a91cf851314a 100644
--- a/drivers/gpu/drm/meson/Kconfig
+++ b/drivers/gpu/drm/meson/Kconfig
@@ -20,6 +20,7 @@ config DRM_MESON_DW_HDMI
 	depends on PM
 	default y if DRM_MESON
 	select DRM_DW_HDMI
+	select PHY_MESON_HDMI_TX
 	imply DRM_DW_HDMI_I2S_AUDIO
 
 config DRM_MESON_DW_MIPI_DSI
diff --git a/drivers/gpu/drm/meson/meson_dw_hdmi.c b/drivers/gpu/drm/meson/meson_dw_hdmi.c
index 20a821936b3a..1ca1ce617356 100644
--- a/drivers/gpu/drm/meson/meson_dw_hdmi.c
+++ b/drivers/gpu/drm/meson/meson_dw_hdmi.c
@@ -11,6 +11,8 @@
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/of_graph.h>
+#include <linux/phy/phy.h>
+#include <linux/phy/phy-meson-hdmi-tx.h>
 #include <linux/platform_device.h>
 #include <linux/pm_runtime.h>
 #include <linux/regulator/consumer.h>
@@ -102,16 +104,6 @@
 #define HDMITX_DWC_DATA_REG	0x14
 #define HDMITX_DWC_CTRL_REG	0x18
 
-/* HHI Registers */
-#define HHI_HDMI_PHY_CNTL0	0x3a0 /* 0xe8 */
-#define HHI_HDMI_PHY_CNTL1	0x3a4 /* 0xe9 */
-#define  PHY_CNTL1_INIT		0x03900000
-#define  PHY_INVERT		BIT(17)
-#define HHI_HDMI_PHY_CNTL2	0x3a8 /* 0xea */
-#define HHI_HDMI_PHY_CNTL3	0x3ac /* 0xeb */
-#define HHI_HDMI_PHY_CNTL4	0x3b0 /* 0xec */
-#define HHI_HDMI_PHY_CNTL5	0x3b4 /* 0xed */
-
 static DEFINE_SPINLOCK(reg_lock);
 
 enum meson_venc_source {
@@ -131,8 +123,7 @@ struct meson_dw_hdmi_data {
 				    unsigned int addr);
 	void		(*dwc_write)(struct meson_dw_hdmi *dw_hdmi,
 				     unsigned int addr, unsigned int data);
-	u32 cntl0_init;
-	u32 cntl1_init;
+	enum meson_hdmi_phy_soc phy_soc;	/* legacy PHY only */
 };
 
 struct meson_dw_hdmi {
@@ -147,6 +138,8 @@ struct meson_dw_hdmi {
 	u32 irq_stat;
 	struct dw_hdmi *hdmi;
 	struct drm_bridge *bridge;
+	struct phy *phy;
+	bool legacy_phy;
 };
 
 static inline int dw_hdmi_is_compatible(struct meson_dw_hdmi *dw_hdmi,
@@ -273,87 +266,6 @@ static inline void dw_hdmi_g12a_dwc_write(struct meson_dw_hdmi *dw_hdmi,
 
 /* Bridge */
 
-/* Setup PHY bandwidth modes */
-static void meson_hdmi_phy_setup_mode(struct meson_dw_hdmi *dw_hdmi,
-				      const struct drm_display_mode *mode,
-				      bool mode_is_420)
-{
-	struct meson_drm *priv = dw_hdmi->priv;
-	unsigned int pixel_clock = mode->clock;
-
-	/* For 420, pixel clock is half unlike venc clock */
-	if (mode_is_420) pixel_clock /= 2;
-
-	if (dw_hdmi_is_compatible(dw_hdmi, "amlogic,meson-gxl-dw-hdmi") ||
-	    dw_hdmi_is_compatible(dw_hdmi, "amlogic,meson-gxm-dw-hdmi")) {
-		if (pixel_clock >= 371250) {
-			/* 5.94Gbps, 3.7125Gbps */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x333d3282);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x2136315b);
-		} else if (pixel_clock >= 297000) {
-			/* 2.97Gbps */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x33303382);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x2036315b);
-		} else if (pixel_clock >= 148500) {
-			/* 1.485Gbps */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x33303362);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x2016315b);
-		} else {
-			/* 742.5Mbps, and below */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x33604142);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x0016315b);
-		}
-	} else if (dw_hdmi_is_compatible(dw_hdmi,
-					 "amlogic,meson-gxbb-dw-hdmi")) {
-		if (pixel_clock >= 371250) {
-			/* 5.94Gbps, 3.7125Gbps */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x33353245);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x2100115b);
-		} else if (pixel_clock >= 297000) {
-			/* 2.97Gbps */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x33634283);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0xb000115b);
-		} else {
-			/* 1.485Gbps, and below */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x33632122);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x2000115b);
-		}
-	} else if (dw_hdmi_is_compatible(dw_hdmi,
-					 "amlogic,meson-g12a-dw-hdmi")) {
-		if (pixel_clock >= 371250) {
-			/* 5.94Gbps, 3.7125Gbps */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x37eb65c4);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x2ab0ff3b);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL5, 0x0000080b);
-		} else if (pixel_clock >= 297000) {
-			/* 2.97Gbps */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x33eb6262);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x2ab0ff3b);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL5, 0x00000003);
-		} else {
-			/* 1.485Gbps, and below */
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, 0x33eb4242);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL3, 0x2ab0ff3b);
-			regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL5, 0x00000003);
-		}
-	}
-}
-
-static inline void meson_dw_hdmi_phy_reset(struct meson_dw_hdmi *dw_hdmi)
-{
-	struct meson_drm *priv = dw_hdmi->priv;
-
-	/* Enable and software reset */
-	regmap_update_bits(priv->hhi, HHI_HDMI_PHY_CNTL1, 0xf, 0xf);
-
-	mdelay(2);
-
-	/* Enable and unreset */
-	regmap_update_bits(priv->hhi, HHI_HDMI_PHY_CNTL1, 0xf, 0xe);
-
-	mdelay(2);
-}
-
 static int dw_hdmi_phy_init(struct dw_hdmi *hdmi, void *data,
 			    const struct drm_display_info *display,
 			    const struct drm_display_mode *mode)
@@ -364,10 +276,18 @@ static int dw_hdmi_phy_init(struct dw_hdmi *hdmi, void *data,
 	unsigned int wr_clk =
 		readl_relaxed(priv->io_base + _REG(VPU_HDMI_SETTING));
 	bool mode_is_420 = false;
+	unsigned int pixel_clock = mode->clock;
+	union phy_configure_opts opts = {};
+	int ret;
 
 	DRM_DEBUG_DRIVER("\"%s\" div%d\n", mode->name,
 			 mode->clock > 340000 ? 40 : 10);
 
+	/* Setup PHY */
+	ret = phy_init(dw_hdmi->phy);
+	if (ret)
+		return ret;
+
 	if (drm_mode_is_420_only(display, mode) ||
 	    (!is_hdmi2_sink && drm_mode_is_420_also(display, mode)) ||
 	    dw_hdmi_bus_fmt_is_420(hdmi))
@@ -392,19 +312,22 @@ static int dw_hdmi_phy_init(struct dw_hdmi *hdmi, void *data,
 	dw_hdmi->data->top_write(dw_hdmi, HDMITX_TOP_TMDS_CLK_PTTN_CNTL, 0x2);
 
 	/* Setup PHY parameters */
-	meson_hdmi_phy_setup_mode(dw_hdmi, mode, mode_is_420);
-
-	/* Disable clock, fifo, fifo_wr */
-	regmap_update_bits(priv->hhi, HHI_HDMI_PHY_CNTL1, 0xf, 0);
+	if (mode_is_420)
+		pixel_clock /= 2;
+	opts.hdmi.tmds_char_rate = (u64)pixel_clock * 1000;
+	opts.hdmi.bpc = 8;
+	ret = phy_configure(dw_hdmi->phy, &opts);
+	if (ret)
+		return ret;
 
 	dw_hdmi_set_high_tmds_clock_ratio(hdmi, display);
 
 	msleep(100);
 
 	/* Reset PHY 3 times in a row */
-	meson_dw_hdmi_phy_reset(dw_hdmi);
-	meson_dw_hdmi_phy_reset(dw_hdmi);
-	meson_dw_hdmi_phy_reset(dw_hdmi);
+	ret = phy_power_on(dw_hdmi->phy);
+	if (ret)
+		return ret;
 
 	/* Temporary Disable VENC video stream */
 	if (priv->venc.hdmi_use_enci)
@@ -443,13 +366,12 @@ static void dw_hdmi_phy_disable(struct dw_hdmi *hdmi,
 				void *data)
 {
 	struct meson_dw_hdmi *dw_hdmi = (struct meson_dw_hdmi *)data;
-	struct meson_drm *priv = dw_hdmi->priv;
 
 	DRM_DEBUG_DRIVER("\n");
 
 	/* Fallback to init mode */
-	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL1, dw_hdmi->data->cntl1_init);
-	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, dw_hdmi->data->cntl0_init);
+	phy_power_off(dw_hdmi->phy);
+	phy_exit(dw_hdmi->phy);
 }
 
 static enum drm_connector_status dw_hdmi_read_hpd(struct dw_hdmi *hdmi,
@@ -572,8 +494,7 @@ static const struct meson_dw_hdmi_data meson_dw_hdmi_gxbb_data = {
 	.top_write = dw_hdmi_top_write,
 	.dwc_read = dw_hdmi_dwc_read,
 	.dwc_write = dw_hdmi_dwc_write,
-	.cntl0_init = 0x0,
-	.cntl1_init = PHY_CNTL1_INIT | PHY_INVERT,
+	.phy_soc = MESON_HDMI_PHY_GXBB,
 };
 
 static const struct meson_dw_hdmi_data meson_dw_hdmi_gxl_data = {
@@ -581,8 +502,7 @@ static const struct meson_dw_hdmi_data meson_dw_hdmi_gxl_data = {
 	.top_write = dw_hdmi_top_write,
 	.dwc_read = dw_hdmi_dwc_read,
 	.dwc_write = dw_hdmi_dwc_write,
-	.cntl0_init = 0x0,
-	.cntl1_init = PHY_CNTL1_INIT,
+	.phy_soc = MESON_HDMI_PHY_GXL,
 };
 
 static const struct meson_dw_hdmi_data meson_dw_hdmi_g12a_data = {
@@ -590,8 +510,7 @@ static const struct meson_dw_hdmi_data meson_dw_hdmi_g12a_data = {
 	.top_write = dw_hdmi_g12a_top_write,
 	.dwc_read = dw_hdmi_g12a_dwc_read,
 	.dwc_write = dw_hdmi_g12a_dwc_write,
-	.cntl0_init = 0x000b4242, /* Bandgap */
-	.cntl1_init = PHY_CNTL1_INIT,
+	.phy_soc = MESON_HDMI_PHY_G12A,
 };
 
 static void meson_dw_hdmi_init(struct meson_dw_hdmi *meson_dw_hdmi)
@@ -623,10 +542,6 @@ static void meson_dw_hdmi_init(struct meson_dw_hdmi *meson_dw_hdmi)
 	/* Enable normal output to PHY */
 	meson_dw_hdmi->data->top_write(meson_dw_hdmi, HDMITX_TOP_BIST_CNTL, BIT(12));
 
-	/* Setup PHY */
-	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL1, meson_dw_hdmi->data->cntl1_init);
-	regmap_write(priv->hhi, HHI_HDMI_PHY_CNTL0, meson_dw_hdmi->data->cntl0_init);
-
 	/* Enable HDMI-TX Interrupt */
 	meson_dw_hdmi->data->top_write(meson_dw_hdmi, HDMITX_TOP_INTR_STAT_CLR,
 				       HDMITX_TOP_INTR_CORE);
@@ -746,6 +661,23 @@ static int meson_dw_hdmi_bind(struct device *dev, struct device *master,
 		return ret;
 	}
 
+	meson_dw_hdmi->phy = devm_phy_optional_get(dev, NULL);
+	if (IS_ERR(meson_dw_hdmi->phy))
+		return dev_err_probe(dev, PTR_ERR(meson_dw_hdmi->phy),
+				     "failed to get HDMI PHY\n");
+
+	if (!meson_dw_hdmi->phy) {
+		/* DEPRECATED: DT without "phys" */
+		dev_warn(dev, "missing \"phys\", using legacy HDMI PHY\n");
+		meson_dw_hdmi->phy = meson_hdmi_phy_create_legacy(dev, priv->hhi,
+						meson_dw_hdmi->data->phy_soc);
+		if (IS_ERR(meson_dw_hdmi->phy))
+			return dev_err_probe(dev, PTR_ERR(meson_dw_hdmi->phy),
+					     "failed to create legacy HDMI PHY\n");
+
+		meson_dw_hdmi->legacy_phy = true;
+	}
+
 	meson_dw_hdmi_init(meson_dw_hdmi);
 
 	/* Bridge / Connector */
@@ -786,6 +718,10 @@ static void meson_dw_hdmi_unbind(struct device *dev, struct device *master,
 
 	devm_free_irq(dev, irq, meson_dw_hdmi);
 	dw_hdmi_unbind(meson_dw_hdmi->hdmi);
+
+	if (meson_dw_hdmi->legacy_phy)
+		devm_phy_destroy(dev, meson_dw_hdmi->phy);
+
 	drm_bridge_put(meson_dw_hdmi->bridge);
 }
 

-- 
2.56.1

