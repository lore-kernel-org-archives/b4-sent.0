From: David Heidelberg <david@ixit.cz>
Date: Sun, 31 May 2026 15:08:10 +0200
Subject: [PATCH WIP v5 2/9] media: qcom: camss: csiphy-3ph: Use odd bits
 for configuring C-PHY lanes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-qcom-cphy-v5-2-6be0f62b4d65@ixit.cz>
References: <20260531-qcom-cphy-v5-0-6be0f62b4d65@ixit.cz>
In-Reply-To: <20260531-qcom-cphy-v5-0-6be0f62b4d65@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>, 
 Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=9077; i=david@ixit.cz;
 h=from:subject:message-id; bh=C25nhEU8+d+0J7rkmbVuRkhEHvtURv4/AV+MAwUrDYE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqHDK6NT/0ETpGRujnjcW4QL8ExB+zDiPJY/MTK
 Ke28h+Y3C+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCahwyugAKCRBgAj/E00kg
 chGQEACGxzctimtSiakUaIX21gllTylMYuC69CqZ51TrvIt5+7zoHRasSYE0y1Lylsqrpda1L7E
 kXanK+GdQOddECv0atvF6iCMgFUuUnyZSQmCD6YwzQvZFTi5asWoVFozpp72Bb8wUEJZiXZ7DRE
 DnBG6VHAgCEI13sTh3iCVyGL+BCh5bX5dBbOCA9EpSC9gzn5fvWL7/n9X5YWPMWPLwbGxB9/SQy
 uVeuo4QSy3vqGX5zqcjF1u5CBo5PKG1mvWzAUdMwV3EpFnKbshkWD+wV6Sr7E8DDijd24Ax/lZm
 w9qyGDdqUlKbKBw3jelWc9C8sQcA1iOHcBVqErK75aLXL5eg84OX6XGLPLZ5X9mz4Qx1tOwzy1R
 gZYKthS+VgeImGxZWLyDKzzuMMeLpq1ocHFYsLJO266MdEOYJjtGMjbhBjSt0Mi2WL0FZPt72d3
 gMse2EFDft47+VzjBwkoNNgpxSNypREXkpYUFc13+/DLlU0pslI+q/dEtzZn7ahBqmpc83kcX0v
 XFzDHLxmePO/Nxjaj0B7Ffa8rCEVN+JaFAPPFBd68OwU+nsLBRZkA/q1tq7KTmN6BfbCnN5c/g5
 f4N+vrw3qu5zmuGOAPWoL2FIc5OXCJqf37UH0IJ6e6SNSN8QQujgPn2jVv3QraddBkz9ExedICz
 mB+7iKW/VEwLc7Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So far, only D-PHY mode was supported, which uses even bits when enabling
or masking lanes. For C-PHY configuration, the hardware instead requires
using the odd bits.

Since there can be unrecognized configuration allow returning failure.

Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Acked-by: Cory Keitz <ckeitz@amazon.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-2ph-1-0.c     |  8 ++--
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 49 +++++++++++++++++-----
 drivers/media/platform/qcom/camss/camss-csiphy.c   |  5 +--
 drivers/media/platform/qcom/camss/camss-csiphy.h   |  6 +--
 4 files changed, 48 insertions(+), 20 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-2ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-2ph-1-0.c
index 9d67e7fa6366a..bb4b91f69616b 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-2ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-2ph-1-0.c
@@ -89,19 +89,19 @@ static u8 csiphy_settle_cnt_calc(s64 link_freq, u32 timer_clk_rate)
 	t_hs_settle = (t_hs_prepare_max + t_hs_prepare_zero_min) / 2;
 
 	timer_period = div_u64(1000000000000LL, timer_clk_rate);
 	settle_cnt = t_hs_settle / timer_period - 1;
 
 	return settle_cnt;
 }
 
-static void csiphy_lanes_enable(struct csiphy_device *csiphy,
-				struct csiphy_config *cfg,
-				s64 link_freq, u8 lane_mask)
+static int csiphy_lanes_enable(struct csiphy_device *csiphy,
+			       struct csiphy_config *cfg,
+			       s64 link_freq, u8 lane_mask)
 {
 	struct csiphy_lanes_cfg *c = &cfg->csi2->lane_cfg;
 	u8 settle_cnt;
 	u8 val, l = 0;
 	int i = 0;
 
 	settle_cnt = csiphy_settle_cnt_calc(link_freq, csiphy->timer_clk_rate);
 
@@ -127,16 +127,18 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 			       CAMSS_CSI_PHY_LNn_CFG2(l));
 		writel_relaxed(settle_cnt, csiphy->base +
 			       CAMSS_CSI_PHY_LNn_CFG3(l));
 		writel_relaxed(0x3f, csiphy->base +
 			       CAMSS_CSI_PHY_INTERRUPT_MASKn(l));
 		writel_relaxed(0x3f, csiphy->base +
 			       CAMSS_CSI_PHY_INTERRUPT_CLEARn(l));
 	}
+
+	return 0;
 }
 
 static void csiphy_lanes_disable(struct csiphy_device *csiphy,
 				 struct csiphy_config *cfg)
 {
 	struct csiphy_lanes_cfg *c = &cfg->csi2->lane_cfg;
 	u8 l = 0;
 	int i = 0;
diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index dac8d2ecf7995..d4624417a7424 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -9,16 +9,17 @@
  */
 
 #include "camss.h"
 #include "camss-csiphy.h"
 
 #include <linux/delay.h>
 #include <linux/interrupt.h>
 #include <linux/io.h>
+#include <linux/media-bus-format.h>
 
 #define CSIPHY_3PH_LNn_CFG1(n)			(0x000 + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG1_SWI_REC_DLY_PRG	(BIT(7) | BIT(6))
 #define CSIPHY_3PH_LNn_CFG2(n)			(0x004 + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG2_LP_REC_EN_INT	BIT(3)
 #define CSIPHY_3PH_LNn_CFG3(n)			(0x008 + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG4(n)			(0x00c + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG4_T_HS_CLK_MISS	0xa4
@@ -1108,23 +1109,32 @@ static void csiphy_gen2_config_lanes(struct csiphy_device *csiphy,
 		writel_relaxed(val, csiphy->base + r->reg_addr);
 		if (r->delay_us)
 			udelay(r->delay_us);
 	}
 }
 
 static u8 csiphy_get_lane_mask(struct csiphy_lanes_cfg *lane_cfg)
 {
-	u8 lane_mask;
-	int i;
+	u8 lane_mask = 0;
 
-	lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+	switch (lane_cfg->phy_cfg) {
+	case V4L2_MBUS_CSI2_CPHY:
+		for (int i = 0; i < lane_cfg->num_data; i++)
+			lane_mask |= BIT(lane_cfg->data[i].pos + 1);
+		break;
+	case V4L2_MBUS_CSI2_DPHY:
+		lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
 
-	for (i = 0; i < lane_cfg->num_data; i++)
-		lane_mask |= 1 << lane_cfg->data[i].pos;
+		for (int i = 0; i < lane_cfg->num_data; i++)
+			lane_mask |= BIT(lane_cfg->data[i].pos);
+		break;
+	default:
+		break;
+	}
 
 	return lane_mask;
 }
 
 static bool csiphy_is_gen2(u32 version)
 {
 	bool ret = false;
 
@@ -1143,31 +1153,46 @@ static bool csiphy_is_gen2(u32 version)
 	case CAMSS_X1E80100:
 		ret = true;
 		break;
 	}
 
 	return ret;
 }
 
-static void csiphy_lanes_enable(struct csiphy_device *csiphy,
-				struct csiphy_config *cfg,
-				s64 link_freq, u8 lane_mask)
+static int csiphy_lanes_enable(struct csiphy_device *csiphy,
+			       struct csiphy_config *cfg,
+			       s64 link_freq, u8 lane_mask)
 {
+	struct device *dev = csiphy->camss->dev;
 	struct csiphy_lanes_cfg *c = &cfg->csi2->lane_cfg;
 	struct csiphy_device_regs *regs = csiphy->regs;
 	u8 settle_cnt;
 	u8 val;
 	int i;
 
 	settle_cnt = csiphy_settle_cnt_calc(link_freq, csiphy->timer_clk_rate);
 
-	val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
-	for (i = 0; i < c->num_data; i++)
-		val |= BIT(c->data[i].pos * 2);
+	val = 0;
+
+	switch (c->phy_cfg) {
+	case V4L2_MBUS_CSI2_CPHY:
+		for (i = 0; i < c->num_data; i++)
+			val |= BIT((c->data[i].pos * 2) + 1);
+		break;
+	case V4L2_MBUS_CSI2_DPHY:
+		val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+
+		for (i = 0; i < c->num_data; i++)
+			val |= BIT(c->data[i].pos * 2);
+		break;
+	default:
+		dev_err(dev, "Unsupported bus type %d\n", c->phy_cfg);
+		return -EINVAL;
+	}
 
 	writel_relaxed(val, csiphy->base +
 		       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, 5));
 
 	val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL6_COMMON_PWRDN_B;
 	writel_relaxed(val, csiphy->base +
 		       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, 6));
 
@@ -1184,16 +1209,18 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 	else
 		csiphy_gen1_config_lanes(csiphy, cfg, settle_cnt);
 
 	/* IRQ_MASK registers - disable all interrupts */
 	for (i = 11; i < 22; i++) {
 		writel_relaxed(0, csiphy->base +
 			       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, i));
 	}
+
+	return 0;
 }
 
 static void csiphy_lanes_disable(struct csiphy_device *csiphy,
 				 struct csiphy_config *cfg)
 {
 	struct csiphy_device_regs *regs = csiphy->regs;
 
 	writel_relaxed(0, csiphy->base +
diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.c b/drivers/media/platform/qcom/camss/camss-csiphy.c
index 539ac4888b608..ec0dc9d31b585 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.c
@@ -260,16 +260,17 @@ static int csiphy_set_power(struct v4l2_subdev *sd, int on)
  * Helper function to enable streaming on CSIPHY module.
  * Main configuration of CSIPHY module is also done here.
  *
  * Return 0 on success or a negative error code otherwise
  */
 static int csiphy_stream_on(struct csiphy_device *csiphy)
 {
 	struct csiphy_config *cfg = &csiphy->cfg;
+	const struct csiphy_hw_ops *ops = csiphy->res->hw_ops;
 	s64 link_freq;
 	u8 lane_mask = csiphy->res->hw_ops->get_lane_mask(&cfg->csi2->lane_cfg);
 	u8 bpp = csiphy_get_bpp(csiphy->res->formats->formats, csiphy->res->formats->nformats,
 				csiphy->fmt[MSM_CSIPHY_PAD_SINK].code);
 	u8 num_lanes = csiphy->cfg.csi2->lane_cfg.num_data;
 	u8 val;
 
 	link_freq = camss_get_link_freq(&csiphy->subdev.entity, bpp, num_lanes);
@@ -290,19 +291,17 @@ static int csiphy_stream_on(struct csiphy_device *csiphy)
 			val |= cfg->csid_id;
 		}
 		writel_relaxed(val, csiphy->base_clk_mux);
 
 		/* Enforce reg write ordering between clk mux & lane enabling */
 		wmb();
 	}
 
-	csiphy->res->hw_ops->lanes_enable(csiphy, cfg, link_freq, lane_mask);
-
-	return 0;
+	return ops->lanes_enable(csiphy, cfg, link_freq, lane_mask);
 }
 
 /*
  * csiphy_stream_off - Disable streaming on CSIPHY module
  * @csiphy: CSIPHY device
  *
  * Helper function to disable streaming on CSIPHY module
  */
diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.h b/drivers/media/platform/qcom/camss/camss-csiphy.h
index 2ebb307be18ba..42f0134635316 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.h
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.h
@@ -70,19 +70,19 @@ struct csiphy_hw_ops {
 	 * @lane_cfg - CSI2 lane configuration
 	 *
 	 * Return lane mask
 	 */
 	u8 (*get_lane_mask)(struct csiphy_lanes_cfg *lane_cfg);
 	void (*hw_version_read)(struct csiphy_device *csiphy,
 				struct device *dev);
 	void (*reset)(struct csiphy_device *csiphy);
-	void (*lanes_enable)(struct csiphy_device *csiphy,
-			     struct csiphy_config *cfg,
-			     s64 link_freq, u8 lane_mask);
+	int (*lanes_enable)(struct csiphy_device *csiphy,
+			    struct csiphy_config *cfg,
+			    s64 link_freq, u8 lane_mask);
 	void (*lanes_disable)(struct csiphy_device *csiphy,
 			      struct csiphy_config *cfg);
 	irqreturn_t (*isr)(int irq, void *dev);
 	int (*init)(struct csiphy_device *csiphy);
 };
 
 struct csiphy_subdev_resources {
 	u8 id;

-- 
2.53.0

